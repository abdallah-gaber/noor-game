"""Build private v1 starter candidates from CONTENT-010 evidence."""

from collections import Counter, defaultdict
import json
import re

from curriculum_handoff import CURRICULUM, require, validate_handoff
from curriculum_review_patch import (
    authoring_records, digest, encode_authoring, json_bytes, load_content_009,
    sources_by_id,
)

PACKAGE = "drafts/noor-content-010/candidate-review.json"
OUTPUT = ".dart_tool/noor-starter-candidate"


def prerequisites(lesson):
    return list(dict.fromkeys([*lesson.get("prerequisiteIds", []),
                               *([lesson["prerequisiteId"]] if lesson.get("prerequisiteId") else [])]))


def check_closure(selected, lessons):
    missing = {id: [dependency for dependency in prerequisites(lessons[id]) if dependency not in selected]
               for id in selected}
    missing = {id: dependencies for id, dependencies in missing.items() if dependencies}
    require(not missing, f"Missing starter prerequisites: {missing}")


def source_id(world, id):
    return f"source.{world}.{re.sub(r'[^A-Za-z0-9_.-]', lambda m: f'-{ord(m[0]):x}-', id)}"


def record(kind, id, **data):
    return {"kind": kind, "id": id, "reviewStatus": "draft", **data}


def normalize(handoff, selected, evidence, groups):
    packs = []
    for world in handoff["corePacks"]:
        scope = world["worldId"]
        lessons = [lesson for lesson in world["lessons"] if lesson["id"] in selected]
        if not lessons:
            continue
        records = []
        ids = {}

        def citations(refs):
            for id in refs:
                if id not in ids:
                    original = groups[scope, id]
                    alias = source_id(scope, id)
                    require(alias not in ids.values(), f"Source alias collision in {scope}")
                    ids[id] = alias
                    category = {"القرآن الكريم": "quran", "صحيح البخاري": "hadith",
                                "صحيح مسلم": "hadith"}.get(original["title"])
                    require(category is not None, f"Source category needs review for {scope}/{id}")
                    source = record("source", alias, title=original["title"], locator=original["locator"],
                                    category=category, authoringSourceId=id)
                    if category == "hadith":
                        source["authenticity"] = "pendingClaimLevelReview"
                    if original.get("url"):
                        source["url"] = original["url"]
                    records.append(source)
            return [ids[id] for id in refs]

        units = {}
        for lesson in lessons:
            units.setdefault(lesson["unitId"], []).append(lesson["titleAr"])
        records.extend(record("unit", id, title=" · ".join(titles), worldId=scope)
                       for id, titles in units.items())
        for lesson in lessons:
            variants = [row["record"] for row in evidence.values()
                        if row["lessonId"] == lesson["id"] and row["kind"] == "variant"]
            knowledge = lesson["knowledgeUnits"]
            lesson_knowledge = [row["id"] for row in knowledge]
            objective_titles = {row["id"]: row["textAr"] for row in lesson["objectives"]}
            lesson_record = record(
                "lesson", lesson["id"], title=lesson["titleAr"], unitId=lesson["unitId"], revision="1",
                prerequisiteIds=prerequisites(lesson), knowledgeIds=lesson_knowledge,
                variantIds=[row["id"] for row in variants],
            )
            if lesson.get("parentActivityAr"):
                lesson_record["adultActivity"] = lesson["parentActivityAr"]
            records.append(lesson_record)
            for row in knowledge:
                sources = citations(row["sourceRefs"])
                records.append(record("knowledge", row["id"], title=objective_titles[row["objectiveId"]],
                                      text=row["textAr"], sourceRefs=sources, revision="1"))
            for row in variants:
                id = row["id"]
                require(set(row["knowledgeIds"]) <= set(lesson_knowledge),
                        f"Cross-lesson variant {id} requires its full teaching dependencies")
                sources = citations(row["sourceRefs"])
                definition = {k: v for k, v in handoff["variantDefinitions"][id].items()
                              if k not in {"schema", "id", "knowledgeIds", "sourceRefs", "sourceRefsByKnowledge"}}
                variant = record("variant", id, revision="1", knowledgeIds=row["knowledgeIds"],
                                 sourceRefs=sources, difficulty="recall" if row["level"] == "understanding" else row["level"],
                                 definition=definition)
                if row.get("sourceRefsByKnowledge"):
                    variant["sourceRefsByKnowledge"] = {
                        knowledge_id: citations(refs) for knowledge_id, refs in row["sourceRefsByKnowledge"].items()
                    }
                if definition["type"] == "trueFalse":
                    options = {"true" if item["label"] == "صحيح" else "false": item["id"]
                               for item in definition.pop("options")}
                    variant["authoringBooleanOptionIds"] = options
                    definition["correctOptionId"] = next(
                        fixed for fixed, authored in options.items() if authored == definition["correctOptionId"]
                    )
                records.append(variant)
        packs.append({"schema": 1, "packId": f"starter.{scope}", "channel": "draft", "version": "0.1.0",
                      "records": records})
    return packs


