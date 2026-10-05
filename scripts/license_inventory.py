#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-or-later
"""Snapshot resolved Dart license texts. This is an inventory, not legal clearance."""
import hashlib
import json
from pathlib import Path
import re
from urllib.parse import unquote, urljoin, urlparse

ROOT = Path(__file__).resolve().parents[1]
CONFIG = ROOT / 'app/.dart_tool/package_config.json'
OUTPUT = ROOT / 'third_party'


def classify(name, text):
    if name == 'sky_engine':
        return 'Multiple licenses; aggregated engine notices — review per release'
    if name == 'google_maps_flutter_web':
        return 'BSD-3-Clause AND MIT'
    if 'Neither the name' in text or 'neither the name' in text:
        return 'BSD-3-Clause'
    if 'Apache License' in text:
        return 'Apache-2.0'
    if 'Permission is hereby granted, free of charge' in text:
        return 'MIT'
    return 'REVIEW REQUIRED'


def main():
    config = json.loads(CONFIG.read_text())
    flutter = Path(unquote(urlparse(config['flutterRoot']).path))
    (OUTPUT / 'licenses').mkdir(parents=True, exist_ok=True)
    entries = []
    for package in sorted(config['packages'], key=lambda value: value['name']):
        name = package['name']
        if name == 'gomimap':
            continue
        root = Path(unquote(urlparse(urljoin(CONFIG.as_uri(), package['rootUri'])).path))
        license_file = root / 'LICENSE'
        inherited = False
        if not license_file.is_file() and root.is_relative_to(flutter / 'packages'):
            license_file = flutter / 'LICENSE'
            inherited = True
        if not license_file.is_file():
            raise RuntimeError(f'Missing license: {name}')
        data = license_file.read_bytes()
        text = data.decode('utf-8')
        pubspec = (root / 'pubspec.yaml').read_text()
        match = re.search(r'^version:\s*[\'"]?([^\s\'"#]+)', pubspec, re.MULTILINE)
        version = match.group(1) if match else f"SDK {config['flutterVersion']}"
        target = Path('licenses') / f'{name}.txt'
        (OUTPUT / target).write_bytes(data)
        entries.append({
            'package': name, 'version': version,
            'licenseAssessment': classify(name, text),
            'notice': str(target),
            'sha256': hashlib.sha256(data).hexdigest(),
            'inheritedFlutterLicense': inherited,
        })
    expected = {entry['notice'] for entry in entries}
    for stale in (OUTPUT / 'licenses').glob('*.txt'):
        if str(stale.relative_to(OUTPUT)) not in expected:
            stale.unlink()
    inventory = {
        'scope': 'Resolved Dart packages including development and platform alternatives; not a shipped-binary bill of materials',
        'flutterVersion': config['flutterVersion'],
        'lockfileSha256': hashlib.sha256((ROOT / 'app/pubspec.lock').read_bytes()).hexdigest(),
        'unresolved': ['Native SDKs and Gradle/SPM/CocoaPods dependencies',
                       'Release-specific Flutter engine, fonts and asset notices',
                       'Map services, municipal data and distribution contracts'],
        'packages': entries,
    }
    (OUTPUT / 'dart-packages.json').write_text(json.dumps(inventory, ensure_ascii=False, indent=2) + '\n')
    lines = ['# Resolved Dart package license inventory', '',
             'Generated with `python3 scripts/license_inventory.py`. Package-level text classifications are review aids, not binary distribution approval.', '',
             '| Package | Version | License text assessment | Notice |',
             '| --- | --- | --- | --- |']
    for entry in entries:
        lines.append(f"| {entry['package']} | {entry['version']} | {entry['licenseAssessment']} | [Text]({entry['notice']}) |")
    (OUTPUT / 'README.md').write_text('\n'.join(lines) + '\n')
    print(f'Saved {len(entries)} package license texts and SHA-256 inventory.')


if __name__ == '__main__':
    main()
