# Smoke and spark review — 2026-11-15

The supplied campfire reference has a connected gray plume with readable billows
and bright, fairly consistent ember marks. The guide also calls for slower smoke
motion, legibility at gameplay scale and a coherent palette with the flame.

The preceding implementation missed that shape language:

- Soft opacity and mottled interior erosion made smoke look like blurred stains.
  Its large billows were difficult to read, especially on the light background.
- Making the surrounding dabs sharper exposed translucent discs. Lighting the
  continuous loft instead exposed a folded tube. Neither gave a coherent cloud.
- Sparks mixed faceted chips, long needles and tiny dots. Their broad variation
  and fast flicker made them resemble confetti rather than drawn embers.

## Current construction

The main smoke is one fused 3D volume. Seven expanding billows follow the shared
rise/wind path and blend smoothly into each other, producing a single scalloped
surface without particle intersections. Their animation is prepared at the proxy
vertices. A bounded ray trace finds the surface, and its normal supplies three
broad painted tones. The proxy fits the active billows to limit empty work.

Opacity approximates the strongest billow chord along the view ray, including
billows behind a fading foreground lobe. Using only the first lobe's opacity
exposed thin dark seams at joins. The base fades in above the hottest fire;
older billows lose density before their birth clock wraps. They dissipate rather
than shrinking as separate solid objects. Faint upper brush wisps finish the edge.

The volume tests its actual surface depth against scenery without writing to the
depth buffer. The smoke layers render before the sparks, so the embers remain
readable through the stylized plume while opaque scenery still occludes them.

The initial spark revision overcorrected toward consistency: short rounded
teardrops with ±8% width variation read as glowing beads. The follow-up uses
thin, pointed strokes with hot heads, bent orange/red tails and controlled
variation in width and length. Velocity alignment supplies their direction;
camera-facing broad sides keep the closed 3D flecks readable. They rise and slow
along the plume, with restrained flicker and a tail-first fade.

## Authoring and verification

**Smoke Definition** controls silhouette softness and toon-band transitions.
Its default is **0.8**. Amount controls optical density; Height, Spread, Turbulence,
Color and Wind retain their roles. Spark Amount, Size, Height, Burstiness and
the new **Spark Variation** (default **0.65**) control the embers. Animation stays
on the GPU in six batches.

Open `res://tests/scenes/sculpted_fire_test.tscn` with F6. Inspect the whole effect,
smoke alone and sparks alone, using dark and warm-white backgrounds. Check for
countable hard puffs, faded discs, clipped proxy edges, rocky shading or missing
embers. The follow-up flame revision replaces regular oval loops with a rising
3D curl/density field; the connected toon smoke is retained.

The render check covers separate layer visibility/motion, smoke density and
Definition, foreground/background occlusion of the cloud, freeze, four angles,
perspective, orthographic invariance, fullness, wind and partial recall. Component
checks cover exported control persistence, bounds, shared geometry/private
materials and recall/rebuild continuity.

```sh
godot --headless --path . --script tests/sculpted_fire.gd
godot --path . --script tests/sculpted_fire_render.gd -- --animation --detail --smoke --sparks
```

![Toon smoke](../../../docs/previews/sculpted-fire-smoke.png)

See the [smoke animation](../../../docs/previews/sculpted-fire-smoke-motion.gif)
and [isolated embers](../../../docs/previews/sculpted-fire-sparks.png).
