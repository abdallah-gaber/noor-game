"""Generate the private CONTENT-001–007 review dashboard and data files."""

from collections import defaultdict
from html import escape
import json
import subprocess
import sys

from content_inventory import handoff_inventory, inventory_json
from curriculum_handoff import ROOT
from curriculum_review_patch import load_review_handoff
from generate_dashboard import metrics, table

OUTPUT = ROOT / ".dart_tool/noor-curriculum-review"


def text(value):
    return escape(str(value), quote=True)


def arabic(value):
    return f'<p dir="rtl" lang="ar">{text(value)}</p>'


def link(key, label=None):
    return f'<a href="#{text(key)}">{text(label or key)}</a>'


def links(keys):
    return " · ".join(link(key) for key in keys)


def detail(key, kind, label, body):
    return (f'<details id="{text(key)}"><summary><b>{text(key)}</b> '
            f'<span>{text(kind)}</span> <bdi>{text(label)}</bdi></summary>{body}</details>')


def source_key(scope, source):
    return f"source-{scope}-{source}"


def source_links(scope, refs):
    return " · ".join(link(source_key(scope, ref), ref) for ref in refs)


def render_review(handoff):
    inventory = handoff_inventory(handoff)
    scientific = handoff.get("scientificReview", {})
    conflicts = {row["recordId"]: row for row in scientific.get("semanticConflicts", [])}
    excerpts = {row["id"]: row for row in scientific.get("memorizationReview", [])}
    source_review = {(row["scope"], row["sourceId"]): row for row in scientific.get("sourceLedger", [])}
    source_review.update(((row["scope"], row["sourceId"]), row) for row in scientific.get("sourceAdditions", []))
    unused_sources = {(row["scope"], row["sourceId"]) for row in scientific.get("unusedOriginalSources", [])}
    blueprint = handoff["blueprint"]
    enhancement = handoff["enhancement"]
    extras = handoff["extras"]
    mixed = handoff["mixedReviewPrerequisites"]
    lessons = [row for pack in handoff["corePacks"] for row in pack["lessons"]]
    planned = {row["id"]: row for row in blueprint["lessons"]}
    variants = {row["id"]: row for lesson in lessons for row in lesson["challenges"]}
    variants.update((row["id"], row) for row in enhancement["additions"])
    knowledge_scope = {row["id"]: lesson["worldId"] for lesson in lessons for row in lesson["knowledgeUnits"]}
    ids_by_lesson = {}
    source_usages = defaultdict(set)
    for lesson in lessons:
        for row in lesson["knowledgeUnits"]:
            for ref in row["sourceRefs"]:
                source_usages[lesson["worldId"], ref].add(row["id"])
    for row in (*extras["memorization"], *extras["treasures"]):
        for ref in row["sourceRefs"]:
            source_usages["extras", ref].add(row["id"])
    for row in variants.values():
        ids_by_lesson.setdefault(row["lessonId"], []).append(row["id"])
        by_knowledge = row.get("sourceRefsByKnowledge")
        scoped = ((knowledge_scope[id], ref) for id, refs in by_knowledge.items() for ref in refs) if by_knowledge else (
            (row["worldId"], ref) for ref in row["sourceRefs"]
        )
        for scope_ref in scoped:
            source_usages[scope_ref].add(row["id"])

    path = enhancement["prayerReadiness"]
    path_body = arabic(path["titleAr"]) + "<ol>" + "".join(
        f'<li>{link(id, id + " · " + planned[id]["titleAr"])}</li>' for id in path["lessonIds"]
    ) + "</ol>"
    if followup := scientific.get("followup"):
        path_body += f'<p>{text(followup["prayerReadinessScope"])}</p>'
    path_body += "".join(arabic(activity) for activity in path["optionalOfflineActivitiesAr"])
    path_body += table(("Cross-lesson variant", "Lessons required for future mixed review"),
                       ((id, ", ".join(lessons)) for id, lessons in mixed.items()))

    queue_body = ""
    for row in handoff["correctionQueue"]:
        targets = (source_links(row["sourceScope"], row["ids"])
                   if row["kind"] == "sourceVerification" else links(row["ids"]))
        body = f'<p>Targets · {targets}</p>'
        if "issueAr" in row:
            body += arabic(row["issueAr"])
            proposal = row.get("proposedTextAr")
            body += arabic(proposal) if proposal else "<p>Authoring decision required before replacement text.</p>"
            body += f'<p>Affected variants · {links(row["affectedVariantIds"])}</p>'
        if "fields" in row:
            key = row["ids"][0]
            body += f'<p>Compare CONTENT-001 with the draft lesson · {text(", ".join(row["fields"]))}</p>'
            body += arabic(planned[key]["titleAr"]) + f'<p>Planned unit · {text(planned[key]["unitId"])}</p>'
        if "additionalSourceRefs" in row:
            body += f'<p>Check the additional citations against linked knowledge · {links(row["knowledgeIds"])}</p>'
            body += f'<p>{source_links(row["sourceScope"], row["additionalSourceRefs"])}</p>'
        for field in ("resolutionAr", "noteAr"):
            if row.get(field):
                body += arabic(row[field])
        for url in row.get("evidenceUrls", []):
            body += f'<p dir="ltr">{text(url)}</p>'
        if decision := row.get("followup"):
            body += f'<p>CONTENT-009 · {text(decision["disposition"])}</p>'
            body += arabic(decision["noteAr"])
            for url in decision.get("evidenceUrls", []):
                body += f'<p dir="ltr">{text(url)}</p>'
        for id, conflict in conflicts.items():
            if row["id"] in conflict["reasons"]:
                body += f'<p>Withheld edit · {link(id)} · {text(conflict["reason"])}</p>'
        queue_body += detail(row["id"], row["kind"], row["status"], body)

    lesson_body = ""
    for lesson in lessons:
        key = lesson["id"]
        scope = lesson["worldId"]
        outline = planned[key]
        body = f'<p>{text(scope)} · {text(lesson["unitId"])}</p>'
        body += "<h4>CONTENT-001 planning</h4>" + arabic(outline["titleAr"])
        authored_objectives = {row["id"]: row["textAr"] for row in lesson["objectives"]}
        for row in outline["objectives"]:
            id = row["id"]
            body += f'<div id="{text(id)}">{arabic(id + " · " + row["textAr"])}'
            if authored_objectives[id] != row["textAr"]:
                body += arabic(authored_objectives[id])
            body += "</div>"
        body += arabic(" · ".join(outline["candidateSources"]))
        body += "<h4>Knowledge units</h4>"
        for row in lesson["knowledgeUnits"]:
            body += (f'<div id="{text(row["id"])}"><b>{text(row["id"])}</b> · {text(row["objectiveId"])}'
                     f'{arabic(row["textAr"])}<p>{source_links(scope, row["sourceRefs"])}</p></div>')
        if lesson.get("parentActivityAr"):
            body += "<h4>Authored practical activity</h4>" + arabic(lesson["parentActivityAr"])
        body += "<h4>Question variants</h4>"
        for id in ids_by_lesson[key]:
            row = variants[id]
            definition = handoff["variantDefinitions"][id]
            response = f'<p>Knowledge · {links(row["knowledgeIds"])}</p>'
            if id in mixed:
                response += f'<p>Mixed review · {links(mixed[id])}</p>'
            if "sourceRefsByKnowledge" in row:
                for knowledge, refs in row["sourceRefsByKnowledge"].items():
                    response += f'<p>{link(knowledge)} · {source_links(knowledge_scope[knowledge], refs)}</p>'
            else:
                response += f'<p>Sources · {source_links(scope, row["sourceRefs"])}</p>'
            response += arabic(definition["prompt"]) + arabic(definition["explanation"])
            if "options" in definition:
                response += "".join(
                    arabic(("✓ " if option["id"] == definition["correctOptionId"] else "") + option["label"])
                    for option in definition["options"])
            if "answer" in definition:
                response += arabic(definition["answer"])
            if "pairs" in definition:
                response += "".join(arabic(pair["left"]["label"] + " ↔ " + pair["right"]["label"])
                                    for pair in definition["pairs"])
            if "correctOrder" in definition:
                items = {item["id"]: item["label"] for item in definition["items"]}
                response += '<ol dir="rtl">' + "".join(
                    f'<li>{text(items[item])}</li>' for item in definition["correctOrder"]) + "</ol>"
            body += detail(id, row["type"], row["level"], response)
        lesson_body += detail(key, "Draft lesson", lesson["titleAr"], body)

    extras_body = ""
    for kind in ("memorization", "treasures"):
        for row in extras[kind]:
            body = f'<p>Lesson · {link(row["lessonId"])} · {source_links("extras", row["sourceRefs"])}</p>'
            body += arabic(row["textAr"])
            if kind == "memorization":
                body += arabic(row["explanationAr"]) + arabic(row["recall"]["promptAr"])
                body += "<p>Unscored recall · reuse rights pending.</p>" if not row.get("rights") else "<p>Unscored recall.</p>"
                if review := excerpts.get(row["id"]):
                    body += f'<p>Excerpt review · {text(review["textReview"])}</p>'
                    body += arabic(review["noteAr"])
                    body += f'<p>Rights candidate · {text(review["rightsCandidate"]["evidence"])}</p>'
            extras_body += detail(row["id"], kind, row.get("titleAr", row.get("kind", "")), body)
    for row in extras["deferred"]:
        extras_body += arabic(row["reason"])

    sources_body = ""
    groups = {pack["worldId"]: {row["id"]: row for row in pack["sources"]} for pack in handoff["corePacks"]}
    groups["extras"] = extras["sources"]
    for scope, sources in groups.items():
        sources_body += f'<h3>{text(scope)}</h3>'
        for id, row in sources.items():
            state = row.get("verificationStatus", row.get("status"))
            body = arabic(row.get("title", "")) + arabic(row["locator"])
            if row.get("url"):
                body += f'<p dir="ltr">{text(row["url"])}</p>'
            if (scope, id) in unused_sources:
                body += "<p>Original source retained for provenance. No current record cites it.</p>"
            if review := source_review.get((scope, id)):
                body += f'<p>Review evidence · {text(review.get("status", "new_pending_source"))}</p>'
                for evidence in review["evidence"]:
                    body += arabic(evidence["noteAr"]) + f'<p dir="ltr">{text(evidence["url"])}</p>'
            if usages := source_usages[scope, id]:
                body += f'<p>Linked records · {links(sorted(usages))}</p>'
            sources_body += detail(source_key(scope, id), state, id, body)

    sections = (
        ("prayer-readiness", "Prayer readiness", path_body),
        ("corrections", "Correction queue", queue_body),
        ("lessons", "Lesson and variant review", lesson_body),
        ("extras", "Memorization and treasures", extras_body),
        ("sources", "Source locators", sources_body),
    )
    if scientific:
        backlog = "".join(
            f'<p>{link(row["lessonId"])} · {links(row["variantIds"])}</p>{arabic(row["promptAr"])}'
            for row in scientific["duplicatePromptsBacklog"]
        )
        sections += (("prompt-backlog", "Repeated prompts · Future quality work", backlog),)
    sections_html = "".join(f'<section id="{id}"><h2>{title}</h2>{body}</section>' for id, title, body in sections)
    navigation = " · ".join(link(id, title) for id, title, _ in sections)
    totals = metrics([
        ("Draft lessons", inventory["totals"]["lessons"]),
        ("Draft knowledge units", inventory["totals"]["knowledgeUnits"]),
        ("Draft variants", inventory["totals"]["variants"]),
        ("Open queue items", sum(row["status"] != "applied_draft" for row in handoff["correctionQueue"])),
        ("Final record approvals", sum(stages["finalApproval"] for stages in inventory["stages"].values())),
    ])
    return f"""<!doctype html>
<html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">
<title>Noor · Private curriculum review</title>
<style>
body{{font:16px/1.55 system-ui,sans-serif;background:#f5f6ee;color:#173431;max-width:980px;margin:auto;padding:1.25rem}}
header,section{{background:#fff;border:1px solid #c8d9d0;border-radius:12px;padding:1rem;margin-bottom:1rem}}
a{{color:#185a49;text-underline-offset:.16em}}a:focus-visible,summary:focus-visible{{outline:3px solid #185a49}}
details{{border-top:1px solid #dae6df;padding:.55rem .3rem;scroll-margin:1rem}}summary{{cursor:pointer}}
details>details{{margin-inline-start:1rem}}[dir=rtl]{{text-align:right;font-size:1.08em}}
:target{{outline:2px solid #8a5b20}}.metrics{{display:flex;flex-wrap:wrap;gap:1rem}}
.metric{{background:#e7f1ea;padding:.5rem .75rem;border-radius:8px}}.metric strong{{display:block}}
table{{border-collapse:collapse}}td,th{{text-align:start;border-bottom:1px solid #dae6df;padding:.4rem}}
</style>
<header><h1>Noor · Private curriculum review</h1>
<p>{text("CONTENT-001 through " + scientific.get("package", "CONTENT-007"))} · Structurally checked private drafts for adult review. Source verification, rights and final record approval are pending.</p>
{totals}<p>CONTENT-001 plans {inventory["handoff"]["plannedLessons"]} lessons and {inventory["handoff"]["plannedObjectives"]} objectives.</p>
<nav aria-label="Review sections">{navigation}</nav>
<form id="jump"><label for="record-id">Record ID</label> <input id="record-id" required> <button>Open</button>
<output id="jump-status" aria-live="polite"></output></form>
<p><a href="correction-queue.json">Correction queue JSON</a> · <a href="review-bundle.json">Review bundle JSON</a></p>
</header>{sections_html}
<script>
function openTarget() {{
  const target = document.getElementById(decodeURIComponent(location.hash.slice(1)));
  if (!target) return;
  for (let node = target; node; node = node.parentElement) {{
    if (node.tagName === 'DETAILS') node.open = true;
  }}
  target.scrollIntoView({{block:'nearest'}});
}}
document.getElementById('jump').addEventListener('submit', event => {{
  event.preventDefault();
  const id = document.getElementById('record-id').value.trim();
  const status = document.getElementById('jump-status');
  if (!document.getElementById(id)) {{
    status.value = 'Record ID was not found.';
    return;
  }}
  status.value = '';
  location.hash = encodeURIComponent(id);
  openTarget();
}});
addEventListener('hashchange', openTarget); openTarget();
</script>
</html>
"""


def main():
    handoff, corrected = load_review_handoff()
    html = render_review(handoff)
    OUTPUT.mkdir(parents=True, exist_ok=True)
    for name, data in corrected.items():
        target = OUTPUT / "corrected-drafts" / name
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_bytes(data)
    for name, content in (("review-bundle.json", handoff), ("correction-queue.json", handoff["correctionQueue"])):
        (OUTPUT / name).write_text(json.dumps(content, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    (OUTPUT / "index.html").write_text(html, encoding="utf-8")
    inventory = ROOT / "docs/curriculum/public-inventory.json"
    inventory.write_text(inventory_json(handoff_inventory(handoff)), encoding="utf-8")
    subprocess.run([sys.executable, str(ROOT / "scripts/generate_dashboard.py")], check=True)
    print(f"Private review dashboard: {OUTPUT.relative_to(ROOT)}/index.html")


if __name__ == "__main__":
    main()
