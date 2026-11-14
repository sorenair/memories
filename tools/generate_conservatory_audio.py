"""Original placeholder water and foliage beds; no recorded/library samples."""
import math
import random
from generate_memory_audio import RATE, OUT, save, wind


def beds():
    air = wind()  # Periodic, filtered noise, twenty seconds.
    water = [0.0] * len(air)
    rng = random.Random(140126)
    # Wrap short droplets at the seam so the bed can loop without a fade to silence.
    for _ in range(160):
        start = rng.randrange(len(air))
        frequency = rng.uniform(650, 1900)
        gain = rng.uniform(0.008, 0.030)
        for i in range(round(RATE * 0.10)):
            t = i / RATE
            water[(start + i) % len(air)] += gain * math.sin(
                2 * math.pi * (frequency * t - frequency * 1.4 * t * t)
            ) * (1 - math.exp(-t * 350)) * math.exp(-t * 48)
    fountain, jungle = [], []
    for i, a in enumerate(air):
        phase = math.tau * i / len(air)
        fountain.append(a * (0.85 + 0.08 * math.sin(phase * 3)) + water[i])
        jungle.append(a * (0.40 + 0.11 * math.sin(phase * 2 + 0.4))
                      + water[i] * (0.20 + 0.08 * math.sin(phase)))
    return fountain, jungle


if __name__ == '__main__':
    OUT.mkdir(parents=True, exist_ok=True)
    fountain, jungle = beds()
    save('conservatory_fountain.wav', fountain, 0.42)
    save('conservatory_jungle.wav', jungle, 0.32)
    print('Generated two original twenty-second conservatory ambience loops.')
