# SPEC-003 implementation plan

1. Implement a versioned, pure Dart decoder and ID-based evaluator for choice and true/false. Render both through one reusable RTL question widget. Keep sample questions in a gated, non-religious developer preview. Isolate prior preview reading progress through a non-destructive SQLite migration.
2. Add unscored flashcards and isolated self-assessment.
3. Extend validation and presentation for tap-to-match and tap-to-order. Seek owner review for any P1 deferral.
4. Add immutable session snapshots, persisted order and attempts, scoring and bounded review. Integrate challenge-based completion and idempotent atomic lesson updates. Resume compatible sessions from stable IDs and stored option order. Preserve completion history and disregard incompatible in-flight drafts.
5. Verify all mechanics across sizes and states. Capture runtime evidence, build both platforms, push remaining task commits and open one PR against main for owner review.

[Task breakdown](tasks.md) · [Architecture](../../docs/architecture.md)

For 003-04, persist pack and objective revision, stable variant and knowledge IDs, and the resolved order. Accept eligible sets as session input so SPEC-004 can build mixed quizzes and adaptive review without changing mechanic evaluation.
