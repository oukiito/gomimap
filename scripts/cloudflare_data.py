#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-or-later
"""Prepare, check, and initially deploy the owned fixture via official REST APIs.

No directory scanning, shell dotenv evaluation, SDK, or global credentials.
Existing Workers are refused. This is not the production update pipeline.
"""
import argparse
import base64
from dataclasses import dataclass, field
import hashlib
import json
import os
import re
import stat
import subprocess
import sys
from pathlib import Path
import urllib.error
import urllib.request
import uuid

ROOT = Path(__file__).resolve().parents[1]
SOURCE = Path("data/datasets/fixtures/toshima-demo-v1.json")
WORKER = "gomimap-data-dev"
OUT = ROOT / ".tooling/cloudflare-data"
MAX_RESPONSE = 3 * 1024 * 1024
REPOSITORY = "https://github.com/oukiito/gomimap"


class SafeError(Exception):
    """Messages must never include remote bodies, credentials, or file contents."""


class ApiError(SafeError):
    def __init__(self, status, codes=()):
        self.status = status
        self.codes = [code for code in codes if isinstance(code, int)]
        super().__init__(f"Cloudflare API failed: HTTP {status}, codes {self.codes}")


@dataclass(frozen=True)
class Credentials:
    account: str = field(repr=False)
    token: str = field(repr=False)


def load_credentials(path):
    try:
        if stat.S_IMODE(path.stat().st_mode) & 0o077:
            raise SafeError("Credential file must be readable only by its owner (chmod 600)")
        if path.stat().st_size > 8192:
            raise SafeError("Credential file is too large")
        lines = path.read_text().splitlines()
    except OSError:
        raise SafeError("Cannot read the dedicated credential file") from None
    values = {}
    required = {"CLOUDFLARE_ACCOUNT_ID", "CLOUDFLARE_API_TOKEN", "CLOUDFLARE_WORKER_NAME"}
    for line in lines:
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        key, sep, value = line.partition("=")
        key, value = key.strip(), value.strip()
        if not sep or key not in required or key in values:
            raise SafeError("Invalid or duplicate credential field")
        if len(value) >= 2 and value[0] == value[-1] and value[0] in "\"'":
            value = value[1:-1]
        values[key] = value
    if set(values) != required or not re.fullmatch(r"[a-fA-F0-9]{32}", values["CLOUDFLARE_ACCOUNT_ID"]):
        raise SafeError("Missing field or invalid account ID")
    if not re.fullmatch(r"[A-Za-z0-9_-]{20,2048}", values["CLOUDFLARE_API_TOKEN"]):
        raise SafeError("Invalid token format")
    if values["CLOUDFLARE_WORKER_NAME"] != WORKER:
        raise SafeError("This command only targets gomimap-data-dev")
    return Credentials(values["CLOUDFLARE_ACCOUNT_ID"], values["CLOUDFLARE_API_TOKEN"])


class NoRedirect(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, *args, **kwargs):
        return None


def read_limited(response):
    body = response.read(MAX_RESPONSE + 1)
    if len(body) > MAX_RESPONSE:
        raise SafeError("Response exceeds the size limit")
    return body


class Cloudflare:
    def __init__(self, credentials):
        self.credentials = credentials
        self.opener = urllib.request.build_opener(NoRedirect())

    def request(self, method, path, body=None, content_type="application/json", token=None):
        if not path.startswith("/") or ".." in path or "#" in path:
            raise SafeError("Invalid API path")
        url = f"https://api.cloudflare.com/client/v4/accounts/{self.credentials.account}{path}"
        request = urllib.request.Request(url, data=body, method=method, headers={
            "Authorization": "Bearer " + (token or self.credentials.token),
            "Content-Type": content_type,
        })
        try:
            with self.opener.open(request, timeout=30) as response:
                payload = json.loads(read_limited(response))
        except urllib.error.HTTPError as error:
            try:
                data = json.loads(read_limited(error))
                codes = [entry.get("code") for entry in (data.get("errors") or [])]
            except (ValueError, AttributeError, SafeError):
                codes = []
            finally:
                error.close()
            raise ApiError(error.code, codes) from None
        except (urllib.error.URLError, TimeoutError, ValueError, OSError):
            raise SafeError("Cloudflare connection or response validation failed") from None
        if not isinstance(payload, dict) or payload.get("success") is not True:
            raise SafeError("Cloudflare did not confirm success")
        return payload.get("result")


def json_bytes(value):
    return (json.dumps(value, ensure_ascii=False, indent=2) + "\n").encode()


def git(*args):
    result = subprocess.run(["git", *args], cwd=ROOT, capture_output=True)
    if result.returncode:
        raise SafeError("Git source verification failed")
    return result.stdout


