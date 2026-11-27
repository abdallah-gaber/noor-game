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
from curriculum_review_patch import (FOLLOWUP_DIR, PATCH_DIR, apply_content_009, load_content_008,
                                     load_content_009)


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


@unittest.skipUnless((CURRICULUM / PATCH_DIR / "corrections.json").is_file(),
                     "Private CONTENT-008 files are local only")
class CorrectedDraftTests(unittest.TestCase):
    def test_corrected_inputs_preserve_ids_and_queue_holds_semantic_conflict(self):
        baseline = load_handoff()
        handoff, encoded = load_content_008()
        review = handoff["scientificReview"]
        inventory = handoff_inventory(handoff)
        self.assertEqual(len(encoded), 8)
        self.assertEqual(len(review["changedRecordDigests"]), 142)
        self.assertTrue(all(row["beforeSha256"] != row["afterSha256"] for row in review["changedRecordDigests"]))
        self.assertEqual([row["recordId"] for row in review["semanticConflicts"]], ["S01.Q03"])
        self.assertEqual(handoff["variantDefinitions"]["S01.Q03"], baseline["variantDefinitions"]["S01.Q03"])
        self.assertEqual(handoff["variantDefinitions"].keys(), baseline["variantDefinitions"].keys())
        self.assertEqual(inventory["totals"], handoff_inventory(baseline)["totals"])
        self.assertEqual(inventory["mechanics"], handoff_inventory(baseline)["mechanics"])
        self.assertEqual(inventory["handoff"]["prayerReadinessLessons"],
                         handoff_inventory(baseline)["handoff"]["prayerReadinessLessons"])
        self.assertEqual(len(review["duplicatePromptsBacklog"]), 60)
        self.assertEqual(sum(inventory["sources"].values()), 202)
        self.assertEqual(len(review["unusedOriginalSources"]), 9)
        for stage in ("sourceVerified", "ownerReviewed", "finalApproval", "integrated"):
            self.assertFalse(any(row[stage] for row in inventory["stages"].values()))
        statuses = {row["id"]: row["status"] for row in handoff["correctionQueue"]}
        self.assertEqual(len(statuses), 40)
        self.assertEqual(statuses["CONTENT-007-10"], "conflict_open")
        self.assertEqual(statuses["memorization-rights"], "rights_candidate_open")
        self.assertEqual(statuses["sources-ibadah"], "partial_open")
        self.assertEqual(statuses["CONTENT-007-07"], "applied_edition_pending")
        with tempfile.TemporaryDirectory() as folder:
            corrected = Path(folder)
            for name, data in encoded.items():
                target = corrected / name
                target.parent.mkdir(parents=True, exist_ok=True)
                target.write_bytes(data)
            self.assertEqual(load_handoff(corrected)["variantDefinitions"], handoff["variantDefinitions"])
        html = ReviewLinks()
        html.feed(render_review(handoff))
        self.assertEqual(len(html.ids), len(set(html.ids)))
        self.assertEqual(set(html.fragments) - set(html.ids), set())
        snapshot = inventory_json(inventory)
        self.assertNotRegex(snapshot, r"[\u0600-\u06ff]")
        for private_value in ("https://", "beforeSha256", "afterSha256", "S01.Q03", "sourceRefs"):
            self.assertNotIn(private_value, snapshot)

    def test_wrong_before_or_bundle_digest_fails_closed(self):
        with tempfile.TemporaryDirectory() as folder:
            curriculum = Path(folder) / "curriculum"
            shutil.copytree(CURRICULUM, curriculum)
            corrections = curriculum / PATCH_DIR / "corrections.json"
            summary_file = curriculum / PATCH_DIR / "summary.json"
            patch = json.loads(corrections.read_bytes())
            op = patch["recordOperations"][0]
            delta = next(iter(op["fields"].values()))
            before = delta["before"]
            delta["before"] = "wrong baseline value"
            corrections.write_text(json.dumps(patch))
            with self.assertRaisesRegex(ValueError, "Before-value conflict"):
                load_content_008(curriculum)
            delta["before"] = before
            patch["summary"]["baselineBundleSha256"] = "0" * 64
            summary_file.write_text(json.dumps(patch["summary"]))
            corrections.write_text(json.dumps(patch))
            with self.assertRaisesRegex(ValueError, "baseline digest does not match"):
                load_content_008(curriculum)


@unittest.skipUnless((CURRICULUM / FOLLOWUP_DIR / "corrections.json").is_file(),
                     "Private CONTENT-009 files are local only")
class FollowupTests(unittest.TestCase):
    def test_latest_handoff_keeps_scoring_and_pending_states(self):
        old, encoded = load_content_008()
        new, _ = load_content_009()
        self.assertEqual(new["scientificReview"]["sourceLedger"], old["scientificReview"]["sourceLedger"])
        self.assertEqual(new["variantDefinitions"]["S01.Q03"], old["variantDefinitions"]["S01.Q03"])
        for id, definition in old["variantDefinitions"].items():
            for field in ("type", "correctOptionId", "correctOrder", "items", "pairs"):
                self.assertEqual(definition.get(field), new["variantDefinitions"][id].get(field))
        self.assertEqual(new["variantDefinitions"]["W13.E01"]["sourceRefsByKnowledge"]["W13.K3"], ["B-757", "B-789"])
        planned = next(row for row in new["blueprint"]["lessons"] if row["id"] == "W06")
        drafted = next(row for pack in new["corePacks"] for row in pack["lessons"] if row["id"] == "W06")
        self.assertEqual(planned["objectives"][2]["textAr"], drafted["objectives"][2]["textAr"])
        inventory = handoff_inventory(new)
        self.assertEqual(inventory["totals"], handoff_inventory(old)["totals"])
        self.assertEqual(sum(inventory["sources"].values()), 205)
        self.assertEqual(len(new["scientificReview"]["followup"]["changedRecordDigests"]), 25)
        status = {row["id"]: row["status"] for row in new["correctionQueue"]}
        self.assertEqual(status["CONTENT-007-10"], "retained_edition_pending")
        self.assertEqual(status["NEW-13"], "open_release_gate")
        self.assertEqual(sum(state != "applied_draft" for state in status.values()), 12)
        for stage in ("sourceVerified", "ownerReviewed", "finalApproval", "integrated"):
            self.assertFalse(any(row[stage] for row in inventory["stages"].values()))
        html = ReviewLinks()
        html.feed(render_review(new))
        self.assertFalse(set(html.fragments) - set(html.ids))
        self.assertNotRegex(inventory_json(inventory), r"[\u0600-\u06ff]")

    def test_wrong_digest_and_before_value_fail_closed(self):
        old, encoded = load_content_008()
        folder = CURRICULUM / FOLLOWUP_DIR
        patch = json.loads((folder / "corrections.json").read_bytes())
        ledger = json.loads((folder / "source-ledger.json").read_bytes())
        with self.assertRaisesRegex(ValueError, "baseline SHA-256 mismatch"):
            apply_content_009(old, encoded, {**patch, "baselineBundleSha256": "0" * 64}, ledger)
        patch["recordEdits"][0]["fields"]["sourceRefs"]["before"] = ["wrong"]
        with self.assertRaisesRegex(ValueError, "Before-value conflict"):
            apply_content_009(old, encoded, patch, ledger)
