# ADR 004 — Versioned lessons and local resume

SPEC-002 uses a single shared SQLite database. Schema 2 adds a lesson-progress table and keeps the schema 1 settings row intact. The stored record identifies a lesson by stable ID, a content version and the last saved step. Reopening a changed content version begins at the first step. Completions survive version changes and replay. A completed prerequisite unlocks dependent lessons. A save failure keeps the current page visible and offers another attempt. [Migration and restart QA](../qa/spec-002/002-02-player.md)

The reusable player reads short steps from a versioned catalog with world, unit and lesson IDs. Challenge scoring stays separate. The preview catalog uses reserved fixture IDs and seed states exclusively in debug builds. Approved curriculum should get its own IDs and governance checks. Release and profile builds keep the four world shells and display an availability message while the approved catalog is empty.
