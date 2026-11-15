"""Original sunny block-party groove and outdoor crowd bed. Standard library only."""
import math
import random
from generate_memory_audio import RATE, OUT, save, wind
from generate_museum_audio import room


def groove():
    # Eight original bars at 112 BPM; every event wraps into the loop.
    beat = 60 / 112
    length = round(32 * beat * RATE)
    result = [0.0] * length
    rng = random.Random(42526)

    def event(start, duration, synth):
        for i in range(round(duration * RATE)):
            result[(round(start * RATE) + i) % length] += synth(i / RATE)

    for b in range(32):
        event(b * beat, 0.24, lambda t: 0.32 * math.sin(2 * math.pi * (48*t + 2.0*(1-math.exp(-t*24)))) * math.exp(-t*20))
        if b % 4 in (1, 3):
            event(b * beat, 0.14, lambda t: rng.uniform(-1, 1) * 0.12 * math.exp(-t*32))
        for off in (0, 0.5):
            event((b+off)*beat, 0.055, lambda t: rng.uniform(-1, 1) * 0.045 * math.exp(-t*95))
        root = [45, 48, 41, 43][(b//4) % 4]
        frequency = 440 * 2 ** ((root-69)/12)
        event((b+0.05)*beat, beat*0.75, lambda t, f=frequency: 0.12*(math.sin(2*math.pi*f*t)+0.22*math.sin(4*math.pi*f*t))*(1-math.exp(-t*90))*math.exp(-t*5))
        if b % 2 == 0:
            for note in (root+24, root+28, root+31):
                frequency = 440 * 2 ** ((note-69)/12)
                event((b+0.55)*beat, 0.34, lambda t, f=frequency: 0.028*(math.sin(2*math.pi*f*t)+0.20*math.sin(6*math.pi*f*t))*(1-math.exp(-t*160))*math.exp(-t*11))
    return result


if __name__ == '__main__':
    OUT.mkdir(parents=True, exist_ok=True)
    air = wind()
    chatter = room(True)
    bed = [a*0.28+c*0.9 for a, c in zip(air, chatter)]
    for i in range(len(bed)):
        bed[i] *= min(1.0, i/(RATE*0.08), (len(bed)-1-i)/(RATE*0.08))
    save('mifflin_street.wav', bed, 0.40)
    save('mifflin_groove.wav', groove(), 0.58)
    print('Generated original outdoor crowd/air and eight-bar instrumental loops.')
