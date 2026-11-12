"""Quiet original placeholder room and crowd beds; no recorded speech. Stdlib only."""
import math
import random
from generate_memory_audio import RATE, OUT, save

def room(crowded=False):
    rng = random.Random(120425 + int(crowded))
    samples = []
    low = slow = 0.0
    count = RATE * 16
    # Warm up twice so the filters meet at the loop boundary.
    for cycle in range(2):
        for index in range(count):
            noise = rng.uniform(-1,1)
            low += 0.095 * (noise-low)
            slow += 0.008 * (noise-slow)
            phase = math.tau * index / count
            bed = slow * 0.7 + math.sin(phase * 960) * 0.002
            if crowded:
                envelope = 0.35 + 0.15*math.sin(phase*11) + 0.13*math.sin(phase*17+0.7)
                bed += (low-slow) * envelope
                bed += math.sin(phase*2350 + math.sin(phase*27)*2) * 0.004 * envelope
            if cycle:
                # An inaudibly quiet join prevents a seam in the placeholder noise.
                edge = min(1.0,index/(RATE*0.08),(count-index)/(RATE*0.08))
                samples.append(bed * max(0,edge))
    return samples
if __name__ == '__main__':
    OUT.mkdir(parents=True,exist_ok=True)
    save('museum_room.wav',room(),0.28)
    save('museum_murmur.wav',room(True),0.35)
    print('Generated quiet gallery and crowd room beds.')
