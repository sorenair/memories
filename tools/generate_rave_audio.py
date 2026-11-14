"""Original 120 BPM electronic placeholder loop; no borrowed music or recordings."""
import math
import random
from generate_memory_audio import RATE, OUT, save

BEAT = 0.5
LENGTH = 16.0

def hz(midi):
    return 440 * 2 ** ((midi - 69) / 12)


def make_music():
    result = [0.0] * round(RATE * LENGTH)
    rng = random.Random(311225)
    def add(start, duration, sample):
        for index in range(round(duration * RATE)):
            t = index / RATE
            result[(round(start * RATE) + index) % len(result)] += sample(t, index)
    # A soft four-on-the-floor kick, a dry clap and restrained offbeat hats.
    for beat in range(32):
        add(beat * BEAT, 0.35,
            lambda t, _: 0.34 * math.sin(2 * math.pi * (52 * t + 2.0 * (1 - math.exp(-30 * t))))
            * (1 - math.exp(-t * 220)) * math.exp(-t * 15))
        add((beat + 0.5) * BEAT, 0.10,
            lambda t, _: rng.uniform(-1, 1) * 0.040 * math.exp(-t * 65) * (1 - math.exp(-t * 600)))
        if beat % 2:
            add(beat * BEAT, 0.16,
                lambda t, _: rng.uniform(-1, 1) * 0.065 * math.exp(-t * 35) * (1 - math.exp(-t * 400)))
    progression = [45, 45, 43, 43, 48, 48, 41, 41]
    for bar, root in enumerate(progression):
        for step in range(8):
            start = bar * 2.0 + step * 0.25
            bass = hz(root + (12 if step % 4 == 3 else 0))
            add(start, 0.23, lambda t, _, f=bass: 0.12 * (math.sin(2 * math.pi * f * t)
                + 0.13 * math.sin(2 * math.pi * f * 2 * t)) * (1 - math.exp(-t * 100)) * math.exp(-t * 14))
            pitch = hz(root + 24 + [0, 7, 3, 10, 7, 12, 10, 3][step])
            add(start + 0.018, 0.65, lambda t, _, f=pitch: 0.050 * (math.sin(2 * math.pi * f * t)
                + 0.15 * math.sin(2 * math.pi * f * 2 * t)) * (1 - math.exp(-t * 75)) * math.exp(-t * 7))
        for interval in [0, 3, 7]:
            tone = hz(root + 12 + interval)
            add(bar * 2.0, 2.5, lambda t, _, f=tone: 0.025 * math.sin(2 * math.pi * f * t)
                * min(1, t / 0.18) * max(0, min(1, (2.5 - t) / 0.6)))
    return result


if __name__ == '__main__':
    OUT.mkdir(parents=True, exist_ok=True)
    save('new_years_eve_electronic.wav', make_music(), 0.55)
    print('Generated original 16-second, 120 BPM electronic concert loop.')
