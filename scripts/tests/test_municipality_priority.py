# SPDX-License-Identifier: GPL-3.0-or-later
import sys
import unittest
from pathlib import Path
from xml.etree import ElementTree as ET

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import build_municipality_priority as subject


def row(code, name, population, prefecture="架空県"):
    return dict(code=code, name=name, population=population, prefecture=prefecture, row=9)


class MunicipalityPriorityTest(unittest.TestCase):
    def test_phonetic_guides_are_not_displayed_values(self):
        node = ET.fromstring(f'<si xmlns="{subject.NS["m"]}"><r><t>団体</t></r>'
                             '<r><t>コード</t></r><rPh><t>ダンタイ</t></rPh></si>')
        self.assertEqual(subject.shared_text(node), "団体コード")

    def test_missing_is_not_zero(self):
        for value in [None, "-", "秘匿", "1.5", "-1"]:
            with self.subTest(value=value), self.assertRaises(ValueError):
                subject.count(value)
        self.assertEqual(subject.count("0"), 0)

    def test_duplicate_code_rejected(self):
        with self.assertRaisesRegex(ValueError, "Duplicate"):
            subject.records({"A9": "012345", "B9": "架空県", "C9": "架空市", "F9": "1",
                             "A10": "012345", "F10": "1"})

    def test_code_and_name_must_both_match(self):
        t = {"012345": row("012345", "架空市", 10)}
        with self.assertRaisesRegex(ValueError, "code sets"):
            subject.join_and_rank(t, {})
        with self.assertRaisesRegex(ValueError, "Name/code"):
            subject.join_and_rank(t, {"012345": row("012345", "別市", 2)})
        with self.assertRaisesRegex(ValueError, "exceeds"):
            subject.join_and_rank(t, {"012345": row("012345", "架空市", 11)})

    def test_city_and_ward_not_double_counted(self):
        t = {r["code"]: r for r in [row("010006", "-", 10), row("011002", "架空市", 10),
                                    row("011011", "架空市中央区", 10), row("013005", "架空郡", 0)]}
        included, excluded, wards = subject.join_and_rank(t, t)
        self.assertEqual([r["municipality"] for r in included], ["架空市"])
        self.assertEqual(len(excluded), 2)
        self.assertEqual(len(wards), 1)
        self.assertEqual(subject.kind_of(row("131016", "架空区", 1)), "special_ward")
        self.assertEqual(subject.kind_of(row("133604", "島しょ", 1)), "district_total")

    def test_unknown_geography_is_not_silently_included(self):
        with self.assertRaisesRegex(ValueError, "Unreviewed"):
            subject.kind_of(row("012345", "未解釈合計", 1))

    def test_ranking_uses_total_then_foreign_then_code(self):
        t = {c: row(c, "架空市", p) for c, p in [("012301", 10), ("012302", 10),
                                                   ("012303", 10), ("012304", 9), ("012305", 0)]}
        f = {c: row(c, "架空市", p) for c, p in [("012301", 1), ("012302", 2),
                                                   ("012303", 2), ("012304", 9), ("012305", 0)]}
        ranked, _, _ = subject.join_and_rank(t, f)
        self.assertEqual([r["municipality_code"] for r in ranked],
                         ["012302", "012303", "012301", "012304", "012305"])
        self.assertEqual(ranked[3]["rank_foreign"], 1)

    def test_committed_inventory_reconciles_without_source_download(self):
        import csv
        import json
        root = Path(__file__).resolve().parents[2] / "data/research"
        with (root / "municipality-priority-2026.csv").open() as f:
            rows = list(csv.DictReader(f))
        with (root / "population-excluded-2026.csv").open() as f:
            excluded = list(csv.DictReader(f))
        for r in rows + excluded:
            for k in ("population_total", "population_foreign"):
                r[k] = int(r[k])
        wards = [r for r in excluded if r["entity_type"] == "administrative_ward"]
        aggregates = [r for r in excluded if r["entity_type"] != "administrative_ward"]
        result = subject.validate_rollups(rows, aggregates, wards, {"F7": "123767642"}, {"F7": "4031159"})
        self.assertEqual(result, json.loads((root / "population-checks-2026.json").read_text()))
        self.assertEqual(len({r["municipality_code"] for r in rows + excluded}), len(rows + excluded))
        expected = sorted(rows, key=lambda r: (-r["population_total"], -r["population_foreign"], r["municipality_code"]))
        self.assertEqual(rows, expected)
        self.assertEqual([int(r["rank_total"]) for r in rows], list(range(1, len(rows)+1)))
        rows[0]["population_total"] += 1
        with self.assertRaisesRegex(ValueError, "National total"):
            subject.validate_rollups(rows, aggregates, wards, {"F7": "123767642"}, {"F7": "4031159"})


if __name__ == "__main__":
    unittest.main()
