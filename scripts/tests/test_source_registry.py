"""Regression coverage for permission boundaries. SPDX-License-Identifier: GPL-3.0-or-later"""

import copy
import json
from pathlib import Path
import unittest

from scripts.validate_sources import RegistryError, require_publication, validate_registry


class SourceRegistryTests(unittest.TestCase):
    def setUp(self):
        self.registry = json.loads((Path(__file__).resolve().parents[2] / "data/sources/toshima.json").read_text())

    def source(self, identifier):
        return next(s for s in self.registry["sources"] if s["id"] == identifier)

    def test_actual_registry_has_separate_archive_and_distribution_assessments(self):
        validate_registry(self.registry)
        self.assertTrue(all({"archive", "redistribution"} <= set(s["rights"]) for s in self.registry["sources"]))

    def test_pending_source_can_be_catalogued_but_not_published(self):
        validate_registry(self.registry)
        with self.assertRaisesRegex(RegistryError, "redistribution not approved"):
            require_publication(self.registry, ["toshima-weekdays"])

    def test_explicitly_licensed_csv_passes_permission_gate(self):
        require_publication(self.registry, ["toshima-facilities", "toshima-open-data-list"])

    def test_licensed_facility_data_does_not_approve_a_second_source(self):
        with self.assertRaisesRegex(RegistryError, "redistribution not approved"):
            require_publication(self.registry, ["toshima-facilities", "toshima-batteries"])

    def test_open_data_license_cannot_be_extended_to_an_unlisted_pdf(self):
        self.source("toshima-weekdays")["rights"] = copy.deepcopy(self.source("toshima-facilities")["rights"])
        with self.assertRaisesRegex(RegistryError, "outside license scope"):
            validate_registry(self.registry)

    def test_historical_information_is_rejected_even_with_permission(self):
        old = self.source("toshima-year-end")
        old["rights"] = copy.deepcopy(self.source("toshima-facilities")["rights"])
        self.registry["policies"][1]["covered_urls"].append(old["url"])
        with self.assertRaisesRegex(RegistryError, "not a current data source"):
            require_publication(self.registry, [old["id"]])

    def test_missing_source_ids_are_not_an_implicit_permission(self):
        for identifiers in ([], ["not-registered"]):
            with self.subTest(identifiers=identifiers), self.assertRaises(RegistryError):
                require_publication(self.registry, identifiers)

    def test_duplicate_id_is_rejected(self):
        self.registry["sources"].append(copy.deepcopy(self.registry["sources"][0]))
        with self.assertRaisesRegex(RegistryError, "duplicate ID"):
            validate_registry(self.registry)

    def test_unknown_permission_state_is_rejected(self):
        for state in ("maybe", [], {"allowed": True}):
            with self.subTest(state=state):
                self.source("toshima-batteries")["rights"]["redistribution"] = state
                with self.assertRaisesRegex(RegistryError, "invalid permission state"):
                    validate_registry(self.registry)

    def test_inline_source_body_cannot_be_added_to_metadata_registry(self):
        self.source("toshima-batteries")["raw_html"] = "unapproved page copy"
        with self.assertRaisesRegex(RegistryError, "raw content"):
            validate_registry(self.registry)

    def test_licensed_source_still_requires_attribution(self):
        self.source("toshima-facilities")["rights"]["attribution"] = None
        with self.assertRaisesRegex(RegistryError, "attribution"):
            validate_registry(self.registry)

    def test_review_date_is_not_optional(self):
        self.source("toshima-weekdays")["checked_on"] = None
        with self.assertRaisesRegex(RegistryError, "checked_on"):
            validate_registry(self.registry)


if __name__ == "__main__":
    unittest.main()
