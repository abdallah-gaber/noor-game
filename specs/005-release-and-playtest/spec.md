# SPEC-005 — Release and playtest

## Requirements and acceptance
- Run format, analysis and automated tests. Acceptance: demonstrated behavior or review artifact linked to task 005-01; no unverified completion.
- Capture actual tablet and phone screenshots. Acceptance: demonstrated behavior or review artifact linked to task 005-02; no unverified completion.
- Verify readable Arabic and optional offline effects on supported physical devices (005-03). Check readable behavior with speech unavailable or disabled. System TTS voice availability and bundled narration are future enhancements and do not block the MVP.
- Run supervised child playtest and record observations. Acceptance: demonstrated behavior or review artifact linked to task 005-04; no unverified completion.
- Resolve release blockers and regenerate tracker. Acceptance: demonstrated behavior or review artifact linked to task 005-05; no unverified completion.

- Verify the release candidate on the child’s physical low-end Android tablet (005-06). Given the installed candidate in airplane mode, when an adult exercises launch, both orientations, world and lesson navigation, mascot reactions, background/resume and a full restart, then controls respond comfortably, settings and progress persist, and no crashes, obvious visual stalls or layout failures occur. Record the build, non-identifying hardware and OS details, rendering and responsiveness observations, and actual screenshot evidence where appropriate. An emulator cannot satisfy this gate.

## Gates
Follow constitution and product/architecture docs. Record concrete acceptance scenarios before coding; tests and real screenshots where applicable. P1 items may be deferred with reason, not counted done.

## Pilot and pack release

The weekend candidate must include at least four individually approved, validated and integrated lessons, one per world. Verify compatible pack updates preserve earned progress, display What's New and keep replay and mixed practice available where implemented. Supervised testing of Season One should measure optional engagement before claiming thirty days of play. Confirm the release remains music-free and that any memorization aids or narration have recorded rights and review evidence.
