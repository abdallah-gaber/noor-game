# SPEC-003 — Game engine

| Task | Given | When | Then | Verification |
|---|---|---|---|---|
| 003-01 | Schema 1 choice and true/false definitions | A definition is decoded, shown and answered | Choice has 2–4 distinct stable option IDs and optional illustration references. True/false presents clear Arabic labels. Evaluation uses ID regardless of order. Invalid or unsupported data is rejected. A rapid second tap cannot replace feedback or the submitted answer | Pure Dart decoder and evaluator tests, RTL widget tests, labeled debug preview |
| 003-02 | An unscored flashcard | The learner reveals and optionally self-assesses | The answer can be revealed by tap, and self-assessment stays outside scored attempts | Reveal and scoring-isolation checks |
| 003-03 (P1) | Valid matching pairs or ordering items | The learner taps selections | Match 2–4 pairs and order 2–5 items with correction and reset before submission. Use icons and labels as feedback | Model and interaction tests |
| 003-04 | A reading-only or mixed lesson | The learner continues across reading, challenges, feedback, bounded review and results | Reading-only completion stays compatible. Mixed lessons require the challenge session result. Double taps, abandonment and replay cannot duplicate completion or unlock early. Persist attempts, order and completion atomically | Session and persistence tests |
| 003-05 | Phone, portrait/landscape tablet and offline builds | An adult verifies the end-to-end journey with large text and reduced motion | Required modes work in RTL with accessibly sized controls, and release excludes developer fixtures. Prior phases pass regressions | Automated suite, runtime screenshots and Android/iOS builds |

## Shared rules

No timers, lives or penalties. Explain answers in simple Arabic with reviewed content. Keep first-attempt accuracy separate from later success. A zero-scored session reports an absent accuracy value and can complete once its required activities are done. Retry sequence and persistence details belong to 003-04. XP, stars, achievements and parent-facing results belong to SPEC-004. P1 deferral requires a documented reason and owner review.

## Authorized checkpoint

Deliver only 003-01 in this execution. It owns the two scored question definitions, evaluator, one-question feedback, developer preview and regression checks for progress isolation. Every preview attempt is transient. Lesson integration, review, persistent attempts and completion rules are planned for 003-04. Tasks 003-02 onward await explicit authorization.

## Season One compatibility

Future sessions use stable variant IDs linked to knowledge units. Record the pack and objective compatibility revisions alongside attempts. Plan for lessons, mixed eligible sets and replay beyond the linear path. Keep question difficulty separate from mastery. Variant selection and persisted attempts belong to 003-04. Adaptive review, pack updates, knowledge treasures and What's New belong to later phases. The 003-01 evaluator remains usable across these contexts.
