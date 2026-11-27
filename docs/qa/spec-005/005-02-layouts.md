# 005-02 — Android layouts and accessibility

Captured from the signed 0.1.0 (version code 2) baseline at the SPEC-005 signing checkpoint. Android 9 Pixel 3 emulator, 1080 × 2160 at 440 dpi, and Android 15 Medium Tablet emulator, 1600 × 2560 in portrait and 2560 × 1600 in landscape at 320 dpi. Both emulators reported no active default network. The actual app rendered RTL home and lesson content and exposed readable Arabic labels through Android accessibility. The phone settings screenshot used system font scale 2.0.

- [Phone home](phone-home.png) · [Phone lesson](phone-lesson.png) · [Phone settings at increased text size](phone-large-text-settings.png)
- [Tablet home](tablet-home.png) · [Tablet portrait lesson](tablet-lesson.png) · [Tablet landscape lesson](tablet-landscape-lesson.png)

`flutter test --no-pub test/journey_accessibility_test.dart test/game_accessibility_test.dart` passed all 19 checks for navigation, lesson rendering and activity layouts, including large text and labeled touch targets. `flutter analyze --no-pub` passed.
