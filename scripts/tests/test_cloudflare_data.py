# SPDX-License-Identifier: GPL-3.0-or-later
import base64
from io import BytesIO
import json
from pathlib import Path
from tempfile import TemporaryDirectory
import unittest
from unittest.mock import Mock, patch
import urllib.error

from scripts import cloudflare_data as cf

TEST_TOKEN = "fake-development-credential-for-unit-tests"


class CloudflareDataTests(unittest.TestCase):
    def setUp(self):
        self.temp = TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.credential = self.root / "credentials"
        self.credential.write_text(
            "CLOUDFLARE_ACCOUNT_ID=" + "a" * 32 + "\n"
            "CLOUDFLARE_API_TOKEN=" + TEST_TOKEN + "\n"
            "CLOUDFLARE_WORKER_NAME=gomimap-data-dev\n"
        )
        self.credential.chmod(0o600)
        self.manifest = cf.json_bytes({"datasets": [{"sha256": "f" * 64}]})
        self.assets = {"/manifest.json": (self.manifest, "application/json; charset=utf-8")}
        self.receipt_path = self.root / "receipt.json"
        self.worker = {"id": "b" * 32, "name": cf.WORKER, "created_on": "2026-10-07T16:52:53Z", "deployed_on": None, "subdomain": {"enabled": False}}

    def test_dedicated_credentials_ignore_global_tokens_and_hide_repr(self):
        with patch.dict("os.environ", {"CLOUDFLARE_API_TOKEN": "another-account", "CLOUDFLARE_ACCOUNT_ID": "b" * 32}):
            credentials = cf.load_credentials(self.credential)
        self.assertEqual(credentials.token, TEST_TOKEN)
        self.assertEqual(credentials.account, "a" * 32)
        self.assertNotIn(TEST_TOKEN, repr(credentials))
        self.assertNotIn("a" * 32, repr(credentials))

    def test_credential_owner_permission_is_required(self):
        self.credential.chmod(0o644)
        with self.assertRaisesRegex(cf.SafeError, "owner"):
            cf.load_credentials(self.credential)

    def test_foreign_worker_duplicate_and_shell_text_are_rejected(self):
        original = self.credential.read_text()
        variants = [
            original.replace("gomimap-data-dev", "another-project"),
            original + "CLOUDFLARE_API_TOKEN=overwritten\n",
            original.replace(TEST_TOKEN, "$(touch dangerous)"),
            original.replace("CLOUDFLARE_ACCOUNT_ID=" + "a" * 32, "CLOUDFLARE_ACCOUNT_ID=invalid"),
        ]
        for content in variants:
            with self.subTest(content_type=len(content)):
                self.credential.write_text(content)
                with self.assertRaises(cf.SafeError) as result:
                    cf.load_credentials(self.credential)
                self.assertNotIn(TEST_TOKEN, str(result.exception))

    def test_quote_wrapping_does_not_execute_dotenv(self):
        text = self.credential.read_text().replace(TEST_TOKEN, '"' + TEST_TOKEN + '"')
        self.credential.write_text(text)
        self.assertEqual(cf.load_credentials(self.credential).token, TEST_TOKEN)

    def test_redirect_does_not_forward_authorization(self):
        self.assertIsNone(cf.NoRedirect().redirect_request(None, None, 302, "Found", {}, "https://other.example"))

    def test_api_errors_do_not_echo_secret_from_remote_response(self):
        api = cf.Cloudflare(cf.Credentials("a" * 32, TEST_TOKEN))
        failure = urllib.error.HTTPError("https://api.cloudflare.com", 403, "Forbidden", {}, BytesIO(json.dumps({
            "errors": [{"code": 10000, "message": TEST_TOKEN}],
        }).encode()))
        api.opener.open = Mock(side_effect=failure)
        with self.assertRaises(cf.ApiError) as result:
            api.request("GET", "/tokens/verify")
        self.assertEqual(result.exception.codes, [10000])
        self.assertNotIn(TEST_TOKEN, str(result.exception))

    def test_oversized_response_is_rejected(self):
        with self.assertRaisesRegex(cf.SafeError, "size limit"):
            cf.read_limited(BytesIO(b"x" * (cf.MAX_RESPONSE + 1)))

    def test_existing_worker_refuses_upload(self):
        api = Mock()
        api.request.return_value = {}
        with self.assertRaisesRegex(cf.SafeError, "already exists"):
            cf.deploy(api, self.assets, self.receipt_path)
        self.assertEqual([call.args[0] for call in api.request.call_args_list], ["GET"])

    def test_unauthorized_or_unknown_404_is_not_an_absent_worker(self):
        for error in (cf.ApiError(403, [10000]), cf.ApiError(404, [12345]), cf.ApiError(404, [10222])):
            api = Mock()
            api.request.side_effect = error
            with self.subTest(status=error.status), self.assertRaises(cf.ApiError):
                cf.deploy(api, self.assets, self.receipt_path)
            self.assertEqual(api.request.call_count, 1)

    def stage_api(self, buckets=None, upload_result=None):
        value = cf.asset_hash("/manifest.json", self.manifest)
        api = Mock()
        api.credentials = cf.Credentials("a" * 32, TEST_TOKEN)
        api.request.side_effect = [
            cf.ApiError(404, [10007]),
            {"jwt": "temporary-upload-token", "buckets": [[value]] if buckets is None else buckets},
            [self.worker],
            {"jwt": "completion-token"} if upload_result is None else upload_result,
            self.worker,
            {"id": cf.WORKER},
            {"enabled": True},
        ]
        return api

    def test_success_uploads_only_allowlisted_assets_and_has_no_runtime_secret(self):
        api = self.stage_api()
        cf.deploy(api, self.assets, self.receipt_path)
        calls = api.request.call_args_list
        self.assertEqual([call.args[0] for call in calls], ["GET", "POST", "GET", "POST", "GET", "PUT", "POST"])
        registry = json.loads(calls[1].args[2])
        self.assertEqual(set(registry["manifest"]), {"/manifest.json"})
        upload = calls[3].args[2]
        self.assertIn(base64.b64encode(self.manifest), upload)
        self.assertEqual(calls[3].args[4], "temporary-upload-token")
        payload = calls[5].args[2]
        self.assertIn(b'"run_worker_first": false', payload)
        self.assertIn(b'"not_found_handling": "none"', payload)
        self.assertIn(b'"bindings": []', payload)
        self.assertIn(b'"enabled": false', payload)
        self.assertNotIn(TEST_TOKEN.encode(), payload)
        self.assertNotIn(b"temporary-upload-token", payload)
        self.assertIn(b"completion-token", payload)

    def test_empty_buckets_reuse_the_completion_token_without_asset_upload(self):
        api = Mock()
        api.credentials = cf.Credentials("a" * 32, TEST_TOKEN)
        api.request.side_effect = [
            cf.ApiError(404, [10007]), {"jwt": "already-uploaded", "buckets": []},
            [self.worker], self.worker, {}, {},
        ]
        cf.deploy(api, self.assets, self.receipt_path)
        self.assertEqual(len(api.request.call_args_list), 6)
        self.assertNotIn("/workers/assets/upload?base64=true", [c.args[1] for c in api.request.call_args_list])

    def test_upload_failure_does_not_publish_or_enable_worker(self):
        api = self.stage_api(upload_result={})
        with self.assertRaisesRegex(cf.SafeError, "not completed"):
            cf.deploy(api, self.assets, self.receipt_path)
        self.assertEqual(api.request.call_count, 4)

    def test_unexpected_bucket_cannot_upload_arbitrary_file(self):
        api = self.stage_api(buckets=[["unknown-private-file-hash"]])
        with self.assertRaisesRegex(cf.SafeError, "Unexpected"):
            cf.deploy(api, self.assets, self.receipt_path)
        self.assertEqual(api.request.call_count, 3)

    def test_worker_created_during_staging_is_not_overwritten(self):
        api = Mock()
        api.credentials = cf.Credentials("a" * 32, TEST_TOKEN)
        active = {**self.worker, "deployed_on": "2026-10-07T17:00:00Z"}
        api.request.side_effect = [cf.ApiError(404, [10007]), {"jwt": "completion", "buckets": []}, [self.worker], active]
        with self.assertRaisesRegex(cf.SafeError, "undeployed"):
            cf.deploy(api, self.assets, self.receipt_path)
        self.assertEqual(api.request.call_count, 4)

    def test_pinned_empty_worker_can_resume_without_overwriting_a_version(self):
        api = Mock()
        api.credentials = cf.Credentials("a" * 32, TEST_TOKEN)
        receipt = cf.receipt_for(api, self.assets, self.worker)
        self.receipt_path.write_bytes(cf.json_bytes(receipt))
        self.receipt_path.chmod(0o600)
        api.request.side_effect = [self.worker, {"jwt": "completion", "buckets": []}, self.worker, {}, {}]
        cf.deploy(api, self.assets, self.receipt_path, resume=True)
        self.assertEqual(api.request.call_args_list[0].args[1], "/workers/workers/" + self.worker["id"])
        self.assertEqual([c.args[0] for c in api.request.call_args_list], ["GET", "POST", "GET", "PUT", "POST"])

    def test_receipt_from_another_account_or_dataset_cannot_resume(self):
        api = Mock()
        api.credentials = cf.Credentials("a" * 32, TEST_TOKEN)
        receipt = cf.receipt_for(api, self.assets, self.worker)
        for field in ("accountFingerprint", "datasetSHA256", "workerName"):
            self.receipt_path.write_bytes(cf.json_bytes({**receipt, field: "other"}))
            self.receipt_path.chmod(0o600)
            with self.subTest(field=field), self.assertRaises(cf.SafeError):
                cf.deploy(api, self.assets, self.receipt_path, resume=True)
        api.request.assert_not_called()

    def test_replaced_renamed_public_or_deployed_worker_cannot_resume(self):
        api = Mock()
        api.credentials = cf.Credentials("a" * 32, TEST_TOKEN)
        receipt = cf.receipt_for(api, self.assets, self.worker)
        self.receipt_path.write_bytes(cf.json_bytes(receipt))
        self.receipt_path.chmod(0o600)
        for worker in (
            {**self.worker, "id": "c" * 32},
            {**self.worker, "created_on": "other"},
            {**self.worker, "name": "other"},
            {**self.worker, "subdomain": {"enabled": True}},
            {**self.worker, "deployed_on": "2026-10-07T17:00:00Z"},
        ):
            api.request.reset_mock()
            api.request.return_value = worker
            with self.subTest(change=worker), self.assertRaises(cf.SafeError):
                cf.deploy(api, self.assets, self.receipt_path, resume=True)
            self.assertEqual(api.request.call_count, 1)

    def canonical_source(self):
        source = cf.ROOT / cf.SOURCE
        target = self.root / cf.SOURCE
        target.parent.mkdir(parents=True)
        target.write_bytes(source.read_bytes())
        (self.root / "LICENSE").write_text("Test GPL text\n")
        (self.root / "app").mkdir()
        return target

    def test_prepare_uses_dart_validator_and_has_exactly_three_assets(self):
        source = self.canonical_source()
        def git(*args):
            if "--is-shallow-repository" in args:
                return b"false\n"
            return source.read_bytes() if args[0] == "show" else b"f" * 40
        with patch.object(cf, "ROOT", self.root), patch.object(cf, "OUT", self.root / "output"), patch.object(cf, "git", side_effect=git), patch.object(cf.subprocess, "run", return_value=Mock(returncode=0)) as validator:
            (self.root / "output").mkdir()
            (self.root / "output/.env").write_text(TEST_TOKEN)
            assets = cf.prepare(Path("dart"))
        manifest = json.loads(assets["/manifest.json"][0])
        entry = manifest["datasets"][0]
        self.assertEqual(manifest["kind"], "fixture")
        self.assertEqual(manifest["channel"], "development")
        self.assertEqual(entry["sizeBytes"], len(source.read_bytes()))
        self.assertEqual(entry["sha256"], cf.hashlib.sha256(source.read_bytes()).hexdigest())
        self.assertIn(entry["sha256"], entry["path"])
        self.assertEqual(set(assets), {"/manifest.json", "/LICENSE.txt", entry["path"]})
        self.assertNotIn(TEST_TOKEN.encode(), b"".join(body for body, _ in assets.values()))
        self.assertIn("tool/validate_dataset.dart", validator.call_args.args[0])

    def test_uncommitted_fixture_and_schema_failure_produce_no_release(self):
        source = self.canonical_source()
        output = self.root / "output"
        for committed, valid in ((b"changed", True), (source.read_bytes(), False)):
            with patch.object(cf, "ROOT", self.root), patch.object(cf, "OUT", output), patch.object(cf, "git", side_effect=lambda *args: b"false\n" if "--is-shallow-repository" in args else committed), patch.object(cf.subprocess, "run", return_value=Mock(returncode=0 if valid else 1)):
                with self.assertRaises(cf.SafeError):
                    cf.prepare(Path("dart"))
                self.assertFalse(output.exists())

    def test_shallow_history_cannot_claim_a_last_source_commit(self):
        with patch.object(cf, "git", return_value=b"true\n"):
            with self.assertRaisesRegex(cf.SafeError, "full Git history"):
                cf.prepare(Path("dart"))

    def fake_public(self, url, headers=None):
        if url.endswith(("missing.json", "cloudflare.env", ".env.local")):
            return 404, {}, b"Not found\n"
        if headers:
            return 304, {}, b""
        return 200, {
            "Content-Type": "application/json; charset=utf-8", "Access-Control-Allow-Origin": "*",
            "X-Content-Type-Options": "nosniff", "Cache-Control": "public, max-age=0, must-revalidate",
            "ETag": '"test"',
        }, self.manifest

    def test_public_bytes_headers_conditional_and_private_paths(self):
        cf.verify("https://gomimap-data-dev.demo.workers.dev", self.assets, self.fake_public)

    def test_public_request_identifies_client_and_preserves_conditional_header(self):
        response = Mock()
        response.status = 304
        response.headers = {}
        response.read.return_value = b""
        response.__enter__ = Mock(return_value=response)
        response.__exit__ = Mock(return_value=False)
        opener = Mock()
        opener.open.return_value = response
        with patch.object(cf.urllib.request, "build_opener", return_value=opener):
            cf.public_get("https://gomimap-data-dev.demo.workers.dev/manifest.json", {"If-None-Match": '"test"'})
        request = opener.open.call_args.args[0]
        self.assertEqual(request.get_header("User-agent"), cf.PUBLIC_USER_AGENT)
        self.assertEqual(request.get_header("If-none-match"), '"test"')
        self.assertIsNone(request.get_header("Authorization"))

    def test_public_tamper_missing_cors_bad_cache_or_missing_etag_fail(self):
        for fault in ("tamper", "cors", "cache", "etag", "conditional", "private"):
            def fetch(url, headers=None):
                status, response_headers, content = self.fake_public(url, headers)
                if fault == "private" and url.endswith("cloudflare.env"):
                    status = 200
                if not headers:
                    if fault == "tamper":
                        content += b"changed"
                    elif fault == "cors":
                        response_headers.pop("Access-Control-Allow-Origin", None)
                    elif fault == "cache":
                        response_headers["Cache-Control"] = "immutable"
                    elif fault == "etag":
                        response_headers.pop("ETag", None)
                elif fault == "conditional":
                    status = 200
                return status, response_headers, content
            with self.subTest(fault=fault), self.assertRaises(cf.SafeError):
                cf.verify("https://gomimap-data-dev.demo.workers.dev", self.assets, fetch)

    def test_verification_cannot_follow_a_manifest_to_another_origin(self):
        fetch = Mock()
        for origin in ("http://gomimap-data-dev.demo.workers.dev", "https://other.example", "https://gomimap-data-dev.demo.workers.dev/evil"):
            with self.subTest(origin=origin), self.assertRaises(cf.SafeError):
                cf.verify(origin, self.assets, fetch)
        fetch.assert_not_called()


if __name__ == "__main__":
    unittest.main()
