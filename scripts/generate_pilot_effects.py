#!/usr/bin/env python3
"""Create Noor's short offline foley cues with enveloped, filtered noise."""

from math import cos, pi
from pathlib import Path
from random import Random
import struct
import wave

RATE = 24000
OUT = Path(__file__).resolve().parents[1] / "assets/audio"
# Peak amplitude and gestures (offset, duration, weight, fast/slow smoothing).
# The different patterns resemble a soft click, two bright pops, a muted
# brush, and a longer burst of paper confetti. There are no pitched notes.
CUES = {
    "tap": (.54, [(0, .066, 1, .24, .035)]),
    "correct": (.68, [(0, .09, 1, .24, .040), (.105, .125, .95, .43, .080)]),
    "retry": (.40, [(0, .158, 1, .13, .022)]),
    "complete": (.71, [
        (0, .105, 1, .16, .030),
        (.086, .120, .93, .29, .042),
        (.176, .160, .92, .38, .055),
    ]),
}


def write_cue(name, peak, gestures):
    length = round(max(start + duration for start, duration, *_ in gestures) * RATE)
    samples = [0.0] * (length + 1)
    rng = Random(name)
    for start, duration, weight, fast, slow in gestures:
        first = round(start * RATE)
        count = round(duration * RATE)
        attack = round((.022 if name == "retry" else .009) * RATE)
        fast_state = slow_state = 0.0
        for i in range(count):
            noise = rng.uniform(-1, 1)
            fast_state += fast * (noise - fast_state)
            slow_state += slow * (noise - slow_state)
            rise = (1 - cos(pi * min(i / attack, 1))) / 2
            decay = (1 + cos(pi * i / count)) / 2
            samples[first + i] += (fast_state - slow_state) * weight * rise * decay
    scale = peak * 32767 / max(map(abs, samples))
    pcm = [round(value * scale) for value in samples]
    with wave.open(str(OUT / f"noor_{name}.wav"), "wb") as audio:
        audio.setparams((1, 2, RATE, 0, "NONE", "not compressed"))
        audio.writeframes(struct.pack(f"<{len(pcm)}h", *pcm))


if __name__ == "__main__":
    OUT.mkdir(parents=True, exist_ok=True)
    for cue, (peak, gestures) in CUES.items():
        write_cue(cue, peak, gestures)
