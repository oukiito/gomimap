"""Validate source metadata and explicit permission to publish derived app data.

SPDX-License-Identifier: GPL-3.0-or-later
This checks recorded permissions, not legal validity or garbage-rule accuracy.
"""

import argparse
from datetime import date
import json
from pathlib import Path
import sys
from urllib.parse import urlparse


class RegistryError(ValueError):
    pass


def require(condition, message):
    if not condition:
        raise RegistryError(message)


def text(value, label):
    require(isinstance(value, str) and bool(value.strip()), f"{label}: text required")


def url(value, label):
    text(value, label)
    parsed = urlparse(value)
    require(parsed.scheme == "https" and bool(parsed.hostname) and parsed.username is None,
            f"{label}: HTTPS URL without credentials required")


def day(value, label, nullable=False):
    if value is None and nullable:
        return
    text(value, label)
    try:
        require(date.fromisoformat(value).isoformat() == value, f"{label}: ISO date required")
    except ValueError as error:
        raise RegistryError(f"{label}: ISO date required") from error


def objects(items, label):
    require(isinstance(items, list) and bool(items), f"{label}: nonempty list required")
    result = {}
    for item in items:
        require(isinstance(item, dict), f"{label}: objects required")
        identifier = item.get("id")
        text(identifier, f"{label}.id")
        require(identifier not in result, f"{label}: duplicate ID {identifier}")
        result[identifier] = item
    return result


def validate_registry(registry):
    require(isinstance(registry, dict), "registry: object required")
    require(type(registry.get("schema_version")) is int and registry["schema_version"] == 1,
            "schema_version: expected 1")
    require(set(registry) == {"schema_version", "municipality_id", "checked_on", "scope", "policies", "sources"},
            "registry: metadata fields required; unknown fields prohibited")
    text(registry.get("municipality_id"), "municipality_id")
    text(registry.get("scope"), "scope")
    day(registry.get("checked_on"), "checked_on")
    policies = objects(registry.get("policies"), "policies")
    for identifier, policy in policies.items():
        require(set(policy) == {"id", "url", "checked_on", "updated_on", "license", "covered_urls", "notes"},
                f"{identifier}: invalid policy fields")
        url(policy.get("url"), identifier)
        day(policy.get("checked_on"), identifier + ".checked_on")
        day(policy.get("updated_on"), identifier + ".updated_on", nullable=True)
        text(policy.get("notes"), identifier + ".notes")
        covered = policy.get("covered_urls")
        require(isinstance(covered, list), f"{identifier}: covered_urls required")
        for target in covered:
            url(target, identifier + ".covered_urls")
        if policy.get("license") is not None:
            text(policy["license"], identifier + ".license")

    sources = objects(registry.get("sources"), "sources")
    required_fields = {"id", "title", "url", "publisher", "kind", "topics", "checked_on",
                       "updated_on", "review_method", "reviewed_by", "locator", "validity", "notes", "rights"}
    optional_fields = {"discovered_from", "retrieval_metadata"}
    for identifier, source in sources.items():
        require(required_fields <= set(source) <= required_fields | optional_fields,
                f"{identifier}: metadata fields required; raw content/unknown fields prohibited")
        for field in ("title", "publisher", "review_method", "reviewed_by", "locator", "notes"):
            text(source.get(field), identifier + "." + field)
        url(source.get("url"), identifier)
        if "discovered_from" in source:
            url(source["discovered_from"], identifier + ".discovered_from")
        day(source.get("checked_on"), identifier + ".checked_on")
        day(source.get("updated_on"), identifier + ".updated_on", nullable=True)
        require(source.get("kind") in ("html", "pdf", "csv"), f"{identifier}: invalid kind")
        require(source.get("validity") in ("current_reference", "historical", "reference_only"),
                f"{identifier}: invalid validity")
        topics = source.get("topics")
        require(isinstance(topics, list) and bool(topics), f"{identifier}: topics required")
        for topic in topics:
            text(topic, identifier + ".topics")
        rights = source.get("rights")
        require(isinstance(rights, dict) and set(rights) == {"archive", "redistribution", "policy_id", "license", "attribution", "basis_url"},
                f"{identifier}: separate archive/redistribution assessments required")
        for field in ("archive", "redistribution"):
            require(rights.get(field) in ("allowed", "needs_review", "disallowed"),
                    f"{identifier}.{field}: invalid permission state")
        text(rights.get("policy_id"), identifier + ".policy_id")
        policy = policies.get(rights["policy_id"])
        require(policy is not None, f"{identifier}: unknown rights policy")
        require(rights.get("basis_url") == policy["url"], f"{identifier}: mismatched rights evidence")
        if "allowed" in (rights["archive"], rights["redistribution"]):
            require(source["url"] in policy["covered_urls"], f"{identifier}: outside license scope")
            require(bool(policy["license"]) and rights.get("license") == policy["license"],
                    f"{identifier}: license required for permission")
            text(rights.get("attribution"), identifier + ".attribution")
        metadata = source.get("retrieval_metadata", {})
        require(isinstance(metadata, dict) and set(metadata) <= {"sha256", "bytes", "last_modified", "rows", "columns"},
                f"{identifier}: invalid retrieval metadata")
        if "sha256" in metadata:
            digest = metadata["sha256"]
            require(isinstance(digest, str) and len(digest) == 64 and all(c in "0123456789abcdef" for c in digest),
                    f"{identifier}: invalid content digest")
        for field in ("bytes", "rows"):
            if field in metadata:
                require(type(metadata[field]) is int and metadata[field] >= 0,
                        f"{identifier}.{field}: nonnegative integer required")
        if "last_modified" in metadata and metadata["last_modified"] is not None:
            text(metadata["last_modified"], identifier + ".last_modified")
        if "columns" in metadata:
            require(isinstance(metadata["columns"], list), f"{identifier}: columns list required")
            for column in metadata["columns"]:
                text(column, identifier + ".columns")
    return sources


def require_publication(registry, source_ids):
    sources = validate_registry(registry)
    require(isinstance(source_ids, list) and bool(source_ids), "publication: source IDs required")
    for identifier in source_ids:
        text(identifier, "publication.source_id")
        require(identifier in sources, f"publication: unknown source {identifier}")
        source = sources[identifier]
        require(source["rights"]["redistribution"] == "allowed", f"{identifier}: redistribution not approved")
        require(source["validity"] == "current_reference", f"{identifier}: not a current data source")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--registry", type=Path,
                        default=Path(__file__).resolve().parents[1] / "data/sources/toshima.json")
    parser.add_argument("--publish-source", action="append", help="Explicit source ID for app-data publication; repeatable")
    args = parser.parse_args()
    try:
        registry = json.loads(args.registry.read_text(encoding="utf-8"))
        sources = validate_registry(registry)
        if args.publish_source is not None:
            require_publication(registry, args.publish_source)
            print(f"Permission gate passed for {len(args.publish_source)} sources (data accuracy not assessed)")
        else:
            pending = sum(s["rights"]["redistribution"] != "allowed" for s in sources.values())
            print(f"Source metadata valid: {len(sources)} sources; {pending} not approved for data redistribution")
    except (RegistryError, OSError, json.JSONDecodeError) as error:
        print(f"Source validation failed: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
