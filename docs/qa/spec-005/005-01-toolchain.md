# 005-01 — Release toolchain

The SPEC-005 base is the regular SPEC-004 merge, `73a52460b4555b496e26b3a179cffd52468afd38`. Its second parent is the reviewed `22696f4e3aa1fb2de9265b796440fddefc457f72`. The remote annotated `spec-004-complete` tag resolves to the merge. The stable Mission Control deployment displayed that SHA.

Flutter 3.47.8 and Dart 3.13.7 matched the repository pins. On the accepted starter, Dart format reported 68 unchanged files, Flutter analysis completed without issues, two starter integration widget tests passed and five Mission Control Python tests passed. The private draft-candidate fixture was unavailable in the default invocation. Release builds now use the dedicated PKCS#12 configuration, and an owner-local key and separate Keychain password were provisioned. APK and update verification belong to 005-05. [Signing decision](../../decisions/007-android-release-signing.md)
