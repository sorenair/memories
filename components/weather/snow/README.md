# Painterly snow

Instance `painterly_snow.tscn` under a memory's Environment. Position its origin at the center of the weather area and its local ground level. The demo's `ClearingSnow` covers 26×32 m with 1,200 allocated flakes and Intensity 0.7.

Soft, slightly irregular round flakes fall slowly, weaving through broad swirls and gentle wind. Size, speed, brightness, and phase vary between flakes. Smaller flakes dominate, with occasional larger flakes giving depth without a screen-wide curtain. Normal depth testing hides snow behind scenery; flakes fade at the top and near the ground to hide their looping motion.

| Inspector control | Purpose |
| --- | --- |
| Footprint / Snow Height | Local X/Z coverage and height above the ground. Cover the memory plus a margin for wind. |
| Snow Seed | Repeatable placement and motion variation. |
| Flake Count | Allocated pool, 0–4,000. Zero removes the batch. |
| Intensity | Fraction of flakes enabled. Zero hides the batch. |
| Fall Speed | Approximate downward meters/second, varied per flake. Zero freezes all animation. |
| Wind | Bounded local X/Z drift strength, rather than unbounded lateral velocity. |
| Flutter | Strength of lazy sideways swirls. |
| Flake Size | Minimum/maximum diameter in meters; defaults 0.04–0.11. |
| Snow Color / Shade Color | Pale center and cool, restrained edges. |
| Opacity | Overall translucency; zero hides the batch. |
| Ground Height | Local flat ground level. |
| Visibility Distance | Culling distance. |

Footprint, seed, count, and ground edits rebuild the batch. Other appearance and motion edits update uniforms and bounds without regenerating geometry. Generated nodes remain internal; scene files save the authoring parameters. The volume stays fixed to the memory instead of recentering on the player. Size it to cover the whole play area, and keep its transform upright.

Snow is decorative: it does not accumulate, change foliage palettes, freeze water, extinguish fire, or collide with roofs and arbitrary terrain. Its bottom fade uses the flat Ground Height plane. The demo's existing rain remains hidden, and foliage/recall settings are preserved. Disable or hide either weather component to choose the desired conditions.

## Budget and validation

All flakes share **one MultiMesh draw**, using two triangles each (2,400 allocated triangles in the demo). Shape, edge softness, color, and motion are computed in the shader. No textures, per-frame scripts, physics particles, raycasts, screen/depth reads, or accumulation buffers are needed. Bounds cover the entire height plus wind, flutter, and flake size. It has been visually checked on the desktop Mobile renderer; physical phone performance remains untested.

```sh
godot --headless --path . --script tests/snow_component.gd
godot --path . --script tests/snow_motion_render.gd
```

Checks cover counts/budgets, bounds, live Inspector changes, ordered size ranges, persistence, generated-node isolation, zero-count/intensity modes, and captured frames for visible drift, freezing, and disabling.

`docs/snow-clearing.png` and `docs/snow-motion.gif` show the fully populated memory for visual weather review; the saved memory's recall settings are unchanged.
