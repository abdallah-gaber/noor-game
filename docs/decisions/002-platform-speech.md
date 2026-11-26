# ADR 002 — Evaluate platform speech before enabling playback

Accepted for SPEC-001. Persist speech and non-musical effects preferences independently, off by default. Keep the foundation text-only and avoid initializing or shipping a speech plugin for unused functionality.

Evaluate flutter_tts in SPEC-002 for Android and iOS. Android offers installed-language checks, but offline eligibility also depends on the selected voice and its features. Explicitly verify an installed Arabic voice runs offline before enabling playback. Use the platform Android voice metadata when the plugin cannot establish offline eligibility. Confirm iOS offline behavior separately. Keep visible Arabic text available when a suitable voice is absent or playback fails. Voice downloads remain a user action. [flutter_tts](https://pub.dev/packages/flutter_tts) · [Android Voice](https://developer.android.com/reference/android/speech/tts/Voice)
