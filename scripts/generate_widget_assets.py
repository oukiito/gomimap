#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-or-later
"""Build native fallback labels from the same ARB source as Flutter."""
import argparse
import json
from xml.sax.saxutils import escape
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
TARGET = ROOT / 'app/android/app/src/main/assets/widget_labels.json'
KEYS = ('widgetLabel', 'widgetSample', 'widgetNext', 'uncertain', 'chooseArea', 'areaName')


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--check', action='store_true')
    args = parser.parse_args()
    labels = {}
    qualifiers = {'ja': 'values', 'en': 'values-en', 'zh-Hans': 'values-b+zh+Hans',
                  'zh-Hant': 'values-b+zh+Hant', 'ko': 'values-ko', 'vi': 'values-vi',
                  'ne': 'values-ne', 'pt': 'values-pt', 'es': 'values-es', 'fil': 'values-b+fil'}
    for path in sorted((ROOT / 'app/lib/l10n').glob('app_*.arb')):
        data = json.loads(path.read_text())
        tag = data['@@locale'].replace('_', '-')
        if tag == 'zh':
            continue
        labels[tag] = {key: data[key] for key in KEYS}
        resource = ROOT / 'app/android/app/src/main/res' / qualifiers[tag] / 'widget_strings.xml'
        label = escape(data['appTitle'] + ' · ' + data['widgetLabel'])
        xml = ('<?xml version="1.0" encoding="utf-8"?>\n'
               '<!-- SPDX-License-Identifier: GPL-3.0-or-later; generated from ARB -->\n'
               f'<resources><string name="widget_label">{label}</string></resources>\n')
        if args.check:
            if not resource.is_file() or resource.read_text() != xml:
                raise SystemExit('Native widget resource labels are stale')
        else:
            resource.parent.mkdir(parents=True, exist_ok=True)
            resource.write_text(xml)
    text = json.dumps({'schemaVersion': 1, 'locales': labels}, ensure_ascii=False, indent=2) + '\n'
    if args.check:
        if not TARGET.is_file() or TARGET.read_text() != text:
            raise SystemExit('Native widget labels are stale; run generate_widget_assets.py')
    else:
        TARGET.parent.mkdir(parents=True, exist_ok=True)
        TARGET.write_text(text)
    print(f'Native widget fallback labels: {len(labels)} locales')


if __name__ == '__main__':
    main()
