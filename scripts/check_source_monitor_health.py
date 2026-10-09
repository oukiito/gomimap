#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-or-later
"""Read-only health probe for a scheduler OUTSIDE the monitored Actions job.

This command is not a deployed watchdog or a notification route by itself.
"""
from datetime import datetime, timedelta, timezone
import json
import sys
import urllib.request

BASE = "https://api.github.com/repos/oukiito/gomimap/actions/workflows/source-monitor.yml"


def health(workflow, runs, now):
    if workflow.get("state") != "active":
        return {"healthy": False, "reason": "workflow_not_active"}
    completed = []
    for run in runs.get("workflow_runs", []):
        if run.get("head_branch") != "main" or run.get("event") not in {"schedule", "workflow_dispatch"}:
            continue
        if run.get("status") == "completed" and run.get("conclusion") == "success":
            try:
                started = datetime.fromisoformat(run["run_started_at"].replace("Z", "+00:00"))
                if started.tzinfo is None or started > now + timedelta(minutes=1):
                    continue
                completed.append(started)
            except (KeyError, ValueError, TypeError):
                continue
    if not completed:
        return {"healthy": False, "reason": "no_valid_successful_run"}
    latest = max(completed)
    if now - latest > timedelta(days=8):
        return {"healthy": False, "reason": "successful_run_overdue", "lastSuccess": latest.isoformat()}
    valid = [r for r in runs.get("workflow_runs", []) if r.get("head_branch") == "main" and r.get("event") in {"schedule", "workflow_dispatch"}]
    if valid and valid[0].get("status") == "completed" and valid[0].get("conclusion") != "success":
        return {"healthy": False, "reason": "latest_run_failed", "lastSuccess": latest.isoformat()}
    return {"healthy": True, "reason": "within_weekly_contract", "lastSuccess": latest.isoformat()}


def get(path):
    class NoRedirect(urllib.request.HTTPRedirectHandler):
        def redirect_request(self, *args, **kwargs):
            return None
    request = urllib.request.Request(BASE + path, headers={"User-Agent": "gomimap-monitor-health", "Accept": "application/vnd.github+json"})
    with urllib.request.build_opener(NoRedirect).open(request, timeout=20) as response:
        body = response.read(1024 * 1024 + 1)
        if len(body) > 1024 * 1024:
            raise ValueError("Response exceeds limit")
        return json.loads(body)


def main():
    try:
        value = health(get(""), get("/runs?branch=main&per_page=50"), datetime.now(timezone.utc))
    except Exception:
        value = {"healthy": False, "reason": "health_could_not_be_verified"}
    print(json.dumps(value))
    return 0 if value["healthy"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
