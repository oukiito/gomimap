#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-or-later
"""Validate research bookkeeping, not the truth of municipal collection rules."""
import argparse
import csv
import json
import re
from collections import Counter
from datetime import date
from pathlib import Path
from urllib.parse import urlsplit

ROOT = Path(__file__).resolve().parents[1]
STATUSES = {"unresearched", "source_identified", "partial", "blocked", "scope_review", "research_complete"}


def require(condition, message):
    if not condition:
        raise ValueError(message)


def validate(records, population):
    expected = {r["municipality_code"]: r for r in population}
    require(len(expected) == len(population), "Duplicate population code")
    actual = {}
    for r in records:
        code = r["municipality_code"]
        require(code not in actual, "Duplicate survey code: " + code)
        require(code in expected, "Unexpected survey code: " + code)
        actual[code] = r
        p = expected[code]
        for key in ("prefecture", "municipality"):
            require(r[key] == p[key], "Changed identity: " + code)
        for key in ("rank_total", "population_total"):
            require(type(r[key]) is int and r[key] == int(p[key]), "Changed population/rank: " + code)
        status = r["status"]
        require(status in STATUSES, "Unknown status: " + code)
        require(r["population_total"] != 0 or status == "scope_review", "Zero population requires scope review: " + code)
        sources = r["sources"]
        require(isinstance(sources, list), "Sources must be a list")
        for s in sources:
            url = urlsplit(s["url"])
            require(url.scheme in {"http", "https"} and url.hostname and not url.username and not url.password,
                    "Invalid source URL: " + code)
            require(s["access"] in {"read", "search_only", "failed"}, "Unknown source access: " + code)
            require(s.get("title") and s.get("locator") and s.get("notes"), "Incomplete source evidence: " + code)
        for key in ("assignment_units", "findings", "unresolved"):
            require(isinstance(r[key], list) and all(isinstance(x, str) and x.strip() for x in r[key]),
                    "Expected text list: " + key + " " + code)
        c = r["coverage"]
        require(type(c["whole_municipality"]) is bool, "Coverage flag must be boolean")
        known, examined = c["known_subareas"], c["examined_subareas"]
        require(known is None or type(known) is int and known > 0, "Invalid coverage denominator: " + code)
        require(type(examined) is int and examined >= 0, "Invalid examined count: " + code)
        require(known is None or examined <= known, "Coverage exceeds denominator: " + code)
        if known is not None or examined:
            require(c.get("unit") and c.get("count_basis"), "Coverage counts need unit and basis: " + code)
        if c["whole_municipality"]:
            require(known is not None and known == examined and c.get("scope_evidence"),
                    "Whole-area claim lacks scope evidence: " + code)
        if status in {"unresearched", "scope_review"}:
            require(not sources and not r["findings"] and not c["whole_municipality"],
                    "Unresearched record contains researched claims: " + code)
            require(r["model"] is None and r["effort"] is None and r["checked_on"] is None,
                    "Unresearched record marked as executed: " + code)
        else:
            attempts = r.get("attempts", [])
            if status == "blocked" and not sources:
                require(isinstance(attempts, list) and attempts,
                        "Source-less blockage requires search evidence: " + code)
                for attempt in attempts:
                    require(attempt.get("method") == "web_search" and attempt.get("query")
                            and attempt.get("outcome") == "official_source_not_verified",
                            "Invalid failed search evidence: " + code)
            else:
                require(sources, "Research status requires sources: " + code)
            require((r["model"], r["effort"]) == ("gpt-6-luna", "high"), "Wrong research model/effort: " + code)
            require(re.fullmatch(r"\d{4}-\d{2}-\d{2}", r["checked_on"] or ""), "Missing research date: " + code)
            date.fromisoformat(r["checked_on"])
            if status in {"partial", "research_complete"}:
                require(any(s["access"] == "read" for s in sources), "Body reading not evidenced: " + code)
            if status == "source_identified":
                require(not c["whole_municipality"], "Search evidence is not whole-area coverage: " + code)
        if status == "research_complete":
            require(c["whole_municipality"] and not r["unresolved"], "Complete record has unresolved coverage: " + code)
            mr = r.get("mr_evidence", {})
            require(set(mr) == {f"MR{i:02}" for i in range(1, 10)} and all(mr.values()),
                    "Complete research needs MR01-09 evidence: " + code)
        else:
            require(r["unresolved"], "Incomplete research must identify what remains: " + code)
    require(actual.keys() == expected.keys(), "Missing municipalities in survey")
    counts = dict(sorted(Counter(r["status"] for r in records).items()))
    return {"population_records": len(records), "positive_population_records": sum(r["population_total"] > 0 for r in records),
            "statuses": counts, "whole_municipality_claims": sum(r["coverage"]["whole_municipality"] for r in records),
            "notice": "Bookkeeping checks only; not independent verification of sources, matching, or publication permission."}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--directory", type=Path, default=ROOT / "data/research/nationwide-survey")
    args = parser.parse_args()
    with (ROOT / "data/research/municipality-priority-2026.csv").open(encoding="utf-8") as f:
        population = list(csv.DictReader(f))
    records = []
    for i in range(1, 4):
        shard = json.loads((args.directory / f"shard-{i}.json").read_text(encoding="utf-8"))
        require(all((r["rank_total"] - 1) % 3 + 1 == i for r in shard), "Wrong shard assignment")
        records.extend(shard)
    print(json.dumps(validate(records, population), ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
