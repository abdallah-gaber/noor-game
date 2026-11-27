"""Apply CONTENT-008 to private authoring copies without promoting draft records."""

from collections import Counter, defaultdict
from copy import deepcopy
import hashlib
import json

from curriculum_handoff import (
    AUDIT, BLUEPRINT, CORE, CURRICULUM, ENHANCEMENT, EXTRAS, INPUT_FILES,
    load_handoff, read_json, require, validate_handoff,
)

PATCH_DIR = "drafts/noor-content-008"
FOLLOWUP_DIR = "drafts/noor-content-009"
PATCH_FILES = ("corrections.json", "source-ledger.json", "memorization-review.json",
               "summary.json", "duplicate-prompts.json")
ALLOWED_FIELDS = {
    "objective": {"textAr"},
    "knowledge": {"textAr", "sourceRefs"},
    "variant": {"promptAr", "answerAr", "explanationAr", "sourceRefs", "knowledgeIds", "options"},
    "enhancementVariant": {"promptAr", "explanationAr", "sourceRefs", "sourceRefsByKnowledge", "items"},
    "memorization": {"textAr", "explanationAr", "sourceRefs"},
    "treasure": {"textAr", "sourceRefs"},
    "blueprint": {"titleAr", "unitId", "objectives"},
}
# The proposed flashcard switches the fact being tested. Keep its whole old record together.
SEMANTIC_CONFLICTS = {"S01.Q03": "The proposal changes recall from tribe to genealogy."}


def json_bytes(document, *, canonical=False):
    if canonical:
        return json.dumps(document, ensure_ascii=False, sort_keys=True, separators=(",", ":")).encode()
    return (json.dumps(document, indent=2, ensure_ascii=False) + "\n").encode()


def digest(data):
    return hashlib.sha256(data).hexdigest()


def authoring_records(documents):
    records = {}
    sources = {}

    def add(scope, kind, rows):
        for row in rows:
            key = (scope, kind, row["id"])
            require(key not in records, f"Duplicate record {key}")
            records[key] = row

    for name in CORE:
        pack = documents[f"drafts/{name}"]
        scope = pack["worldId"]
        sources[scope] = pack["sources"]
        add(scope, "lesson", pack["lessons"])
        for lesson in pack["lessons"]:
            for kind, field in (("objective", "objectives"), ("knowledge", "knowledgeUnits"), ("variant", "challenges")):
                add(scope, kind, lesson[field])
    extras = documents[f"drafts/{EXTRAS}"]
    sources["extras"] = extras["sources"]
    for kind, field in (("memorization", "memorization"), ("treasure", "treasures")):
        add("extras", kind, extras[field])
    for row in documents[f"drafts/{ENHANCEMENT}"]["additions"]:
        add(row["worldId"], "enhancementVariant", [row])
    add("planning", "blueprint", documents[BLUEPRINT]["lessons"])
    return records, sources


def sources_by_id(groups):
    return {
        (scope, id): row
        for scope, sources in groups.items()
        for id, row in (sources.items() if isinstance(sources, dict)
                        else ((row["id"], row) for row in sources))
    }


def guarded_operations(patch, records):
    operations = [
        ((row["scope"], row["kind"], row["recordId"]), row["fields"], row["reasons"])
        for row in patch["recordOperations"]
    ]
    operations += [
        (("planning", "blueprint", row["id"]), row["fields"], [row["reason"]])
        for row in patch["blueprintOperations"]
    ]
    keys = set()
    for key, fields, _ in operations:
        scope, kind, id = key
        require(key not in keys and key in records, f"Duplicate or missing correction target {scope}/{kind}/{id}")
        keys.add(key)
        require(fields and fields.keys() <= ALLOWED_FIELDS.get(kind, set()), f"Unsupported correction field in {id}")
        for field, delta in fields.items():
            row = records[key]
            require(set(delta) == {"before", "after"} and field in row
                    and json_bytes(row[field], canonical=True) == json_bytes(delta["before"], canonical=True),
                    f"Before-value conflict at {scope}/{kind}/{id}/{field}")
            if field in {"options", "items", "objectives"}:
                require([r["id"] for r in delta["before"]] == [r["id"] for r in delta["after"]],
                        f"Nested stable IDs changed in {id}/{field}")
    return operations


