#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-or-later
"""Check only MCP startup and metadata. Never select/control/capture a device."""

import json
import os
from pathlib import Path
import select
import subprocess
import sys
import time

ROOT = Path(__file__).resolve().parents[1]


def main():
    output = ROOT / ".tooling/maestro-mcp-preflight.json"
    output.parent.mkdir(exist_ok=True)
    log = output.with_suffix(".log")
    with log.open("w") as errors:
        os.chmod(log, 0o600)
        process = subprocess.Popen(["rtk", "proxy", sys.executable,
                                    str(ROOT / "scripts/maestro_runtime.py"),
                                    "mcp", "--no-viewer", "--working-dir", str(ROOT)],
                                   stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=errors)
        pending = bytearray()
        def send(message):
            process.stdin.write(json.dumps(message).encode() + b"\n")
            process.stdin.flush()
        def receive(identifier):
            deadline = time.monotonic() + 30
            while time.monotonic() < deadline:
                while b"\n" in pending:
                    line, _, rest = pending.partition(b"\n")
                    pending[:] = rest
                    if not line.strip():
                        continue
                    message = json.loads(line)  # Reject non-protocol stdout.
                    if message.get("id") == identifier:
                        if "error" in message:
                            raise RuntimeError("MCP returned an error")
                        return message["result"]
                if select.select([process.stdout], [], [], 1)[0]:
                    chunk = os.read(process.stdout.fileno(), 65536)
                    if not chunk:
                        raise RuntimeError("MCP server exited")
                    pending.extend(chunk)
            raise TimeoutError("MCP startup/metadata timed out")
        try:
            send({"jsonrpc": "2.0", "id": 1, "method": "initialize", "params": {
                "protocolVersion": "2024-11-05", "capabilities": {},
                "clientInfo": {"name": "gomimap-preflight", "version": "1"}}})
            initialized = receive(1)
            send({"jsonrpc": "2.0", "method": "notifications/initialized"})
            send({"jsonrpc": "2.0", "id": 2, "method": "tools/list", "params": {}})
            listed = receive(2)
            names = {tool["name"] for tool in listed["tools"]}
            if not {"list_devices", "inspect_screen", "take_screenshot", "run", "cheat_sheet"} <= names:
                raise RuntimeError("Required tools missing")
            output.write_text(json.dumps({"initialized": initialized, "tools": listed,
                                          "deviceOperations": 0}, indent=2))
            os.chmod(output, 0o600)
            print("MCP initialize/tools.list passed; device operations: 0")
        finally:
            process.terminate()
            try:
                process.wait(timeout=10)
            except subprocess.TimeoutExpired:
                process.kill()
                process.wait()


if __name__ == "__main__":
    main()
