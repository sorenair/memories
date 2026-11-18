"""Original quiet winter air and soft fire crackles, without borrowed recordings."""
import math
import random
from generate_memory_audio import RATE, OUT, save, wind

def add_crackles(result, count):
    rng = random.Random(21026)
    for _ in range(count):
        start = rng.randrange(len(result))
        duration = rng.uniform(0.025, 0.095)
        gain = rng.uniform(0.02, 0.07)
        for i in range(round(duration * RATE)):
            t = i / RATE
            result[(start + i) % len(result)] += rng.uniform(-1, 1) * gain * (
                1 - math.exp(-t * 600)) * math.exp(-t * 85)


if __name__ == '__main__':
    OUT.mkdir(parents=True, exist_ok=True)
    bed = [sample * 0.42 for sample in wind()]
    add_crackles(bed, 125)
    save('cabin_clearing.wav', bed, 0.42)

    fire = [0.0] * (RATE * 12)
    add_crackles(fire, 76)
    save('cabin_fire_crackle.wav', fire, 0.62)
    print('Generated the winter-air/fire bed and a separate campfire loop.')
