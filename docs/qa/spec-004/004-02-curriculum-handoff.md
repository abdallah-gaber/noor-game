# 004-02 curriculum handoff

The owner accepted the playable four-world pilot after physical-tablet review. Readable Arabic satisfies the MVP. System TTS and bundled narration are optional future enhancements. Retain the existing accessibility semantics and optional speech support. Improve optional effects in a later polish pass with more audible, joyful and distinct cues, gentle retries, no clipping and no music. Difficulty tuning and richer interactions remain backlog items.

## Local review inventory

| Input | Structurally checked draft evidence |
|---|---|
| CONTENT-001 | 60 planned lessons, 180 planned objectives and all 12 prior-outline mappings |
| CONTENT-002–005 | 60 authored lessons, 180 knowledge units and 600 core variants |
| CONTENT-006 | 20 memorization entries and 30 treasures |
| CONTENT-007 | 36 added variants, a 14-lesson prayer-readiness path across two worlds, and 11 authored findings |

The combined 636 variants include 266 multiple choice, 180 true/false, 168 flashcards, 12 matching and 10 ordering. Eight cross-lesson variants retain their linked lesson requirements for future mixed review. Source identifiers and available locators were checked for references across their original scopes. There are 181 pending scoped source records, including seven historical-edition checks.

The private queue contains 27 items. It includes 11 authored findings, seven blueprint alignment items, three variant citation alignment items, five scoped source verification groups and one reuse-rights group covering 20 memorization entries. The handoff applies no editorial proposal. There are zero final record approvals or integrated child records.

## Verification

- `python3 scripts/generate_curriculum_review.py` generated the private dashboard, full review bundle and correction queue, and refreshed Mission Control from sanitized aggregates.
- `python3 scripts/content_inventory.py --check` matched the canonical snapshot.
- `python3 -m unittest discover -s scripts -p 'test_*.py'` passed 10 tests against the local drafts and synthetic cases. Checks covered duplicate visible options, answer-order completeness, cyclic prerequisites, input digest drift, unresolved scoped citations, untrusted approval signals, dashboard fragment links and publication privacy.
- `flutter analyze --no-pub` reported no issues. The 12 targeted tests in `draft_pilot_test.dart` and `curriculum_packs_test.dart` passed with the private pilot defines. They verified continued pilot access, preview isolation and production-gate regressions.

The next review is consolidated editorial and record approval. Use the [curriculum workflow](../../curriculum/README.md) to regenerate the private materials. The local dashboard and draft payloads are ignored by Git and excluded from Pages and app packaging.
