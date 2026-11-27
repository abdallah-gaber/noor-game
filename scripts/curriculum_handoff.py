"""Validate and adapt local CONTENT-001–007 for consolidated owner review."""

from collections import Counter
import hashlib
import json
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
CURRICULUM = ROOT / "docs/curriculum"
CORE = (
    "noor-content-002/iman.json",
    "noor-content-003/ibadah.json",
    "noor-content-004/seerah.json",
    "noor-content-005/exemplars.json",
)
EXTRAS = "noor-content-006/extras.json"
ENHANCEMENT = "noor-content-007/enhancement.json"
AUDIT = "noor-content-007/audit.json"
BLUEPRINT = "planning/noor-content-001/blueprint.json"
INPUT_FILES = (BLUEPRINT, *(f"drafts/{name}" for name in (*CORE, EXTRAS, ENHANCEMENT, AUDIT)))
MECHANICS = {
    "multiple_choice": "multipleChoice", "true_false": "trueFalse",
    "flashcard": "flashcard", "matching": "matching", "ordering": "ordering",
}
LEVELS = {"recognition", "understanding", "recall", "application"}
INVISIBLE = re.compile(r"[\u061c\u200b-\u200f\u202a-\u202e\u2060-\u2069]")


def read_json(path):
    return json.loads(path.read_bytes())


def verify_inputs(drafts):
    audit = read_json(drafts / AUDIT)
    if set(audit["inputSha256"]) != {*CORE, EXTRAS}:
        raise ValueError("CONTENT-007 audit must cover all core packs and extras")
    for name, digest in audit["inputSha256"].items():
        if hashlib.sha256((drafts / name).read_bytes()).hexdigest() != digest:
            raise ValueError(f"CONTENT-007 input digest differs for {name}")
    return audit


def require(condition, message):
    if not condition:
        raise ValueError(message)


def visible(text):
    return " ".join(INVISIBLE.sub("", text).split()) if isinstance(text, str) else ""


def stable(value):
    return isinstance(value, str) and bool(re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9_.-]*", value))


def index(records, kind, valid_id=stable):
    indexed = {}
    for record in records:
        key = record["id"]
        require(valid_id(key) and key not in indexed, f"Invalid or duplicate {kind} ID {key}")
        indexed[key] = record
    return indexed


def refs(values, candidates, label, *, allow_empty=False):
    require(isinstance(values, list) and (values or allow_empty), f"Missing {label}")
    require(len(set(values)) == len(values) and all(value in candidates for value in values),
            f"Duplicate or unresolved {label}")


def option(record):
    return {"id": record["id"], "label": record["textAr"]}


def options(entries, minimum, maximum, label):
    ids = index(entries, label)
    labels = [visible(item["label"]) for item in entries]
    require(minimum <= len(entries) <= maximum and all(labels) and len(set(labels)) == len(labels),
            f"Ambiguous or invalid {label}")
    return ids


def challenge(record):
    """Preserve authored IDs and Arabic while projecting to the existing mechanics."""
    key = record["id"]
    kind = MECHANICS.get(record["type"])
    require(kind is not None and record["level"] in LEVELS, f"Unknown mechanic or difficulty in {key}")
    result = {
        "schema": 1, "type": kind, "id": key,
        "prompt": record["promptAr"], "explanation": record["explanationAr"],
        "knowledgeIds": record["knowledgeIds"], "sourceRefs": record["sourceRefs"],
    }
    require(visible(result["prompt"]) and visible(result["explanation"]), f"Missing prompt or explanation in {key}")
    if kind in ("multipleChoice", "trueFalse"):
        choices = list(map(option, record["options"]))
        allowed = options(choices, 2, 2 if kind == "trueFalse" else 4, f"{key} options")
        if kind == "trueFalse":
            require({item["label"] for item in choices} == {"صحيح", "خطأ"}, f"Invalid true/false labels in {key}")
        answers = record["correctOptionIds"]
        refs(answers, allowed, f"{key} answer")
        require(len(answers) == 1, f"Non-unique answer in {key}")
        if record.get("answerAr") is not None:
            require(visible(record["answerAr"]) == visible(allowed[answers[0]]["label"]),
                    f"Answer text differs from selected answer in {key}")
        result.update(correctOptionId=answers[0], options=choices)
    elif kind == "flashcard":
        require(visible(record["answerAr"]) and not record.get("correctOptionIds"),
                f"Invalid unscored flashcard {key}")
        result["answer"] = record["answerAr"]
    elif kind == "matching":
        pairs = [{side: {"id": pair[side + "Id"], "label": pair[side + "Ar"]}
                  for side in ("left", "right")} for pair in record["pairs"]]
        for side in ("left", "right"):
            options([pair[side] for pair in pairs], 2, 4, f"{key} {side} pairs")
        result["pairs"] = pairs
    else:
        items = list(map(option, record["items"]))
        allowed = options(items, 2, 5, f"{key} items")
        order = record["correctOrderIds"]
        refs(order, allowed, f"{key} order")
        require(len(order) == len(items), f"Incomplete order in {key}")
        result.update(items=items, correctOrder=order)
    if "sourceRefsByKnowledge" in record:
        result["sourceRefsByKnowledge"] = record["sourceRefsByKnowledge"]
    return result


