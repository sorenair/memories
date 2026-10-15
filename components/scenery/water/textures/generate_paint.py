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
