#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-or-later
"""Monitor cleared CSV catalogs. Never extracts garbage rules or publishes data.

Raw bodies stay in a private cache. Reports/candidates contain metadata only.
"""
import argparse
import csv
from datetime import datetime, timedelta, timezone
import hashlib
from email.utils import parsedate_to_datetime, format_datetime
import io
import json
import os
from pathlib import Path
import re
import sys
import time
import urllib.error
import urllib.request
import uuid
from urllib.parse import urlparse
from validate_sources import validate_registry, RegistryError

ROOT = Path(__file__).resolve().parents[1]
DEFAULT_SOURCES = ["toshima-facilities", "toshima-open-data-list"]
MAX_BYTES = 2 * 1024 * 1024
USER_AGENT = "gomimap-source-monitor/1.0 (+https://github.com/oukiito/gomimap)"


class MonitorError(ValueError):
    pass


class NoRedirect(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, *args, **kwargs):
        return None


def fetch(url, headers):
    request = urllib.request.Request(url, headers={"User-Agent": USER_AGENT, **headers})
    opener = urllib.request.build_opener(NoRedirect)
    for attempt in range(3):
        try:
            with opener.open(request, timeout=20) as response:
                content = response.read(MAX_BYTES + 1)
                if len(content) > MAX_BYTES:
                    raise MonitorError("Response exceeds the size limit")
                return response.status, dict(response.headers), content
        except urllib.error.HTTPError as error:
            if error.code == 304:
                return 304, dict(error.headers), b""
            if error.code >= 500 and attempt < 2:
                time.sleep(2 ** attempt)
                continue
            raise MonitorError(f"HTTP {error.code}; body not retained") from None
        except (urllib.error.URLError, TimeoutError, OSError):
            if attempt < 2:
                time.sleep(2 ** attempt)
                continue
            raise MonitorError("Network request failed") from None
    raise MonitorError("Retry limit reached")


def safe_header(value):
    if value is None:
        return None
    if not isinstance(value, str) or len(value) > 512 or "\r" in value or "\n" in value:
        raise MonitorError("Invalid conditional-response header")
    return value


def csv_metadata(content, expected_columns):
    if not 1 <= len(content) <= MAX_BYTES:
        raise MonitorError("Empty or oversized CSV")
    try:
        text = content.decode("utf-8-sig")
    except UnicodeDecodeError:
        try:
            text = content.decode("cp932")
        except UnicodeDecodeError:
            raise MonitorError("Unsupported CSV encoding") from None
    try:
        records = csv.reader(io.StringIO(text, newline=""), strict=True)
        columns = next(records)
        if columns != expected_columns or len(set(columns)) != len(columns):
            raise MonitorError("CSV header changed; source review required")
        count = 0
        for row in records:
            if not row or all(not value for value in row):
                continue
            if len(row) != len(columns) or any(len(value) > 16000 for value in row):
                raise MonitorError("Malformed CSV row")
            count += 1
            if count > 100000:
                raise MonitorError("CSV row limit exceeded")
        if count == 0:
            raise MonitorError("CSV contains no data rows")
        return {"sha256": hashlib.sha256(content).hexdigest(), "bytes": len(content),
                "rows": count, "columns": columns}
    except (csv.Error, StopIteration):
        raise MonitorError("Invalid CSV") from None


def replace(path, content):
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_name(path.name + "." + uuid.uuid4().hex + ".pending")
    with os.fdopen(os.open(temporary, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600), "wb") as stream:
        stream.write(content)
        stream.flush()
        os.fsync(stream.fileno())
    os.chmod(temporary, 0o600)
    temporary.replace(path)


