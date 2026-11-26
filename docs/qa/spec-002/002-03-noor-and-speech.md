# 002-03 — Noor and speech

Formatting and `flutter analyze --no-pub` passed. `flutter test --no-pub --reporter expanded` passed 40 tests, covering the [six-expression golden](../../../test/goldens/noor-expressions.png), inactivity and reduced motion, preference gating, explicit read and stop actions, cancellation on step change and back navigation, localized fallback, and the platform channel contract.

The Android debug APK compiled the Kotlin bridge. On the offline Android 15 tablet emulator, used `uiautomator dump` to verify all six labels in the developer gallery. Enabled the saved speech preference in settings, opened a non-religious preview lesson, and tapped the listen button. The platform path returned the Arabic unavailable message and kept the lesson text present. `dumpsys connectivity` confirmed no active default network.

[Six expressions in the app](mascot-expressions.webp) · [Offline text fallback](speech-fallback.webp) · [Decision record](../../decisions/005-offline-speech-implementation.md)

Successful synthesis with an installed offline Arabic voice and pronunciation quality remain physical-device checks. iOS uses the text fallback. The low-end tablet and offline audio release gates are in SPEC-005.