def prepare(dart):
    """Validate canonical committed bytes with the app's actual schema validator."""
    if git("rev-parse", "--is-shallow-repository").strip() != b"false":
        raise SafeError("A full Git history is required for reproducible data provenance")
    content = (ROOT / SOURCE).read_bytes()
    if content != git("show", f"HEAD:{SOURCE.as_posix()}"):
        raise SafeError("Commit the canonical fixture before preparing a release")
    result = subprocess.run([
        str(dart), "run", "tool/validate_dataset.dart", "--allow-fixtures", str(ROOT / SOURCE),
    ], cwd=ROOT / "app", capture_output=True,
        env={**os.environ, "CI": "true", "DART_SUPPRESS_ANALYTICS": "true"})
    if result.returncode:
        raise SafeError("App dataset validation failed; nothing prepared")
    data = json.loads(content)
    if (data.get("kind"), data.get("version"), data.get("municipality", {}).get("id")) != (
        "fixture", "toshima-demo-v1", "demo-toshima",
    ):
        raise SafeError("Only the explicitly owned demo fixture is supported")
    checksum = hashlib.sha256(content).hexdigest()
    path = f"/datasets/demo-toshima/toshima-demo-v1.{checksum}.json"
    manifest = {
        "manifestVersion": 1,
        "channel": "development",
        "kind": "fixture",
        "sourceRepository": REPOSITORY,
        "sourceCommit": git("log", "-1", "--format=%H", "--", SOURCE.as_posix()).decode().strip(),
        "license": "GPL-3.0-or-later",
        "licensePath": "/LICENSE.txt",
        "datasets": [{
            "municipalityId": "demo-toshima", "version": data["version"],
            "schemaVersion": 1, "kind": "fixture", "path": path,
            "sizeBytes": len(content), "sha256": checksum,
            "validPeriod": data["validPeriod"],
        }],
    }
    # Explicit files only: private/, raw source snapshots and build trees are never scanned.
    assets = {
        "/manifest.json": (json_bytes(manifest), "application/json; charset=utf-8"),
        path: (content, "application/json; charset=utf-8"),
        "/LICENSE.txt": ((ROOT / "LICENSE").read_bytes(), "text/plain; charset=utf-8"),
    }
    OUT.mkdir(parents=True, exist_ok=True)
    for name, (body, _) in assets.items():
        target = OUT / name.lstrip("/")
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_bytes(body)
    return assets


def asset_hash(path, body):
    # Official Direct Uploads recipe: base64 contents + extension, SHA-256 truncated to 32 hex.
    return hashlib.sha256(base64.b64encode(body) + Path(path).suffix.encode()).hexdigest()[:32]


def multipart(parts):
    boundary = "gomimap-" + uuid.uuid4().hex
    body = bytearray()
    for name, filename, mime, content in parts:
        if not re.fullmatch(r"[A-Za-z0-9_.-]+", name + filename):
            raise SafeError("Invalid multipart field")
        body.extend(f'--{boundary}\r\nContent-Disposition: form-data; name="{name}"; filename="{filename}"\r\nContent-Type: {mime}\r\n\r\n'.encode())
        body.extend(content)
        body.extend(b"\r\n")
    body.extend(f"--{boundary}--\r\n".encode())
    return bytes(body), f"multipart/form-data; boundary={boundary}"


def check(api):
    result = api.request("GET", "/tokens/verify")
    if not isinstance(result, dict) or result.get("status") != "active":
        raise SafeError("Token is not active")
    subdomain = api.request("GET", "/workers/subdomain").get("subdomain", "")
    if not re.fullmatch(r"[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?", subdomain):
        raise SafeError("Register a workers.dev account subdomain before deploying")
    return f"https://{WORKER}.{subdomain}.workers.dev"


def require_absent(api):
    try:
        api.request("GET", f"/workers/scripts/{WORKER}/settings")
    except ApiError as error:
        if error.status == 404 and 10007 in error.codes:
            return
        raise
    raise SafeError("Target Worker already exists; initial deployment refuses to overwrite it")


