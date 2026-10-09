# SPDX-License-Identifier: GPL-3.0-or-later
from datetime import datetime,timedelta,timezone
import importlib.util
from pathlib import Path
import unittest

spec=importlib.util.spec_from_file_location("health",Path(__file__).parents[1]/"check_source_monitor_health.py")
h=importlib.util.module_from_spec(spec);spec.loader.exec_module(h)

class Health(unittest.TestCase):
    def setUp(self):self.now=datetime(2026,10,10,tzinfo=timezone.utc)
    def run_record(self,days=1,**extra):
        return {"head_branch":"main","event":"schedule","status":"completed","conclusion":"success","run_started_at":(self.now-timedelta(days=days)).isoformat(),**extra}
    def test_weekly_success_is_healthy_but_overdue_is_not(self):
        self.assertTrue(h.health({"state":"active"},{"workflow_runs":[self.run_record()]},self.now)["healthy"])
        self.assertFalse(h.health({"state":"active"},{"workflow_runs":[self.run_record(9)]},self.now)["healthy"])
    def test_disabled_or_no_success_never_count_as_healthy(self):
        self.assertFalse(h.health({"state":"disabled_inactivity"},{"workflow_runs":[self.run_record()]},self.now)["healthy"])
        self.assertFalse(h.health({"state":"active"},{"workflow_runs":[]},self.now)["healthy"])
    def test_pr_branch_unrelated_event_and_future_timestamp_are_ignored(self):
        for run in [self.run_record(head_branch="feature"),self.run_record(event="pull_request"),self.run_record(-1)]:
            self.assertFalse(h.health({"state":"active"},{"workflow_runs":[run]},self.now)["healthy"])
    def test_recent_failure_remains_actionable_even_after_old_success(self):
        runs={"workflow_runs":[self.run_record(conclusion="failure"),self.run_record(2)]}
        self.assertEqual(h.health({"state":"active"},runs,self.now)["reason"],"latest_run_failed")
