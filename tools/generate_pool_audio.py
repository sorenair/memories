"""Original short, restrained acoustic cues for the pool-table component."""
from pathlib import Path
import math
import random
import struct
import wave

DEST = Path(__file__).resolve().parents[1] / "components/activities/bar/audio"
RATE = 24000


def write(name, duration, tones, noise_gain, seed):
    rng = random.Random(seed)
    samples = []
    previous = 0.0
    for index in range(int(duration * RATE)):
        time = index / RATE
        noise = rng.uniform(-1, 1)
        filtered = noise - previous * 0.65
        previous = noise
        attack = min(1.0, time / 0.0008)
        sound = sum(gain * math.sin(math.tau * frequency * time) * math.exp(-decay * time)
                    for frequency, gain, decay in tones)
        sound += filtered * noise_gain * math.exp(-time * 170)
        samples.append(sound * attack)
    peak = max(abs(value) for value in samples) or 1
    DEST.mkdir(parents=True, exist_ok=True)
    with wave.open(str(DEST / f"{name}.wav"), "wb") as target:
        target.setnchannels(1)
        target.setsampwidth(2)
        target.setframerate(RATE)
        target.writeframes(b"".join(struct.pack("<h", int(value / peak * 24500)) for value in samples))


if __name__ == "__main__":
    write("pool_strike", 0.12, [(1600, 0.6, 85), (2900, 0.3, 110), (340, 0.15, 60)], 0.6, 48)
    write("pool_clack", 0.085, [(1950, 0.7, 105), (3180, 0.25, 145)], 0.35, 21)
    write("pool_pocket", 0.19, [(145, 0.7, 25), (310, 0.25, 38)], 0.13, 55)
