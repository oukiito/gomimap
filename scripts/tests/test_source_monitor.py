# SPDX-License-Identifier: GPL-3.0-or-later
import copy
import hashlib
import importlib.util
import json
from pathlib import Path
import sys
import tempfile
import unittest

SCRIPTS = Path(__file__).parents[1]
sys.path.insert(0, str(SCRIPTS))
spec = importlib.util.spec_from_file_location("monitor", SCRIPTS / "source_monitor.py")
m = importlib.util.module_from_spec(spec)
spec.loader.exec_module(m)


class CatalogChecks(unittest.TestCase):
    def setUp(self):
        self.registry = json.loads((SCRIPTS.parent / "data/sources/toshima.json").read_text())
        self.registry["sources"] = [s for s in self.registry["sources"] if s["id"] == "toshima-open-data-list"]
        self.source = self.registry["sources"][0]
        self.source["retrieval_metadata"]["columns"] = ["name", "value"]
        self.body = b"name,value\nsample,one\n"
        self.source["retrieval_metadata"]["sha256"] = hashlib.sha256(self.body).hexdigest()
        self.directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.directory.cleanup)
        self.calls = []

    def monitor(self, response):
        def downloader(url, headers):
            self.calls.append((url, headers))
            return response
        return m.SourceMonitor(self.registry, self.directory.name, downloader)

    def test_equal_body_is_not_changed_when_headers_change(self):
        result = self.monitor((200, {"ETag": '"one"'}, self.body)).run()
        self.assertEqual(result["results"][0]["status"], "unchanged")
        self.assertEqual(m.candidate(result)["updates"], [])
        self.assertEqual(self.monitor((200, {"ETag": '"two"'}, self.body)).run()["results"][0]["status"], "unchanged")

    def test_304_requires_valid_snapshot_and_sends_validator(self):
        self.monitor((200, {"ETag": '"one"'}, self.body)).run()
        result = self.monitor((304, {}, b"")).run()
        self.assertTrue(result["complete"])
        self.assertEqual(self.calls[-1][1], {"If-None-Match": '"one"'})
        for file in Path(self.directory.name).rglob("*.csv"):
            file.write_bytes(b"corrupted")
        result = self.monitor((304, {}, b"")).run()
        self.assertFalse(result["complete"])
        self.assertEqual(self.calls[-1][1], {})

    def test_missing_snapshot_304_and_empty_200_fail(self):
        for response in [(304, {}, b""), (200, {}, b""), (200, {}, b"name,value\n")]:
            self.assertFalse(self.monitor(response).run()["complete"])

    def test_changed_valid_body_produces_metadata_only_candidate(self):
        result = self.monitor((200, {}, b"name,value\nsample,two\n")).run()
        value = m.candidate(result)
        self.assertTrue(value["eligible"])
        self.assertEqual(len(value["updates"]), 1)
        self.assertNotIn("sample", json.dumps(value))
        self.assertNotIn("body", json.dumps(value))

    def test_unknown_header_bad_row_and_redirect_fail_without_candidate(self):
        for response in [(200, {}, b"other,header\nsample,two\n"), (200, {}, b"name,value\nthree,columns,here\n"), (302, {}, b"redirect")]:
            report = self.monitor(response).run()
            self.assertFalse(report["complete"])
            self.assertFalse(m.candidate(report)["eligible"])

    def test_uncleared_source_never_calls_network(self):
        self.source["rights"]["archive"] = "needs_review"
        report = self.monitor((200, {}, self.body)).run()
        self.assertEqual(self.calls, [])
        self.assertFalse(report["complete"])
        self.assertEqual(len(report["notMonitored"]), 1)

    def test_failed_check_preserves_success_snapshot_and_updates_attempt(self):
        self.monitor((200, {}, self.body)).run()
        directory = Path(self.directory.name) / self.source["id"]
        old = (directory / "snapshot.json").read_bytes()
        report = self.monitor((200, {}, b"broken")).run()
        self.assertFalse(report["complete"])
        self.assertEqual((directory / "snapshot.json").read_bytes(), old)
        self.assertEqual(json.loads((directory / "last-attempt.json").read_text())["status"], "failed")

    def test_header_injection_and_oversized_body_fail(self):
        for response in [(200, {"ETag": "bad\r\nvalue"}, self.body), (200, {}, b"x" * (m.MAX_BYTES + 1))]:
            self.assertFalse(self.monitor(response).run()["complete"])

    def test_contract_does_not_silently_shrink_when_rights_are_revoked(self):
        self.source["rights"]["archive"] = "needs_review"
        report=self.monitor((200, {}, self.body)).run([self.source["id"]])
        self.assertFalse(report["complete"])
        self.assertEqual(report["results"][0]["status"],"failed")
        self.assertEqual(self.calls,[])

    def test_contract_missing_source_and_unreviewed_schema_fail_before_fetch(self):
        report=self.monitor((200, {}, self.body)).run(["missing"])
        self.assertFalse(report["complete"])
        self.source["retrieval_metadata"]["columns"]=[]
        report=self.monitor((200, {}, self.body)).run([self.source["id"]])
        self.assertFalse(report["complete"])
        self.assertEqual(self.calls,[])

    def test_corrupt_cached_structure_is_ignored_and_refetched(self):
        directory=Path(self.directory.name)/self.source["id"]
        directory.mkdir();(directory/"snapshot.json").write_text('[]')
        report=self.monitor((200, {}, self.body)).run()
        self.assertTrue(report["complete"])
        self.assertEqual(self.calls[-1][1],{})

    def test_metadata_candidate_cannot_change_rights_and_rejects_stale_registry(self):
        import apply_source_candidate as a
        value=m.candidate(self.monitor((200, {}, b"name,value\nsample,two\n")).run())
        updated=a.apply_candidate(self.registry,value)
        self.assertEqual(updated["sources"][0]["rights"],self.source["rights"])
        stale=copy.deepcopy(self.registry);stale["sources"][0]["retrieval_metadata"]["sha256"]="f"*64
        with self.assertRaises(ValueError):a.apply_candidate(stale,value)
        blocked=copy.deepcopy(self.registry);blocked["sources"][0]["rights"]["redistribution"]="needs_review"
        with self.assertRaises(ValueError):a.apply_candidate(blocked,value)