class SourceMonitor:
    def __init__(self, registry, cache, downloader=fetch, clock=None):
        self.registry = registry
        self.sources = validate_registry(registry)
        self.cache = Path(cache)
        self.downloader = downloader
        self.clock = clock or (lambda: datetime.now(timezone.utc))

    def eligible(self, source):
        return source["kind"] == "csv" and source["rights"]["archive"] == "allowed" and source["validity"] == "current_reference"

    def check(self, identifier):
        source = self.sources[identifier]
        if not self.eligible(source):
            raise MonitorError("Source is not cleared for catalog monitoring")
        if not re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9._-]{0,119}", identifier):
            raise MonitorError("Unsafe source ID")
        if not source.get("retrieval_metadata", {}).get("columns"):
            raise MonitorError("CSV schema has not been reviewed")
        uri = urlparse(source["url"])
        if uri.scheme != "https" or uri.username or uri.query or uri.fragment:
            raise MonitorError("Unsafe source URL")
        directory = self.cache / identifier
        old = None
        old_body = None
        try:
            snapshot = directory / "snapshot.json"
            if snapshot.stat().st_size > 65536:
                raise MonitorError("Cached snapshot is oversized")
            value = json.loads(snapshot.read_text())
            if not isinstance(value, dict) or value.get("snapshotVersion") != 1:
                raise MonitorError("Unknown cached snapshot")
            if value["url"] == source["url"] and re.fullmatch(r"[a-f0-9]{64}", value["metadata"]["sha256"]):
                cached = directory / (value["metadata"]["sha256"] + ".csv")
                if cached.stat().st_size > MAX_BYTES:
                    raise MonitorError("Cached CSV is oversized")
                body = cached.read_bytes()
                if csv_metadata(body, source["retrieval_metadata"]["columns"]) == {k: value["metadata"][k] for k in ["sha256", "bytes", "rows", "columns"]}:
                    old = value
                    old_body = body
        except (OSError, ValueError, KeyError, TypeError):
            pass
        conditional = {}
        if old:
            if old.get("etag"):
                conditional["If-None-Match"] = safe_header(old["etag"])
            elif old["metadata"].get("last_modified"):
                conditional["If-Modified-Since"] = safe_header(old["metadata"]["last_modified"])
        status, headers, body = self.downloader(source["url"], conditional)
        headers = {k.lower(): v for k, v in headers.items()}
        if status == 304:
            if old is None:
                raise MonitorError("304 without a validated complete snapshot")
            body = old_body
            metadata = dict(old["metadata"])
        elif status == 200:
            metadata = csv_metadata(body, source["retrieval_metadata"]["columns"])
            last_modified = safe_header(headers.get("last-modified"))
            if last_modified:
                try:
                    last_modified = format_datetime(parsedate_to_datetime(last_modified).astimezone(timezone.utc), usegmt=True)
                except (ValueError, TypeError):
                    raise MonitorError("Invalid Last-Modified date") from None
            metadata["last_modified"] = last_modified
        else:
            raise MonitorError(f"Unexpected HTTP {status}")
        checked = self.clock().astimezone(timezone.utc).replace(microsecond=0)
        value = {"snapshotVersion": 1, "url": source["url"], "metadata": metadata,
                 "etag": safe_header(headers.get("etag")) or (old or {}).get("etag"),
                 "checkedAt": checked.isoformat().replace("+00:00", "Z")}
        replace(directory / (metadata["sha256"] + ".csv"), body)
        replace(directory / "snapshot.json", json.dumps(value, ensure_ascii=False).encode())
        changed = metadata["sha256"] != source.get("retrieval_metadata", {}).get("sha256")
        return {"sourceId": identifier, "status": "changed" if changed else "unchanged", "oldSha256": source.get("retrieval_metadata", {}).get("sha256"), **value}

    def run(self, source_ids=None):
        targets = list(source_ids) if source_ids is not None else [identifier for identifier, source in self.sources.items() if self.eligible(source)]
        if not targets or len(set(targets)) != len(targets) or any(not re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9._-]{0,119}", identifier) for identifier in targets):
            return {"reportVersion": 1, "scope": "cleared-csv-catalogs-only", "checkedAt": self.clock().astimezone(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z"), "complete": False, "results": [], "notMonitored": [{"sourceId": identifier, "reason": "not_cleared_csv_catalog"} for identifier in self.sources]}
        results = []
        omitted = [{"sourceId": identifier, "reason": "outside_monitor_contract"} for identifier in self.sources if identifier not in targets]
        for identifier in targets:
            attempted = self.clock().astimezone(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")
            try:
                if identifier not in self.sources:
                    raise MonitorError("Contract source is missing")
                result = self.check(identifier)
                result["attemptedAt"] = attempted
                results.append(result)
            except (MonitorError, OSError, ValueError) as error:
                results.append({"sourceId": identifier, "attemptedAt": attempted, "status": "failed", "error": str(error) if isinstance(error, MonitorError) else "Local validation/storage failed"})
            replace(self.cache / identifier / "last-attempt.json", json.dumps({k: results[-1][k] for k in ["sourceId", "attemptedAt", "status"]}).encode())
        now = self.clock().astimezone(timezone.utc).replace(microsecond=0)
        return {"reportVersion": 1, "scope": "cleared-csv-catalogs-only", "checkedAt": now.isoformat().replace("+00:00", "Z"),
                "complete": bool(results) and all(r["status"] != "failed" for r in results),
                "results": results, "notMonitored": omitted}


def candidate(report):
    if not report["complete"]:
        return {"candidateVersion": 1, "eligible": False, "updates": []}
    return {"candidateVersion": 1, "eligible": True,
            "updates": [{"sourceId": r["sourceId"], "oldSha256": r["oldSha256"], "metadata": r["metadata"], "checkedOn":
                        (datetime.fromisoformat(report["checkedAt"].replace("Z", "+00:00")) + timedelta(hours=9)).date().isoformat()}
                       for r in report["results"] if r["status"] == "changed"]}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source", action="append", help="Explicit contract source ID; defaults to the two cleared Toshima catalogs")
    parser.add_argument("--registry", type=Path, default=ROOT / "data/sources/toshima.json")
    parser.add_argument("--cache", type=Path, default=ROOT / ".tooling/source-monitor/cache")
    parser.add_argument("--report", type=Path, default=ROOT / ".tooling/source-monitor/report.json")
    parser.add_argument("--candidate", type=Path, default=ROOT / ".tooling/source-monitor/candidate.json")
    args = parser.parse_args()
    try:
        monitor = SourceMonitor(json.loads(args.registry.read_text()), args.cache)
        report = monitor.run(args.source or DEFAULT_SOURCES)
        replace(args.report, (json.dumps(report, ensure_ascii=False, indent=2) + "\n").encode())
        replace(args.candidate, (json.dumps(candidate(report), ensure_ascii=False, indent=2) + "\n").encode())
        print(json.dumps({"complete": report["complete"], "scope": report["scope"],
                          "counts": {status: sum(r["status"] == status for r in report["results"]) for status in ["unchanged", "changed", "failed"]},
                          "notMonitored": len(report["notMonitored"])}, ensure_ascii=False))
        return 0 if report["complete"] else 1
    except (RegistryError, ValueError, OSError):
        failure = {"reportVersion": 1, "scope": "cleared-csv-catalogs-only", "checkedAt": datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z"),
                   "complete": False, "results": [{"sourceId": "monitor-configuration", "status": "failed", "error": "Configuration/storage validation failed"}], "notMonitored": []}
        try:
            replace(args.report, (json.dumps(failure) + "\n").encode())
            replace(args.candidate, (json.dumps(candidate(failure)) + "\n").encode())
        except OSError:
            pass
        print("Monitor configuration failed; raw source contents not displayed", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
