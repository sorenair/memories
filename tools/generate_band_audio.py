"""Generate the band's original, short mono instrument sounds (Python stdlib only)."""
from pathlib import Path
import math
import random
import struct
import wave

RATE = 44100
OUT = Path(__file__).resolve().parents[1] / 'components/activities/arcade/mechanical_band/audio'


def save(name, samples):
    peak = max(abs(s) for s in samples)
    data = bytearray()
    for i, sample in enumerate(samples):
        # Click-free ends, while retaining the percussion's quick attack.
        fade = min(1, i / (RATE * .0015), (len(samples) - 1 - i) / (RATE * .04))
        data.extend(struct.pack('<h', round(sample * .78 / peak * fade * 32767)))
    with wave.open(str(OUT / f'{name}.wav'), 'wb') as wav:
        wav.setnchannels(1)
        wav.setsampwidth(2)
        wav.setframerate(RATE)
        wav.writeframes(data)
    rms = math.sqrt(sum(s*s for s in samples) / len(samples)) * .78 / peak
    print(f'{name}: {len(samples)/RATE:.2f}s, normalized RMS {rms:.3f}')


def guitar():
    rng = random.Random(82)
    result = [0.] * int(RATE * 1.65)
    # A soft C-major voicing, with slightly staggered plucked strings.
    for j, freq in enumerate((196., 261.626, 329.628, 391.995)):
        count = round(RATE / freq - .5)
        ring = [rng.uniform(-1, 1) for _ in range(count)]
        offset = round(j * .017 * RATE)
        for i in range(len(result) - offset):
            k = i % count
            value = ring[k]
            ring[k] = .496 * (value + ring[(k+1) % count])
            result[i+offset] += value * math.exp(-i / RATE * .65) * min(1., i / (RATE * .003))
    return result


def kick():
    phase = 0.
    result = []
    for i in range(int(RATE * .48)):
        t = i / RATE
        phase += 2 * math.pi * (54 + 106 * math.exp(-t * 62)) / RATE
        result.append(math.sin(phase) * math.exp(-t * 12) + .08 * math.sin(phase * 2.01) * math.exp(-t * 35))
    return result


def snare():
    rng = random.Random(17)
    low = 0.
    high = 0.
    result = []
    for i in range(int(RATE * .34)):
        t = i / RATE
        noise = rng.uniform(-1, 1)
        low += .12 * (noise - low)
        high += .65 * ((noise - low) - high)
        body = .32 * math.sin(2*math.pi*185*t) + .12 * math.sin(2*math.pi*330*t)
        result.append(high * math.exp(-t * 19) + body * math.exp(-t * 28))
    return result


def piano():
    result = []
    for i in range(int(RATE * 1.85)):
        t = i / RATE
        sample = 0.
        for j, freq in enumerate((523.251, 659.255, 783.991)):
            for h, level in enumerate((1., .25, .14, .055, .025), 1):
                # Slightly inharmonic overtones and a soft hammer envelope.
                frequency = freq * h * math.sqrt(1 + .00014*h*h)
                sample += level * math.sin(2*math.pi*frequency*t + j*.2) * math.exp(-t * (2.4 + h*1.2))
        result.append(sample * (1-math.exp(-t*500)))
    return result


if __name__ == '__main__':
    OUT.mkdir(parents=True, exist_ok=True)
    for name, make in [('guitar', guitar), ('kick', kick), ('snare', snare), ('piano', piano)]:
        save(name, make())
