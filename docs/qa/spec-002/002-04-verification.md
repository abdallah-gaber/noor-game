# SPEC-002 final verification — 2026-11-26

Task commits for the visual map, lesson player and lantern/audio were `9e2fa51`, `35b4422` and `53ebacf`. The final verification task includes acceptance tests and application captures. [Specification](../../../specs/002-learning-worlds/spec.md) · [Mission Control](../../mission-control/index.html)

| Check | Command | Result |
|---|---|---|
| Format | `dart format --output=none --set-exit-if-changed lib test` | Passed, 27 files |
| Static analysis | `flutter analyze --no-pub` | Passed, no issues |
| Automated suite | `flutter test --no-pub --reporter expanded` | 52 passed, including SPEC-001 regressions and both illustration goldens |
| Android release | `flutter build apk --release --no-pub` | Passed, 49.9 MB, Android API 24+, ARM64, ARMv7 and x86-64 |
| iOS simulator | `flutter build ios --simulator --no-codesign --no-pub` | Passed, unsigned build |

The new layout checks exercise the map, path, player and back navigation at 390×844, 600×960, 800×1280 and 1024×768 logical px at text scales 1.0, 1.3 and 2.0. Checks cover RTL world order, reachable offscreen controls, accessible state labels and Android touch-target sizes. SPEC-001 regression coverage includes settings, layout, greeting and finite reduced-motion behavior.

The release APK SHA-256 is `bc5a2017ce359d54bc8b1a3682c2008081ec6df138268c6c888fab1b3efac9e5`. `aapt dump permissions` reported no Internet permission. Android emitted the existing Cupertino icon-font tree-shaking warning. Icons were visible in the sampled Android screens.

## Runtime evidence

The Android 15 tablet emulator exercised the debug journey offline using `adb install -r`, `am start -W`, accessibility labels from `uiautomator dump`, and touch and back input. `dumpsys connectivity` confirmed no active default network. The phone and tablet layouts were captured from the running app with `adb exec-out screencap -p` and exported as WebP with a maximum long edge of 1280 pixels. The phone home uses the release APK. Tablet path, lesson, and expression captures use the explicitly labeled debug fixtures.

| Screen | Capture |
|---|---|
| Adventure map | [Tablet landscape](tablet-landscape-home.webp), [Tablet portrait](tablet-portrait-home.webp), [Phone](mobile-home.webp) |
| Learning worlds | [Faith](world-iman.webp), [Worship](world-ibadah.webp), [Seerah](world-seerah.webp), [Exemplars](world-exemplars.webp) |
| Path and player | [Completed, current, available and locked stops](world-ibadah.webp), [Unlocked path after completion](path-unlocked.webp), [Lesson](lesson-player.webp), [Celebration](lesson-celebration.webp) |
| Mascot and speech | [All six expressions](mascot-expressions.webp), [Offline text fallback](speech-fallback.webp) |
| Public content gate | [World in the release APK](release-world.webp) |

On the Android 9 phone and the offline Android 15 tablet, the release APK opened the real world shell and displayed the Arabic availability message. Starting directly with `am start -W --es route /worlds/iman/lessons/iman-colors` also opened the shell. The Arabic debug fixture title and developer preview were absent from the release flow.

## Observations and release follow-up

The Flutter-painted world art and lantern run locally without downloaded assets. Home, path and lesson transitions ran on the tablet emulator with software graphics. The Android app provided a readable Arabic fallback when its emulator had no eligible installed voice. iOS currently uses that fallback. Physical low-end performance and successful offline Arabic speech with pronunciation review remain SPEC-005 release checks. [Offline speech decision](../../decisions/005-offline-speech-implementation.md) · [Release acceptance criteria](../../../specs/005-release-and-playtest/spec.md)
