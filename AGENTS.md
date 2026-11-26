# Agent instructions

Read the constitution, product, architecture, curriculum workflow and decision log before implementation. Work on one specification at a time. Keep `main` stable and use one feature branch and one pull request per specification. Use Conventional Commits with a SPEC scope and include the task identifier in each task commit. Preserve individual task commits when merging. Obtain explicit owner approval before merging a specification PR.

## Task workflow

1. Refine the specification, plan and acceptance checks before implementation. Mark the task `doing` in `docs/mission-control/progress.json`.
2. Implement only that task, then run relevant formatting, analysis and tests.
3. Capture actual evidence and record commands, results, commit references and screenshots in `docs/qa`. Update status and documentation. Regenerate Mission Control with `python3 scripts/generate_dashboard.py`. Never edit the generated HTML.
4. Review the staged diff, make one atomic task commit and push the feature branch immediately. Verify the commit is on the remote. A task is fully delivered when its verified commit is published. If publishing fails, preserve the local commit, record the error and report the delivery blocker.

Task statuses are `todo`, `doing`, `blocked`, `review`, `done` and `deferred`. Use `done` only with real, linked verification. Keep evidence free of child identifiers and sensitive information. Religious approval and physical playtest require real human evidence. Identify owner reports and emulator evidence accurately.

Before moving to the next specification, report completed tasks, blockers, tests and next steps and wait for owner review. Follow the constitution for religious content approval.
