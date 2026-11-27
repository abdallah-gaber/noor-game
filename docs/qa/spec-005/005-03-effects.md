# 005-03 — Offline effects and readable Arabic

The signed Android audio checkpoint (version code 3) ships four original, single-stream foley cues. PCM peaks measured −5.4 dBFS for tap, −3.3 dBFS for correct, −8.0 dBFS for retry and −3.0 dBFS for completion. Cues last 66–336 ms and start and end at zero. The retry uses a slower attack and has the lowest RMS level. No music or narration assets are included.

On Android 9 with no active network, a fresh install enabled effects and left speech off. Android audio diagnostics recorded the app’s game SoundPool entering the started state after pressing the preview button. Disabling effects, force-stopping and reopening settings left the preview disabled. The approved lesson remained readable with speech off. [Settings on the signed build](phone-audio-settings.png)

The 32 focused Flutter checks exercised the production lesson/game cues, saved defaults and opt-out, pilot retry, and speech fallback. Physical speaker audibility and comfort are recorded separately from PCM and native playback evidence.

The connected Android 16 tablet also entered native playback for the lesson tap and the settings preview while in airplane mode. The isolated app retained the saved opt-out after a cold restart. [Physical hardware run](005-06-physical-android.md)

Compared with the prior pilot cues at their native playback gain, effective RMS increased by 7.0 dB for retry, 8.6 dB for completion, 8.8 dB for correct and 15.8 dB for tap.
