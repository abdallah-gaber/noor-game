# 005-05 — Android starter release candidate

Candidate 0.1.1 (Android version code 4), application ID `dev.noor.noor`, tested 27 November 2026. This pilot has six owner-approved introductory lessons, 18 knowledge units and 65 challenge variants across four worlds. The `starter.iman` patch advances from 0.1.1 to 0.1.2. The projection check matched 112 approved records and the exact trusted ledger. [Starter scope](../../curriculum/starter-release.md)

## In-place Android upgrade

On the offline Android 15 tablet emulator, the installed signed baseline (version code 2) completed W05 through the production UI, saved step 2 of I03, disabled effects explicitly, removed the three-day review interval, and opened adaptive and daily rounds. `adb install -r` then installed version code 4 over that app. Both APKs use the dedicated Noor release certificate.

Android accessibility snapshots matched before and after for the saved Arabic reading step, one completed lesson, W05 scores and three stars, 10 XP, audio settings, customized review intervals, historical knowledge-level counts, and the open adaptive and daily rounds. The updated app showed the Arabic What's New note and opened I03, W05, S11 and P10 with no active network. Replay opened a new round. Deferred lesson and developer routes were rejected by the release. [Before update](upgrade-before-history.png) · [After update](upgrade-after-history.png) · [What's New](upgrade-whats-new.png)

## Verification and packaging

| Check | Evidence |
| --- | --- |
| Flutter and Dart | Flutter 3.47.8 and Dart 3.13.7. Format and analysis clean. Full suite passed 104 tests with both private local fixtures enabled. |
| Curriculum and tracker | 20 Python tests passed. The starter projection and canonical public inventory checks passed. The public snapshot includes the reviewed QA allowlist. |
| Android APK | 52.7 MB universal APK. API 24 minimum and API 36 target. ABIs are arm64-v8a, armeabi-v7a and x86_64. APK Signature Scheme v2 and 16 KiB ZIP alignment verified. Rebuild was byte-identical to the device-tested APK. |
| Android App Bundle | 51.5 MB signed AAB. JAR signature verified and certificate matches the APK. |
| Privacy and release scope | Packaged manifest disables backup and has no Internet permission. The only requested permission is the app-scoped AndroidX receiver permission. Six curriculum files and four original effects matched the tracked bytes. Archive inspection found no draft, approval-request or deferred payloads. |
| Accessibility and offline device QA | Signed Android phone and tablet screenshots, including both tablet orientations and enlarged text. Android semantics and targeted accessibility checks passed. The separately identified physical build exercised airplane mode, background/resume, local retention and native playback. [Layouts](005-02-layouts.md) · [Physical smoke](005-06-physical-android.md) |
| iOS | Debug simulator build launched on iPad A16. The unsigned device release build completed at 17.7 MB. [Simulator home](ipad-simulator-home.png) |
| Signing guard | Both `:app:assembleRelease` and `:app:bundleRelease` failed at the signing check when all release inputs were absent. |

The APK SHA-256 is `9fd624f4724c8aa46df4d76e26b79104a25ef3d62b54c7102f6902287e5cd72a`. The AAB SHA-256 is `58ed0ef5397f7406939ec35ceadadfeb1e5eb7274d467d36a155587bdaa30709`.

The Android APK and AAB use the same owner-local release key. Its public SHA-256 certificate fingerprint is `a0d6fa84a61c0d8248baa1b15eb32d6ff67439612c892fe1981471e50c5a873a`. A same-signed update preserves the installed app identity. The original debug-signed pilot uses a different certificate and requires a distinct installation path if its local data must be retained. [Signing and update strategy](../../decisions/007-android-release-signing.md)

The designated low-end Android hardware gate remains open. Speaker comfort and the separate supervised child playtest await owner observations. [Owner playtest](005-04-owner-playtest.md)
