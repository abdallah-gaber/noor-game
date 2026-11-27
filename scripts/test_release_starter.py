import json
import unittest

from release_starter import (CANDIDATE, DESTINATION, RECEIPT, RELEASES, apply_pack_releases,
                             release_files, scoped_claim_evidence)


class ScopedReleaseTests(unittest.TestCase):
    def test_selected_claim_must_match_scoped_reference(self):
        sources = {"source.iman.Q-test": {"record": {"authoringSourceId": "Q-test", "url": "https://example.invalid"}}}
        record = {"record": {"id": "test.K1", "sourceRefs": ["source.iman.Q-test"]},
                  "evidence": [{"id": "Q-test", "url": "https://example.invalid", "supportsAr": "Example"}]}
        scoped_claim_evidence(record, sources)
        record["evidence"][0]["url"] = "https://wrong.invalid"
        with self.assertRaisesRegex(ValueError, "Missing selected claim evidence"):
            scoped_claim_evidence(record, sources)

    @unittest.skipUnless((CANDIDATE / "approval-request.json").is_file(), "Private owner request is local only")
    def test_exact_authorization_and_release_bytes(self):
        manifest = (CANDIDATE / "approval-request.json").read_bytes()
        receipt = json.loads(RECEIPT.read_bytes())
        read_pack = lambda id: (CANDIDATE / f"{id}.json").read_bytes()
        assets = release_files(receipt, manifest, read_pack)
        self.assertEqual(len(assets), 6)
        projected = apply_pack_releases(dict(assets), json.loads(RELEASES.read_bytes())["releases"])
        self.assertTrue(all((DESTINATION / name).read_bytes() == data for name, data in projected.items()))
        self.assertEqual(projected["approvals.json"], assets["approvals.json"])
        packs = [name for name in assets if name.startswith("packs/")]
        for name in packs:
            reference = json.loads(assets[name])
            actual = json.loads(projected[name])
            actual["version"] = reference["version"]
            self.assertEqual(actual, reference)
        with self.assertRaisesRegex(ValueError, "Approval request SHA-256 differs"):
            release_files(receipt, manifest + b"\n", read_pack)

        def tampered(id):
            pack = json.loads(read_pack(id))
            pack["records"][0]["title"] = "Changed after owner approval"
            return json.dumps(pack).encode()

        with self.assertRaisesRegex(ValueError, "Exact candidate pack differs"):
            release_files(receipt, manifest, tampered)