def source_evidence(ledger, groups, record_ids):
    original = sources_by_id(groups)
    statuses = {}
    for row in ledger:
        key = (row["scope"], row["sourceId"])
        require(key in original and key not in statuses and row["originalSource"] == original[key]
                and row["finalApproval"] is False and row["allLinkedClaimsVerified"] is False
                and set(row["affectedRecordIds"]) <= record_ids
                and all(evidence["finalApproval"] is False for evidence in row["evidence"]),
                f"Invalid source ledger entry {key}")
        statuses[key] = row
    require(statuses.keys() == original.keys(), "The source ledger must cover every original scoped record")
    return statuses


def rebuild_queue(baseline, corrected, patch, conflicts, record_ids):
    original = {row["id"]: row for row in baseline}
    derived = {row["id"]: row for row in corrected}
    queue = []
    applied = {"patch_ready", "editorial_ready"}
    conflict_reasons = {reason for row in conflicts for reason in row["reasons"]}
    supplied = set()
    for row in patch["queueDispositions"]:
        id = row["id"]
        prior = original.get(id)
        require(prior is not None and id not in supplied and all(row.get(k) == v for k, v in prior.items()),
                f"Baseline queue disposition differs for {id}")
        supplied.add(id)
        disposition = row["disposition"]
        status = {
            "patch_ready_edition_pending": "applied_edition_pending",
            "rights_candidate_open": "rights_candidate_open",
            "partial_open": "partial_open",
        }.get(disposition, "applied_draft" if disposition in applied else None)
        require(status is not None, f"Unknown disposition for {id}")
        updated_ids = derived.get(id, prior)["ids"]
        queue.append({**row, "ids": updated_ids, "baselineStatus": row["status"],
                      "status": "conflict_open" if id in conflict_reasons else status})
    require(supplied == original.keys(), "Patch must dispose every baseline queue item")
    for row in patch["additionalFindings"]:
        require(row["id"] not in supplied and set(row["ids"]) <= record_ids,
                f"Invalid additional finding {row['id']}")
        supplied.add(row["id"])
        queue.append({**row, "kind": "newFinding", "disposition": row["status"],
                      "status": "applied_draft" if row["status"] in applied else row["status"]})
    queue.extend(row for key, row in derived.items() if key not in supplied)
    return queue


def duplicate_groups(records):
    groups = defaultdict(list)
    for key, row in records.items():
        if key[1] in {"variant", "enhancementVariant"}:
            groups[row["lessonId"], row["promptAr"]].append(row["id"])
    return [
        {"lessonId": lesson, "promptAr": prompt, "variantIds": ids}
        for (lesson, prompt), ids in groups.items() if len(ids) > 1
    ]


def encode_authoring(documents):
    encoded = {name: json_bytes(document) for name, document in documents.items()}
    audit_path = f"drafts/{AUDIT}"
    audit = documents[audit_path]
    audit["inputSha256"] = {name: digest(encoded[f"drafts/{name}"]) for name in audit["inputSha256"]}
    encoded[audit_path] = json_bytes(audit)
    return encoded


