import hashlib
from html.parser import HTMLParser
import json
from pathlib import Path
import shutil
import tempfile
import unittest
from urllib.parse import unquote

from content_inventory import handoff_inventory, inventory_json
from curriculum_handoff import (AUDIT, BLUEPRINT, CORE, CURRICULUM, ENHANCEMENT,
                                challenge, load_handoff, validate_path, validate_prerequisites)
from generate_curriculum_review import render_review


class ReviewLinks(HTMLParser):
    def __init__(self):
        super().__init__()
        self.ids = []
        self.fragments = []

    def handle_starttag(self, tag, attrs):
        for key, value in attrs:
            if key == "id":
                self.ids.append(value)
            if key == "href" and value.startswith("#"):
                self.fragments.append(unquote(value[1:]))


class StructureTests(unittest.TestCase):
    def test_answer_identity_and_ambiguous_label(self):
        row = {
            "id": "test.Q1", "type": "multiple_choice", "level": "recall",
            "knowledgeIds": ["test.K1"], "sourceRefs": ["local:source"],
            "promptAr": "Example prompt", "explanationAr": "Example explanation",
            "correctOptionIds": ["answer"], "answerAr": "Circle",
            "options": [{"id": "answer", "textAr": "Circle"}, {"id": "other", "textAr": "Square"}],
        }
        self.assertEqual(challenge(row)["correctOptionId"], "answer")
        row["options"][1]["textAr"] = "Ci\u200brcle"
        with self.assertRaisesRegex(ValueError, "Ambiguous"):
            challenge(row)

    def test_path_requires_earlier_dependencies_and_rejects_cycle(self):
        lessons = {"A": {"worldId": "iman"}, "B": {"worldId": "ibadah", "prerequisiteIds": ["A"]}}
        path = {"id": "path", "titleAr": "Example", "lessonIds": ["A", "B"]}
        validate_prerequisites(lessons)
        validate_path(path, lessons)
        with self.assertRaisesRegex(ValueError, "must appear before"):
            validate_path({**path, "lessonIds": ["B", "A"]}, lessons)
        lessons["A"]["prerequisiteIds"] = ["B"]
        with self.assertRaisesRegex(ValueError, "Cyclic"):
            validate_prerequisites(lessons)

    def test_arrangement_requires_each_item_once(self):
        row = {
            "id": "test.Q2", "type": "ordering", "level": "application",
            "knowledgeIds": ["test.K1"], "sourceRefs": ["local:source"],
            "promptAr": "Example prompt", "explanationAr": "Example explanation",
            "items": [{"id": "first", "textAr": "First"}, {"id": "last", "textAr": "Last"}],
            "correctOrderIds": ["first"],
        }
        with self.assertRaisesRegex(ValueError, "Incomplete order"):
            challenge(row)


@unittest.skipUnless((CURRICULUM / BLUEPRINT).is_file(), "Private authoring files are local only")
class CanonicalTests(unittest.TestCase):
    def test_review_preserves_all_inputs_without_record_approvals(self):
        handoff = load_handoff()
        inventory = handoff_inventory(handoff)
        self.assertEqual(handoff["channel"], "privateDraftReview")
        self.assertEqual(len(handoff["inputDigests"]), 8)
        self.assertEqual(inventory["handoff"]["contentPackages"], 7)
        self.assertEqual(inventory["totals"], {
            "lessons": 60, "knowledgeUnits": 180, "objectives": 180, "variants": 636,
            "mnemonics": 20, "treasures": 30,
        })
        self.assertEqual(len(inventory["mechanics"]), 5)
        self.assertEqual(sum(inventory["sources"].values()), 181)
        self.assertEqual(len(handoff["mixedReviewPrerequisites"]), 8)
        self.assertEqual(inventory["handoff"]["prayerReadinessLessons"][:2], ["I03", "W02"])
        self.assertEqual(len(inventory["handoff"]["prayerReadinessLessons"]), 14)
        self.assertEqual(len(handoff["correctionQueue"]), 27)
        self.assertEqual(inventory["stages"]["variants"]["validated"], 636)
        for stage in ("sourceVerified", "ownerReviewed", "finalApproval", "integrated"):
            self.assertFalse(any(row[stage] for row in inventory["stages"].values()))
        review = render_review(handoff)
        links = ReviewLinks()
        links.feed(review)
        self.assertEqual(len(links.ids), len(set(links.ids)))
        self.assertEqual(set(links.fragments) - set(links.ids), set())
        snapshot = inventory_json(inventory)
        self.assertNotRegex(snapshot, r"[\u0600-\u06ff]")
        self.assertNotIn("https://", snapshot)
        self.assertNotIn("sourceRefs", snapshot)
        finding = next(row for row in handoff["correctionQueue"] if row["ids"] == ["W06.K3"])
        self.assertTrue(finding["affectedVariantIds"])
        self.assertIn("W06.K3", review)

    def test_rejects_drift_and_unresolved_cross_lesson_sources(self):
        with tempfile.TemporaryDirectory() as folder:
            curriculum = Path(folder) / "curriculum"
            shutil.copytree(CURRICULUM, curriculum)
            drafts = curriculum / "drafts"
            first = drafts / CORE[0]
            first.write_bytes(first.read_bytes() + b"\n")
            with self.assertRaisesRegex(ValueError, "input digest differs"):
                load_handoff(curriculum)
            audit = drafts / AUDIT
            summary = json.loads(audit.read_text())
            summary["inputSha256"][CORE[0]] = hashlib.sha256(first.read_bytes()).hexdigest()
            audit.write_text(json.dumps(summary))
            patch = drafts / ENHANCEMENT
            enhancement = json.loads(patch.read_text())
            row = next(row for row in enhancement["additions"] if row["id"] == "P02.E01")
            row["approvalHash"] = "f" * 64
            patch.write_text(json.dumps(enhancement))
            with self.assertRaisesRegex(ValueError, "Unexpected approval signal"):
                load_handoff(curriculum)
            row["approvalHash"] = None
            row["sourceRefsByKnowledge"]["P03.K2"] = ["missing:source"]
            patch.write_text(json.dumps(enhancement))
            with self.assertRaisesRegex(ValueError, "Unresolved|unresolved"):
                load_handoff(curriculum)
