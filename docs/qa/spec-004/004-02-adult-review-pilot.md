# 004-02 adult-review pilot

Verified 27 November 2026. This is a private Android debug build for adult review of unverified drafts.

| World | Selected lesson | Included activities |
|---|---|---|
| Worship | W06 · كيف نتوضأ؟ | Authored practical activity, choice, true/false, flashcard and CONTENT-007 ordering |
| Faith | I03 · لمن تكون العبادة؟ | Choice, true/false, flashcard and a same-lesson CONTENT-007 choice |
| Seerah | S11 · المسلمون في المدينة | Choice, true/false, flashcard and CONTENT-007 matching |
| Exemplars | P01 · أبو بكر الصديق | Choice, true/false and flashcard |

The local adapter matched all five CONTENT-007 input digests, including CONTENT-006. It selected three core variants per lesson and three same-lesson additions for 15 total. The projection preserves lesson, unit, knowledge, variant, option and source identities. Draft wording and open review findings remain as authored. CONTENT-006 extras and cross-lesson activities stay in the authoring track. The standard entry point and production activation still require the existing approval gate. Pilot reading and attempts use preview storage in a separate Android application.

## Launch on Android

Open **نور — مراجعة البالغين** and select **أنا بالغ وأريد مراجعة المسودات**. The worship world appears first for a quick start with W06. Advance through the authored reading and practical activity, then choose **إلى التحدّيات**. Try Arabic speech, ordering, and stopping and reopening to resume. Visit the other three worlds and try matching in S11. Choose **إنهاء مراجعة المسودات** from the pilot home to return to the adult gate.

To rebuild from the local draft files:

```sh
python3 scripts/prepare_draft_pilot.py
ORG_GRADLE_PROJECT_noorAdultReview=true flutter build apk --debug --no-pub \
  -t lib/pilot_main.dart --dart-define-from-file=.dart_tool/noor-pilot/defines.json
adb -d install -r build/app/outputs/flutter-apk/app-debug.apk
adb -d shell am start -n dev.noor.noor.adultreview/dev.noor.noor.MainActivity
```

The generated payload and APK are local ignored files. Keep the pilot APK private because it contains unverified authoring text.

## Verification

- `flutter analyze --no-pub` passed with no issues.
- The 16 focused Flutter tests passed across `draft_pilot_test.dart`, `curriculum_packs_test.dart`, `game_journey_test.dart` and `scored_question_test.dart`. The local-payload test decoded all four selected lessons. The tests also cover draft identity, the adult route gate and re-lock, preview-only saves, child routing, and production approval and game regressions.
- The Android debug build installed on the connected ROD2_W09 tablet as `dev.noor.noor.adultreview`. Android accepted the launch. The secure lock screen prevented seeing the Flutter UI during the physical-device check.
