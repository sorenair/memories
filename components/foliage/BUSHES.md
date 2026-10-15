# Painterly procedural bushes

Instance `components/foliage/painterly_bush.tscn` under any memory's `Environment`, place its origin on the ground, and tune its Inspector fields. The bush previews in the editor and rebuilds automatically when authoring parameters change. **Regenerate bush** also rebuilds it manually. Generated children are internal, so scenes save authoring parameters rather than hundreds of leaf nodes.

## Controls

| Field | Effect |
| --- | --- |
| Palette | Shared `GrassPalette` resource; meadow and dusk presets work with grass, trees, and bushes. |
| Bush Seed | Repeatable mound shapes, leaf positions, and color clusters. |
| Footprint | Nominal X/Z spread; individual sprays extend beyond the nominal outline. |
| Bush Height | Height of the mound, with smaller spreading masses around its base. |
| Mass Count | 3–7 overlapping growth masses; default 4. |
| Sprays per Mass | Leaf density; default 54. Zero removes both foliage and ground pigment. |
| Wind Strength / Speed | Coherent world-space sway plus leaf flutter; default strength 0.055 m. Zero freezes the foliage. |
| React to Explorers | Smoothly pushes leaves aside around up to two characters in the `explorers` group. Disable to keep only wind. |
| Disturbance Strength / Radius | Push amount in meters and the reach around each character; defaults 0.28 m / 0.8 m. |
| Visibility Distance | Culls the bush as a unit; default 40 m. |

Place on flat ground and rotate around Y freely. Use Footprint and Bush Height for proportions. The component is decorative and has no collision. Bushes now bend smoothly around characters, alongside the existing grass interaction. Nearby leaves shift outward and down while their root-weighted bases stay anchored. Sources use interpolated player positions, exponential follow smoothing, and eased activation/release, avoiding physics-tick stepping and sharp direction reversals. Two source slots remain stable when characters join or leave; large teleports reset and ease in at the new position. Bushes are present at startup with no recollection effects.

## Shared visual language

Each bush has one taller central mass and lower offset masses with uneven borders. Eight smaller growth clumps in each mass organize curved, volumetric leaf sprays. Light and dark colors are shared within clumps, with brighter upper foliage and darker low foliage. Roots fade into a feathered procedural ground wash using the same palette as the grass.

Trees and bushes share `shared/leaf_geometry.gd`, which caches the existing curved three-leaf spray mesh, and `shaders/tree_canopy.gdshader`, which supplies painterly color and GPU wind. The tree's seeded leaf geometry and behavior are preserved. There are no canopy spheres, surface decals, texture cards, or per-frame geometry updates.

## Budget

The default bush is **216 instanced leaf sprays / 6,480 triangles**, plus a two-triangle ground plane. It has **two geometry surfaces**: opaque instanced foliage and one transparent ground wash. No real-time shadow passes, per-leaf nodes, particles, or per-leaf CPU updates are needed. A small per-bush script uploads two smoothed source positions/weights each rendered frame; group membership is refreshed four times per second. Disabling React to Explorers removes that process callback while wind continues entirely on the GPU. Culling bounds are calculated from actual instance transforms with an animation margin. Palette and wind materials are independent per bush, while the leaf mesh is shared with all bushes and trees.

The demo includes three differently seeded and sized bushes: one larger meadow bush, a smaller bush toward the back, and a compact shrub near the tree base. With the existing four-branch demo tree, the full scene measured **19 draw calls and about 73,100 primitives** on Godot 4.4.1's Metal Mobile renderer. These counts are not a phone frame-rate guarantee. For many shrubs, try 24–36 sprays per mass and profile on the intended device. Each bush is culled independently; distance LOD and forest-wide batching are not implemented.

The ground wash sits slightly above the grass pigment plane to avoid coplanar flicker. Overlapping bushes can darken shared ground-wash areas; slight overlap works well, but densely stacked patches should be avoided.

## Validation

```sh
godot --path . --script tests/bush_smoke.gd
godot --headless --path . --script tests/bush_interaction.gd
godot --path . --script tests/bush_interaction_render.gd
```

A rendering device is required for reliable MultiMesh transform-buffer readback. The checks cover repeatable placement and colors, seed variation, geometry budget, volumetric leaf shapes, culling bounds, palette independence, shared tree/bush geometry, live wind controls, and fully empty zero-density components.

`docs/bush-demo.png` shows the playable scene. `docs/bush-detail.png` shows the bushes more closely.

The interaction checks cover two independent explorers, easing, frame-rate independence, removal, teleports, and disabling the effect without disabling wind. A rendered check isolates a bush and confirms visible disturbance, return to its resting shape, and continued wind. Tree shaders keep disturbance strength at zero, preserving their existing behavior.

## Palette selector

Each component exposes **Foliage Colors → Palette Preset** in the Inspector. Choose seasonal or dreamlike colors, or edit a custom four-color mix. Palette changes preserve geometry and the painterly color distribution. See [the palette guide](PALETTES.md).