def load_content_008(curriculum=CURRICULUM):
    baseline = load_handoff(curriculum)
    package = curriculum / PATCH_DIR
    if not package.is_dir():
        return baseline, {}
    patch, ledger, memorization, summary, duplicates = (read_json(package / name) for name in PATCH_FILES)
    require(patch["schemaVersion"] == 1 and patch["contentVersion"] == "CONTENT-008"
            and patch["channel"] == "draft_review_patch", "Unsupported review patch")
    require(patch["summary"] == summary and summary["baselineBundleSha256"] == digest(json_bytes(baseline))
            and patch["baselineInputDigests"] == baseline["inputDigests"], "CONTENT-008 baseline digest does not match")
    policy = patch["approvalPolicy"]
    require(all(policy[field] is False for field in ("finalApproval", "sourceVerifiedStatusMayBeSetAutomatically",
                                                     "productionIntegrationAllowed"))
            and summary["finalApprovals"] == summary["productionIntegrated"] == 0,
            "Draft patch cannot approve or activate records")
    payloads = {name: (curriculum / name).read_bytes() for name in INPUT_FILES}
    require({name: digest(data) for name, data in payloads.items()} == baseline["inputDigests"],
            "Baseline inputs changed after review digest validation")
    documents = {name: json.loads(data) for name, data in payloads.items()}
    records, groups = authoring_records(documents)
    record_ids = {key[-1] for key in records}
    baseline_keys = set(records)
    supplied_duplicates = {
        (row["lessonId"], row["promptAr"]): frozenset(row["variantIds"]) for row in duplicates
    }
    require(len(supplied_duplicates) == len(duplicates) and supplied_duplicates == {
        (row["lessonId"], row["promptAr"]): frozenset(row["variantIds"]) for row in duplicate_groups(records)
    }, "CONTENT-008 duplicate-prompt evidence differs from the baseline")
    counts = Counter(kind for _, kind, _ in records if kind != "blueprint")
    require(counts == summary["counts"] and len(duplicates) == summary["duplicatePromptGroups"]
            and len(ledger) == summary["sourceLedgerCount"] and len(memorization) == summary["memorizationExcerptsReviewed"]
            and len(patch["recordOperations"]) == summary["changedRecords"]
            and len(patch["sourceAdditions"]) == summary["addedSources"]
            and len(patch["additionalFindings"]) == summary["newFindings"], "CONTENT-008 report counts differ")
    require(Counter(row["status"] for row in ledger) == summary["sourceLedgerStatuses"]
            and Counter(row["disposition"] for row in patch["queueDispositions"]) == summary["dispositions"],
            "CONTENT-008 report dispositions differ")
    evidence = source_evidence(ledger, groups, record_ids)
    operations = guarded_operations(patch, records)
    original_sources = sources_by_id(groups)
    new_sources = {}
    for item in patch["sourceAdditions"]:
        scope, id, row = item["scope"], item["sourceId"], item["record"]
        key = (scope, id)
        require(scope in groups and key not in original_sources and key not in new_sources
                and row.get("id", id) == id
                and row.get("verificationStatus", row.get("status")) == "locator_review_pending"
                and all(proof["finalApproval"] is False for proof in item["evidence"]),
                f"Invalid or duplicate source addition {scope}/{id}")
        new_sources[key] = item
    excerpts = {key[-1]: row for key, row in records.items() if key[1] == "memorization"}
    require(len(memorization) == len({row["id"] for row in memorization}) == len(excerpts),
            "Memorization review must cover every excerpt")
    for row in memorization:
        require(row["id"] in excerpts and excerpts[row["id"]]["textAr"] == row["originalTextAr"]
                and row["humanApproval"] is False, f"Invalid excerpt review {row['id']}")

    grading_fields = ("id", "worldId", "lessonId", "objectiveId", "type", "level",
                      "correctOptionIds", "correctOrderIds", "reviewStatus", "approvalHash", "reviewer", "reviewedAt")
    conflicts = []
    changed_digests = []
    for key, fields, reasons in operations:
        scope, kind, id = key
        if id in SEMANTIC_CONFLICTS:
            conflicts.append({"recordId": id, "reasons": reasons, "reason": SEMANTIC_CONFLICTS[id]})
            continue
        row = records[key]
        before = deepcopy(row)
        for field, delta in fields.items():
            row[field] = delta["after"]
        require(all(before.get(field) == row.get(field) for field in grading_fields), f"Grading or approval drift in {id}")
        changed_digests.append({"scope": scope, "kind": kind, "recordId": id,
                                "beforeSha256": digest(json_bytes(before, canonical=True)),
                                "afterSha256": digest(json_bytes(row, canonical=True))})
    require(all(excerpts[row["id"]]["textAr"] == row["proposedTextAr"] and
                set(row["sourceRefs"]) == set(excerpts[row["id"]]["sourceRefs"]) for row in memorization),
            "Corrected excerpts disagree with the supplied review")
    for (scope, id), item in new_sources.items():
        if isinstance(groups[scope], dict):
            groups[scope][id] = item["record"]
        else:
            groups[scope].append(item["record"])

    # Rebuild the technical digest manifest in the corrected copy. The original
    # audit remains available as evidence for the patch's preconditions.
    encoded = encode_authoring(documents)
    corrected = validate_handoff(documents, {name: digest(data) for name, data in encoded.items()})
    corrected["correctionQueue"] = rebuild_queue(baseline["correctionQueue"], corrected["correctionQueue"],
                                                patch, conflicts, record_ids)
    require(authoring_records(documents)[0].keys() == baseline_keys and
            set(corrected["variantDefinitions"]) == set(baseline["variantDefinitions"]),
            "Patch changed stable IDs")
    knowledge_scopes = {key[-1]: key[0] for key in records if key[1] == "knowledge"}
    used = set()
    for (scope, _, _), row in records.items():
        if row.get("sourceRefsByKnowledge"):
            used.update((knowledge_scopes[id], ref)
                        for id, refs in row["sourceRefsByKnowledge"].items() for ref in refs)
        else:
            used.update((scope, ref) for ref in row.get("sourceRefs", []))
    unused = sorted(original_sources.keys() - used)
    corrected["scientificReview"] = {
        "package": patch["contentVersion"], "baselineBundleSha256": summary["baselineBundleSha256"],
        "patchDigests": {name: digest((package / name).read_bytes()) for name in PATCH_FILES},
        "scopeLimit": summary["scopeLimit"], "sourceLedger": list(evidence.values()),
        "sourceAdditions": list(new_sources.values()), "memorizationReview": memorization,
        "baselineDuplicatePrompts": duplicates, "duplicatePromptsBacklog": duplicate_groups(records),
        "changedRecordDigests": changed_digests,
        "semanticConflicts": conflicts,
        "unusedOriginalSources": [{"scope": scope, "sourceId": id} for scope, id in unused],
    }
    return corrected, encoded


