# Sculpted painterly fire

`painterly_sculpted_fire.tscn` is a separate 3D fire component. The original
`components/vfx/fire/painterly_fire.tscn` and existing memory instances are retained.
Place the root on the fire's base and use **Fire Size** for width and height.

The effect combines a full lower flame, a bright flowing heart, and large
red-orange tongues that rapidly rise
and fold over into sharp curls, three brief detached tips, billowing smoke, varied embers, and
a restrained warm ground wash. The main flame is a continuous 3D volume, with
negative spaces forming inside its curling tongues. Its bent columns feed tapered curls, and its surface stays closed as it curls,
including when seen from another side. No flipbooks, textures or external assets
are required. The ground wash reuses the original fire's shader.

Broad, pale-gold pigment strokes travel upward inside the bright heart, keeping
the heat flow readable when the outer silhouette is full and rounded.
Tongues use staggered sub-second/one-second bursts with a quick attack, thinning
tip, and early breakup; smoke moves on a slower independent cadence.

## Controls

| Inspector group | Main controls |
| --- | --- |
| Fire | **Fire Size** (width/height in meters), **Body Fullness**, **Intensity**, **Animation Speed**, **Curl Amount** (how far tongues/wisps roll over), **Wind** (local X/Z), **Fire Seed** |
| Paint and Glow | **Core Color**, **Flame Color**, **Edge Color**, **Glow Strength** |
| Smoke | **Smoke Amount** (density), **Smoke Height** (plume rise), **Smoke Spread**, **Smoke Turbulence**, **Smoke Color** |
| Sparks | **Spark Amount**, **Spark Height** in flame-height multiples, **Spark Size** in meters, **Spark Burstiness** |
| Recall | **Recall Enabled**, using the shared proximity distance and fade lifecycle |

**Body Fullness** defaults to **0.72**. It fills the lower flame without raising
a sphere into the upper silhouette. Large overlapping curls and a bending,
tapered spine form the upper mass. Lower values narrow the base.

Set **Animation Speed** to zero to freeze every layer. Set **Intensity** to zero
to hide the effect. Smoke Amount, Spark Amount and Glow Strength each support
zero to disable their batches. Spark Amount adjusts the active pool; Smoke Amount
changes the density of both smoke layers without rebuilding geometry. Smoke uses
a connected 3D flow volume with soft painted billows around it. A faint volume connects the lower column; rolling brush billows supply its visible
shape. Its warm base overlaps the fire, internal density erodes, and upper lobes
separate and disperse.
Flame and smoke colors remain readable on the
game's warm-white background; emission supplies an accent without requiring bloom.
Glow Strength controls painted glow/emission, with no dynamic light added.

All appearance controls update uniforms and bounds; only Fire Seed regenerates
the seeded instance data. Each component owns private materials while sharing
cached geometry. Generated children stay internal, so the saved scene contains
only its authoring parameters. Recall preserves progress through rebuilds.

Open `res://tests/scenes/sculpted_fire_test.tscn` and press **F6**. This inherits the
generic component stage, including an explorer for scale, three backdrop options,
visibility/reload controls, and optional recall replay. Existing memories continue
using the original fire until an instance is deliberately swapped.

## Construction and cost

Six batches: main flame volume, detached flamelets, smoke volume, smoke fray,
sparks, and ground wash. The main flame ray marches a smooth union of bent, tapered columns and curling tips inside an invisible bounds box, with a maximum of 128 bounded steps
per pixel. Tongue tips can turn downward, then pinch away as the stroke rises.
Their burst envelopes overlap, while each cycle changes its reach and width.
A low body and smoothly fused rolling shoulder maintain a full lower
silhouette between bursts. Openings form naturally within the strokes; the core
has no separately punched holes. The shader writes the depth of the
actual fire surface, so opaque scenery correctly occludes the volume.
Orthographic cameras use parallel tracing rays; perspective cameras use rays
through the proxy pixels. A camera-dolly check guards against projection distortion.

Animated column/arc/tip data is prepared on the bounds-box vertices and reused by the
ray steps. A bounded angle approximation reduces the tracing cost while keeping
its shape error below the surface-hit tolerance.

