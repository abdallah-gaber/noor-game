# ADR 005 — On-demand platform speech and lantern reactions

SPEC-002 uses a small Android method-channel bridge and the platform service. A read requires the saved speech preference and a tap. The bridge selects an Arabic voice only when its metadata reports local execution and does not flag missing voice data. Changing step, leaving the route, interrupting the app or tapping stop cancels the current request. The app never initiates a voice download and ships no recorded audio or third-party speech plugin. [Android offline voice metadata](https://developer.android.com/reference/android/speech/tts/Voice) · [Android engine features](https://developer.android.com/reference/android/speech/tts/TextToSpeech.Engine)

When no eligible voice is available, the Arabic text stays visible and the interface announces that speech is unavailable. iOS uses the same fallback pending device verification of offline Arabic voice availability. The choice keeps the core usable offline and keeps the audio surface small. Non-musical effects retain their independent preference for later content.

Noor reuses the original painted lantern frame. Facial geometry distinguishes six moods. Brief greeting and completion reactions play once, stop when inactive, and render without movement when reduced motion is selected. No bitmap asset or animation library is needed.
