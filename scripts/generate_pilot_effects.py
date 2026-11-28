#!/usr/bin/env python3
"""Create Noor's short offline foley cues with enveloped, filtered noise."""

from math import cos, pi, tanh
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


# W06 uses filtered noise only. The short wooden, water and paper gestures
# have softer transients and more sustained energy than the original pilot.
ADVENTURE = {
    "pickup": (.72, .009, [(0, .085, 1, .36, .085)]),
    "place": (.80, .012, [(0, .116, 1, .24, .047), (.040, .069, .44, .47, .09)]),
    "splash": (.86, .013, [
        (0, .17, 1, .57, .09), (.062, .128, .71, .34, .046), (.137, .107, .49, .48, .08),
    ]),
    "wipe": (.76, .027, [(0, .19, 1, .22, .045), (.090, .109, .58, .36, .09)]),
    "retry": (.60, .036, [(0, .172, 1, .125, .031)]),
    "finish": (.85, .012, [
        (0, .145, 1, .23, .047), (.097, .146, .92, .46, .096), (.221, .161, .84, .39, .055),
    ]),
    "reveal": (.86, .013, [
        (0, .128, 1, .20, .045), (.081, .132, .74, .31, .105),
        (.165, .154, .84, .44, .063), (.287, .185, .63, .60, .103),
    ]),
}


def write_cue(name, peak, gestures, *, attack_seconds=None, soft_drive=None):
    length = round(max(start + duration for start, duration, *_ in gestures) * RATE)
    samples = [0.0] * (length + 1)
    rng = Random(name)
    for start, duration, weight, fast, slow in gestures:
        first = round(start * RATE)
        count = round(duration * RATE)
        attack = round((attack_seconds or (.022 if name == "retry" else .009)) * RATE)
        fast_state = slow_state = 0.0
        for i in range(count):
            noise = rng.uniform(-1, 1)
            fast_state += fast * (noise - fast_state)
            slow_state += slow * (noise - slow_state)
            rise = (1 - cos(pi * min(i / attack, 1))) / 2
            decay = (1 + cos(pi * i / count)) / 2
            samples[first + i] += (fast_state - slow_state) * weight * rise * decay
    if soft_drive is not None:
        maximum = max(map(abs, samples))
        samples = [tanh(value * soft_drive / maximum) for value in samples]
    scale = peak * 32767 / max(map(abs, samples))
    pcm = [round(value * scale) for value in samples]
    with wave.open(str(OUT / f"noor_{name}.wav"), "wb") as audio:
        audio.setparams((1, 2, RATE, 0, "NONE", "not compressed"))
        audio.writeframes(struct.pack(f"<{len(pcm)}h", *pcm))


if __name__ == "__main__":
    OUT.mkdir(parents=True, exist_ok=True)
    for cue, (peak, gestures) in CUES.items():
        write_cue(cue, peak, gestures)
    for cue, (peak, attack, gestures) in ADVENTURE.items():
        write_cue(f"wudu_{cue}", peak, gestures, attack_seconds=attack, soft_drive=1.9)
