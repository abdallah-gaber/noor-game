# SPEC-001 — Foundation

| Task | Given | When | Then | Verification |
|---|---|---|---|---|
| 001-01 | A clean checkout and the pinned Flutter SDK | A developer resolves dependencies, analyzes, tests and builds the app | Android and iOS project entry points exist, and the Android app opens to an Arabic home with no network requirement | SDK version, locked resolution, format, analysis, tests and Android build/launch recorded in QA |
| 001-02 | An Arabic device-independent locale and available content width | Home is shown at widths below 600, from 600 through 839, or at least 840 logical px | Home flows top-to-bottom on compact and medium widths and places the greeting at the leading (right) edge in expanded view. Buttons have at least 48 logical px targets and use directional padding, visible text and semantics | Widget assertions for locale, RTL, breakpoints, target sizes and safe insets |
| 001-02 | Noor's lantern and the home greeting action | The greeting is tapped with motion allowed or disabled | Noor switches from a resting smile to a happy expression, with a brief nudge only when motion is allowed. It is still at rest and has no continuous animation | Widget tests cover expressions, finite animation and reduced motion |
| 001-03 | Fresh local storage and Arabic home | A user opens settings, changes speech or effects preference, goes back and restarts the app | Settings default to off, save independently and survive restart. Saving is serialized in the UI, failed reads and writes offer recovery, and the last saved values remain authoritative | Router and error-state widget tests plus native database smoke test across a process restart |
| 001-03 | A debug build or a release/profile build | A user visits the developer preview route | Debug shows a visibly labeled non-religious mock screen. Release/profile resolves to home | Debug route and release-policy widget tests, plus offline release build smoke where available |
| 001-04 | Phone and tablet viewport matrix | Home and settings render at 390×844, 600×960, 800×1280 and 1024×768 at scales 1.0, 1.3 and 2.0 | Controls fit or are reachable by scrolling, without overflow or forced rotation | Widget matrix and actual app screenshots from phone and tablet runtimes |
| 001-04 | The owner’s physical tablet running the foundation | The owner exercises startup, orientation, navigation, mascot, preferences, airplane mode and background/resume | All ten smoke checks pass and the owner accepts the foundation | [Owner-reported physical QA](../../docs/qa/spec-001/results.md) |

## Scope

Home, settings, a debug-only mock screen, and an original smiling lantern with one greeting reaction. The four worlds, lesson player, speech playback, games, curriculum and rewards are later phases. Settings store preferences for future audio. There is no religious material in this phase.
