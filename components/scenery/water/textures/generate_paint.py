"""Bake seamless pigment and light masks; only the PNG is needed at runtime.
Run with Python + numpy. RGBA = pigment region, light seam, broad warp, brush center.
"""
from pathlib import Path
import struct
import zlib
import numpy as np

size = 512
rng = np.random.default_rng(24017)
y, x = np.mgrid[0:size, 0:size] / size
u = x + 0.035 * np.sin(y * np.pi * 6) + 0.012 * np.sin((x + y) * np.pi * 14)
v = y + 0.030 * np.sin(x * np.pi * 8) + 0.010 * np.sin((y - x) * np.pi * 12)
first = np.full((size, size), 100.0)
second = first.copy()
pigment = np.zeros_like(first)
for row in range(8):
    for col in range(8):
        cx, cy = (col + rng.uniform(.18, .82)) / 8, (row + rng.uniform(.18, .82)) / 8
        dx, dy = (u - cx + .5) % 1 - .5, (v - cy + .5) % 1 - .5
        distance = np.sqrt((dx * 0.85) ** 2 + (dy * 1.15) ** 2)
        closest = distance < first
        second = np.where(closest, first, np.minimum(second, distance))
        first = np.where(closest, distance, first)
        pigment = np.where(closest, rng.uniform(.08, .95), pigment)
seam = np.exp(-(second - first) * 85)
warp = .5 + .22 * np.sin(x * np.pi * 4 + np.sin(y * np.pi * 2)) + .17 * np.sin(y * np.pi * 6 + np.sin(x * np.pi * 4))
center = np.clip(1 - first * 12, 0, 1)
rgba = np.clip(np.stack([pigment, seam, warp, center], axis=-1) * 255, 0, 255).astype(np.uint8)
def chunk(kind, data):
    return struct.pack('>I', len(data)) + kind + data + struct.pack('>I', zlib.crc32(kind + data))
raw = b''.join(b'\0' + row.tobytes() for row in rgba)
png = b'\x89PNG\r\n\x1a\n' + chunk(b'IHDR', struct.pack('>IIBBBBB', size, size, 8, 6, 0, 0, 0)) + chunk(b'IDAT', zlib.compress(raw, 9)) + chunk(b'IEND', b'')
Path(__file__).with_name('water_paint.png').write_bytes(png)

# Independent masks keep pigment, wave slopes, caustic light, and foam from
# outlining the same repeating cells. These are shared data textures at runtime.
def write_rgba(name, channels):
    data = np.clip(np.stack(channels, axis=-1) * 255, 0, 255).astype(np.uint8)
    raw = b''.join(b'\0' + row.tobytes() for row in data)
    result = b'\x89PNG\r\n\x1a\n' + chunk(b'IHDR', struct.pack('>IIBBBBB', size, size, 8, 6, 0, 0, 0)) + chunk(b'IDAT', zlib.compress(raw, 9)) + chunk(b'IEND', b'')
    Path(__file__).with_name(name).write_bytes(result)

def smooth(seed, frequency_x, frequency_y=None):
    source = np.random.default_rng(seed).standard_normal((size, size))
    kx = np.fft.rfftfreq(size) * size
    ky = np.fft.fftfreq(size) * size
    radius = (kx[None, :] / frequency_x) ** 2 + (ky[:, None] / (frequency_y or frequency_x)) ** 2
    field = np.fft.irfft2(np.fft.rfft2(source) * np.exp(-radius * .5), s=(size,size))
    return np.clip(.5 + field / field.std() * .17, 0, 1)

broad = smooth(7821, 2.8)
fine = smooth(9182, 8)
write_rgba('water_pigment.png', [broad * .50 + pigment * .50, fine, smooth(713, 3.5), smooth(461, 40)])
height = smooth(241, 8, 3) * .65 + smooth(612, 14, 8) * .35
dx = np.roll(height, -1, axis=1) - np.roll(height, 1, axis=1)
dy = np.roll(height, -1, axis=0) - np.roll(height, 1, axis=0)
write_rgba('water_normals.png', [.5 + dx * 8, .5 + dy * 8, height, smooth(281, 4)])

def caustic(seed, count):
    local_rng = np.random.default_rng(seed)
    nearest = np.full((size,size), 100.0)
    other = nearest.copy()
    for row in range(count):
        for col in range(count):
            cx, cy = (col + local_rng.uniform(.1,.9))/count, (row + local_rng.uniform(.1,.9))/count
            du, dv = (u-cx+.5)%1-.5, (v-cy+.5)%1-.5
            distance = np.sqrt(du*du+dv*dv)
            closest = distance < nearest
            other = np.where(closest, nearest, np.minimum(other,distance))
            nearest = np.minimum(nearest,distance)
    return np.exp(-(other-nearest)*125)
write_rgba('water_caustics.png', [caustic(901, 11), caustic(347, 7), smooth(814, 3), smooth(577, 9)])
