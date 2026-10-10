# SPDX-License-Identifier: GPL-3.0-or-later
import copy
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from validate_nationwide_survey import validate


class SurveyBookkeepingTest(unittest.TestCase):
    def setUp(self):
        self.population = [dict(municipality_code="012345", prefecture="架空県", municipality="架空市",
                                rank_total="1", population_total="10")]
        self.row = {**self.population[0], "rank_total": 1, "population_total": 10,
                    "status": "unresearched", "sources": [], "assignment_units": [], "findings": [],
                    "unresolved": ["資料未確認"], "model": None, "effort": None, "checked_on": None,
                    "coverage": {"whole_municipality": False, "known_subareas": None, "examined_subareas": 0}}

    def partial(self):
        r = copy.deepcopy(self.row)
        r.update(status="partial", model="gpt-6-luna", effort="high", checked_on="2026-10-10",
                 sources=[dict(url="https://example.org/waste", title="架空資料", access="read",
                               locator="地区一覧", notes="テスト用")])
        return r

    def test_unresearched_is_not_executed(self):
        self.assertEqual(validate([self.row], self.population)["statuses"], {"unresearched": 1})
        self.row["model"] = "gpt-6-luna"
        with self.assertRaisesRegex(ValueError, "marked as executed"):
            validate([self.row], self.population)

    def test_missing_and_duplicate_municipalities(self):
        for rows in [[], [self.row, self.row]]:
            with self.assertRaises(ValueError):
                validate(rows, self.population)

    def test_identity_cannot_drift(self):
        self.row["population_total"] = 9
        with self.assertRaisesRegex(ValueError, "Changed population"):
            validate([self.row], self.population)

    def test_partial_requires_actual_body_reading(self):
        r = self.partial()
        self.assertEqual(validate([r], self.population)["statuses"], {"partial": 1})
        r["sources"][0]["access"] = "search_only"
        with self.assertRaisesRegex(ValueError, "Body reading"):
            validate([r], self.population)

    def test_counts_need_units_and_denominator(self):
        r = self.partial()
        r["coverage"]["examined_subareas"] = 1
        with self.assertRaisesRegex(ValueError, "unit and basis"):
            validate([r], self.population)
        r["coverage"].update(unit="収集区域", count_basis="公式資料の表", whole_municipality=True)
        with self.assertRaisesRegex(ValueError, "scope evidence"):
            validate([r], self.population)

    def test_complete_cannot_be_claimed_from_one_source(self):
        r = self.partial()
        r["status"] = "research_complete"
        with self.assertRaisesRegex(ValueError, "unresolved coverage"):
            validate([r], self.population)
        r["coverage"].update(known_subareas=1, examined_subareas=1, unit="収集区域", count_basis="表の全行",
                             whole_municipality=True, scope_evidence="架空の証拠")
        r["unresolved"] = []
        with self.assertRaisesRegex(ValueError, "MR01-09"):
            validate([r], self.population)

    def test_model_and_effort_are_explicit(self):
        for model, effort in [("gpt-6-sol", "high"), ("gpt-6-luna", "low")]:
            r = self.partial()
            r.update(model=model, effort=effort)
            with self.assertRaisesRegex(ValueError, "model/effort"):
                validate([r], self.population)

    def test_unresolved_items_are_required(self):
        r = self.partial()
        r["unresolved"] = []
        with self.assertRaisesRegex(ValueError, "what remains"):
            validate([r], self.population)

    def test_failed_search_is_not_forced_into_unresearched_or_a_guessed_url(self):
        r = self.partial()
        r.update(status="blocked", sources=[])
        with self.assertRaisesRegex(ValueError, "search evidence"):
            validate([r], self.population)
        r["attempts"] = [{"method": "web_search", "query": "架空市 公式 ごみ収集日",
                          "outcome": "official_source_not_verified"}]
        self.assertEqual(validate([r], self.population)["statuses"], {"blocked": 1})


if __name__ == "__main__":
    unittest.main()
