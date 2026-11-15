"""Original quiet winter air and soft fire crackles, without borrowed recordings."""
import math
import random
from generate_memory_audio import RATE, OUT, save, wind

if __name__ == '__main__':
    OUT.mkdir(parents=True, exist_ok=True)
    air = wind()
    result = [sample * 0.42 for sample in air]
    rng = random.Random(21026)
    for _ in range(125):
        start = rng.randrange(len(result))
        duration = rng.uniform(0.025, 0.095)
        gain = rng.uniform(0.02, 0.07)
        for i in range(round(duration * RATE)):
            t = i / RATE
            result[(start + i) % len(result)] += rng.uniform(-1, 1) * gain * (
                1 - math.exp(-t * 600)) * math.exp(-t * 85)
    save('cabin_clearing.wav', result, 0.42)
    print('Generated an original twenty-second winter-air/fire bed.')
