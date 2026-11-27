# SPEC-004 — Content and rewards

| Task | Acceptance |
|---|---|
| 004-01 | Validate independently versioned offline packs, stable knowledge IDs, variant links, sources, audio and reuse rights. Reject inconsistent or unapproved production input before activation. Preserve earned progress across compatible content updates. Show What's New from pack release metadata. |
| 004-02 | Maintain the authoring pipeline and provisional 12-lesson baseline. Supply a four-world pilot and track Season One targets of 60 micro-lessons, 180+ knowledge units and 600+ reviewed variants. Optional knowledge treasures and established memorization aids follow the same review rules. |
| 004-03 | Require explicit human review of the exact production record and approval hash. Keep source verification, schema validation, integration and release QA independently evidenced. |
| 004-04 | Track mastery by knowledge ID, along with progress, stars and XP. Use revision compatibility and prevent duplicate awards when replaying. |
| 004-05 (P1) | Support non-linear mixed quizzes, continued play, adaptive review and configurable spaced repetition. Keep difficulty separate from mastery and review prior misses sooner. |
| 004-06 | Parent Mode shows progress and verified source context. |

Curriculum production is a separate track. See the [curriculum roadmap](../../docs/curriculum/roadmap.md). P1 deferral requires a documented reason and owner review.

Prioritize a prayer-readiness learning path. CONTENT-007 supplies draft matching and ordering, including cross-lesson variants for later mixed review. The owner’s provisional acceptance of existing drafts is subject to corrections and final source verification.

## 004-01 acceptance

| Given | When | Then |
|---|---|---|
| Independent schema-1 packs and a trusted approval ledger | The app validates and activates a batch | Stable typed references, all five mechanics, sources and assets, prerequisite graphs and record digests pass before the new catalog becomes visible |
| Drafts, malformed definitions or missing/stale approval | The same entry point receives them | The entire candidate is rejected and the previous catalog stays usable |
| A compatible editorial pack update | The active version changes | Reading resumes under the same lesson key, compatible sessions keep answer identity, and historical rows are retained without rewriting SQLite |
| A cross-world path marked prayer readiness | The integrated catalog is inspected | The path is prioritized, its lesson dependencies resolve, and memorization and treasures remain addressable as separately approved records |

004-01 delivers infrastructure and synthetic fixtures. The 60 lessons, 180 knowledge units, and 600 variants remain provisionally accepted drafts. CONTENT-006 and CONTENT-007 are authored and reviewed separately.

## 004-02 adult-review pilot checkpoint

| Given | When | Then |
|---|---|---|
| The owner builds a local debug pilot from the canonical drafts | An adult acknowledges the unverified-content notice | The existing worlds and game screens open one selected lesson per world, including the practical ablution lesson and its authored ordering activity |
| A user follows a lesson or game deep link before acknowledgment | The pilot router handles it | The review notice opens before any draft content |
| A learner uses a normal build | The app starts or resolves a pilot lesson link | Production approval still controls the catalog and preview progress cannot count toward it |
| The reviewed input files or references differ from the expected draft graph | The local adapter prepares the pilot | Preparation fails before a new payload is emitted |

The pilot samples the core packs and compatible CONTENT-007 activities. CONTENT-006 extras, open editorial corrections, further conversion and final approval remain on the separate authoring track.

## 004-02 curriculum handoff acceptance

- Import CONTENT-001 planning and CONTENT-002–007 draft evidence into one private, independently versioned review snapshot. Preserve all native IDs and source references. Track outlined, structurally validated and finally approved items separately.
- Validate the whole draft graph, including authored answer definitions, scoped sources, cross-lesson knowledge, and ordered prayer readiness. Keep cross-lesson variants available for later mixed review.
- Preserve proposals as an open correction queue and identify affected variant IDs. Show unresolved source verification and reuse rights separately. Reconcile draft and blueprint differences without changing authored text.
- Generate browsable private review HTML and machine-readable records and queue. Regenerate public Mission Control from the same analysis using aggregate data and stable identifiers. Existing production activation remains the gate for any child content.

## 004-03 corrected draft checkpoint

- Require the exact CONTENT-008 baseline bundle digest, input file digests and guarded before-values before constructing a corrected draft snapshot.
- Preserve original authoring files for audit. Apply compatible operations to their private authoring records and regenerate the review artifacts. Hold answer-semantic conflicts for review.
- Keep the supplied dispositions and evidence linked to their queue items. Distinguish applied text edits from open source, historical edition, rights and human approval work.
- Keep the public inventory aggregate-only and require the existing approval gate for child integration. Log repeated question prompts as future content-quality work.

## 004-04 preview rewards acceptance

- Verified preview game completion earns 10 XP and up to three stars for the lesson. Use first-attempt scored accuracy for stars. A later better round may raise the lesson's best stars within the three-star cap.
- Retry, replay and compatible content updates retain earned progress without paying XP again for the same stable lesson ID. Unfinished and unscored rounds earn no rewards.
- Track first and eventual correctness by stable knowledge and variant IDs across durable scored attempts. A repeated variant contributes at most once to a knowledge unit's accuracy denominator.
- Keep Rewards inside the preview catalog and preview progress scope. Award for in-app learning only. Worship practice, streaks and ordinary child routes do not award anything at this checkpoint.

## 004-05 preview review acceptance

- Resume an unfinished adaptive or daily round from durable preview attempts and its saved variant order. A daily round stays available for the local date. A compatible edit preserves the saved sequence.
- Choose from available lessons using stable knowledge IDs, previously missed variants, separate first and eventual correctness, and recent first-pass performance. Prefer due or weak knowledge, then vary mechanics and avoid identical prompts within a round.
- Persist the selected spacing intervals from 1, 3, 7 and 14 days, with at least one enabled. The default enables all four. Early optional practice carries no penalty or extra payout.

## 004-06 Parent Mode acceptance

- An explicit preview-only Parent Mode entry shows actual saved world and lesson progress, recent activity and knowledge results. Pre-seeded fixture unlocks do not inflate completion.
- Separate first-attempt, recent first-pass and eventual correctness. Describe strengths and review needs using recent evidence, and offer recommended practice from the adaptive schedule.
- Show readable draft source titles, locators and available addresses in context, with an unverified label. Synthetic fixtures contain no religious sources. The view works offline with no account and stays behind the adult review gate for authored drafts.
