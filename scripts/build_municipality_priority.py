#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-or-later
"""Read the reviewed e-Stat 2026 workbooks without changing them.

Produces research data, never app collection schedules. Standard-library only;
the supported layout is deliberately fixed and unexpected changes fail closed.
"""
import argparse
import csv
import hashlib
import json
import re
import zipfile
from collections import Counter, defaultdict
from decimal import Decimal
from pathlib import Path
from xml.etree import ElementTree as ET

NS = {"m": "http://schemas.openxmlformats.org/spreadsheetml/2006/main"}
AS_OF = "2026-01-01"
SOURCES = {
    "total": ("000040479049", "26-03", "76378bfa269f3b3c5681eeb895929f2078a25d719bf5d3428d1394831e95df17"),
    "foreign": ("000040479057", "26-11", "725033a7dd695f7865ffbffb8a81b54b1673471ada3cf604c8214128a3aa58e6"),
}


def shared_text(node):
    # Phonetic guides (rPh) are not part of the displayed cell value.
    parts = []
    for child in node:
        if child.tag == f"{{{NS['m']}}}t":
            parts.append(child.text or "")
        elif child.tag == f"{{{NS['m']}}}r":
            parts.extend(t.text or "" for t in child.findall("m:t", NS))
    return "".join(parts)


def read_cells(path, kind):
    raw = Path(path).read_bytes()
    if hashlib.sha256(raw).hexdigest() != SOURCES[kind][2]:
        raise ValueError("Workbook differs from the reviewed source; review a revision first")
    with zipfile.ZipFile(path) as archive:
        if sum(i.file_size for i in archive.infolist()) > 32 * 1024 * 1024:
            raise ValueError("Uncompressed workbook exceeds limit")
        shared = ET.fromstring(archive.read("xl/sharedStrings.xml"))
        strings = [shared_text(n) for n in shared.findall("m:si", NS)]
        sheet = ET.fromstring(archive.read("xl/worksheets/sheet1.xml"))
        cells = {}
        for c in sheet.findall(".//m:sheetData/m:row/m:c", NS):
            value = c.find("m:v", NS)
            if value is None:
                continue
            if c.find("m:f", NS) is not None:
                raise ValueError("Unexpected formula; cached calculations must not be silently trusted")
            text = value.text or ""
            cells[c.attrib["r"]] = strings[int(text)] if c.get("t") == "s" else text
    if "令和8年1月1日" not in cells.get("A1", ""):
        raise ValueError("Wrong reference date")
    if not cells["A1"].endswith("（総計）" if kind == "total" else "（外国人住民）"):
        raise ValueError("Wrong population universe")
    for cell, expected in {"A6": "団体コード", "B6": "都道府県名", "C6": "市区町村名", "F3": "2026年", "F4": "人口", "F5": "計", "F6": "人"}.items():
        if cells.get(cell) != expected:
            raise ValueError("Unexpected column layout: " + cell)
    return cells


def count(value):
    if value is None or not re.fullmatch(r"[0-9]+(?:\.0+)?", value):
        raise ValueError("Missing/non-numeric population")
    result = Decimal(value)
    if result < 0 or result != result.to_integral_value():
        raise ValueError("Population is not a nonnegative integer")
    return int(result)


def records(cells):
    result = {}
    for key, value in cells.items():
        if not re.fullmatch(r"A\d+", key) or not re.fullmatch(r"\d{6}", value):
            continue
        row = int(key[1:])
        if value in result:
            raise ValueError("Duplicate source code")
        result[value] = {"code": value, "prefecture": cells.get(f"B{row}"),
                         "name": cells.get(f"C{row}"), "population": count(cells.get(f"F{row}")), "row": row}
    return result


def kind_of(row):
    name, code = row["name"], row["code"]
    if name == "-":
        return "prefecture_total"
    if name.endswith("区"):
        if "市" in name:
            return "administrative_ward"
        if code.startswith("13"):
            return "special_ward"
        raise ValueError("Unrecognized ward: " + name)
    for suffix, kind in [("市", "city"), ("町", "town"), ("村", "village")]:
        if name.endswith(suffix):
            return kind
    if name.endswith("郡") or name == "島しょ":
        return "district_total"
    raise ValueError("Unreviewed geographic row: " + str(name))


