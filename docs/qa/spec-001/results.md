# SPEC-001 verification — 2026-11-26

Implementation revision `fbd8914`. Scope and task order were recorded at `232e34f`. Mobile runners, SDK pins and dependency decisions were committed at `a80b231`.

## Build and automated checks

| Check | Command | Result |
|---|---|---|
| Installed SDK | `flutter --version --machine` | Flutter 3.47.8 stable, framework `737ba8f885dc774b53b442759999a312c9461e4e`, Dart 3.13.7 |
| Locked dependency resolution from a clean archive of `fbd8914` | `flutter pub get --offline --enforce-lockfile` | Passed. Riverpod 3.5.0, GoRouter 18.1.4, sqflite 2.4.2 |
| Formatting | `dart format --output=none --set-exit-if-changed lib test` | Passed, 10 files, zero changes |
| Static analysis | `flutter analyze --no-pub` | Passed, no issues |
| Acceptance tests | `flutter test --no-pub --reporter expanded` | 21 passed, including 12 viewport and text-scale combinations |
| Android build, repeated from the clean archive | `flutter build apk --release --no-pub --target-platform android-arm64` | Passed, 17.2 MB ARM64 APK, min API 24, target API 36 |
| iOS simulator build | `flutter build ios --simulator --no-codesign --no-pub` | Passed, unsigned `Runner.app` |

Test coverage includes Arabic locale and RTL, 600 and 840 logical-pixel breakpoints, horizontal safe insets, labeled and sized Android touch targets, the finite lantern reaction and reduced motion, settings load/save recovery, and debug-preview routing. The matrix exercises 390×844, 600×960, 800×1280 and 1024×768 at text scales 1.0, 1.3 and 2.0. Preference persistence uses the real SQLite plugin in the Android runtime checks below.

Release APK tested on the emulators had SHA-256 `4684da63a68d863bb0fc52aa2bd2df9acde4dee236af26cfa7b9611b23647706`. `aapt dump permissions` confirmed the release manifest lacks Internet permission. Android icon tree shaking reported a Cupertino icon-font warning. The tested Android home and settings had visible icons. The iOS check was build-only.

## Android runtime smoke

Installed the release APK via `adb -s <emulator> install -r` and launched with `adb -s <emulator> shell am start -W -n dev.noor.noor/.MainActivity`. Used `uiautomator dump` to read the accessibility labels and checked states, `input tap` to exercise the controls and `input keyevent KEYCODE_BACK` to return home. Confirmed the debug preview was absent from release home. On both emulators, tapping the greeting changed the mascot’s accessibility label from smiling to happy.

Both installs started with speech off and effects off. Toggling speech, then effects, then speech back off produced the expected independent states after each tap. After `am force-stop dev.noor.noor`, `pidof dev.noor.noor` confirmed the old process had stopped. Relaunching and opening settings confirmed speech off and effects on again. Screenshots came from `adb exec-out screencap -p`.

| Runtime | Display | Evidence |
|---|---|---|
| Pixel 3 AVD, Android 9 (API 28) | 1080×2160 px at 440 dpi, approx. 393×785 logical px, portrait | [Home](pixel-3-home.png), [Settings after relaunch](pixel-3-settings.png) |
| Medium Tablet AVD, Android 15 (API 35), SwiftShader | 2560×1600 px at 320 dpi, 1280×800 logical px, landscape | [Home](tablet-landscape-home.png), [Settings after relaunch](tablet-landscape-settings.png) |
| Same tablet AVD rotated using `adb emu rotate` | 1600×2560 px at 320 dpi, 800×1280 logical px, portrait | [Home](tablet-portrait-home.png). Opened settings and rechecked persisted values. |

Viewport dimensions above describe the full display before safe insets. The tablet was in airplane mode with Wi-Fi disabled before first launch. `dumpsys connectivity` reported `Active default network: none`. Startup, navigation, mascot interaction, SQLite writes, restart and rotation were exercised in that state.

## Owner-reported physical tablet smoke test

The project owner personally tested SPEC-001 on a physical tablet and accepted the foundation. The following ten results are the owner’s report.

| Check | Result |
|---|---|
| Application launches without crashes | Pass |
| Landscape layout | Pass |
| Portrait layout | Pass |
| Arabic text and RTL layout | Pass |
| Smooth Noor mascot animations | Pass |
| Large, comfortable touch targets | Pass |
| Responsive navigation | Pass |
| Audio preferences persist after restarting | Pass |
| Application launches in airplane mode | Pass |
| Application resumes after backgrounding | Pass |

Device model, OS, viewport, photos and performance measurements were not supplied. The emulator captures above retain their original labels. Verification on the child’s low-end Android tablet is a [SPEC-005 release gate](../../../specs/005-release-and-playtest/spec.md).
