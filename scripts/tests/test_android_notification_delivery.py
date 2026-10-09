# SPDX-License-Identifier: GPL-3.0-or-later
import argparse
import importlib.util
from pathlib import Path
import unittest
from unittest.mock import patch

spec = importlib.util.spec_from_file_location("delivery", Path(__file__).parents[1] / "android_notification_delivery.py")
delivery = importlib.util.module_from_spec(spec)
spec.loader.exec_module(delivery)


class DeliverySafety(unittest.TestCase):
    def test_rejects_physical_or_injected_device_before_any_command(self):
        with patch.object(delivery.subprocess, "run") as run:
            for value in ("physical-device", "emulator-5556;reboot", "emulator-", "emulator-5556 extra"):
                with self.assertRaises(argparse.ArgumentTypeError):
                    delivery.Control("adb", value)
            run.assert_not_called()

    def test_requires_both_qemu_and_installed_qa(self):
        with patch.object(delivery.Control, "command", return_value="0") as command:
            with self.assertRaisesRegex(RuntimeError, "Emulator property"):
                delivery.Control("adb", "emulator-5556")
            self.assertEqual(command.call_count, 1)
        with patch.object(delivery.Control, "command", side_effect=["1", ""]):
            with self.assertRaisesRegex(RuntimeError, "Installed QA"):
                delivery.Control("adb", "emulator-5556")

    def test_reboot_requires_matching_prepared_case(self):
        c = object.__new__(delivery.Control)
        with patch.object(c, "marker", return_value={"case": "basic"}), patch.object(c, "command") as command:
            with self.assertRaisesRegex(RuntimeError, "Reboot is restricted"):
                c.reboot()
            command.assert_not_called()

    def test_failed_doze_releases_simulation(self):
        c = object.__new__(delivery.Control)
        with patch.object(c, "marker", return_value={"case": "doze"}), patch.object(c, "awake") as awake, patch.object(c, "command", side_effect=["", "", "mState=ACTIVE"]):
            with self.assertRaisesRegex(RuntimeError, "deep idle"):
                c.doze()
            awake.assert_called_once()

    def test_cleanup_failure_still_releases_idle_first(self):
        c = object.__new__(delivery.Control)
        calls = []
        with patch.object(c, "awake", side_effect=lambda: calls.append("awake")), patch.object(c, "command", side_effect=lambda *args: calls.append("restore") or "result=FAIL"):
            with self.assertRaises(RuntimeError):
                c.cleanup()
        self.assertEqual(calls, ["awake", "restore"])

    def test_manual_post_is_not_actual_alarm_delivery(self):
        c = object.__new__(delivery.Control)
        with patch.object(c, "marker", return_value={"case": "basic", "due": 1000}), patch.object(c, "read", return_value=[{"event": "manual", "at": 1100}]):
            self.assertFalse(c.report()["delivered"])

    def test_unrelated_or_late_post_is_not_case_delivery(self):
        c = object.__new__(delivery.Control)
        events = [
            {"event": "posted", "id": 39000, "due": 1000, "osPostTime": 1100, "at": 1100},
            {"event": "posted", "id": 30001, "due": 999, "osPostTime": 1100, "at": 1100},
            {"event": "posted", "id": 30001, "due": 1000, "osPostTime": 1200, "at": 1200},
        ]
        with patch.object(c, "marker", return_value={"case": "basic", "due": 1000, "expires": 1200}), patch.object(c, "read", return_value=events):
            self.assertFalse(c.report()["delivered"])
        events.append({"event": "posted", "id": 30001, "due": 1000, "osPostTime": 1100, "at": 1101})
        with patch.object(c, "marker", return_value={"case": "basic", "due": 1000, "expires": 1200}), patch.object(c, "read", return_value=events):
            self.assertTrue(c.report()["delivered"])
            self.assertEqual(c.report()["lagsMs"], [101])
            self.assertEqual(c.report()["osLagsMs"], [100])
