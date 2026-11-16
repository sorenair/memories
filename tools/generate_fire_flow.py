"""Bake a deterministic, periodic curl/density field for the sculpted fire.

Run this, then tools/bake_fire_flow.gd in Godot to save the shared Texture3D.
RGBA half-floats: RGB stores curl displacement; A stores broad density.
No downloaded assets. Requires NumPy; generation is offline only.
"""
from pathlib import Path
import argparse
import numpy as np


def generate(size: int, seed: int) -> np.ndarray:
    rng = np.random.default_rng(seed)
    frequencies = np.fft.fftfreq(size) * size
    kz, ky, kx = np.meshgrid(frequencies, frequencies, frequencies, indexing="ij")
    k2 = kx * kx + ky * ky + kz * kz

    def smooth_field(bandwidth: float) -> np.ndarray:
        spectrum = np.fft.fftn(rng.normal(size=(size, size, size)))
        field = np.fft.ifftn(spectrum * np.exp(-k2 / (2 * bandwidth**2))).real
        return (field - field.mean()) / field.std()

    def derivative(field: np.ndarray, frequency: np.ndarray) -> np.ndarray:
        return np.fft.ifftn(np.fft.fftn(field) * (2j * np.pi * frequency)).real

    potential = [smooth_field(1.8) for _ in range(3)]
    curl = [
        derivative(potential[2], ky) - derivative(potential[1], kz),
        derivative(potential[0], kz) - derivative(potential[2], kx),
        derivative(potential[1], kx) - derivative(potential[0], ky),
    ]
    curl_scale = np.sqrt(np.mean([np.mean(channel**2) for channel in curl]))
    density = smooth_field(2.2) + smooth_field(4.5) * 0.22
    density /= density.std()
    channels = [channel / curl_scale * 0.16 + 0.5 for channel in curl]
    channels.append(density * 0.16 + 0.5)
    return np.clip(np.stack(channels, axis=-1), 0, 1).astype("<f2")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, default=Path("/tmp/fire_flow.rgba"))
    parser.add_argument("--size", type=int, default=64)
    parser.add_argument("--seed", type=int, default=73011)
    args = parser.parse_args()
    if args.size < 2:
        parser.error("--size must be at least 2")
    field = generate(args.size, args.seed)
    args.output.write_bytes(field.tobytes())
    print(f"Saved {args.size}³ RGBA flow field: {args.output}")
