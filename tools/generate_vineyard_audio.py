"""Original quiet breeze and small bird-like tones; no recordings or speech."""
import math
import random
from generate_memory_audio import RATE, OUT, wind, save

if __name__ == '__main__':
    OUT.mkdir(parents=True, exist_ok=True)
    air = wind()
    for name, seed, level in [('vineyard_rows.wav', 80126, 0.38), ('vineyard_field.wav', 80127, 0.32)]:
        rng = random.Random(seed)
        result = [sample * 0.65 for sample in air]
        for _ in range(7):
            start = rng.randrange(len(result))
            frequency = rng.uniform(1700, 2500)
            for i in range(round(RATE * 0.18)):
                t = i / RATE
                envelope = math.sin(math.pi * t / 0.18) ** 2
                phase = math.tau * (frequency*t + 450*t*t)
                result[(start+i) % len(result)] += 0.014 * envelope * math.sin(phase)
        save(name, result, level)
    print('Generated two original summer breeze/bird ambience loops.')
