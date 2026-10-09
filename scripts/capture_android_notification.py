#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-or-later
"""Capture one owned, delivered QA card through a fresh Maestro MCP session.

A fresh session avoids a stale Android driver connection after emulator reboot.
Never launches QA: foreground reconciliation would replace the injected plan.
"""
import argparse
import json
import os
from pathlib import Path
import select
import subprocess
import sys
import time
from android_notification_delivery import Control, emulator_id

ROOT = Path(__file__).resolve().parents[1]


def flatten(elements):
    for element in elements:
        yield element
        yield from flatten(element.get("c", []))


def own_card(elements, title):
    for node in flatten(elements):
        if node.get("rid") != "com.android.systemui:id/expandableNotificationRow":
            continue
        children = list(flatten([node]))
        if (any(e.get("rid") == "android:id/title" and e.get("txt") == title for e in children)
                and any(e.get("rid") == "android:id/app_name_text" and e.get("txt") == "gomimap QA" for e in children)):
            return True
    return False


class FreshMaestro:
    def __init__(self, log):
        self.process = subprocess.Popen(["rtk", "proxy", sys.executable, str(ROOT / "scripts/maestro_runtime.py"),
                                         "mcp", "--no-viewer", "--working-dir", str(ROOT)],
                                        stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=log)
        self.buffer = bytearray()
        self.sequence = 0

    def call(self, method, params):
        self.sequence += 1
        key = self.sequence
        self.process.stdin.write((json.dumps({"jsonrpc": "2.0", "id": key, "method": method, "params": params}) + "\n").encode())
        self.process.stdin.flush()
        deadline = time.monotonic() + 60
        while time.monotonic() < deadline:
            while b"\n" in self.buffer:
                line, _, rest = self.buffer.partition(b"\n")
                self.buffer = bytearray(rest)
                if not line.strip():
                    continue
                message = json.loads(line)
                if message.get("id") == key:
                    if "error" in message or message.get("result", {}).get("isError"):
                        raise RuntimeError("Fresh Maestro MCP operation failed; inspect the private log")
                    return message["result"]
            if select.select([self.process.stdout], [], [], 1)[0]:
                chunk = os.read(self.process.stdout.fileno(), 65536)
                if not chunk:
                    raise RuntimeError("Fresh Maestro MCP exited")
                self.buffer.extend(chunk)
        raise TimeoutError("Maestro MCP operation timed out")

    def tool(self, name, arguments):
        result = self.call("tools/call", {"name": name, "arguments": arguments})
        value = json.loads(result["content"][0]["text"])
        if value.get("success") is False:
            raise RuntimeError("Maestro assertion failed")
        return value

    def close(self):
        self.process.terminate()
        try:
            self.process.wait(timeout=5)
        except subprocess.TimeoutExpired:
            self.process.kill()
            self.process.wait()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--adb", default="adb")
    parser.add_argument("--device", type=emulator_id, required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    proof = Control(args.adb, args.device).report()
    if not proof["delivered"]:
        parser.error("No matching automatic OS delivery to capture")
    case = proof["case"]
    title = f"テスト：予約通知 {case['case']} {case['date']}"
    output = args.output.resolve()
    if output.suffix != ".png":
        parser.error("Output must end in .png")
    output.parent.mkdir(parents=True, exist_ok=True)
    with (output.parent / "fresh-maestro-private.log").open("w") as log:
        os.chmod(log.name, 0o600)
        client = FreshMaestro(log)
        try:
            client.call("initialize", {"protocolVersion": "2024-11-05", "capabilities": {},
                                     "clientInfo": {"name": "gomimap-delivery", "version": "1"}})
            client.process.stdin.write(b'{"jsonrpc":"2.0","method":"notifications/initialized"}\n')
            client.process.stdin.flush()
            client.call("tools/list", {})
            devices = client.tool("list_devices", {})["devices"]
            if not any(d["device_id"] == args.device and d["connected"] for d in devices):
                raise RuntimeError("Requested emulator is not connected")
            client.call("tools/call", {"name": "cheat_sheet", "arguments": {}})
            arguments = {"device_id": args.device}
            screen = client.tool("inspect_screen", arguments)
            if not own_card(screen["elements"], title):
                if not any(e.get("rid") == "com.android.systemui:id/status_bar" for e in flatten(screen["elements"])):
                    raise RuntimeError("Notification shade must be reachable from the observed status bar")
                client.tool("run", {**arguments, "yaml": "appId: dev.gomimap.gomimap.qa\n---\n- swipe:\n    from:\n      id: com.android.systemui:id/status_bar\n    direction: DOWN\n    duration: 400\n"})
                screen = client.tool("inspect_screen", arguments)
            if not own_card(screen["elements"], title):
                raise RuntimeError("Matching gomimap QA notification card is absent")
            quoted = json.dumps(title, ensure_ascii=False)
            path = json.dumps(str(output.with_suffix("")))
            flow = ("appId: dev.gomimap.gomimap.qa\n---\n- assertVisible: " + quoted +
                    "\n- takeScreenshot:\n    path: " + path +
                    "\n    cropOn:\n      id: android:id/notification_main_column_container\n      containsDescendants:\n        - text: " + quoted + "\n- pressKey: Home\n")
            client.tool("run", {**arguments, "yaml": flow})
            print(json.dumps({"captured": True, "case": case["case"], "path": str(output)}, ensure_ascii=False))
        finally:
            client.close()


if __name__ == "__main__":
    main()
