#!/usr/bin/env python3
"""Create Noor's original offline foley cues from enveloped noise."""

from pathlib import Path
from random import Random
import struct
import wave

RATE = 16000
OUT = Path(__file__).resolve().parents[1] / "android/app/src/main/res/raw"
# Each tuple is (offset, duration, level, smoothing). No melody or instruments.
CUES = {
    "tap": [(0, .045, .24, .32)],
    "correct": [(0, .064, .63, .30), (.076, .100, .48, .46)],
    "retry": [(0, .148, .66, .14)],
    "complete": [(0, .081, .56, .24), (.084, .085, .55, .35), (.174, .125, .50, .47)],
}

for cue, gestures in CUES.items():
    samples = [0.0] * (round(max(start + duration for start, duration, *_ in gestures) * RATE) + 1)
    rng = Random(cue)
    for start, duration, level, smoothing in gestures:
        state = 0.0
        count = round(duration * RATE)
        for i in range(count):
            state += smoothing * (rng.uniform(-1, 1) - state)
            envelope = min(i / 80, 1) * (1 - i / count) ** 1.7
            samples[round(start * RATE) + i] += state * level * envelope
    with wave.open(str(OUT / f"noor_{cue}.wav"), "wb") as audio:
        audio.setparams((1, 2, RATE, 0, "NONE", "not compressed"))
        audio.writeframes(struct.pack(f"<{len(samples)}h", *(round(value * 32767) for value in samples)))
