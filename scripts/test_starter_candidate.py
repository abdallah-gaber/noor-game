import json
import unittest

from curriculum_handoff import CURRICULUM
from curriculum_review_patch import load_content_009
from starter_candidate import PACKAGE, build_candidate, check_closure, load_starter_candidate


class StarterGateTests(unittest.TestCase):
    def test_missing_dependency_fails(self):
        lessons = {"A": {"prerequisiteIds": ["B"]}, "B": {}, "C": {"prerequisiteId": "B"}}
        check_closure({"A", "B", "C"}, lessons)
        with self.assertRaisesRegex(ValueError, "Missing starter prerequisites"):
            check_closure({"A", "C"}, lessons)


@unittest.skipUnless((CURRICULUM / PACKAGE).is_file(), "Private CONTENT-010 files are local only")
class StarterCandidateTests(unittest.TestCase):
    def test_candidate_coverage_and_pending_gates(self):
        handoff, _, packs, approval = load_starter_candidate()
        records = [row for pack in packs for row in pack["records"]]
        self.assertEqual(len(approval["recordRequests"]), 112)
        self.assertEqual(len(approval["openQueue"]), 12)
        self.assertEqual(len(approval["deferredLessonIds"]), 54)
        self.assertEqual({row["kind"] for row in records}, {"source", "unit", "lesson", "knowledge", "variant"})
        self.assertEqual({row["reviewStatus"] for row in records}, {"draft"})
        self.assertEqual({pack["channel"] for pack in packs}, {"draft"})
        for row in records:
            if row["kind"] == "variant" and row["definition"]["type"] == "trueFalse":
                old = handoff["variantDefinitions"][row["id"]]
                self.assertEqual(row["authoringBooleanOptionIds"][row["definition"]["correctOptionId"]],
                                 old["correctOptionId"])
        self.assertNotIn("approvals", approval)

    def test_input_digest_and_guarded_values_fail_closed(self):
        baseline, encoded = load_content_009()
        raw = (CURRICULUM / PACKAGE).read_bytes()
        evidence = json.loads(raw)
        evidence["inputDigests"].clear()
        with self.assertRaisesRegex(ValueError, "bundle or input digest differs"):
            build_candidate(baseline, encoded, evidence)
        evidence = json.loads(raw)
        evidence["guardedEdits"][0]["before"] = ["changed"]
        with self.assertRaisesRegex(ValueError, "before-value conflict"):
            build_candidate(baseline, encoded, evidence)
