# 003-01 checkpoint — 2026-11-26

Formatting (32 files) and `flutter analyze --no-pub` passed. `flutter test --no-pub --reporter expanded` passed all 59 tests, including 52 prior checks. New checks cover JSON round-trip and malformed inputs, stable answer identity under shuffle, correct and incorrect outcomes, duplicate taps, large-text RTL, release routing and progress scope.

Android debug and release APKs and the unsigned iOS simulator build succeeded. The Android release APK (50.1 MB) has SHA-256 `15fb5d7a57d9f6fee65b7588c91d07c1452aedf38cfa20d64a7e8bcda2fd24f2`. An Android 9 phone emulator redirected a direct release preview request to the home screen.

On the phone, used the SPEC-002 debug build to save a reading step under schema 2. After updating to schema 3, the step resumed. Read-only comparisons of the emulator SQLite files confirmed that old progress moved intact into the preview table, preferences survived, and approved progress stayed empty after answering both fixtures. The Android 15 tablet emulator exercised both fixtures with no active default network.

| Mechanic | Phone | Tablet landscape |
|---|---|---|
| Multiple choice | [Question](phone-choice.webp) · [Feedback](phone-choice-feedback.webp) | [Question](tablet-choice.webp) · [Feedback](tablet-choice-feedback.webp) |
| True/false | [Question](phone-true-false.webp) · [Feedback](phone-true-false-feedback.webp) | [Question](tablet-true-false.webp) · [Feedback](tablet-true-false-feedback.webp) |

The captures are Android emulator screenshots from labeled non-religious debug routes. Open the developer preview from the app home or use `/preview/challenges/shapes-choice` and `/preview/challenges/shapes-true-false`. Each question locks after one answer. Attempts are transient. [Remaining tasks](../../../specs/003-game-engine/tasks.md) cover flashcards, matching and ordering, persisted sessions, required challenge completion, and full-phase QA.