def join_and_rank(total, foreign):
    if total.keys() != foreign.keys():
        raise ValueError("The two source code sets differ")
    included, excluded, wards = [], [], []
    for code, t in total.items():
        f = foreign[code]
        if (t["prefecture"], t["name"]) != (f["prefecture"], f["name"]):
            raise ValueError("Name/code join mismatch")
        if f["population"] > t["population"]:
            raise ValueError("Foreign population exceeds total")
        kind = kind_of(t)
        row = {"municipality_code": code, "prefecture": t["prefecture"], "municipality": t["name"],
               "entity_type": kind, "population_total": t["population"], "population_foreign": f["population"],
               "as_of": AS_OF, "source_total_row": t["row"], "source_foreign_row": f["row"]}
        if kind == "administrative_ward":
            wards.append(row)
        elif kind in {"prefecture_total", "district_total"}:
            excluded.append(row)
        else:
            included.append(row)
    by_foreign = sorted(included, key=lambda r: (-r["population_foreign"], -r["population_total"], r["municipality_code"]))
    for i, row in enumerate(by_foreign, 1):
        row["rank_foreign"] = i
    included.sort(key=lambda r: (-r["population_total"], -r["population_foreign"], r["municipality_code"]))
    for i, row in enumerate(included, 1):
        row["rank_total"] = i
    return included, excluded, wards


def validate_rollups(included, excluded, wards, total_cells, foreign_cells):
    checks = {}
    prefectures = [r for r in excluded if r["entity_type"] == "prefecture_total"]
    if len(prefectures) != 47:
        raise ValueError("Expected all 47 prefecture totals")
    for field, cells in [("population_total", total_cells), ("population_foreign", foreign_cells)]:
        actual = sum(r[field] for r in included)
        if actual != count(cells["F7"]):
            raise ValueError("National total does not reconcile")
        for p in prefectures:
            if sum(r[field] for r in included if r["prefecture"] == p["prefecture"]) != p[field]:
                raise ValueError("Prefecture total does not reconcile: " + p["prefecture"])
        checks[field] = actual
    parents = defaultdict(list)
    for ward in wards:
        matches = [c for c in included if c["entity_type"] == "city" and c["prefecture"] == ward["prefecture"]
                   and ward["municipality"].startswith(c["municipality"])]
        if len(matches) != 1:
            raise ValueError("Administrative ward has no unique city parent")
        parents[matches[0]["municipality_code"]].append(ward)
    by_code = {r["municipality_code"]: r for r in included}
    for code, children in parents.items():
        for field in ["population_total", "population_foreign"]:
            if sum(w[field] for w in children) != by_code[code][field]:
                raise ValueError("City/ward rollup mismatch")
    if sum(r["entity_type"] == "special_ward" for r in included) != 23:
        raise ValueError("Tokyo special wards are incomplete")
    return {**checks, "ranked_records": len(included), "administrative_wards_excluded": len(wards),
            "city_ward_rollups": len(parents), "prefecture_rollups": len(prefectures),
            "aggregate_rows_excluded": len(excluded), "types": dict(Counter(r["entity_type"] for r in included)),
            "zero_population_records": [r["municipality_code"] for r in included if r["population_total"] == 0]}


def write_csv(path, rows, fields):
    with path.open("w", encoding="utf-8", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=fields, lineterminator="\n")
        writer.writeheader()
        writer.writerows(rows)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--total", required=True)
    parser.add_argument("--foreign", required=True)
    parser.add_argument("--output-dir", required=True)
    args = parser.parse_args()
    t, f = read_cells(args.total, "total"), read_cells(args.foreign, "foreign")
    ranked, excluded, wards = join_and_rank(records(t), records(f))
    checks = validate_rollups(ranked, excluded, wards, t, f)
    out = Path(args.output_dir)
    out.mkdir(parents=True, exist_ok=True)
    fields = ["rank_total", "rank_foreign", "municipality_code", "prefecture", "municipality", "entity_type",
              "population_total", "population_foreign", "as_of", "source_total_row", "source_foreign_row"]
    write_csv(out / "municipality-priority-2026.csv", ranked, fields)
    write_csv(out / "population-excluded-2026.csv", sorted(excluded + wards, key=lambda r: r["municipality_code"]), fields[2:])
    (out / "population-checks-2026.json").write_text(
        json.dumps(checks, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(checks, ensure_ascii=False))
    for row in ranked[:10]:
        print(row["rank_total"], row["municipality"], row["population_total"], row["population_foreign"])


if __name__ == "__main__":
    main()