def variant_signature(record):
    correct = set(record.get("correctOptionIds") or ())
    options = tuple(sorted(
        (visible(option.get("textAr")), option.get("id") in correct)
        for option in (record.get("options") or [])
    ))
    pairs = tuple(sorted(
        (visible(pair["leftAr"]), visible(pair["rightAr"])) for pair in record.get("pairs", [])
    ))
    items = {item["id"]: visible(item["textAr"]) for item in record.get("items", [])}
    order = tuple(items[id] for id in record.get("correctOrderIds", []))
    return (
        record.get("type"), tuple(sorted(set(record.get("knowledgeIds") or ()))),
        visible(record.get("promptAr")), visible(record.get("answerAr")), options, pairs, order,
    )


def validate_path(path, lessons):
    refs(path["lessonIds"], lessons, "prayer-readiness lessons")
    require(stable(path["id"]) and visible(path["titleAr"]), "Invalid prayer-readiness path")
    available = set()
    for key in path["lessonIds"]:
        require(set(lessons[key].get("prerequisiteIds", [])) <= available,
                f"Path prerequisite must appear before {key}")
        available.add(key)
    require(len({lessons[key]["worldId"] for key in available}) > 1, "Prayer readiness must cross worlds")
    require(all(visible(activity) for activity in path.get("optionalOfflineActivitiesAr", [])),
            "Invalid prayer-readiness offline activity")


def validate_prerequisites(lessons):
    done = set()

    def visit(key, visiting):
        require(key not in visiting, f"Cyclic lesson prerequisite at {key}")
        if key not in done:
            requirements = lessons[key].get("prerequisiteIds", [])
            refs(requirements, lessons, f"{key} prerequisites", allow_empty=True)
            for dependency in requirements:
                visit(dependency, visiting | {key})
            done.add(key)

    for key in lessons:
        visit(key, set())


def load_handoff(curriculum=CURRICULUM):
    verify_inputs(curriculum / "drafts")
    documents = {name: read_json(curriculum / name) for name in INPUT_FILES}
    digests = {name: hashlib.sha256((curriculum / name).read_bytes()).hexdigest() for name in INPUT_FILES}
    return validate_handoff(documents, digests)


