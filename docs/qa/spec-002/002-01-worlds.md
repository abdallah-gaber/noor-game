# 002-01 — Map and paths

Flutter 3.47.8 / Dart 3.13.7. Formatting and `flutter analyze --no-pub` passed. `flutter test --no-pub --reporter expanded` passed 30 tests, including the updated SPEC-001 layout matrix, world and lesson route policies, prerequisite logic and the [world artwork golden](../../../test/goldens/world-environments.png). The golden is an automated rendering baseline.

`flutter build apk --debug --no-pub --target-platform android-arm64` passed. Installed with `adb install -r`, started the app with `am start -W`, and read accessibility labels via `uiautomator dump`. On the tablet emulator, each of the four world links opened its named path, labeled developer preview and all four explicit lesson states. The tablet was in airplane mode with no active default network. Rotated using `adb emu rotate` and checked that home stayed reachable. The phone opened the compact, scrollable map.

[Tablet landscape](tablet-landscape-home.webp) · [Tablet portrait](tablet-portrait-home.webp) · [Phone](mobile-home.webp) · [Faith](world-iman.webp) · [Worship](world-ibadah.webp) · [Seerah](world-seerah.webp) · [Exemplars](world-exemplars.webp)

Evidence was captured from the Pixel 3 Android 9/API 28 emulator (1080×2160 px at 440 dpi) and Medium Tablet Android 15/API 35 emulator (2560×1600 or 1600×2560 px at 320 dpi). Layout images were captured via `adb exec-out screencap -p` and exported as metadata-stripped WebP at up to 1280 px on the long edge. Later task builds may update the linked captures. Low-end physical performance belongs to SPEC-005.
