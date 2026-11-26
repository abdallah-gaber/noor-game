# 002-02 — Lesson player, migration and resume

Formatting and `flutter analyze --no-pub` passed. `flutter test --no-pub --reporter expanded` passed 33 tests. Added coverage for advancing and going back, restoring the saved step in a fresh app scope, retrying a failed save, unlocking after completion, replay and content-version change behavior.

Built the debug APK with `flutter build apk --debug --no-pub --target-platform android-arm64`. On the offline Android 15 tablet emulator, advanced the fixture lesson to its second step, force-stopped the app, relaunched and reopened the lesson at step two. Completed the lesson and verified with `uiautomator dump` that the path labeled it complete and enabled the previously locked stop. A second force-stop and relaunch preserved both outcomes. [Resumed player](lesson-player.webp) · [Unlocked path](path-unlocked.webp)

On the Pixel 3 Android 9 emulator, copied Noor’s debug app-private SQLite database and its WAL/SHM files using `adb exec-out run-as` before and after updating with `adb install -r`. Read the copies locally in SQLite read-only mode. Before updating, the schema version was 1 with speech off and effects on. After opening settings in the new build, the schema version was 2 with the same preference row and a new, empty lesson progress table. The checked states also matched in the app.
