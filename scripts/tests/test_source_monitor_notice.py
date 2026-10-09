# SPDX-License-Identifier: GPL-3.0-or-later
import copy
import importlib.util
from pathlib import Path
import unittest

spec=importlib.util.spec_from_file_location("notice",Path(__file__).parents[1]/"source_monitor_notice.py")
n=importlib.util.module_from_spec(spec);spec.loader.exec_module(n)

class Notices(unittest.TestCase):
    def report(self,status="unchanged"):
        return {"reportVersion":1,"scope":"cleared-csv-catalogs-only","complete":status!="failed",
                "results":[{"sourceId":"catalog","status":status,"metadata":{"sha256":"a"*64},"error":"SECRET_REMOTE_BODY"}]}
    def test_normal_check_never_calls_github(self):
        calls=[]
        self.assertEqual(n.notify(self.report(),"42",lambda *args:calls.append(args)),"quiet")
        self.assertEqual(calls,[])
    def test_failure_does_not_echo_remote_error(self):
        body=n.message(self.report("failed"),"42")
        self.assertNotIn("SECRET",body)
        self.assertIn("catalog: failed",body)
    def test_same_attention_does_not_repeat_notifications(self):
        report=self.report("changed");body=n.message(report,"42");calls=[]
        def api(method,path,value):
            calls.append(method)
            return [{"title":n.TITLE,"number":1,"body":body}]
        self.assertEqual(n.notify(report,"43",api),"unchanged_attention")
        self.assertEqual(calls,["GET"])
    def test_new_attention_creates_once_and_changed_attention_updates_same_issue(self):
        calls=[]
        def empty(method,path,value):calls.append((method,path,value));return []
        self.assertEqual(n.notify(self.report("changed"),"42",empty),"created")
        self.assertEqual(calls[-1][0],"POST")
        calls=[]
        def existing(method,path,value):calls.append((method,path,value));return [{"title":n.TITLE,"number":7,"body":"previous"}]
        self.assertEqual(n.notify(self.report("failed"),"43",existing),"updated")
        self.assertEqual(calls[-1][1],"/issues/7")
    def test_untrusted_scope_ids_and_run_urls_are_rejected(self):
        report=self.report("changed")
        for field,value in [("scope","other"),("reportVersion",2)]:
            altered=copy.deepcopy(report);altered[field]=value
            with self.assertRaises(ValueError):n.message(altered,"42")
        report["results"][0]["sourceId"]="@all\nbody"
        with self.assertRaises(ValueError):n.message(report,"42")
        with self.assertRaises(ValueError):n.message(self.report("changed"),"other/path")
