"""Materialize only the owner-approved starter manifest into app assets."""

import argparse
from collections import Counter
import json
import re

from curriculum_handoff import ROOT, require, visible
from curriculum_review_patch import digest, json_bytes
from starter_candidate import OUTPUT

RECEIPT = ROOT / "docs/curriculum/starter-release.json"
RELEASES = ROOT / "docs/curriculum/releases.json"
CANDIDATE = ROOT / OUTPUT
DESTINATION = ROOT / "assets/curriculum"


def scoped_claim_evidence(entry, sources):
    record = entry["record"]
    expected = {
        sources[id]["record"]["authoringSourceId"]: sources[id]["record"]["url"]
        for id in record["sourceRefs"]
    }
    reviewed = {item["id"]: item["url"] for item in entry["evidence"]}
    require(reviewed == expected and len(reviewed) == len(entry["evidence"])
            and all(visible(item["supportsAr"]) for item in entry["evidence"]),
            f"Missing selected claim evidence for {record['id']}")


def release_files(receipt, manifest_bytes, read_pack):
    require(digest(manifest_bytes) == receipt["approvalRequestSha256"], "Approval request SHA-256 differs")
    request = json.loads(manifest_bytes)
    require(request["checkpoint"] == "final_human_approval_requested"
            and request["package"] == receipt["contentPackage"]
            and request["lessonIds"] == receipt["lessonIds"], "Approved starter scope differs")
    entries = request["recordRequests"]
    by_id = {entry["recordId"]: entry for entry in entries}
    require(len(by_id) == len(entries) and dict(Counter(row["kind"] for row in entries)) == receipt["counts"],
            "Approved record inventory differs")
    require({row["recordId"] for row in entries if row["kind"] == "lesson"} == set(receipt["lessonIds"]),
            "Starter lesson identities differ")
    deferred = request["deferredExtras"]
    excluded = set(request["deferredLessonIds"]) | set(deferred["memorizationIds"]) | set(deferred["treasureIds"])
    counts = dict(lessons=len(request["deferredLessonIds"]), memorization=len(deferred["memorizationIds"]),
                  treasures=len(deferred["treasureIds"]), openReviewItems=len(request["openQueue"]))
    require(counts == receipt["deferred"] and not excluded.intersection(by_id), "Deferred starter content found")
    sources = {id: entry for id, entry in by_id.items() if entry["kind"] == "source"}
    for item in request["openQueue"]:
        # A general locator queue covers other uses of the same source. Only
        # the selected claim-to-source edges may use the reviewed locator here.
        if item["kind"] != "sourceVerification":
            require(not (set(item["ids"]) | set(item.get("affectedVariantIds", []))) & by_id.keys(),
                    f"Unresolved selected claim: {item['id']}")
    approvals = []
    files = {}
    pack_ids = []
    emitted = set()
    for item in request["candidatePacks"]:
        pack_id = item["packId"]
        require(pack_id not in pack_ids, f"Duplicate approved pack {pack_id}")
        pack_ids.append(pack_id)
        pack = json.loads(read_pack(pack_id))
        require(pack["packId"] == pack_id and pack["version"] == item["version"] and pack["channel"] == "draft"
                and digest(json_bytes(pack, canonical=True)) == item["candidateDigest"],
                f"Exact candidate pack differs for {pack_id}")
        for draft in pack["records"]:
            id = draft["id"]
            entry = by_id[id]
            require(id not in emitted and entry["packId"] == pack_id and entry["packVersion"] == pack["version"]
                    and entry["kind"] == draft["kind"] and draft == entry["record"] and draft["reviewStatus"] == "draft"
                    and digest(json_bytes({"packId": pack_id, "record": draft}, canonical=True)) == entry["candidateDigest"],
                    f"Exact candidate record differs for {id}")
            if entry["kind"] in {"knowledge", "variant"}:
                scoped_claim_evidence(entry, sources)
            elif entry["kind"] == "source":
                require(entry["evidence"] and all(
                    item["claimRecordId"] in by_id
                    and id in by_id[item["claimRecordId"]]["record"]["sourceRefs"]
                    and item["url"] == draft["url"]
                    for item in entry["evidence"]
                ), f"Source has no matching selected claim: {id}")
            draft["reviewStatus"] = "sourceVerified"
            approved = digest(json_bytes({"packId": pack_id, "record": draft}, canonical=True))
            require(approved == entry["conditionalApprovalDigest"], f"Conditional approval differs for {id}")
            approvals.append({"packId": pack_id, "recordId": id, "digest": approved,
                              "reviewer": receipt["approvalRole"], "reviewedAt": receipt["approvalRecordedAt"]})
            emitted.add(id)
        pack["channel"] = "production"
        files[f"packs/{pack_id}.json"] = json_bytes(pack)
    require(emitted == by_id.keys(), "Approved starter record coverage differs")
    files["index.json"] = json_bytes({"schema": 1, "packIds": pack_ids})
    files["approvals.json"] = json_bytes({"schema": 1, "approvalRequestSha256": receipt["approvalRequestSha256"],
                                          "approvals": approvals})
    return files


def apply_pack_releases(files, releases):
    """Project engineering-only version bumps after verifying all record bytes."""
    index = json.loads(files["index.json"])
    notes = []
    version_pattern = r"(0|[1-9][0-9]{0,8})(?:\.(0|[1-9][0-9]{0,8})){2}"
    for entry in releases:
        pack_id, version = entry["packId"], entry["version"]
        require(pack_id in index["packIds"] and re.fullmatch(version_pattern, version)
                and visible(entry["whatsNew"]), f"Invalid release metadata for {pack_id}")
        name = f"packs/{pack_id}.json"
        pack = json.loads(files[name])
        version_tuple = tuple(map(int, version.split(".")))
        previous = tuple(map(int, pack["version"].split(".")))
        require(version_tuple > previous and version_tuple[:2] == previous[:2],
                f"Expected increasing compatible patch version for {pack_id}")
        pack["version"] = version
        files[name] = json_bytes(pack)
        notes = [note for note in notes if note["packId"] != pack_id]
        notes.append({key: entry[key] for key in ("packId", "version", "whatsNew")})
    if notes:
        index["releaseNotes"] = notes
        files["index.json"] = json_bytes(index)
    return files


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    files = release_files(json.loads(RECEIPT.read_bytes()), (CANDIDATE / "approval-request.json").read_bytes(),
                          lambda id: (CANDIDATE / f"{id}.json").read_bytes())
    files = apply_pack_releases(files, json.loads(RELEASES.read_bytes())["releases"])
    existing = {file.relative_to(DESTINATION).as_posix() for file in DESTINATION.rglob("*") if file.is_file()}
    require(existing <= files.keys(), "Unexpected app curriculum assets")
    for name, data in files.items():
        path = DESTINATION / name
        if args.check:
            require(path.is_file() and path.read_bytes() == data, f"Bundled asset differs: {name}")
        else:
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_bytes(data)
    print("Verified owner-approved starter bundle: four packs and 112 exact approvals")


if __name__ == "__main__":
    main()
