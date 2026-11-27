"""Generate the standalone Noor dashboard and its curated Pages bundle."""
import argparse
from collections import defaultdict
from html import escape
from html.parser import HTMLParser
import json
from pathlib import Path
import shutil
import subprocess
from urllib.parse import quote, unquote, urlsplit

ROOT = Path(__file__).resolve().parents[1]
GITHUB = "https://github.com/abdallah-gaber/noor-game"
STATUSES = ("todo", "doing", "blocked", "review", "done", "deferred")
STAGE_LABELS = {
    "draft": "Draft",
    "sourceVerified": "Source verified",
    "ownerReviewed": "Record reviewed",
    "finalApproval": "Final hash approval",
    "validated": "Structurally checked",
    "integrated": "Integrated",
    "releaseVerified": "Release verified",
}
KINDS = {
    "lessons": "Lessons", "objectives": "Objectives", "knowledgeUnits": "Knowledge units",
    "variants": "Question variants", "mnemonics": "Memorization aids", "treasures": "Knowledge treasures",
}
VIEWS = (
    ("engineering", "Engineering"), ("curriculum", "Curriculum roadmap"),
    ("coverage", "Coverage"), ("questions", "Question mix"),
    ("approval", "Source and approval"), ("extras", "Aids and treasures"),
    ("releases", "Content releases"), ("qa", "QA evidence"),
)
# Publish individually reviewed evidence. Future assets require an explicit addition.
PUBLIC_FILES = {
    "docs/product.md", "docs/architecture.md", "docs/curriculum/README.md",
    "docs/curriculum/roadmap.md", "docs/curriculum/season-one.json",
    "docs/curriculum/releases.json", "docs/mission-control/deployment.md",
    "docs/curriculum/pack-schema.md", "docs/curriculum/starter-release.md",
    "docs/curriculum/starter-release.json",
    "docs/curriculum/examples/geometry.pack.json",
    "docs/curriculum/examples/follow-up.pack.json",
    "docs/curriculum/examples/approvals.example.json",
    "docs/curriculum/examples/circle.svg",
    "test/goldens/noor-expressions.png", "test/goldens/world-environments.png",
}
for phase, folder in enumerate(("foundation", "learning-worlds", "game-engine",
                                "content-and-rewards", "release-and-playtest"), 1):
    for name in ("spec", "plan", "tasks"):
        PUBLIC_FILES.add(f"specs/{phase:03d}-{folder}/{name}.md")
for name in (
    "000-baseline", "001-local-storage", "002-platform-speech", "003-foundation-acceptance",
    "004-lesson-progress", "005-offline-speech-implementation", "006-spec-002-acceptance",
    "007-android-release-signing",
):
    PUBLIC_FILES.add(f"docs/decisions/{name}.md")
