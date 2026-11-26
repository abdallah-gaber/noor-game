# SPEC-002 tasks

| Task | Scope | Dependencies |
|---|---|---|
| 002-01 | Adventure map, illustrated world shells, stable fixture catalog, reusable learning paths and route boundaries | SPEC-001 |
| 002-02 | Content-driven player, SQLite migration, resume and completion | 002-01 |
| 002-03 | Contextual lantern expressions, motion and speech controls with offline fallback | 002-02 |
| 002-04 | Navigation and accessibility verification, screenshot gallery, platform builds and delivery checks | 002-01 through 002-03 |

Mission Control reads canonical task status and evidence from [progress.json](../../docs/mission-control/progress.json).