def deploy(api, assets):
    # No update switch: an existing Worker, even ours, must not be silently overwritten.
    require_absent(api)
    manifest, by_hash = {}, {}
    for path, (content, mime) in assets.items():
        value = asset_hash(path, content)
        manifest[path] = {"hash": value, "size": len(content)}
        by_hash[value] = (content, mime)
    session = api.request("POST", f"/workers/scripts/{WORKER}/assets-upload-session", json_bytes({"manifest": manifest}))
    upload_token = session.get("jwt")
    buckets = session.get("buckets")
    if not isinstance(upload_token, str) or not upload_token or not isinstance(buckets, list):
        raise SafeError("Invalid asset upload session")
    completion = upload_token if not buckets else None
    for bucket in buckets:
        if not isinstance(bucket, list) or not bucket or any(value not in by_hash for value in bucket):
            raise SafeError("Unexpected upload bucket")
        parts = [(value, value, by_hash[value][1], base64.b64encode(by_hash[value][0])) for value in bucket]
        body, content_type = multipart(parts)
        result = api.request("POST", "/workers/assets/upload?base64=true", body, content_type, upload_token)
        if isinstance(result, dict) and result.get("jwt"):
            completion = result["jwt"]
    if not isinstance(completion, str) or not completion:
        raise SafeError("Asset upload was not completed; Worker not deployed")
    # Guard against a Worker created between the preflight and asset staging.
    require_absent(api)
    metadata = {
        "main_module": "data-worker.mjs", "compatibility_date": "2026-10-01",
        "annotations": {"workers/message": "gomimap owned fixture; initial development deployment"},
        "assets": {"jwt": completion, "config": {
            "html_handling": "none", "not_found_handling": "none", "run_worker_first": False,
            "_headers": (ROOT / "infra/cloudflare/asset-headers.txt").read_text(),
        }},
        "bindings": [], "observability": {"enabled": False},
    }
    body, mime = multipart([
        ("metadata", "metadata.json", "application/json", json_bytes(metadata)),
        ("data-worker.mjs", "data-worker.mjs", "application/javascript+module", (ROOT / "infra/cloudflare/data-worker.mjs").read_bytes()),
    ])
    result = api.request("PUT", f"/workers/scripts/{WORKER}", body, mime)
    api.request("POST", f"/workers/scripts/{WORKER}/subdomain", json_bytes({"enabled": True, "previews_enabled": False}))
    return result


def public_get(url, headers=None):
    opener = urllib.request.build_opener(NoRedirect())
    try:
        with opener.open(urllib.request.Request(url, headers=headers or {}), timeout=30) as response:
            return response.status, dict(response.headers), read_limited(response)
    except urllib.error.HTTPError as error:
        return error.code, dict(error.headers), read_limited(error)
    except (urllib.error.URLError, TimeoutError, OSError):
        raise SafeError("Public endpoint connection failed") from None


def verify(base, assets, fetch=public_get):
    if not re.fullmatch(r"https://gomimap-data-dev\.[a-z0-9-]+\.workers\.dev", base):
        raise SafeError("Only the development Worker origin can be verified")
    for path, (expected, mime) in assets.items():
        status, response_headers, content = fetch(base + path)
        headers = {key.lower(): value for key, value in response_headers.items()}
        if status != 200 or content != expected:
            raise SafeError("Public asset mismatch: " + path)
        if not headers.get("content-type", "").startswith(mime.split(";")[0]):
            raise SafeError("Unexpected asset content type")
        if headers.get("access-control-allow-origin") != "*" or headers.get("x-content-type-options") != "nosniff":
            raise SafeError("Required public response headers missing")
        cache = headers.get("cache-control", "")
        if path == "/manifest.json" and "must-revalidate" not in cache:
            raise SafeError("Manifest freshness policy missing")
        if path.startswith("/datasets/") and "immutable" not in cache:
            raise SafeError("Immutable dataset cache policy missing")
        etag = headers.get("etag")
        if not etag or fetch(base + path, {"If-None-Match": etag})[0] != 304:
            raise SafeError("Conditional asset request failed")
    for path in ("/missing.json", "/private/cloudflare.env", "/.env.local"):
        if fetch(base + path)[0] != 404:
            raise SafeError("Unknown or private path did not return 404")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("command", choices=["prepare", "check", "deploy", "verify"])
    parser.add_argument("--credentials", type=Path, default=ROOT / "private/cloudflare.env")
    parser.add_argument("--dart", type=Path, default=Path("dart"))
    args = parser.parse_args()
    try:
        if args.command == "prepare":
            assets = prepare(args.dart.resolve() if args.dart.exists() else args.dart)
            print(f"Prepared {len(assets)} explicitly selected public fixture assets")
            return
        api = Cloudflare(load_credentials(args.credentials))
        base = check(api)
        if args.command == "check":
            print("Dedicated account token active; development origin: " + base)
            return
        assets = prepare(args.dart.resolve() if args.dart.exists() else args.dart)
        if args.command == "deploy":
            if git("branch", "--show-current").strip() != b"main" or git("status", "--porcelain", "--untracked-files=no").strip():
                raise SafeError("Deploy only from clean main after the required PR checks")
            deploy(api, assets)
            print("Worker created; verifying the public bytes and response policies")
        verify(base, assets)
        print("Verified fixture assets, checksums, conditional requests and private-path 404: " + base + "/manifest.json")
    except SafeError as error:
        print(str(error), file=sys.stderr)
        sys.exit(1)
    except Exception:
        # Do not leak subprocess output, HTTP bodies or credentials through tracebacks.
        print("Operation failed; no sensitive diagnostic contents displayed", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
