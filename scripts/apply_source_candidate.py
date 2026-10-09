#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-or-later
"""Apply reviewed metadata candidates locally; never changes source permissions.

Inspect original allowed CSV before applying. This does not release app data.
"""
import argparse
import copy
from datetime import date, datetime, timezone, timedelta
import json
from pathlib import Path
import re
import sys
from source_monitor import MAX_BYTES, SourceMonitor, replace
from validate_sources import validate_registry


def apply_candidate(registry, candidate):
    validate_registry(registry)
    if candidate.get("candidateVersion") != 1 or candidate.get("eligible") is not True or not isinstance(candidate.get("updates"), list):
        raise ValueError("Candidate is not eligible")
    result = copy.deepcopy(registry)
    sources = {s["id"]: s for s in result["sources"]}
    seen = set()
    for update in candidate["updates"]:
        identifier = update["sourceId"]
        source = sources.get(identifier)
        if identifier in seen or source is None or source["kind"] != "csv" or source["rights"]["archive"] != "allowed" or source["rights"]["redistribution"] != "allowed" or source["validity"] != "current_reference":
            raise ValueError("Source is not cleared")
        seen.add(identifier)
        if update["oldSha256"] != source.get("retrieval_metadata", {}).get("sha256"):
            raise ValueError("Registry changed since this candidate")
        metadata = update["metadata"]
        if set(metadata) != {"sha256", "bytes", "rows", "columns", "last_modified"} or not re.fullmatch(r"[a-f0-9]{64}", metadata["sha256"]):
            raise ValueError("Invalid candidate metadata")
        if metadata["columns"] != source["retrieval_metadata"]["columns"] or type(metadata["bytes"]) is not int or not 0 < metadata["bytes"] <= MAX_BYTES or type(metadata["rows"]) is not int or not 0 < metadata["rows"] <= 100000:
            raise ValueError("Candidate schema/size changed")
        checked = date.fromisoformat(update["checkedOn"])
        if checked.isoformat() != update["checkedOn"] or checked > datetime.now(timezone(timedelta(hours=9))).date():
            raise ValueError("Invalid date")
        source["retrieval_metadata"] = copy.deepcopy(metadata)
        source["checked_on"] = update["checkedOn"]
    if seen:
        result["checked_on"] = max(s["checked_on"] for s in result["sources"])
    validate_registry(result)
    return result


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--candidate", type=Path, required=True)
    parser.add_argument("--registry", type=Path, default=Path("data/sources/toshima.json"))
    args = parser.parse_args()
    try:
        if args.candidate.stat().st_size > 1024 * 1024:
            raise ValueError("Candidate is too large")
        value = apply_candidate(json.loads(args.registry.read_text()), json.loads(args.candidate.read_text()))
        replace(args.registry, (json.dumps(value, ensure_ascii=False, indent=2) + "\n").encode())
        print("Applied reviewed metadata only; permissions unchanged; not an app-data release")
    except (OSError, ValueError, KeyError, TypeError):
        print("Candidate rejected; source data not displayed", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
