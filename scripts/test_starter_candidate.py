import json
import unittest

from curriculum_handoff import CURRICULUM
from curriculum_review_patch import load_content_009
from starter_candidate import (FINAL_EDITORIAL, PACKAGE, apply_final_editorial, build_candidate,
                               check_closure, load_starter_candidate)


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

    @unittest.skipUnless((CURRICULUM / FINAL_EDITORIAL).is_file(), "Private final editorial overlay is local only")
    def test_final_request_updates_only_editorial_and_attribution_hashes(self):
        baseline, encoded = load_content_009()
        manifest = json.loads((CURRICULUM / PACKAGE).read_bytes())
        base = build_candidate(baseline, encoded, manifest)
        handoff, _, packs, final = load_starter_candidate()
        self.assertEqual(final["checkpoint"], "final_human_approval_requested")
        self.assertEqual(final["openQueue"], base[3]["openQueue"])
        self.assertEqual(handoff["starterCandidate"]["finalEditorialRecords"], 12)
        self.assertEqual(handoff["starterCandidate"]["hadithAttributions"], 10)
        old = {row["recordId"]: row["candidateDigest"] for row in base[3]["recordRequests"]}
        changed = [row for row in final["recordRequests"] if old[row["recordId"]] != row["candidateDigest"]]
        self.assertEqual(len(changed), 22)
        self.assertEqual({p["version"] for p in packs}, {"0.1.1"})
        self.assertTrue(all(row["record"]["reviewStatus"] == "draft" for row in final["recordRequests"]))
        self.assertTrue(all(row["record"]["authenticity"] == "صحيح"
                            for row in final["recordRequests"] if "collectionAttribution" in row))
        self.assertEqual(sum("collectionAttribution" in row for row in final["recordRequests"]), 10)
        definitions = handoff["variantDefinitions"]
        self.assertEqual(definitions["P10.Q09"]["answer"], "نتعلم الرفق وحسن المعاملة.")
        self.assertEqual(definitions["I03.Q10"]["explanation"], "نشكر الله ونشكر والدينا على مساعدتهم لنا.")
        self.assertEqual(definitions["W08.E01"]["explanation"], definitions["W08.Q04"]["explanation"])
        self.assertIn("مع المرفقين", definitions["W05.Q04"]["explanation"])

        editorial = json.loads((CURRICULUM / FINAL_EDITORIAL).read_bytes())
        with self.assertRaisesRegex(ValueError, "baseline approval request differs"):
            apply_final_editorial(base, manifest, {**editorial, "baselineApprovalRequestSha256": "0" * 64})
        next(iter(editorial["recordEdits"][0]["fields"].values()))["before"] = "changed"
        with self.assertRaisesRegex(ValueError, "before-value or scored answer conflict"):
            apply_final_editorial(base, manifest, editorial)
