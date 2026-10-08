#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-or-later
"""Install an official, checksum-pinned host test tool in the ignored workspace."""

import hashlib
import json
from pathlib import Path
import stat
import urllib.request
import zipfile

try:
    from .maestro_runtime import ROOT, VERSION, ARCHIVE_SHA256
except ImportError:
    from maestro_runtime import ROOT, VERSION, ARCHIVE_SHA256


def download(url, target):
    request = urllib.request.Request(url, headers={"User-Agent": "gomimap-development-setup"})
    with urllib.request.urlopen(request, timeout=30) as response, target.open("wb") as output:
        while chunk := response.read(1024 * 1024):
            output.write(chunk)


def main():
    cache = ROOT / ".tooling"
    cache.mkdir(exist_ok=True)
    archive = cache / f"maestro-cli-{VERSION}.zip"
    if not archive.is_file() or hashlib.sha256(archive.read_bytes()).hexdigest() != ARCHIVE_SHA256:
        download(f"https://github.com/mobile-dev-inc/Maestro/releases/download/cli-{VERSION}/maestro.zip", archive)
    if hashlib.sha256(archive.read_bytes()).hexdigest() != ARCHIVE_SHA256:
        raise SystemExit("Official Maestro archive checksum mismatch; not installed")
    destination = cache / f"maestro-cli-{VERSION}"
    with zipfile.ZipFile(archive) as bundle:
        for entry in bundle.infolist():
            path = Path(entry.filename)
            if path.is_absolute() or ".." in path.parts or stat.S_ISLNK(entry.external_attr >> 16):
                raise SystemExit("Unsafe archive member; not installed")
        bundle.extractall(destination)
    for binary in (destination / "maestro/bin").glob("*"):
        binary.chmod(0o755)
    license_file = destination / "LICENSE"
    download(f"https://raw.githubusercontent.com/mobile-dev-inc/Maestro/cli-{VERSION}/LICENSE", license_file)
    if b"Apache License" not in license_file.read_bytes():
        raise SystemExit("Unexpected root license; inspect distribution before use")
    jars = []
    embedded_apks = []
    for jar in sorted(destination.rglob("*.jar")):
        with zipfile.ZipFile(jar) as bundle:
            notices = [name for name in bundle.namelist()
                       if ("license" in name.lower() or "notice" in name.lower())
                       and not name.endswith((".class", "/"))]
            embedded_apks.extend(f"{jar.relative_to(destination)}:{name}"
                                 for name in bundle.namelist() if name.endswith(".apk"))
        jars.append({"file": str(jar.relative_to(destination)),
                     "sha256": hashlib.sha256(jar.read_bytes()).hexdigest(), "noticePaths": notices})
    (destination / "license-inventory.json").write_text(json.dumps({
        "tool": "Maestro", "version": VERSION, "archiveSha256": ARCHIVE_SHA256,
        "license": "Apache-2.0", "licenseSha256": hashlib.sha256(license_file.read_bytes()).hexdigest(),
        "jars": jars, "embeddedApks": embedded_apks,
    }, indent=2))
    print(f"Installed Maestro {VERSION}; checksum verified; {len(jars)} host jars inventoried")


if __name__ == "__main__":
    main()
