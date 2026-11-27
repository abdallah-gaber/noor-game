import json
from pathlib import Path
import tempfile
import unittest

from content_inventory import create_inventory, record_stages
from generate_dashboard import Dashboard, LinkCheck, PUBLIC_FILES


class InventoryTests(unittest.TestCase):
    def sample(self, directory, *, duplicate=False):
        options = [{"id": "a", "textAr": "سرّ"}, {"id": "b", "textAr": "خاص"}]
        variant = {
            "id": "q1", "type": "multiple_choice", "level": "recall",
            "knowledgeIds": ["k1"], "promptAr": "Draft-only text", "options": options,
            "correctOptionIds": ["a"], "reviewStatus": "draft",
        }
        challenges = [variant]
        if duplicate:
            challenges.append({**variant, "id": "q2", "options": list(reversed(options))})
        data = {
            "worldId": "iman", "status": "draft_not_for_release",
            "sources": [{"id": "locator", "url": "https://private.invalid/", "verificationStatus": "locator_review_pending"}],
            "lessons": [{"id": "l1", "unitId": "u1", "objectives": [{"id": "o1"}],
                         "knowledgeUnits": [{"id": "k1", "textAr": "Draft-only fact"}],
                         "challenges": challenges}],
        }
        path = Path(directory) / "draft.json"
        path.write_text(json.dumps(data), encoding="utf-8")
        return path

    def test_counts_from_records_without_copying_authoring_text(self):
        with tempfile.TemporaryDirectory() as directory:
            inventory = create_inventory([self.sample(directory)])
        self.assertEqual(inventory["totals"]["knowledgeUnits"], 1)
        self.assertEqual(inventory["totals"]["variants"], 1)
        self.assertEqual(inventory["stages"]["variants"]["draft"], 1)
        self.assertEqual(inventory["stages"]["variants"]["finalApproval"], 0)
        self.assertEqual(inventory["sources"], {"locator_review_pending": 1})
        self.assertNotIn("Draft-only", json.dumps(inventory))
        self.assertNotIn("private.invalid", json.dumps(inventory))

    def test_shuffled_options_cannot_inflate_variant_counts(self):
        with tempfile.TemporaryDirectory() as directory:
            with self.assertRaisesRegex(ValueError, "option permutation"):
                create_inventory([self.sample(directory, duplicate=True)])

    def test_review_approval_validation_and_integration_are_distinct(self):
        record = dict(reviewStatus="approved_hash", approvalHash="1" * 64,
                      reviewer="reviewer", reviewedAt="2026-11-26")
        self.assertTrue(record_stages(record, False)["finalApproval"])
        self.assertFalse(record_stages(record, False)["sourceVerified"])
        self.assertFalse(record_stages(record, False)["validated"])
        self.assertFalse(record_stages(record, False)["integrated"])
        self.assertFalse(record_stages(record, True)["finalApproval"])
        record.update(validationStatus="validated", integrationStatus="integrated")
        self.assertTrue(record_stages(record, False)["integrated"])


class PublicationTests(unittest.TestCase):
    def test_authoring_payload_and_environment_files_are_excluded(self):
        forbidden = ("docs/curriculum/drafts/", "docs/curriculum/planning/", "noor-season-one/")
        self.assertFalse(any(path.startswith(forbidden) for path in PUBLIC_FILES))
        self.assertFalse(any(Path(path).name.startswith(".env") for path in PUBLIC_FILES))
        self.assertNotIn("docs/curriculum/public-inventory.json", PUBLIC_FILES)

    def test_evidence_and_relative_links_fail_closed(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            with self.assertRaisesRegex(ValueError, "Broken relative link"):
                LinkCheck(root, root).validate('<a href="missing.webp">Missing</a>')
            with self.assertRaisesRegex(ValueError, "Escaping Pages link"):
                LinkCheck(root, root).validate('<a href="../secret">Outside</a>')
            dashboard = root / "docs/mission-control"
            dashboard.mkdir(parents=True)
            (dashboard / "progress.json").write_text(json.dumps({"phases": [
                {"tasks": [{"id": "001-01", "status": "done", "evidence": []}]},
            ]}), encoding="utf-8")
            with self.assertRaisesRegex(ValueError, "Missing evidence"):
                Dashboard(root, "main", "commit", "date", True)