def validate_handoff(documents, digests):
    audit = documents[f"drafts/{AUDIT}"]
    blueprint = documents[BLUEPRINT]
    cores = [documents[f"drafts/{name}"] for name in CORE]
    extras = documents[f"drafts/{EXTRAS}"]
    enhancement = documents[f"drafts/{ENHANCEMENT}"]
    require(all(pack["status"] == "draft_not_for_release" and pack["schemaVersion"] == 1
                for pack in [*cores, extras, enhancement]), "Expected schema-1 drafts")
    require(blueprint["schemaVersion"] == 1, "Unknown CONTENT-001 schema")
    lesson_by_id = index([row for pack in cores for row in pack["lessons"]], "lesson")
    objective_by_id = index([row for lesson in lesson_by_id.values() for row in lesson["objectives"]], "objective")
    knowledge = index([row for lesson in lesson_by_id.values() for row in lesson["knowledgeUnits"]], "knowledge")
    knowledge_owner = {row["id"]: lesson for lesson in lesson_by_id.values() for row in lesson["knowledgeUnits"]}
    planned = index(blueprint["lessons"], "planned lesson")
    require(planned.keys() == lesson_by_id.keys(), "CONTENT-001 lesson IDs differ from the authored packs")
    for alias, ids in blueprint["previousOutlineOverlap"].items():
        refs(ids, planned, f"outline overlap {alias}")
    validate_prerequisites(lesson_by_id)
    world_sources = {pack["worldId"]: index(pack["sources"], "source", valid_id=visible) for pack in cores}
    require(set(world_sources) == {"iman", "ibadah", "seerah", "exemplars"} and len(cores) == 4,
            "Expected all four core worlds")
    for pack in cores:
        sources = world_sources[pack["worldId"]]
        for lesson in pack["lessons"]:
            key = lesson["id"]
            require(lesson["worldId"] == pack["worldId"] == planned[key]["worldId"]
                    and stable(lesson["unitId"]) and visible(lesson["titleAr"]),
                    f"Invalid world or unit in {key}")
            objectives = {row["id"] for row in lesson["objectives"]}
            require(objectives == index(planned[key]["objectives"], "planned objective").keys(),
                    f"CONTENT-001 objective identity differs in {key}")
            for row in lesson["knowledgeUnits"]:
                require(row["objectiveId"] in objectives and visible(row["textAr"]), f"Invalid knowledge {row['id']}")
                refs(row["sourceRefs"], sources, f"{row['id']} sources")
    base = [row for lesson in lesson_by_id.values() for row in lesson["challenges"]]
    for lesson in lesson_by_id.values():
        require(all(row["lessonId"] == lesson["id"] for row in lesson["challenges"]),
                f"Base challenge assigned to wrong lesson {lesson['id']}")
    variants = index([*base, *enhancement["additions"]], "variant")
    require(audit["coreCounts"] == {"lessons": len(lesson_by_id), "knowledgeUnits": len(knowledge), "variants": len(base)}
            and audit["baseMechanics"] == dict(Counter(row["type"] for row in base))
            and audit["addedMechanics"] == dict(Counter(row["type"] for row in enhancement["additions"])),
            "CONTENT-007 coverage audit differs")
    projected = {}
    mixed = {}
    signatures = set()
    citation_alignment = []
    for key, row in variants.items():
        owner = lesson_by_id.get(row["lessonId"])
        require(owner is not None and owner["worldId"] == row["worldId"], f"Invalid variant owner {key}")
        refs(row["knowledgeIds"], knowledge, f"{key} knowledge")
        knowledge_lessons = list(dict.fromkeys(knowledge_owner[id]["id"] for id in row["knowledgeIds"]))
        if knowledge_lessons != [owner["id"]]:
            require("sourceRefsByKnowledge" in row, f"Cross-lesson variant {key} needs scoped sources")
            mixed[key] = list(dict.fromkeys([owner["id"], *knowledge_lessons]))
        if "sourceRefsByKnowledge" in row:
            by_knowledge = row["sourceRefsByKnowledge"]
            require(by_knowledge.keys() == set(row["knowledgeIds"]), f"Incomplete knowledge source map in {key}")
            for knowledge_id, links in by_knowledge.items():
                available = world_sources[knowledge_owner[knowledge_id]["worldId"]]
                refs(links, available, f"{key} sources for {knowledge_id}")
                require(set(links) <= set(knowledge[knowledge_id]["sourceRefs"]),
                        f"{key} cites sources outside {knowledge_id}")
            source_ids = set().union(*(set(links) for links in by_knowledge.values()))
        else:
            source_ids = world_sources[owner["worldId"]]
            knowledge_sources = {ref for id in row["knowledgeIds"] for ref in knowledge[id]["sourceRefs"]}
            additional = [ref for ref in row["sourceRefs"] if ref not in knowledge_sources]
            if additional:
                citation_alignment.append({
                    "id": f"citation-{key}", "kind": "citationAlignment", "status": "open_editorial",
                    "ids": [key], "knowledgeIds": row["knowledgeIds"], "sourceScope": owner["worldId"],
                    "additionalSourceRefs": additional,
                })
        refs(row["sourceRefs"], source_ids, f"{key} sources")
        if "sourceRefsByKnowledge" in row:
            require(set(row["sourceRefs"]) == source_ids, f"Source summary differs in {key}")
        projected[key] = challenge(row)
        signature = variant_signature(row)
        require(signature not in signatures, f"Duplicate variant or option permutation {key}")
        signatures.add(signature)
    for kind in ("memorization", "treasures"):
        for key, row in index(extras[kind], kind).items():
            lesson = lesson_by_id.get(row["lessonId"])
            require(lesson is not None and row["worldId"] == lesson["worldId"] and visible(row["textAr"]),
                    f"Invalid {kind} attachment {key}")
            refs(row["sourceRefs"], extras["sources"], f"{key} sources")
            if kind == "memorization":
                require(row["recall"]["scored"] is False and visible(row["recall"]["promptAr"]),
                        f"Invalid unscored memorization recall {key}")
    all_records = index([*lesson_by_id.values(), *objective_by_id.values(), *knowledge.values(),
                         *variants.values(), *extras["memorization"], *extras["treasures"]], "review record")
    path = enhancement["prayerReadiness"]
    validate_path(path, lesson_by_id)
    require(path["id"] not in all_records, "Duplicate prayer-readiness record ID")
    for row in all_records.values():
        require(not any(row.get(key) for key in ("approvalHash", "reviewer", "reviewedAt")) and
                row.get("reviewStatus", "draft") == "draft", f"Unexpected approval signal in {row['id']}")
    queue = []
    for number, finding in enumerate(enhancement["reviewFindings"], 1):
        refs(finding["ids"], all_records, "correction targets")
        require(finding["status"] == "open_release_gate" and visible(finding["issueAr"]) and
                (finding["proposedTextAr"] is None or visible(finding["proposedTextAr"])),
                "Invalid authored correction")
        impacted = set()
        for key in finding["ids"]:
            if key in knowledge:
                impacted.add(key)
            if key in lesson_by_id:
                impacted.update(row["id"] for row in lesson_by_id[key]["knowledgeUnits"])
        linked = [key for key, row in variants.items() if impacted.intersection(row["knowledgeIds"])
                  or row["lessonId"] in finding["ids"]]
        queue.append({"id": f"CONTENT-007-{number:02}", "kind": "authoredCorrection",
                      **finding, "affectedVariantIds": linked if finding["propagateToLinkedChallenges"] else []})
    for key, outline in planned.items():
        differences = [field for field in ("titleAr", "unitId") if outline[field] != lesson_by_id[key][field]]
        if differences:
            queue.append({"id": f"outline-{key}", "kind": "outlineAlignment", "status": "open_editorial",
                          "ids": [key], "fields": differences})
    queue.extend(citation_alignment)
    missing_rights = [row["id"] for row in extras["memorization"] if not row.get("rights")]
    if missing_rights:
        queue.append({"id": "memorization-rights", "kind": "rights", "status": "open_release_gate",
                      "ids": missing_rights})
    source_groups = {**world_sources, "extras": extras["sources"]}
    require(all(visible(row["locator"]) for group in source_groups.values() for row in group.values()),
            "Missing source locator")
    for scope, sources in source_groups.items():
        pending = [key for key, row in sources.items()
                   if row.get("verificationStatus", row.get("status")) not in {"verified", "source_verified"}]
        if pending:
            queue.append({"id": f"sources-{scope}", "kind": "sourceVerification",
                          "status": "open_release_gate", "sourceScope": scope, "ids": pending})
    return {
        "schema": 1, "channel": "privateDraftReview", "inputDigests": digests,
        "blueprint": blueprint, "corePacks": cores, "extras": extras,
        "enhancement": enhancement, "audit": audit,
        "variantDefinitions": projected, "mixedReviewPrerequisites": mixed, "correctionQueue": queue,
    }
