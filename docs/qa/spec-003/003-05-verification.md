# SPEC-003 final verification — 2026-11-26 to 2026-11-27

| Check | Result |
|---|---|
| Dart formatting | Passed, 46 files |
| `flutter analyze --no-pub` | Passed |
| `flutter test --no-pub --reporter expanded` | 78 passed, including SPEC-001 and SPEC-002 regressions |
| `flutter build apk --release --no-pub` | Passed, 50.2 MB, Android API 24+, ARM64, ARMv7 and x86-64 |
| `flutter build ios --simulator --no-codesign --no-pub` | Passed, unsigned simulator app |
| `python3 -m unittest discover -s scripts -p 'test_*.py'` | 5 passed |
| `python3 scripts/content_inventory.py --check` | Matches four canonical draft packs |

The device matrix exercises every mechanic at 390×844, 800×1280 and 1024×768 logical pixels at 1× and 2× text scale. Checks include RTL, labeled controls, Android touch targets, ambiguous visible labels, deterministic option identity, reading-only compatibility, mixed-lesson unlocks, persisted feedback, revision safety, bounded retries and independent first-attempt, eventual correctness and replay history.

The Android runtime checks used a Pixel 3 Android 9 emulator and a Medium Tablet Android 15 emulator. The tablet used software graphics and had no active default network. All challenge captures show labeled non-religious debug fixtures. The speech control passed a simulated non-overlap check and displayed Arabic text fallback on the offline tablet. The iOS build retains text fallback.

The release APK SHA-256 is `93bca635ce236737e1f653ac32bb9abd1eba644f5e80bbbb27ff6c91ab4cbb00`. Android emitted the existing Cupertino icon-font tree-shaking warning. The final feedback captures confirm that submitted matching and ordering options retain readable contrast.

On both Android emulators, a direct developer challenge route redirected to home in the release build. A direct mixed-lesson game route opened the public world shell. The release manifest lacks Internet permission.

## Captures

| Activity | Phone | Tablet landscape |
|---|---|---|
| Multiple choice | [Question](phone-choice.webp) · [Feedback](phone-choice-feedback.webp) | [Question](tablet-choice.webp) · [Feedback](tablet-choice-feedback.webp) |
| True/false | [Question](phone-true-false.webp) · [Feedback](phone-true-false-feedback.webp) | [Question](tablet-true-false.webp) · [Feedback](tablet-true-false-feedback.webp) |
| Flashcard | [Question](phone-flashcard.webp) · [Recall](phone-flashcard-recall.webp) | [Question](tablet-flashcard.webp) · [Recall](tablet-flashcard-recall.webp) |
| Matching | [Question](phone-matching.webp) · [Feedback](phone-matching-feedback.webp) | [Question](tablet-matching.webp) · [Feedback](tablet-matching-feedback.webp) |
| Ordering | [Question](phone-ordering.webp) · [Feedback](phone-ordering-feedback.webp) | [Question](tablet-ordering.webp) · [Feedback](tablet-ordering-feedback.webp) |
| Game results | [Results](phone-game-results.webp) | [Results](game-results.webp) |

[Tablet portrait](tablet-portrait-ordering.webp) · [Offline speech fallback](tablet-speech-fallback.webp) · [Session and database evidence](003-04-sessions.md)

## Release gates

Physical low-end performance and playable offline Arabic synthesis remain SPEC-005 gates. Actual pronunciation and operating-system voice coverage require physical testing. The current draft curriculum has no authored matching or ordering variants. SPEC-004 owns their authoring and the prayer-readiness priority. Provisional owner acceptance covers the authored draft packs subject to corrections and final source verification. Production still requires record-level approval, validation and integration.