for folder, names in {
    "spec-001": (
        "results.md", "pixel-3-home.png", "pixel-3-settings.png", "tablet-landscape-home.png",
        "tablet-landscape-settings.png", "tablet-portrait-home.png",
    ),
    "spec-002": (
        "002-01-worlds.md", "002-02-player.md", "002-03-noor-and-speech.md", "002-04-verification.md",
        "tablet-landscape-home.webp", "tablet-portrait-home.webp", "mobile-home.webp",
        "world-iman.webp", "world-ibadah.webp", "world-seerah.webp", "world-exemplars.webp",
        "path-unlocked.webp", "lesson-player.webp", "lesson-celebration.webp",
        "mascot-expressions.webp", "speech-fallback.webp", "release-world.webp",
    ),
    "spec-003": (
        "003-01-questions.md",
        "003-02-flashcards.md",
        "003-03-arrangements.md",
        "003-04-sessions.md",
        "003-05-verification.md",
        "game-results.webp",
        "phone-choice-feedback.webp",
        "phone-choice.webp",
        "phone-flashcard-recall.webp",
        "phone-flashcard.webp",
        "phone-game-results.webp",
        "phone-matching-feedback.webp",
        "phone-matching.webp",
        "phone-ordering-feedback.webp",
        "phone-ordering.webp",
        "phone-true-false-feedback.webp",
        "phone-true-false.webp",
        "resumed-feedback.webp",
        "tablet-choice-feedback.webp",
        "tablet-choice.webp",
        "tablet-flashcard-recall.webp",
        "tablet-flashcard.webp",
        "tablet-matching-feedback.webp",
        "tablet-matching.webp",
        "tablet-ordering-feedback.webp",
        "tablet-ordering.webp",
        "tablet-portrait-ordering.webp",
        "tablet-speech-fallback.webp",
        "tablet-true-false-feedback.webp",
        "tablet-true-false.webp",
    ),
    "spec-005": (
        "005-01-toolchain.md", "005-02-layouts.md", "005-03-effects.md",
        "phone-audio-settings.png",
        "phone-home.png", "phone-lesson.png", "phone-large-text-settings.png",
        "tablet-home.png", "tablet-lesson.png", "tablet-landscape-lesson.png",
    ),
    "spec-004": (
        "004-01-curriculum-packs.md", "004-02-curriculum-handoff.md",
        "004-03-corrected-draft.md", "004-03-content-009.md",
        "004-04-preview-rewards.md", "004-05-adaptive-review.md",
        "004-06-parent-mode.md", "004-03-starter-candidate.md",
        "004-03-final-starter-approval.md", "004-03-starter-release-verification.md",
        "phone-starter-home.webp", "tablet-starter-results.webp", "tablet-starter-parent.webp",
        "release-world.webp",
    ),
}.items():
    PUBLIC_FILES.update(f"docs/qa/{folder}/{name}" for name in names)


def load_json(path):
    return json.loads(path.read_text(encoding="utf-8")) if path.is_file() else None


def git_value(root, *args):
    result = subprocess.run(["git", "-C", str(root), *args], capture_output=True, text=True)
    return result.stdout.strip() if result.returncode == 0 else "unavailable"


def table(headers, rows):
    heading = "".join(f'<th scope="col">{escape(str(value))}</th>' for value in headers)
    cells = "".join(
        "<tr>" + "".join(f"<td>{escape(str(value))}</td>" for value in row) + "</tr>"
        for row in rows
    )
    return f'<div class="table-scroll"><table><thead><tr>{heading}</tr></thead><tbody>{cells}</tbody></table></div>'


def count(value):
    return f"{value:,}" if isinstance(value, int) else "Unknown"


def section(name, title, content):
    return f'<section id="{name}"><h2>{title}</h2>{content}</section>'


def metrics(items):
    return '<div class="metrics">' + "".join(
        f'<div class="metric"><small>{escape(label)}</small><strong>{escape(str(value))}</strong></div>'
        for label, value in items
    ) + "</div>"


