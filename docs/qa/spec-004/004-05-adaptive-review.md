# 004-05 adaptive review and daily challenges

Preview home links to an adaptive round and a daily challenge. The scheduler considers available lessons and favors the latest missed variants, weak knowledge and due items. It varies mechanics, favors less recently seen variants within a priority group and skips repeated visible prompts. Each round has up to five activities.

Intervals of 1, 3, 7 and 14 days can be selected independently on the review screen. At least one must be enabled. Successful practice advances spacing across dates. Repeating on the same day cannot advance the interval. First-attempt evidence, recent first-pass results and eventual correctness remain separate. Old undated history still informs selection.

The daily round is keyed to the local date. Both formats reuse preview game snapshots and restore order and attempts after restart or compatible wording changes. Incompatible scoring definitions start a fresh round with historical evidence retained. Schema 5 adds nullable timestamps and private review preferences. Review attempts do not write lesson completion or award XP or stars.

## Verification

Static analysis passed. Eighteen targeted tests passed across the adaptive review, game journey, game session, Rewards and curriculum pack suites. They cover prioritization, prompt deduplication, spacing, settings persistence, date rollover, compatible resume, preview and child route isolation, no Rewards from review, and existing pack approval behavior.
