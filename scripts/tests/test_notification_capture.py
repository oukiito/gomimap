# SPDX-License-Identifier: GPL-3.0-or-later
import importlib.util
from pathlib import Path
import sys
import unittest

scripts = Path(__file__).parents[1]
sys.path.insert(0, str(scripts))
spec = importlib.util.spec_from_file_location("capture", scripts / "capture_android_notification.py")
capture = importlib.util.module_from_spec(spec)
spec.loader.exec_module(capture)


class OwnCard(unittest.TestCase):
    def test_matching_text_in_another_apps_card_is_rejected(self):
        card = {"rid": "com.android.systemui:id/expandableNotificationRow", "c": [
            {"rid": "android:id/title", "txt": "Test title"},
            {"rid": "android:id/app_name_text", "txt": "Other app"}]}
        self.assertFalse(capture.own_card([card], "Test title"))
        card["c"][1]["txt"] = "gomimap QA"
        self.assertTrue(capture.own_card([card], "Test title"))
        self.assertFalse(capture.own_card([card], "Another title"))

    def test_title_and_app_name_must_belong_to_the_same_row(self):
        rows = [
            {"rid": "com.android.systemui:id/expandableNotificationRow", "c": [{"rid": "android:id/title", "txt": "Test title"}]},
            {"rid": "com.android.systemui:id/expandableNotificationRow", "c": [{"rid": "android:id/app_name_text", "txt": "gomimap QA"}]},
        ]
        self.assertFalse(capture.own_card(rows, "Test title"))
