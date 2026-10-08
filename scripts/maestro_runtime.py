#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-or-later
"""Run the pinned, project-local Maestro without changing global SDK settings."""

import os
from pathlib import Path
import sys

VERSION = "2.11.0"
ARCHIVE_SHA256 = "5384593cb4e7a106489e75a821d157dd43f4e438df6bc308b72e82c685e1283a"
ROOT = Path(__file__).resolve().parents[1]


def environment():
    env = dict(os.environ)
    for secret in ("GH_TOKEN", "GITHUB_TOKEN", "CLOUDFLARE_API_TOKEN", "MAESTRO_CLOUD_API_KEY"):
        env.pop(secret, None)
    sdk = env.get("GOMIMAP_ANDROID_SDK")
    if not sdk:
        properties = ROOT / "app/android/local.properties"
        if properties.is_file():
            sdk = next((line[8:] for line in properties.read_text().splitlines()
                        if line.startswith("sdk.dir=")), None)
    if not sdk:
        sdk = env.get("ANDROID_HOME") or env.get("ANDROID_SDK_ROOT")
    if not sdk or not (Path(sdk) / "platform-tools/adb").is_file():
        raise SystemExit("Set GOMIMAP_ANDROID_SDK to an installed Android SDK")
    java = env.get("GOMIMAP_JAVA_HOME") or env.get("JAVA_HOME")
    studio = Path("/Applications/Android Studio.app/Contents/jbr/Contents/Home")
    if not java and studio.is_dir():
        java = str(studio)
    if not java or not (Path(java) / "bin/java").is_file():
        raise SystemExit("Set GOMIMAP_JAVA_HOME to a Java 17+ runtime")
    env.update({
        "JAVA_HOME": java,
        "ANDROID_HOME": sdk,
        "ANDROID_SDK_ROOT": sdk,
        "MAESTRO_CLI_NO_ANALYTICS": "true",
        "MAESTRO_CLI_ANALYSIS_NOTIFICATION_DISABLED": "true",
        "MAESTRO_DISABLE_UPDATE_CHECK": "true",
        "PATH": str(Path(sdk) / "platform-tools") + os.pathsep + env.get("PATH", ""),
    })
    return env


def main():
    executable = ROOT / f".tooling/maestro-cli-{VERSION}/maestro/bin/maestro"
    if not executable.is_file():
        raise SystemExit("Maestro is missing; run scripts/install_maestro.py first")
    os.chdir(ROOT)
    os.execve(executable, [str(executable), *sys.argv[1:]], environment())


if __name__ == "__main__":
    main()
