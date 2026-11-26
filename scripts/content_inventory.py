"""Export public-safe counts from local canonical curriculum records."""
import argparse
from collections import Counter
import hashlib
import json
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
KINDS = {
    "lessons": None,
    "objectives": "objectives",
    "knowledgeUnits": "knowledgeUnits",
    "variants": "challenges",
    "mnemonics": "mnemonics",
    "treasures": "treasures",
}
STAGES = (
    "draft", "sourceVerified", "ownerReviewed", "finalApproval",
    "validated", "integrated", "releaseVerified",
)
MECHANICS = {"multiple_choice", "true_false", "flashcard", "matching", "ordering", "recitation"}
LEVELS = {"recognition", "understanding", "recall", "application"}
SOURCE_STATES = {"locator_review_pending", "historical_edition_review_pending", "verified", "source_verified", "rejected"}


def stable_id(value):
    if not isinstance(value, str) or not re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9_.-]*", value):
        raise ValueError("Expected a public-safe stable identifier")
    return value


def record_stages(record, draft_pack):
    status = record.get("reviewStatus", record.get("status"))
    verified = record.get("sourceVerificationStatus") in {"verified", "source_verified"}
    verified |= status == "source_verified"
    owner = status in {"owner_reviewed", "approved", "approved_hash", "integrated", "release_verified"}
    digest = record.get("approvalHash")
    approved = (
        not draft_pack
        and status in {"approved", "approved_hash", "integrated", "release_verified"}
        and isinstance(digest, str)
        and re.fullmatch(r"[a-fA-F0-9]{64}", digest) is not None
        and bool(record.get("reviewer"))
        and bool(record.get("reviewedAt"))
    )
    validated = record.get("validationStatus") == "validated"
    integrated = approved and validated and record.get("integrationStatus") == "integrated"
    return dict(zip(STAGES, (
        draft_pack or status == "draft", verified, owner, approved, validated,
        integrated, integrated and record.get("releaseStatus") == "release_verified",
    )))


def variant_signature(record):
    def normalized(value):
        return " ".join(str(value or "").split())

    correct = set(record.get("correctOptionIds") or ())
    options = tuple(sorted(
        (normalized(option.get("textAr")), option.get("id") in correct)
        for option in (record.get("options") or [])
    ))
    return (
        record.get("type"), tuple(sorted(set(record.get("knowledgeIds") or ()))),
        normalized(record.get("promptAr")), normalized(record.get("answerAr")), options,
    )


def create_inventory(files):
    result = {
        "catalogs": 0, "inputDigest": "", "totals": {},
        "stages": {kind: {stage: 0 for stage in STAGES} for kind in KINDS},
        "sources": {}, "mechanics": {}, "difficulty": {}, "worlds": {},
    }
    ids = {kind: set() for kind in KINDS}
    source_status = {}
    variants = set()
    fingerprint = hashlib.sha256()
    for file in sorted(files):
        payload = file.read_bytes()
        fingerprint.update(hashlib.sha256(payload).digest())
        pack = json.loads(payload)
        world = stable_id(pack["worldId"])
        draft_pack = pack.get("status") == "draft_not_for_release"
        result["catalogs"] += 1
        world_units = result["worlds"].setdefault(world, {})
        for source in pack["sources"]:
            key = source["id"]
            if not isinstance(key, str) or not key.strip():
                raise ValueError("Missing source identifier")
            value = source.get("verificationStatus")
            status = value if value in SOURCE_STATES else "unknown"
            if key in source_status and source_status[key] != status:
                raise ValueError("Conflicting verification statuses for a source identifier")
            source_status[key] = status
        for lesson in pack["lessons"]:
            unit = stable_id(lesson["unitId"])
            lesson_id = stable_id(lesson["id"])
            counts = {kind: 0 for kind in KINDS}
            for kind, field in KINDS.items():
                records = [lesson] if field is None else lesson.get(field, [])
                for record in records:
                    key = stable_id(record["id"])
                    if key in ids[kind]:
                        raise ValueError(f"Duplicate {kind} identifier {key}")
                    ids[kind].add(key)
                    counts[kind] += 1
                    for stage, present in record_stages(record, draft_pack).items():
                        result["stages"][kind][stage] += int(present)
                    if kind == "variants":
                        signature = variant_signature(record)
                        if signature in variants:
                            raise ValueError(f"Duplicate variant or option permutation {key}")
                        variants.add(signature)
                        for group, value, allowed in (
                            ("mechanics", record.get("type"), MECHANICS),
                            ("difficulty", record.get("level"), LEVELS),
                        ):
                            bucket = value if value in allowed else "unknown"
                            breakdown = result[group]
                            breakdown[bucket] = breakdown.get(bucket, 0) + 1
            world_units.setdefault(unit, {})[lesson_id] = counts
    result["inputDigest"] = fingerprint.hexdigest()
    result["totals"] = {kind: len(keys) for kind, keys in ids.items()}
    result["sources"] = dict(Counter(source_status.values()))
    return result


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("inputs", type=Path, nargs="*", default=[])
    parser.add_argument("--check", action="store_true", help="compare the export with the tracked snapshot")
    args = parser.parse_args()
    inputs = args.inputs or list((ROOT / "docs/curriculum/drafts").glob("*/*.json"))
    if not inputs:
        parser.error("No canonical curriculum packs found")
    snapshot = ROOT / "docs/curriculum/public-inventory.json"
    content = json.dumps(create_inventory(inputs), ensure_ascii=False, indent=2, sort_keys=True) + "\n"
    if args.check:
        if snapshot.read_text() != content:
            parser.error("Public inventory differs from canonical records")
    else:
        snapshot.write_text(content)
    print("Public inventory matches", len(inputs), "canonical packs")


if __name__ == "__main__":
    main()
