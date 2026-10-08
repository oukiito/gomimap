# SPDX-License-Identifier: GPL-3.0-or-later
import hashlib
import os
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch
import zipfile

from scripts import install_maestro, maestro_runtime


class MaestroSetupTests(unittest.TestCase):
    def test_bad_download_cannot_install_a_binary(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            def bad_download(url, target):
                target.write_bytes(b"not the official archive")
            with patch.object(install_maestro, "ROOT", root), patch.object(
                install_maestro, "download", bad_download
            ):
                with self.assertRaisesRegex(SystemExit, "checksum mismatch"):
                    install_maestro.main()
            self.assertFalse((root / f".tooling/maestro-cli-{install_maestro.VERSION}").exists())

    def test_unsafe_archive_member_cannot_write_outside_the_installation(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            cache = root / ".tooling"
            cache.mkdir()
            archive = cache / f"maestro-cli-{install_maestro.VERSION}.zip"
            with zipfile.ZipFile(archive, "w") as bundle:
                bundle.writestr("../../escaped-file", "invalid")
            digest = hashlib.sha256(archive.read_bytes()).hexdigest()
            with patch.object(install_maestro, "ROOT", root), patch.object(
                install_maestro, "ARCHIVE_SHA256", digest
            ):
                with self.assertRaisesRegex(SystemExit, "Unsafe archive member"):
                    install_maestro.main()
            self.assertFalse((root / "escaped-file").exists())

    def test_child_sdk_settings_do_not_change_global_environment_or_pass_cloud_tokens(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            sdk, java = root / "sdk", root / "jdk"
            (sdk / "platform-tools").mkdir(parents=True)
            (sdk / "platform-tools/adb").touch()
            (java / "bin").mkdir(parents=True)
            (java / "bin/java").touch()
            original = {
                "GOMIMAP_ANDROID_SDK": str(sdk), "GOMIMAP_JAVA_HOME": str(java),
                "JAVA_HOME": "another-project-jdk", "GH_TOKEN": "test-marker",
                "MAESTRO_CLOUD_API_KEY": "test-marker", "PATH": "/test-bin",
            }
            with patch.dict(os.environ, original, clear=True):
                child = maestro_runtime.environment()
                self.assertEqual(os.environ["JAVA_HOME"], "another-project-jdk")
                self.assertEqual(child["JAVA_HOME"], str(java))
                self.assertEqual(child["ANDROID_HOME"], str(sdk))
                self.assertNotIn("GH_TOKEN", child)
                self.assertNotIn("MAESTRO_CLOUD_API_KEY", child)
                self.assertEqual(child["MAESTRO_CLI_NO_ANALYTICS"], "true")


if __name__ == "__main__":
    unittest.main()
