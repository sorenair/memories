"""Original small acoustic winter waltz; no borrowed tune or recordings."""
import math
from generate_memory_audio import RATE, OUT, save

BEAT = 60 / 96
LENGTH = BEAT * 24

def frequency(note):
    return 440 * 2 ** ((note - 69) / 12)


def make_music():
    samples = [0.0] * round(RATE * LENGTH)
    def note(midi, start, duration, gain, voice):
        hz = frequency(midi)
        for i in range(round(RATE * duration)):
            t = i / RATE
            if voice == 'pluck':
                tone = sum(math.sin(2 * math.pi * hz * h * t) / h ** 1.7 for h in range(1, 6))
                envelope = (1 - math.exp(-t * 140)) * math.exp(-t * 4.3)
            elif voice == 'fiddle':
                phase = 2 * math.pi * hz * t + 0.018 * math.sin(2 * math.pi * 4.2 * t)
                tone = math.sin(phase) + 0.17 * math.sin(phase * 2) + 0.065 * math.sin(phase * 3)
                envelope = min(1, t / 0.12) * min(1, (duration - t) / 0.18) * 0.5
            else:
                tone = math.sin(2 * math.pi * hz * t) + 0.12 * math.sin(2 * math.pi * hz * 2 * t)
                envelope = (1 - math.exp(-t * 80)) * math.exp(-t * 4)
            # Wrap release tails into the start for a seamless cyclic performance.
            at = (round(start * RATE) + i) % len(samples)
            samples[at] += gain * tone * envelope
    chords = [(43,55,59,62), (48,55,60,64), (45,57,60,64), (50,57,62,66),
              (47,55,59,62), (48,55,60,64), (50,57,62,66), (43,55,59,62)]
    melody = [[71,74,76], [76,72,71], [69,72,76], [74,78,76],
              [74,71,67], [69,72,76], [78,76,74], [71,69,67]]
    for bar, chord in enumerate(chords):
        start = bar * 3 * BEAT
        note(chord[0], start, BEAT * 2.8, 0.25, 'bass')
        for beat in range(3):
            for n, midi in enumerate(chord[1:]):
                note(midi, start + beat * BEAT + n * 0.022, BEAT * 1.4, 0.105, 'pluck')
            note(melody[bar][beat], start + beat * BEAT, BEAT * 1.07, 0.13, 'fiddle')
    return samples


if __name__ == '__main__':
    OUT.mkdir(parents=True, exist_ok=True)
    save('christmas_market_waltz.wav', make_music(), 0.55)
    print('Generated original 15-second acoustic market waltz.')