class Dashboard:
    def __init__(self, root, branch, commit, updated, pages):
        self.root = root
        self.branch = branch
        self.commit = commit
        self.updated = updated
        self.pages = pages
        self.progress = load_json(root / "docs/mission-control/progress.json")
        self.plan = load_json(root / "docs/curriculum/season-one.json")
        self.inventory = load_json(root / "docs/curriculum/public-inventory.json")
        self.releases = load_json(root / "docs/curriculum/releases.json")
        self.validate_progress()

    def exists(self, rel):
        path = (self.root / rel).resolve()
        return path.is_relative_to(self.root) and path.is_file()

    def validate_progress(self):
        seen = set()
        for phase in self.progress["phases"]:
            for item in phase["tasks"]:
                key = item["id"]
                evidence = item["evidence"]
                if key in seen or item["status"] not in STATUSES:
                    raise ValueError(f"Invalid task {key}")
                if item["status"] == "done" and not evidence:
                    raise ValueError(f"Missing evidence for {key}")
                if not all(self.exists(path) for path in evidence):
                    raise ValueError(f"Unresolved evidence for {key}")
                seen.add(key)

    def url(self, path):
        encoded = quote(path, safe="/")
        if not self.pages:
            return f"../../{encoded}"
        if path in PUBLIC_FILES:
            return encoded
        return f"{GITHUB}/blob/{quote(self.commit, safe='')}/{encoded}"

    def link(self, path, label=None):
        href = escape(self.url(path), quote=True)
        return f'<a href="{href}">{escape(label or Path(path).name)}</a>'

    def engineering(self):
        cards = []
        evidence = defaultdict(list)
        all_tasks = [task for phase in self.progress["phases"] for task in phase["tasks"]]
        done = sum(task["status"] == "done" for task in all_tasks)
        active = [task["id"] for task in all_tasks if task["status"] in {"doing", "review"}]
        overview = metrics([
            ("Verified tasks", f"{done}/{len(all_tasks)}"),
            ("Active tasks", ", ".join(active) or "None"),
            ("Blocked tasks", count(sum(task["status"] == "blocked" for task in all_tasks))),
        ])
        for phase in self.progress["phases"]:
            tasks = phase["tasks"]
            verified = sum(task["status"] == "done" for task in tasks)
            rows = []
            for task in tasks:
                status = task["status"]
                paths = task["evidence"]
                for path in paths:
                    evidence[path].append(task["id"])
                links = " · ".join(self.link(path) for path in paths)
                rows.append(
                    f'<div class="task" data-status="{status}"><span class="tag {status}">{status}</span>'
                    f'<div><small>{escape(task["id"])} · {escape(task["priority"])}</small>'
                    f'<div>{escape(task["title"])}</div><p class="note">{escape(task["note"])} {links}</p></div></div>'
                )
            cards.append(
                f'<details open><summary>SPEC-{escape(phase["id"])} · {escape(phase["name"])}'
                f'<small>{verified}/{len(tasks)}</small></summary><progress aria-label="Verified tasks" value="{verified}" max="{len(tasks)}"></progress>'
                f'<nav>{self.link(phase["spec"], "Specification")} {self.link(phase["plan"], "Plan")}</nav>'
                + "".join(rows) + "</details>"
            )
        options = "".join(f"<option>{status}</option>" for status in STATUSES)
        controls = f'<label>Task status <select id="filter"><option value="all">All tasks</option>{options}</select></label>'
        gallery = []
        for path, tasks in evidence.items():
            preview = ""
            if Path(path).suffix.lower() in {".png", ".jpg", ".jpeg", ".webp"}:
                image = escape(self.url(path), quote=True)
                alt = escape(Path(path).stem.replace("-", " "), quote=True)
                preview = f'<a href="{image}"><img loading="lazy" src="{image}" alt="{alt}"></a>'
            gallery.append(f'<article><small>{escape(", ".join(tasks))}</small><div>{self.link(path)}</div>{preview}</article>')
        return overview + controls + "".join(cards), '<div class="gallery">' + "".join(gallery) + "</div>"

    def curriculum(self):
        if self.plan is None:
            return "<p>Season One planning data is unavailable in this source snapshot.</p>"
        target = self.plan["targets"]
        baseline = self.plan["provisionalOutline"]
        pilot = self.plan["pilot"]
        intro = metrics([
            ("Target micro-lessons", count(target["lessons"])),
            ("Target knowledge units", f'{count(target["knowledgeUnits"])}+'),
            ("Target reviewed variants", f'{count(target["variants"])}+'),
            ("Pilot approved lessons (target)", count(pilot["approvedLessons"])),
        ])
        minutes = "–".join(map(str, target["dailyMinutes"]))
        text = (
            f'<p>Planning estimate · {target["days"]} days of optional {minutes} minute sessions. '
            f'The owner provisionally accepted {baseline["lessons"]} lesson outlines. '
            f'Their {baseline["questionIdeas"]} question ideas are a planning baseline.</p>'
        )
        review = self.plan.get("authoredDraftReview")
        if review:
            text += f'<p>{escape(review["note"])}</p>'
        for line in [*self.plan.get("coverageGaps", []), self.plan.get("priorityPath")]:
            if line:
                text += f'<p>{escape(line)}</p>'
        for world in self.plan["worlds"]:
            text += f'<details><summary><b dir="rtl">{escape(world["title"])}</b><small>{world["lessons"]} target lessons</small></summary>'
            text += table(["Planned unit", "Lesson target"], world["units"]) + "</details>"
        return intro + text

    def inventory_views(self):
        if self.inventory is None:
            empty = "<p>Canonical inventory is unavailable in this source snapshot.</p>"
            return empty, empty, empty, empty
        data = self.inventory
        names = {world["id"]: world["title"] for world in (self.plan or {}).get("worlds", [])}
        coverage = metrics((KINDS[k], count(data["totals"].get(k))) for k in ("lessons", "objectives", "knowledgeUnits", "variants"))
        coverage += f'<p>Unique record counts from {data["catalogs"]} core packs and included supplements. Open each world for unit totals and lesson coverage.</p>'
        if handoff := data.get("handoff"):
            coverage += metrics([
                ("Authoring packages", handoff["contentPackages"]),
                ("Planned lessons", handoff["plannedLessons"]),
                ("Planned objectives", handoff["plannedObjectives"]),
                ("Prayer-readiness lessons", len(handoff["prayerReadinessLessons"])),
                ("Cross-lesson review variants", handoff["mixedReviewVariants"]),
            ])
            coverage += '<p>Prayer readiness · ' + escape(' → '.join(handoff["prayerReadinessLessons"])) + '</p>'

        for world, units in data["worlds"].items():
            rows = []
            units_total = []
            for unit, lessons in units.items():
                totals = [sum(lesson[group] for lesson in lessons.values()) for group in ("objectives", "knowledgeUnits", "variants")]
                units_total.append((unit, len(lessons), *totals))
                rows.extend((unit, lesson, values["objectives"], values["knowledgeUnits"], values["variants"]) for lesson, values in lessons.items())
            coverage += f'<details><summary><b dir="rtl">{escape(names.get(world, world))}</b></summary>'
            coverage += table(("Unit", "Lessons", "Objectives", "Knowledge units", "Variants"), units_total)
            coverage += table(("Unit", "Lesson ID", "Objectives", "Knowledge units", "Variants"), rows) + "</details>"
        questions = '<div class="columns">'
        for group, label in (("mechanics", "Question types"), ("difficulty", "Recorded difficulty")):
            questions += f"<div><h3>{label}</h3>" + table(
                (label, "Variant records"), ((key.replace("_", " "), count(total)) for key, total in data[group].items())
            ) + "</div>"
        questions += "</div><p>Difficulty labels describe question demand. Mastery uses learner outcomes.</p>"
        approval = table(
            ("Record", *STAGE_LABELS.values()),
            ((label, *(count(data["stages"][kind][stage]) for stage in STAGE_LABELS)) for kind, label in KINDS.items()),
        )
        approval += "<p>Stage counts reflect recorded evidence. Provisional acceptance applies to the initial outline. Production requires per-record approval.</p>"
        if handoff := data.get("handoff"):
            approval += table(("Open queue category", "Items"), handoff["correctionQueue"].items())
            if review := handoff.get("scientificReview"):
                approval += metrics([
                    ("Draft records corrected", review["appliedDraftRecords"]),
                    ("New pending sources", review["addedPendingSources"]),
                    ("Repeated prompt groups (backlog)", review["repeatPromptGroups"]),
                ])
                if followup := review.get("followup"):
                    approval += metrics([
                        ("Follow-up draft edits", followup["appliedDraftRecords"]),
                        ("Follow-up pending sources", followup["addedPendingSources"]),
                        ("Retained learning objectives", followup["retainedObjectives"]),
                    ])
                approval += table(("Correction disposition", "Items"), review["queueStatus"].items())
                approval += table(("Partial source evidence", "Original scoped sources"),
                                  review["originalSourceEvidence"].items())
        if release := data.get("starterRelease"):
            approval += metrics([
                ("Approved starter lessons", release["counts"]["lesson"]),
                ("Approved starter records", release["approvedRecords"]),
                ("Lessons in private authoring", release["deferred"]["lessons"]),
                ("Open review items", release["deferred"]["openReviewItems"]),
            ])
            approval += "<p>The bundled starter is introductory. The original draft pipeline and broader scientific review remain tracked here.</p>"
        elif starter := data.get("handoff", {}).get("starterCandidate"):
            approval += metrics([
                ("Starter lessons awaiting approval", starter["lessons"]),
                ("Starter record approval requests", starter["recordRequests"]),
                ("Lessons in authoring", starter["deferredLessons"]),
            ])
        approval += table(("Source status", "Scoped source records"),
                          ((key.replace("_", " "), count(total)) for key, total in data["sources"].items()))
        extras = table(
            ("Content", "Records", "Draft", "Final approval", "Integrated"),
            ((KINDS[k], count(data["totals"].get(k)), *(count(data["stages"][k][stage]) for stage in ("draft", "finalApproval", "integrated")))
             for k in ("mnemonics", "treasures")),
        )
        return coverage, questions, approval, extras

    def render(self, preview_link=False):
        engineering, qa = self.engineering()
        coverage, questions, approval, extras = self.inventory_views()
        if self.releases is None:
            releases = "<p>Pack release data is unavailable in this snapshot.</p>"
        elif not self.releases["releases"]:
            releases = "<p>No released content packs are recorded.</p>"
        else:
            releases = table(("Pack", "Version", "Released", "What's New"),
                             ((r["packId"], r["version"], r["releasedAt"], r["whatsNew"]) for r in self.releases["releases"]))
        sections = [engineering, self.curriculum(), coverage, questions, approval, extras, releases, qa]
        view_links = "".join(f'<a href="#{key}">{title}</a>' for key, title in VIEWS)
        if preview_link:
            view_links += '<a href="previews/season-one/">Season One branch preview</a>'
        docs = (("docs/product.md", "Product"), ("docs/architecture.md", "Architecture"),
                ("docs/curriculum/roadmap.md", "Authoring roadmap"), ("docs/mission-control/deployment.md", "Deployment"))
        doc_links = " · ".join(self.link(path, label) for path, label in docs if self.exists(path))
        page = "".join(section(key, title, content) for (key, title), content in zip(VIEWS, sections))
        return f"""<!doctype html>
<html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Noor Mission Control</title><style>{STYLE}</style></head>
<body><main><header><h1>Noor Mission Control</h1>
<p>Engineering delivery and Season One curriculum</p>
<dl><div><dt>Source branch</dt><dd>{escape(self.branch)}</dd></div>
<div><dt>Commit SHA</dt><dd><code>{escape(self.commit)}</code></dd></div>
<div><dt>Last updated (commit time)</dt><dd>{escape(self.updated)}</dd></div></dl></header>
<nav aria-label="Dashboard views" class="views">{view_links}</nav>
{page}<footer>{doc_links}</footer></main>
<script>
document.querySelector('#filter').addEventListener('change', event => {{
  document.querySelectorAll('.task').forEach(task => {{
    task.hidden = event.target.value !== 'all' && event.target.value !== task.dataset.status;
  }});
}});
</script></body></html>
"""


