# Implementation plan — Learning worlds

1. Add a responsive adventure map, four distinct Flutter-painted world environments, stable catalog identifiers and a reusable path. Keep preview data behind debug mode and preserve the SPEC-001 greeting, settings and preview behaviors.
2. Add a data-driven lesson player, version-scoped resume and persistent completion using a migration of the existing app SQLite database. Keep progress separate from future challenge scoring.
3. Extend the original vector lantern with six moods and finite, reduced-motion-aware reactions. Add on-demand Arabic speech controls with installed offline voice checks where available and a text fallback. Respect the persisted speech preference and document platform limitations.
4. Run regression, accessibility, layout and offline smoke checks. Capture optimized, anonymized application screenshots, update Mission Control, build Android and iOS and open one PR for owner review.

Follow the per-task publication workflow in [AGENTS.md](../../AGENTS.md). See [tasks.md](tasks.md) for task dependencies and evidence.
