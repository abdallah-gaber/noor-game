# 004-02 physical-tablet pilot follow-up

The owner accepted the home and world navigation, lesson presentation and length, Arabic typography, results, and responsiveness. This checkpoint addresses the reported silent audio and hard-to-find matching and ordering.

## Finding and change

- The installed APK hash matched the first private pilot. Its settings database had no saved sound preferences, so speech and effects each used their off default. Speech is on demand through **استمع**. The original build displayed an effects switch without a playback backend.
- On the ROD2_W09 Android 16 tablet, the media stream was unmuted at 11/15 and routed to the speaker. Google Text-to-Speech reported nine Arabic voices and zero installed offline Arabic voices. A pilot speech test failed gracefully and displayed the voice setup instructions.
- Both authored activities were in position four of the existing round. The pilot now also offers a quick practice button on each relevant lesson. Quick practice reuses the arrangement activity and writes no progress. Normal lesson, question, approval and preview storage rules still apply.
- Four original offline foley cues are generated from enveloped noise, without samples, instruments or melody. The four WAV files total 21,560 bytes. A subtle tap acknowledges interactions, a double sound marks a correct answer, a soft single sound accompanies an incorrect answer, and a short flutter signals lesson completion. The effects setting controls playback. The Android sound player uses one stream, stops effects before speech, and suppresses effects while a narration request is active. [Source for the generated sounds](../../../scripts/generate_pilot_effects.py)

## Manual retest

Open **نور — مراجعة البالغين**, then tap **أنا بالغ وأريد مراجعة المسودات**.

| Mechanic | Steps |
|---|---|
| Ordering | **عالم العبادة** → **كيف نتوضأ؟** (W06) → **جرّب الترتيب**. Tap all five items in sequence, then tap **تحقّق**. Tap a selected item again to remove it before checking. |
| Matching | **عالم السيرة** → **المسلمون في المدينة** (S11) → **جرّب المطابقة**. Tap a target in the first group, then its match in the second group. Pair all items and tap **تحقّق**. |
| Full rounds | From either lesson, tap **التالي** through the reading until **إلى التحدّيات** appears. Answer the multiple-choice and true/false questions, advancing with **التالي** after each. For the flashcard, tap **اكشف الإجابة**, choose **تذكّرت** or **أريد المراجعة**, and tap **التالي** again. Ordering or matching is activity 4 of 4. For an already completed round, tap **أعد التحدّيات** to replay. Go through any retry items and tap **النتيجة** to hear the completion cue. |
| Effects | Under **الإعدادات**, turn on **المؤثّرات الصوتية** and tap **جرّب المؤثّر الصوتي**. Check a correct answer, an incorrect answer, item selection and completion. |

To enable offline Arabic speech, open Android **Settings → Accessibility → Text-to-speech output**. Use the gear beside Google’s engine, select **Install voice data → Arabic**, and install an offline voice if offered. Use the Android **Play** sample. In Noor **الإعدادات**, turn on **القراءة الصوتية** and tap **استمع** under **اختبار القراءة العربية**. Test once with Wi-Fi off to confirm offline operation. If the engine offers no downloadable Arabic voice, the pilot keeps text available and effects can still play. [Android text-to-speech setup](https://support.google.com/accessibility/android/answer/6006983?hl=en)

## Verification

- Static analysis passed. The 45 targeted tests passed with the actual local pilot payload, including both authored routes, feedback events, effects preference, speech fallback, progress isolation and production approval regressions.
- The Android debug APK installed over the existing adult-review package. The speech and effects switches were enabled in the pilot for this check. Both practice activities opened through ordinary tablet navigation. Android reported successful SoundPool streams for a correct match, the gentle retry after incorrect ordering, and selection taps, as well as the settings effect sample. Subjective loudness and the offline Arabic pronunciation still need an owner listening check.
