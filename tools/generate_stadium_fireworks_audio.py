"""Generate the original stadium firework cues using only the standard library."""
from array import array
from math import exp, pi, sin
from pathlib import Path
from random import Random
import sys
import wave

RATE = 24000
OUT = Path(__file__).resolve().parents[1] / "audio" / "samples"


def save(name, samples, peak):
    scale = peak * 32767 / max(abs(value) for value in samples)
    pcm = array("h", (round(value * scale) for value in samples))
    if sys.byteorder != "little":
        pcm.byteswap()
    with wave.open(str(OUT / name), "wb") as stream:
        stream.setparams((1, 2, RATE, 0, "NONE", "not compressed"))
        stream.writeframes(pcm.tobytes())


def launch():
    random = Random(61)
    phase = low = previous = 0.0
    for index in range(round(0.8 * RATE)):
        t = index / RATE
        noise = random.uniform(-1.0, 1.0)
        low += (noise - low) * 0.075
        phase += 2 * pi * (270 + 940 * (t / 0.8) ** 1.3) / RATE
        pop = (0.65 * low + 0.40 * sin(2 * pi * 81 * t)) * exp(-t * 48)
        tail = (0.29 * sin(phase + low * 0.48) + 0.58 * (noise - previous)) * exp(-t * 2.1)
        previous = noise
        yield (pop + tail) * min(1.0, t / 0.003, (0.8 - t) / 0.07)


def burst():
    random = Random(127)
    length = round(1.55 * RATE)
    samples = [0.0] * length
    low = mid = 0.0
    for index in range(length):
        t = index / RATE
        noise = random.uniform(-1.0, 1.0)
        low += (noise - low) * 0.025
        mid += (noise - mid) * 0.24
        thump = 0.68 * sin(2 * pi * (48 * t + 3.0 * (1.0 - exp(-t * 20)))) * exp(-t * 12)
        body = 1.55 * low * exp(-t * 8) + (noise - mid) * exp(-t * 59) * 0.85
        samples[index] = (thump + body) * min(1.0, t / 0.003)
    for _ in range(47):
        t = random.uniform(0.075, 1.25)
        start = round(t * RATE)
        gain = random.uniform(0.035, 0.21) * exp(-t * 1.5)
        for offset in range(round(0.036 * RATE)):
            samples[start + offset] += random.uniform(-gain, gain) * exp(-offset / 130)
    # A quiet stadium reflection gives the report some distance.
    direct = samples.copy()
    for time, gain in [(0.16, 0.14), (0.33, 0.08)]:
        delay = round(time * RATE)
        for index in range(delay, length):
            samples[index] += direct[index - delay] * gain
    return samples


if __name__ == "__main__":
    save("stadium_firework_launch.wav", list(launch()), 0.64)
    save("stadium_firework_burst.wav", burst(), 0.84)