def apply_content_009(baseline, encoded, patch, ledger):
    require(patch["package"] == "CONTENT-009" and patch["status"] == "draft_proposal_only",
            "Unsupported CONTENT-009 patch")
    require(patch["baselineBundleSha256"] == digest(json_bytes(baseline)), "CONTENT-009 baseline SHA-256 mismatch")
    previous = baseline["scientificReview"]
    require(ledger == previous["sourceLedger"], "CONTENT-009 carried-forward source ledger differs")
    documents = {name: json.loads(payload) for name, payload in encoded.items()}
    records, groups = authoring_records(documents)
    by_id = {id: key for key in records for id in [key[-1]] if key[1] != "blueprint"}
    require(len(by_id) == sum(key[1] != "blueprint" for key in records), "Ambiguous authoring IDs")
    operations = []
    for edit in patch["recordEdits"]:
        key = by_id.get(edit["id"])
        require(key is not None and edit.get("scope", key[0]) == key[0], f"Missing or incorrect scope for {edit['id']}")
        require(edit["id"] != "S01.Q03", "The flashcard must retain its current objective")
        operations.append({"scope": key[0], "kind": key[1], "recordId": key[2], "fields": edit["fields"], "reasons": []})
    edits = guarded_operations({"recordOperations": operations, "blueprintOperations": []}, records)
    objectives = {
        row["id"]: (lesson, row)
        for lesson in documents[BLUEPRINT]["lessons"] for row in lesson["objectives"]
    }
    for (_, kind, id), fields, _ in edits:
        if kind == "objective":
            require(objectives[id][1]["textAr"] == fields["textAr"]["before"],
                    f"Blueprint objective before-value differs for {id}")

    original_sources = sources_by_id(groups)
    additions = {}
    for addition in patch["sourceAdditions"]:
        scope = addition["scope"]
        id = addition["id"]
        fields = {"id", "locator", "url", "status"} if scope == "extras" else {
            "id", "title", "locator", "url", "verificationStatus",
        }
        key = (scope, id)
        require(scope in groups and key not in original_sources and key not in additions
                and set(addition) == fields | {"scope"}
                and addition.get("verificationStatus", addition.get("status")) == "locator_review_pending",
                f"Invalid CONTENT-009 pending source {scope}/{id}")
        new_source = {k: v for k, v in addition.items() if k != "scope"}
        additions[key] = {"scope": scope, "sourceId": id, "record": new_source, "evidence": []}

    changed = []
    blueprint_before = {}
    for key, fields, _ in edits:
        scope, kind, id = key
        row = records[key]
        before = digest(json_bytes(row, canonical=True))
        for field, delta in fields.items():
            row[field] = delta["after"]
        if kind == "objective":
            lesson, objective = objectives[id]
            blueprint_before.setdefault(lesson["id"], digest(json_bytes(lesson, canonical=True)))
            objective["textAr"] = row["textAr"]
        if "sourceRefsByKnowledge" in fields:
            expected = {ref for links in row["sourceRefsByKnowledge"].values() for ref in links}
            row["sourceRefs"] = list(dict.fromkeys([
                *(ref for ref in row["sourceRefs"] if ref in expected),
                *(ref for links in row["sourceRefsByKnowledge"].values() for ref in links),
            ]))
        changed.append({"scope": scope, "kind": kind, "recordId": id, "beforeSha256": before,
                        "afterSha256": digest(json_bytes(row, canonical=True))})
    for id, before in blueprint_before.items():
        changed.append({"scope": "planning", "kind": "blueprint", "recordId": id, "beforeSha256": before,
                        "afterSha256": digest(json_bytes(records["planning", "blueprint", id], canonical=True))})
    for (scope, id), item in additions.items():
        row = item["record"]
        if isinstance(groups[scope], dict):
            groups[scope][id] = {key: value for key, value in row.items() if key != "id"}
        else:
            groups[scope].append(row)

    encoded = encode_authoring(documents)
    corrected = validate_handoff(documents, {name: digest(data) for name, data in encoded.items()})
    require(corrected["variantDefinitions"].keys() == baseline["variantDefinitions"].keys(),
            "CONTENT-009 changed variant IDs")
    require(corrected["variantDefinitions"]["S01.Q03"] == baseline["variantDefinitions"]["S01.Q03"],
            "CONTENT-009 changed the retained flashcard")
    previous_queue = {row["id"]: row for row in baseline["correctionQueue"]}
    followup = {row["id"]: row for row in patch["queueDispositions"]}
    require(len(followup) == len(patch["queueDispositions"]) and followup.keys() == {
        id for id, row in previous_queue.items() if row["status"] != "applied_draft"
    }, "CONTENT-009 must cover each open queue item")
    refreshed = {row["id"]: row for row in corrected["correctionQueue"]}
    for id, row in previous_queue.items():
        if id not in followup:
            continue
        decision = followup[id]
        status = {
            "retain_existing": "retained_edition_pending",
            "patch_ready": "applied_claim_pending" if id == "NEW-12" else "applied_draft",
            "open_release_gate": "open_release_gate",
        }.get(decision["disposition"])
        require(status is not None and (id == "CONTENT-007-10") == (decision["disposition"] == "retain_existing"),
                f"Invalid CONTENT-009 disposition for {id}")
        previous_queue[id] = {**row, "ids": refreshed.get(id, row)["ids"],
                              "status": status, "followup": decision}
    corrected["correctionQueue"] = [*previous_queue.values(),
                                   *(row for id, row in refreshed.items() if id not in previous_queue)]
    corrected["scientificReview"] = {
        **previous,
        "package": patch["package"],
        "sourceAdditions": [*previous["sourceAdditions"], *additions.values()],
        "duplicatePromptsBacklog": duplicate_groups(records),
        "semanticConflicts": [],
        "semanticResolutions": [{"recordId": "S01.Q03", "queueId": "CONTENT-007-10",
                                 "status": "retained_existing_objective"}],
        "followup": {"baselineBundleSha256": patch["baselineBundleSha256"],
                     "changedRecordDigests": changed, "addedPendingSources": len(additions),
                     "prayerReadinessScope": "Introductory preparation; complete practical prayer instruction remains pending."},
    }
    # Recompute the provenance list against the current graph, keeping every original source.
    knowledge_scopes = {id: scope for scope, kind, id in records if kind == "knowledge"}
    used = {
        (knowledge_scopes[knowledge], ref)
        for row in records.values() for knowledge, refs in row.get("sourceRefsByKnowledge", {}).items()
        for ref in refs
    } | {
        (scope, ref) for (scope, _, _), row in records.items() if not row.get("sourceRefsByKnowledge")
        for ref in row.get("sourceRefs", [])
    }
    corrected["scientificReview"]["unusedOriginalSources"] = [
        {"scope": row["scope"], "sourceId": row["sourceId"]} for row in ledger
        if (row["scope"], row["sourceId"]) not in used
    ]
    return corrected, encoded


def load_review_handoff(curriculum=CURRICULUM):
    baseline, encoded = load_content_008(curriculum)
    package = curriculum / FOLLOWUP_DIR
    if not package.is_dir():
        return baseline, encoded
    corrections = (package / "corrections.json").read_bytes()
    ledger = (package / "source-ledger.json").read_bytes()
    corrected, encoded = apply_content_009(baseline, encoded, json.loads(corrections), json.loads(ledger))
    corrected["scientificReview"]["patchDigests"].update({
        "content-009/corrections.json": digest(corrections),
        "content-009/source-ledger.json": digest(ledger),
    })
    return corrected, encoded
