"""Generate the original quiet surf placeholder used by the Central Vietnam beach."""
from pathlib import Path
import math
import random
import struct
import wave


def main():
    rng = random.Random(61526)
    rate, seconds = 24000, 12
    count = rate * seconds
    low = deep = 0.0
    frames = bytearray()
    for index in range(count):
        time = index / rate
        noise = rng.uniform(-1, 1)
        low += 0.065 * (noise - low)
        deep += 0.006 * (noise - deep)
        swell = (0.38 + 0.32 * (0.5 + 0.5 * math.sin(2 * math.pi * time / 6 - 0.9)) ** 2
                 + 0.18 * (0.5 + 0.5 * math.sin(2 * math.pi * time / 4 + 0.5)))
        seam = max(0.0, min(1.0, index / (rate * 0.04), (count - 1 - index) / (rate * 0.04)))
        value = (low * 0.72 + deep * 0.65) * swell * 0.78 * seam
        frames += struct.pack('<h', int(max(-1, min(1, value)) * 32767))
    target = Path(__file__).resolve().parents[1] / 'audio/samples/central_vietnam_surf.wav'
    with wave.open(str(target), 'wb') as output:
        output.setnchannels(1)
        output.setsampwidth(2)
        output.setframerate(rate)
        output.writeframes(frames)
    print(target)


if __name__ == '__main__':
    main()