def build_candidate(baseline, encoded, manifest):
    require(manifest["package"] == "CONTENT-010" and manifest["status"] == "candidate_only_not_approved",
            "Unsupported starter evidence manifest")
    require(manifest["baselineBundleSha256"] == digest(json_bytes(baseline))
            and manifest["inputDigests"] == baseline["inputDigests"]
            and baseline["inputDigests"] == {name: digest(data) for name, data in encoded.items()},
            "CONTENT-010 baseline bundle or input digest differs")
    pending = [row for row in baseline["correctionQueue"] if row["status"] != "applied_draft"]
    require(pending == manifest["openQueue"], "CONTENT-010 changed open review items")
    documents = {name: json.loads(payload) for name, payload in encoded.items()}
    rows, scoped = authoring_records(documents)
    records = {(scope, id): row for (scope, kind, id), row in rows.items()
               if kind in {"knowledge", "variant", "enhancementVariant"}}
    lessons = {id: row for (_, kind, id), row in rows.items() if kind == "lesson"}
    selected = set(manifest["selectedLessonIds"])
    require(len(selected) == len(manifest["selectedLessonIds"]) == 6
            and selected <= lessons.keys()
            and sorted(lessons.keys() - selected) == sorted(manifest["deferredLessonIds"]),
            "Starter selection or deferred lessons differ")
    check_closure(selected, lessons)
    require(manifest["deferredExtras"] == {
        "memorizationIds": [row["id"] for row in baseline["extras"]["memorization"]],
        "treasureIds": [row["id"] for row in baseline["extras"]["treasures"]],
    }, "Deferred extras differ")
    evidence = {}
    for row in manifest["reviewedRecords"]:
        id = row["id"]
        old = records.get((row["worldId"], id))
        require(old is not None and id not in evidence and row["lessonId"] in selected
                and row["reviewDisposition"] == "claim_review_candidate"
                and row["baselineRecordSha256"] == digest(json_bytes(old, canonical=True)),
                f"Starter evidence baseline differs for {id}")
        evidence[id] = row
    edits = set()
    for edit in manifest["guardedEdits"]:
        key = (edit["worldId"], edit["id"])
        require(key not in edits and key in records and edit["id"] in evidence
                and edit["field"] == "sourceRefs" and records[key]["sourceRefs"] == edit["before"],
                f"CONTENT-010 before-value conflict for {key}")
        edits.add(key)
    existing = sources_by_id(scoped)
    added = set()
    for addition in manifest["sourceAdditions"]:
        scope, source = addition["worldId"], addition["record"]
        key = (scope, source["id"])
        require(scope in scoped and isinstance(scoped[scope], list) and key not in existing and key not in added
                and set(source) == {"id", "title", "locator", "url", "verificationStatus"}
                and source["verificationStatus"] == "locator_review_pending", f"Invalid pending source {key}")
        added.add(key)
    for edit in manifest["guardedEdits"]:
        records[edit["worldId"], edit["id"]]["sourceRefs"] = edit["after"]
    for addition in manifest["sourceAdditions"]:
        scoped[addition["worldId"]].append(addition["record"])
    sources = sources_by_id(scoped)
    for row in evidence.values():
        current = records[row["worldId"], row["id"]]
        require(current == row["record"] and row["candidateRecordSha256"] == digest(json_bytes(current, canonical=True))
                and current["sourceRefs"] == row["sourceRefs"]
                and set(row["sourceRefs"]) == {item["id"] for item in row["evidence"]},
                f"Starter evidence differs after patch for {row['id']}")
    expected = {id for (_, kind, id), row in rows.items()
                if (kind == "knowledge" and any(id == k["id"] for lesson in selected for k in lessons[lesson]["knowledgeUnits"]))
                or (kind in {"variant", "enhancementVariant"} and row["lessonId"] in selected)}
    require(evidence.keys() == expected, "Starter evidence does not cover the selected lessons")
    require(dict(Counter(row["kind"] for row in evidence.values())) == manifest["counts"]
            and dict(Counter(row["record"]["type"] for row in evidence.values() if row["kind"] == "variant"))
            == manifest["mechanics"], "Starter evidence counts differ")

    output = encode_authoring(documents)
    corrected = validate_handoff(documents, {name: digest(payload) for name, payload in output.items()})
    # Keep the scientific queue verbatim, including statuses that predate this selection.
    corrected["correctionQueue"] = baseline["correctionQueue"]
    corrected["scientificReview"] = baseline["scientificReview"]
    packs = normalize(corrected, selected, evidence, sources)
    source_evidence = defaultdict(list)
    for row in evidence.values():
        for item in row["evidence"]:
            source_evidence[source_id(row["worldId"], item["id"])].append({
                "claimRecordId": row["id"], **item,
            })
    requests = []
    for pack in packs:
        for entry in pack["records"]:
            def v1_digest(review_status):
                return digest(json_bytes({"packId": pack["packId"], "record": {
                    **entry, "reviewStatus": review_status,
                }}, canonical=True))
            evidence_row = evidence.get(entry["id"])
            requests.append({
                "packId": pack["packId"], "packVersion": pack["version"], "recordId": entry["id"],
                "kind": entry["kind"], "candidateDigest": v1_digest("draft"),
                "conditionalApprovalDigest": v1_digest("sourceVerified"),
                "approvalState": "pending_human_review",
                "evidence": source_evidence.get(entry["id"], []) if evidence_row is None else evidence_row["evidence"],
            })
    approval = {
        "schema": 1, "kind": "candidate_approval_request", "package": "CONTENT-010",
        "baselineBundleSha256": manifest["baselineBundleSha256"],
        "candidatePacks": [{"packId": p["packId"], "version": p["version"],
                            "candidateDigest": digest(json_bytes(p, canonical=True))} for p in packs],
        "recordRequests": requests, "openQueue": pending,
        "digestScope": (
            "candidateDigest hashes the exact draft record. conditionalApprovalDigest applies only "
            "if humans verify the exact record and the sole record change is reviewStatus. "
            "Any other edit requires a new review digest."
        ),
        "lessonIds": manifest["selectedLessonIds"], "deferredLessonIds": manifest["deferredLessonIds"],
        "deferredExtras": manifest["deferredExtras"],
    }
    corrected["starterCandidate"] = {
        "lessons": len(selected), **manifest["counts"], "packs": len(packs),
        "recordRequests": len(requests), "deferredLessons": len(manifest["deferredLessonIds"]),
        "openQueue": len(pending), "scopedSourceAdditions": len(added),
    }
    return corrected, output, packs, approval


def load_starter_candidate(curriculum=CURRICULUM):
    baseline, encoded = load_content_009(curriculum)
    return build_candidate(baseline, encoded, json.loads((curriculum / PACKAGE).read_bytes()))


def main():
    from curriculum_handoff import ROOT
    _, _, packs, approval = load_starter_candidate()
    output = ROOT / OUTPUT
    output.mkdir(parents=True, exist_ok=True)
    for pack in packs:
        (output / (pack["packId"] + ".json")).write_bytes(json_bytes(pack))
    (output / "approval-request.json").write_bytes(json_bytes(approval))
    print(f"Private starter candidate: {len(packs)} packs, {len(approval['recordRequests'])} pending record requests")


if __name__ == "__main__":
    main()
