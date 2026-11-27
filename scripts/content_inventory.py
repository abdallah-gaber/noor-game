"""Export public-safe counts from local canonical curriculum records."""
import argparse
from collections import Counter
import hashlib
import json
from pathlib import Path
import re

from curriculum_handoff import load_handoff, variant_signature

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


def create_inventory(files):
    payloads = [file.read_bytes() for file in sorted(files)]
    fingerprint = hashlib.sha256(b"".join(hashlib.sha256(payload).digest() for payload in payloads))
    return inventory_for_packs([json.loads(payload) for payload in payloads], fingerprint.hexdigest())


def inventory_for_packs(packs, input_digest, *, structurally_checked=False):
    result = {
        "catalogs": 0, "inputDigest": "", "totals": {},
        "stages": {kind: {stage: 0 for stage in STAGES} for kind in KINDS},
        "sources": {}, "mechanics": {}, "difficulty": {}, "worlds": {},
    }
    ids = {kind: set() for kind in KINDS}
    source_status = {}
    variants = set()
    for pack in packs:
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
            scoped = (world, key)
            if scoped in source_status:
                raise ValueError("Duplicate source identifier within a world")
            source_status[scoped] = status
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
                        result["stages"][kind][stage] += int(
                            present or (stage == "validated" and structurally_checked)
                        )
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
    result["inputDigest"] = input_digest
    result["totals"] = {kind: len(keys) for kind, keys in ids.items()}
    result["sources"] = dict(Counter(source_status.values()))
    return result


def handoff_inventory(handoff):
    extras = handoff["extras"]
    enhancement = handoff["enhancement"]
    by_lesson = {}
    for collection, field in (
        (extras["memorization"], "mnemonics"),
        (extras["treasures"], "treasures"),
        (enhancement["additions"], "challenges"),
    ):
        for row in collection:
            by_lesson.setdefault(row["lessonId"], {}).setdefault(field, []).append(row)

    packs = []
    for pack in handoff["corePacks"]:
        lessons = []
        for lesson in pack["lessons"]:
            supplements = by_lesson.get(lesson["id"], {})
            lessons.append({**lesson, **{
                field: [*lesson.get(field, []), *rows] for field, rows in supplements.items()
            }})
        packs.append({**pack, "lessons": lessons})

    digests = b"".join(bytes.fromhex(digest) for _, digest in sorted(handoff["inputDigests"].items()))
    result = inventory_for_packs(packs, hashlib.sha256(digests).hexdigest(), structurally_checked=True)
    source_counts = Counter(result["sources"])
    for source in extras["sources"].values():
        state = source["status"]
        source_counts[state if state in SOURCE_STATES else "unknown"] += 1
    result["sources"] = dict(source_counts)
    queue = handoff["correctionQueue"]
    result["handoff"] = {
        "contentPackages": len(handoff["inputDigests"]) - 1,  # CONTENT-007 has two audited inputs.
        "plannedLessons": len(handoff["blueprint"]["lessons"]),
        "plannedObjectives": sum(len(row["objectives"]) for row in handoff["blueprint"]["lessons"]),
        "correctionQueue": dict(Counter(row["kind"] for row in queue)),
        "mixedReviewVariants": len(handoff["mixedReviewPrerequisites"]),
        "prayerReadinessLessons": enhancement["prayerReadiness"]["lessonIds"],
    }
    return result


def inventory_json(result):
    return json.dumps(result, ensure_ascii=False, indent=2, sort_keys=True) + "\n"


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("inputs", type=Path, nargs="*", default=[])
    parser.add_argument("--check", action="store_true", help="compare the export with the tracked snapshot")
    args = parser.parse_args()
    result = create_inventory(args.inputs) if args.inputs else handoff_inventory(load_handoff())
    snapshot = ROOT / "docs/curriculum/public-inventory.json"
    content = inventory_json(result)
    if args.check:
        if snapshot.read_text() != content:
            parser.error("Public inventory differs from canonical records")
    else:
        snapshot.write_text(content)
    print("Public inventory matches the canonical curriculum inputs")


if __name__ == "__main__":
    main()