STYLE = """
*{box-sizing:border-box}html{color-scheme:light}body{margin:0;background:#f4f6f1;color:#1f3830;font:16px/1.5 system-ui,sans-serif}
main{width:min(1160px,100%);margin:auto;padding:clamp(12px,4vw,40px)}header{background:#163d32;color:#fffaf0;border-radius:24px;padding:clamp(20px,4vw,42px)}
h1,h2,h3,p{margin:0 0 .65em}h1{font-size:clamp(2rem,4vw,3rem);line-height:1.15}header dl{display:flex;flex-wrap:wrap;gap:16px 24px;margin:18px 0 0}
dt,small{font-size:.8rem;color:#4c6357}header dt{color:#bdd4c5}dd{margin:0;overflow-wrap:anywhere}dd code{font-size:.78rem}
nav{display:flex;flex-wrap:wrap;gap:8px 16px;margin:14px 0}a{color:#245d49;text-underline-offset:3px}a:focus-visible,select:focus-visible,summary:focus-visible{outline:3px solid #187a61;outline-offset:3px}
.views{margin:16px 0 28px}.views a{background:#e0eee5;border:1px solid #ccddd1;border-radius:99px;padding:7px 12px}.metrics,.columns,.gallery{display:grid;gap:12px;grid-template-columns:repeat(auto-fit,minmax(min(100%,190px),1fr))}
.gallery{grid-template-columns:repeat(auto-fit,minmax(min(100%,225px),1fr))}.metric,details,article{background:#fff;border:1px solid #d7e3d8;border-radius:16px;padding:14px}
.metric strong{display:block;font-size:1.65rem}.metrics{margin-bottom:14px}section{margin:28px 0;scroll-margin-top:12px}details{margin:10px 0}
summary{cursor:pointer;font-weight:700}summary small{float:inline-end}progress{width:100%;height:8px;accent-color:#327354}
select{font:inherit;padding:6px 8px;border:1px solid #a3baaa;border-radius:7px}.task{display:flex;gap:12px;align-items:start;padding:9px 0;border-top:1px solid #eaf0e9}.note{font-size:.88rem;color:#405a4e;margin:2px 0}
.tag{flex:0 0 68px;text-align:center;border-radius:8px;padding:3px;background:#edf0ed;font-size:.8rem}.done{background:#d8eddc}.blocked{background:#f6ddd4}.doing,.review{background:#f7ebcb}.table-scroll{overflow:auto;margin:10px 0}
table{width:100%;border-collapse:collapse;background:white}td,th{text-align:start;padding:8px 10px;border-bottom:1px solid #e0e8e1}th{background:#e4efe8;font-weight:650}
img{display:block;max-width:100%;max-height:220px;border-radius:8px;margin-top:8px}footer{border-top:1px solid #d7e3d8;padding-top:12px}[hidden]{display:none!important}
"""


