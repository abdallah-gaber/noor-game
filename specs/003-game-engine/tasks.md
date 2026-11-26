# SPEC-003 tasks

| ID | Scope | Dependency |
|---|---|---|
| 003-01 | Validate, serialize, evaluate and render multiple choice and true/false. Verify debug gating and progress isolation | SPEC-002 |
| 003-02 | Implement flashcard reveal and unscored recall | 003-01 |
| 003-03 | Implement tap-to-match and tap-to-order (P1) | 003-01 |
| 003-04 | Integrate game sessions, feedback, retries, randomization, scoring and atomic completion | Implemented mechanics |
| 003-05 | Verify regression, builds, offline behavior, accessibility and runtime evidence | 003-04 |

Use [Mission Control data](../../docs/mission-control/progress.json) for live status. Owner authorization is required before starting 003-02.
