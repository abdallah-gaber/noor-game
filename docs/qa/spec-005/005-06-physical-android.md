# 005-06 — Connected Android tablet smoke test

Tested a HUAWEI ROD2-W09 tablet running Android 16 with SM8635, arm64 and approximately 11 GiB usable RAM. The connected device has sufficient resources for a hardware compatibility check. The designated low-end tablet was unavailable.

The signed arm64 release build used version code 3 and the QA-only `dev.noor.noor.deviceqa` ID. Android can run it alongside the existing debug-signed pilot. The physical pilot’s app data was left intact. The original network and rotation settings were restored after the test.

Airplane mode and no active default network were verified. ADB and Android accessibility checks covered a cold launch (Android reported 310 ms), the home greeting, world and lesson navigation, going to the next reading step, rotation, background/resume, a force-stop and cold reopen with the saved step, and an effects toggle that remained off after restart. Android audio diagnostics recorded the game SoundPool starting in the lesson and settings. This run measured functional response on the connected hardware. It leaves speaker comfort and low-end frame pacing for hands-on verification.

[Portrait lesson](physical-portrait-lesson.png) · [Landscape lesson](physical-landscape-lesson.png) · [Effects evidence](005-03-effects.md)
