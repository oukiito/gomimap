#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-or-later
"""Summarize metadata-only monitor results; report actionable changes/failures.

One fixed repository/issue title. No auto-approval, data publication, or raw CSV.
"""
import argparse
import hashlib
import json
import os
from pathlib import Path
from source_monitor import candidate
import re
import sys
import urllib.error
import urllib.request

REPOSITORY = "oukiito/gomimap"
TITLE = "Public CSV catalog monitor needs attention"
API = "https://api.github.com/repos/" + REPOSITORY


def validate(report):
    if not isinstance(report, dict):
        raise ValueError("Invalid monitor report")
    if report.get("reportVersion") != 1 or report.get("scope") != "cleared-csv-catalogs-only" or type(report.get("complete")) is not bool:
        raise ValueError("Invalid monitor report")
    results = report.get("results")
    if not isinstance(results, list) or len(results) > 100:
        raise ValueError("Invalid result list")
    for r in results:
        if not isinstance(r, dict):
            raise ValueError("Invalid source result")
        if not re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9._-]{0,119}", r.get("sourceId", "")) or r.get("status") not in {"unchanged", "changed", "failed"}:
            raise ValueError("Invalid source result")
        if r["status"] != "failed" and not re.fullmatch(r"[a-f0-9]{64}", r.get("metadata", {}).get("sha256", "")):
            raise ValueError("Invalid digest")
    return results


def message(report, run_id):
    results = validate(report)
    attention = [r for r in results if r["status"] in {"changed", "failed"}]
    if not attention and report["complete"]:
        return None
    if not re.fullmatch(r"[0-9]+", str(run_id)):
        raise ValueError("Invalid run ID")
    facts = [{"sourceId": r["sourceId"], "status": r["status"], "sha256": r.get("metadata", {}).get("sha256")} for r in attention]
    fingerprint = hashlib.sha256(json.dumps(facts, sort_keys=True).encode()).hexdigest()
    lines = [f"<!-- gomimap-source-monitor:{fingerprint} -->", "", "Scope: cleared CSV catalogs only. Garbage schedules/acceptance pages are not monitored yet.", "", "Review the source and metadata candidate before changing the registry. No automatic publication.", ""]
    lines.extend(f"- {r['sourceId']}: {r['status']}" + (f"; SHA-256 {r['sha256']}" if r['sha256'] else "; raw errors omitted") for r in facts)
    lines += ["", f"[Monitor run](https://github.com/{REPOSITORY}/actions/runs/{run_id})"]
    return "\n".join(lines)


def notify(report, run_id, api):
    body = message(report, run_id)
    if body is None:
        return "quiet"
    issues = api("GET", "/issues?state=open&creator=github-actions%5Bbot%5D&per_page=100", None)
    if not isinstance(issues, list) or any(not isinstance(i, dict) for i in issues):
        raise ValueError("Invalid GitHub issue response")
    existing = next((i for i in issues if i.get("title") == TITLE and "pull_request" not in i), None)
    if existing:
        if body.splitlines()[0] in (existing.get("body") or ""):
            return "unchanged_attention"
        api("PATCH", f"/issues/{existing['number']}", {"body": body})
        return "updated"
    api("POST", "/issues", {"title": TITLE, "body": body})
    return "created"


def github_api(token):
    class NoRedirect(urllib.request.HTTPRedirectHandler):
        def redirect_request(self, *args, **kwargs):
            return None
    opener = urllib.request.build_opener(NoRedirect)
    def request(method, path, value):
        payload = None if value is None else json.dumps(value).encode()
        req = urllib.request.Request(API + path, data=payload, method=method,
                                     headers={"Authorization": "Bearer " + token, "Accept": "application/vnd.github+json",
                                              "X-GitHub-Api-Version": "2022-11-28", "User-Agent": "gomimap-source-monitor"})
        try:
            with opener.open(req, timeout=20) as response:
                content = response.read(1024 * 1024 + 1)
                if len(content) > 1024 * 1024:
                    raise ValueError("GitHub response exceeds limit")
                return json.loads(content)
        except (urllib.error.URLError, OSError, ValueError):
            raise ValueError("GitHub notice failed; remote/token contents omitted") from None
    return request


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--report", type=Path, required=True)
    parser.add_argument("--summary", type=Path)
    parser.add_argument("--notify", action="store_true")
    args = parser.parse_args()
    try:
        if args.report.stat().st_size > 1024 * 1024:
            raise ValueError("Report is oversized")
        report = json.loads(args.report.read_text())
        results = validate(report)
        lines = ["## Cleared CSV catalog monitoring", "", "Scope: public facility/open-data catalogs; not garbage collection schedules.", "", "| Source | Result | SHA-256 |", "| --- | --- | --- |"]
        lines.extend(f"| {r['sourceId']} | {r['status']} | {r.get('metadata', {}).get('sha256', 'not validated')} |" for r in results)
        lines += ["", f"Complete for this scope: {report['complete']}", "", "The metadata candidate and raw cache are not production releases."]
        if report["complete"]:
            lines += ["", "### Metadata candidate (review before applying)", "", "```json", json.dumps(candidate(report), ensure_ascii=False, indent=2), "```"]
        if args.summary:
            with args.summary.open("a") as stream:
                stream.write("\n".join(lines) + "\n")
        if args.notify:
            token = os.environ.get("GITHUB_TOKEN")
            if not token:
                raise ValueError("Workflow token is missing")
            print(notify(report, os.environ.get("GITHUB_RUN_ID", ""), github_api(token)))
        else:
            print("summary_written")
        return 0
    except (OSError, ValueError):
        print("Monitor summary/notice failed; sensitive contents omitted", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