class LinkCheck(HTMLParser):
    def __init__(self, directory, site=None):
        super().__init__()
        self.directory = directory.resolve()
        self.site = site.resolve() if site is not None else None
        self.ids = set()
        self.anchors = set()

    def handle_starttag(self, tag, attributes):
        for key, value in attributes:
            if key == "id":
                self.ids.add(value)
            if key in {"href", "src"} and value.startswith("#"):
                self.anchors.add(value[1:])
            if key in {"href", "src"} and not value.startswith(("#", "https://")):
                path = self.directory / unquote(urlsplit(value).path)
                if self.site is not None and not path.resolve().is_relative_to(self.site):
                    raise ValueError(f"Escaping Pages link: {value}")
                if not path.is_file() and not (path / "index.html").is_file():
                    raise ValueError(f"Broken relative link: {value}")

    def validate(self, html):
        self.feed(html)
        if not self.anchors <= self.ids:
            raise ValueError(f"Broken navigation anchors: {self.anchors - self.ids}")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=ROOT)
    parser.add_argument("--pages-dir", type=Path)
    parser.add_argument("--source-branch")
    parser.add_argument("--source-sha")
    parser.add_argument("--updated-at")
    parser.add_argument("--preview-link", action="store_true")
    args = parser.parse_args()
    root = args.root.resolve()
    pages = args.pages_dir.resolve() if args.pages_dir else None
    dashboard = Dashboard(
        root,
        args.source_branch or git_value(root, "branch", "--show-current"),
        args.source_sha or git_value(root, "rev-parse", "HEAD"),
        args.updated_at or git_value(root, "show", "-s", "--format=%cI", "HEAD"),
        pages is not None,
    )
    if pages:
        for rel in sorted(PUBLIC_FILES):
            source = root / rel
            if source.is_file():
                if source.is_symlink() or not source.resolve().is_relative_to(root):
                    raise ValueError(f"Unsafe publication path: {rel}")
                dest = pages / rel
                dest.parent.mkdir(parents=True, exist_ok=True)
                shutil.copyfile(source, dest)
    output = pages or (root / "docs/mission-control")
    output.mkdir(parents=True, exist_ok=True)
    html = dashboard.render(args.preview_link)
    LinkCheck(output, pages).validate(html)
    (output / "index.html").write_text(html, encoding="utf-8")
    print("Generated", output / "index.html")


if __name__ == "__main__":
    main()
