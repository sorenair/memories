"""Original placeholder wind and fragment cue; Python standard library only.

Replace these with finished sound design as needed. No third-party recordings.
"""
from pathlib import Path
import math
import random
import struct
import wave

RATE = 22050
OUT = Path(__file__).resolve().parents[1] / "audio" / "samples"


def save(name, samples, peak):
    scale = peak / max(abs(s) for s in samples)
    with wave.open(str(OUT / name), "wb") as sound:
        sound.setnchannels(1)
        sound.setsampwidth(2)
        sound.setframerate(RATE)
        sound.writeframes(b"".join(struct.pack("<h", round(s * scale * 32767)) for s in samples))


def wind():
    count = RATE * 20
    rng = random.Random(1211)
    noise = [rng.uniform(-1, 1) for _ in range(count)]
    fast = slow = 0.0
    result = []
    # Repeat the noise through the filters to settle their periodic boundary state.
    for cycle in range(2):
        for index, sample in enumerate(noise):
            fast += 0.12 * (sample - fast)
            slow += 0.012 * (sample - slow)
            if cycle:
                phase = 2 * math.pi * index / count
                breath = 0.7 + 0.13 * math.sin(phase) + 0.09 * math.sin(3 * phase + 0.8)
                result.append((fast - slow) * breath)
    return result


def chime():
    result = []
    for index in range(int(RATE * 1.2)):
        t = index / RATE
        value = 0.0
        for frequency, offset, gain in [(659.255, 0.0, 1.0), (987.767, 0.09, 0.45)]:
            elapsed = max(0.0, t - offset)
            envelope = (1 - math.exp(-elapsed * 100)) * math.exp(-elapsed * 7)
            value += gain * envelope * (math.sin(2 * math.pi * frequency * elapsed)
                                       + 0.12 * math.sin(2 * math.pi * frequency * 2 * elapsed))
        value *= min(1.0, (1.2 - t) / 0.06)
        result.append(value)
    return result


def arcade_hum():
    # A quiet cabinet/room tone with a periodic envelope, beneath the game cues.
    air = wind()
    return [
        sample * 0.45 + 0.025 * math.sin(2 * math.pi * 120 * index / RATE)
        + 0.008 * math.sin(2 * math.pi * 240 * index / RATE)
        for index, sample in enumerate(air)
    ]


if __name__ == "__main__":
    OUT.mkdir(parents=True, exist_ok=True)
    save("autumn_wind.wav", wind(), 0.65)
    save("fragment_chime.wav", chime(), 0.55)
    save("arcade_hum.wav", arcade_hum(), 0.45)
    print("Generated wind and arcade ambience loops, and a fragment chime.")