Three detached tips use closed, curved 24-sided × 28-ring meshes (1,344 triangles each).
Each shares a clock and profile with one main tongue, appearing near its tip as
the parent thins, lifting briefly and burning away. They are small accents rather
than a separate cloud of repeated commas.
Smoke has one closed 32-sided × 48-ring loft (3,072 triangles) and 16 soft,
procedural billboard brush dabs that follow the same 3D flow. Both layers use
alpha blending and depth testing without writing depth, allowing embers to show
through. The main flame writes its actual surface depth. The connecting volume uses restrained density instead of strong normal lighting;
softly eroded, unequal lobes roll within each surrounding brush dab. UV-edge
feathering keeps those lobes inside their quads.

Sparks have a pool of 64 tiny meshes; the default amount shows 42. Seeded particles
vary in size, launch direction, lifetime phase, flicker and trail length. They
orient along their rising velocity, slow as they climb, and cool from bright
heads through orange to red. Burstiness groups some emissions into overlapping
packets. They use depth testing and alpha fade, keeping a readable size until they dissipate
instead of shrinking into pixel dust. Their paths inherit the smoke flow.

Animation runs on the GPU, including the fused fire shape, rolling openings,
graphic pigment bands, smoke rolling/expansion/drift, and spark rise. The component has no animation frame
callback, physics particles, simulation textures, screen/depth sampling, collision,
or sound. Bounds include the plume, lifted fragments, wind and spark travel.
The implicit flame costs more per covered pixel than the original simple fire.
Tight ray bounds and early exits limit empty work; physical-device performance
still needs profiling before using many large instances.

Local profiling of this revision on the M1 Mac (Godot 4.4.1 Mobile/Metal,
1280×720, VSync disabled, median of 120 frames after warm-up) measured about
7.2 ms/frame for one complete fire and 22.8 ms/frame for four. These are whole
viewport times; physical phone profiling remains necessary for large groups.

## References

The user's references informed the bright core, negative-space curls, detached
flame pieces and separate smoke/spark layers. Implementation research:

- [Alex Starovoyt — Stylized Fire Spell VFX](https://discofish.artstation.com/projects/eRDOkP): simple volume meshes, animated vertices and scrolling masks.
- [Cyanilux — Fire/Flame Shader Breakdown](https://www.cyanilux.com/tutorials/fire-shader-breakdown/): upward distortion, clear teardrop shapes and restrained overdraw.
- [Marina VFX — Stylized Fire Texture](https://realtimevfx.com/t/marina-vfx-50-weeks-of-stylized-vfx-between-art-emotion-code/29826): separate vertical fire flow and slower breathing shape.

These informed the design; all geometry and shaders here are original project
code, with no downloaded reference assets.

## Verification

```sh
godot --headless --path . --script tests/sculpted_fire.gd
godot --path . --script tests/sculpted_fire_render.gd
godot --path . --script tests/sculpted_fire_render.gd -- --animation
godot --path . --script tests/sculpted_fire_render.gd -- --animation --detail
godot --path . --script tests/sculpted_fire_render.gd -- --animation --detail --smoke
```

Checks cover parameter persistence, geometry/material sharing, independent
materials, bounds, layer disabling, amount changes, recall/rebuild continuity,
frozen animation, visible motion, and visibility from four angles. The render check
also isolates the main fire across seven times, checks its core at both Curl Amount
extremes, verifies foreground/background occlusion and perspective projection,
and checks smoke density and animation in isolation.
The solid flame is also tested through partial recall and maximum wind at low
intensity. It writes
light/dark previews to `docs/previews/sculpted-fire-{light,dark}.png`. The optional
animation frames go to `/tmp/sculpted-fire-frame-*.png`. `--detail` also captures
the flame/wisps close up with smoke disabled to `/tmp/sculpted-fire-detail-*.png`.
`--smoke` captures the isolated plume to `/tmp/sculpted-fire-smoke-*.png`. Animation
captures are four seconds at 24 frames/second. See [the art-direction guide](../../../docs/SCULPTED_FIRE_ART_DIRECTION.md) and
[the smoke critique](SMOKE_REVIEW.md)
for the rationale behind the layered plume.

![Actual engine animation](../../../docs/previews/sculpted-fire-motion.gif)

![Close-up curl study, smoke disabled](../../../docs/previews/sculpted-fire-curl-detail.gif)
