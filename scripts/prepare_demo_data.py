#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-or-later
"""Bundle only the explicitly selected, owned fixture. No network or raw copies."""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "data/datasets/fixtures/toshima-demo-v1.json"
DESTINATION = ROOT / "app/assets/generated/toshima-demo-v1.json"


def prepare() -> None:
    content = SOURCE.read_bytes()
    data = json.loads(content)
    if data.get("schemaVersion") != 1 or data.get("kind") != "fixture":
        raise ValueError("Only the owned schema-1 fixture can be bundled by this script")
    if data.get("version") != "toshima-demo-v1":
        raise ValueError("Unexpected fixture version")
    DESTINATION.parent.mkdir(parents=True, exist_ok=True)
    DESTINATION.write_bytes(content)
    print("Prepared bundled demo data from the canonical fixture")


if __name__ == "__main__":
    prepare()
