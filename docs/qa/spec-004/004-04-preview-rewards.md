# 004-04 preview rewards

The existing preview results now show the lesson's best stars, total stars and XP. A scored lesson earns 10 XP once on its first completed round. A completed round earns one star, two for at least half correct on the first attempt, and three for all correct on the first attempt. Replays can improve the best star count within that cap. Incomplete rounds and unscored flashcards earn no payout.

The preview summary reads completed game snapshots in bounded pages. It uses stable lesson IDs to retain rewards across compatible revisions. Knowledge practice is keyed by stable knowledge and variant IDs with separate first and eventual correctness counts. No new payout row, schema migration or runtime dependency is required. Historical game snapshots remain the data source, and already completed preview rounds count when displayed. The summary only reads preview-scoped rows. Rewards represent in-app practice.

## Verification

- Static analysis passed with no issues.
- Fourteen targeted tests passed across `reward_progress_test.dart`, `game_journey_test.dart`, `game_session_test.dart` and `curriculum_packs_test.dart`. They cover old snapshots, fixed XP and capped improvement on replay, retained first-attempt evidence, preview-only data reads, visible results after persistence, incomplete and unscored rounds, and production entry gates.
- Mission Control was regenerated. The CONTENT-009 sanitized inventory continues to match the private corrected inputs.
