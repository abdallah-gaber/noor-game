# 003-04 — Game sessions and lesson completion

Dart formatting, `flutter analyze --no-pub` and all **71 Flutter tests** passed. Coverage includes stable restored candidate order, duplicate submission rejection, save-error recovery, invalid direct routes, one review per first-pass miss, unscored recall, null accuracy for an all-unscored round, mixed-lesson completion gating, unlocks, and replay history.

On the offline Android 15 tablet emulator, opened the labeled mixed lesson, submitted an incorrect answer and force-stopped the app. Reopening restored the same feedback. Completed all five activities and the one review. A read-only copy of the database showed no lesson completion before results; after results, completion and the session were present. Starting replay created a separate session row and retained the first attempt history. Both sessions used preview scope, and approved progress stayed empty. The Android 9 phone emulator also preserved its existing schema 3 preview resume step after upgrading to schema 4.

[Resumed feedback](resumed-feedback.webp) · [Game results](game-results.webp)

The compatibility key includes content version and exact variant definitions. A newer incompatible plan opens a fresh round and preserves history. Unsubmitted selection is transient. The existing reading-only lessons still complete on their final step.
