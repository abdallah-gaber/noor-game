# 005-05 — Release branding follow-up

Verified the signed 0.1.1 APK, Android version code 5, on 27 November 2026. The package is `dev.noor.noor` and the production label is **نور**. The release certificate matches build 4. The APK SHA-256 is `196e353c604f4a444877744cbdb4eaaed73e1bb9cce6d7c0bbb33db055896b83`.

The launcher uses the smiling Noor lantern in warm gold and deep green, with Android adaptive, legacy, round and monochrome assets. Android 12+ uses the native splash attributes. Earlier releases use a centered bitmap in the starting window. The normal Flutter window and both iOS storyboards use the same warm ivory as Noor’s home screen. The native launch screens follow first-frame readiness.

The iOS simulator build compiled the asset catalog and launch storyboard. All 15 AppIcon entries matched the declared pixel dimensions and used opaque RGB. The compiled display name is نور. The five targeted Flutter tests and Dart analysis passed. All six packaged curriculum files matched build 4 byte for byte, and the approval projection check passed.

Cold-launch captures on Android 9 and Android 15 show the lantern splash followed by the Noor home screen. The sampled frames showed the warm background through the handoff. The Android 15 emulator accepted an in-place update from build 4 and retained the saved lesson step and explicit effects opt-out. The physical tablet was unavailable to ADB during this branding follow-up.

[Android 9 splash](android-9-noor-splash.png) · [Android 15 splash](android-15-noor-splash.png)
