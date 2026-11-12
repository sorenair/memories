"""Generate original short arcade cues, with no external recordings or packages."""
from pathlib import Path
import math
import random
import struct
import wave

RATE = 22050
OUT = Path(__file__).resolve().parents[1] / "audio" / "samples"


def save(name, duration, synth):
    samples = []
    for i in range(round(duration * RATE)):
        t = i / RATE
        fade = min(1.0, t / .0015, (duration - t) / .025)
        samples.append(synth(t) * fade)
    scale = .65 / max(abs(s) for s in samples)
    with wave.open(str(OUT / name), "wb") as sound:
        sound.setnchannels(1)
        sound.setsampwidth(2)
        sound.setframerate(RATE)
        sound.writeframes(b"".join(struct.pack("<h", round(s * scale * 32767)) for s in samples))


def launch():
    rng = random.Random(41)
    return lambda t: (
        math.sin(2 * math.pi * (360 * t + 36 * (1 - math.exp(-t * 28)))) * math.exp(-t * 20)
        + .45 * rng.uniform(-1, 1) * math.exp(-t * 80)
    )


def bumper(t):
    return (
        math.sin(2 * math.pi * 880 * t) * math.exp(-t * 24)
        + .35 * math.sin(2 * math.pi * 1420 * t) * math.exp(-t * 38)
    )


def impact():
    rng = random.Random(27)
    low = 0.0

    def sample(t):
        nonlocal low
        low += .22 * (rng.uniform(-1, 1) - low)
        phase = 2 * math.pi * (58 * t + 1.3 * (1 - math.exp(-t * 50)))
        return math.sin(phase) * math.exp(-t * 24) + low * 1.4 * math.exp(-t * 48)
    return sample


def result(t):
    value = 0.0
    for frequency, offset in [(660, 0.0), (880, .13)]:
        age = max(0.0, t - offset)
        envelope = (1 - math.exp(-age * 700)) * math.exp(-age * 24)
        value += math.sin(2 * math.pi * frequency * age) * envelope
    return value


if __name__ == "__main__":
    OUT.mkdir(parents=True, exist_ok=True)
    save("pinball_launch.wav", .28, launch())
    save("pinball_bumper.wav", .20, bumper)
    save("punch_impact.wav", .28, impact())
    save("arcade_result.wav", .44, result)
    print("Generated pinball launch/bumper, punch impact, and arcade result cues.")
