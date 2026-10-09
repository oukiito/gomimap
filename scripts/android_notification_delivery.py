#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-or-later
"""QA/emulator-only notification test control. Never captures whole screens.

Use Maestro MCP for actual notification card screenshots and interaction.
Instrumentation is used only to prepare/clean up; observing must not restart QA.
"""
import argparse
import json
import re
import subprocess
from datetime import datetime, timezone

QA = "dev.gomimap.gomimap.qa"
RUNNER = QA + ".test/dev.gomimap.gomimap.WidgetChecksInstrumentation"


def emulator_id(value):
    if not re.fullmatch(r"emulator-[0-9]+", value):
        raise argparse.ArgumentTypeError("Only a dedicated emulator ID is accepted")
    return value


class Control:
    def __init__(self, adb, device):
        emulator_id(device)
        self.prefix = ["rtk", "proxy", adb, "-s", device]
        if self.command("shell", "getprop", "ro.kernel.qemu").strip() != "1":
            raise RuntimeError("Emulator property required")
        if not self.command("shell", "pm", "path", QA).strip().startswith("package:"):
            raise RuntimeError("Installed QA package required")

    def command(self, *args, optional=False):
        result = subprocess.run(self.prefix + list(args), text=True, capture_output=True, timeout=90)
        if result.returncode and not optional:
            raise RuntimeError("QA command failed: " + result.stderr.strip())
        return result.stdout if not result.returncode else ""

    def read(self, path):
        raw = self.command("shell", "run-as", QA, "cat", "files/qa-delivery/" + path, optional=True)
        return json.loads(raw) if raw.strip() else None

    def marker(self):
        value = self.read("case.json")
        if not isinstance(value, dict) or value.get("case") not in {"basic", "reboot", "doze", "expiry", "cancel"}:
            raise RuntimeError("Prepare a QA test case first")
        return value

    def prepare(self, case, delay):
        text = self.command("shell", "am", "instrument", "-w", "-e", "deliveryAction", "prepare",
                            "-e", "case", case, "-e", "delaySeconds", str(delay), RUNNER)
        if "result=PREPARED" not in text:
            raise RuntimeError(text.strip())
        return self.report()

    def report(self):
        marker = self.marker()
        events = self.read("events.json") or []
        posts = [e for e in events if e.get("event") == "posted" and e.get("id") == 30001
                 and e.get("due") == marker["due"] and e.get("osPostTime", 0) >= marker["due"]
                 and marker["due"] <= e.get("at", 0) < marker["expires"]]
        return {"case": marker, "events": events, "delivered": bool(posts),
                "lagsMs": [e["at"] - marker["due"] for e in posts],
                "osLagsMs": [e["osPostTime"] - marker["due"] for e in posts],
                "observedAt": datetime.now(timezone.utc).isoformat()}

    def cleanup(self):
        # Always release forced idle/battery simulation, even if registry restore fails.
        try:
            self.awake()
        finally:
            text = self.command("shell", "am", "instrument", "-w", "-e", "deliveryAction", "cleanup", RUNNER)
        if "result=RESTORED" not in text:
            raise RuntimeError(text.strip())
        return {"restored": True}

    def reboot(self):
        if self.marker()["case"] != "reboot":
            raise RuntimeError("Reboot is restricted to a prepared reboot case")
        self.command("reboot")
        return {"rebootRequested": True}

    def doze(self):
        if self.marker()["case"] != "doze":
            raise RuntimeError("Doze is restricted to a prepared doze case")
        try:
            self.command("shell", "dumpsys", "battery", "unplug")
            self.command("shell", "dumpsys", "deviceidle", "force-idle")
            state = self.command("shell", "dumpsys", "deviceidle")
            if not re.search(r"mState=IDLE(?:\s|$)", state):
                raise RuntimeError("Device did not enter deep idle")
        except Exception:
            self.awake()
            raise
        return {"deepIdle": True}

    def awake(self):
        try:
            self.command("shell", "dumpsys", "deviceidle", "unforce")
        finally:
            self.command("shell", "dumpsys", "battery", "reset")
        return {"forcedIdleReleased": True, "batterySimulationReset": True}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--adb", default="adb")
    parser.add_argument("--device", type=emulator_id, required=True)
    parser.add_argument("action", choices=["prepare", "report", "cleanup", "reboot", "doze", "awake"])
    parser.add_argument("--case", choices=["basic", "reboot", "doze", "expiry", "cancel"], default="basic")
    parser.add_argument("--delay-seconds", type=int, default=45)
    args = parser.parse_args()
    if not 30 <= args.delay_seconds <= 3600:
        parser.error("delay must be 30..3600 seconds")
    control = Control(args.adb, args.device)
    result = control.prepare(args.case, args.delay_seconds) if args.action == "prepare" else getattr(control, args.action)()
    print(json.dumps(result, ensure_ascii=False))


if __name__ == "__main__":
    main()
