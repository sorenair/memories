# Painterly grass patches

Instance `painterly_grass_patch.tscn` beneath any memory's `Environment`, place it on the ground, and tune its Inspector fields. A preview is generated in the editor and regenerated after parameter changes; **Regenerate patch** also rebuilds it manually. Generated children are internal, so only authoring parameters are saved in the scene. The patch is fully present from scene startup, with no discovery, recollection, or entrance effect.

## Shape and palette

- **Patch Size:** full X/Z footprint in meters. Shape is an irregular ellipse, with a slightly larger ground wash. Place several small patches to compose a meadow; do not scale one patch to cover an entire level.
- **Patch Seed:** repeatable shape, placements, size variations, and color clusters.
- **Palette:** a reusable `GrassPalette` resource. `palettes/meadow.tres` and `palettes/dusk.tres` are included. Duplicate a preset to create another look. Editing a shared palette updates all patches that use it.
- **Tufts / Leaves per Square Meter:** independent density controls for upright rounded grass strokes and low oval groundcover. Zero disables that layer.
- **Grass Height:** height of upright grass; tips and edges vary organically around that value.
- **Wind Strength / Speed:** continuous, GPU-driven sway. Set strength to zero for still foliage.
- **React to Explorer:** gently bends foliage around the local character. No gameplay collision is added. The position uniform updates each rendered frame from the interpolated player transform with exponential follow smoothing; geometry stays on the GPU. The bend direction also eases through the character center to avoid sharp flips.
- **Visibility Distance:** whole-patch culling distance. Keep patches small so distant ones can be culled independently.

The component expects a flat ground plane at the patch's local Y=0. Rotate around Y and translate freely. Author its dimensions using Patch Size; nonuniform node scaling also scales its height, wind, and bending. Place patches slightly apart or just touching: overlapping transparent pigment washes can darken their shared area. Terrain projection, painting arbitrary outlines, and patch merging are not implemented.

## Why it feels rooted

Both the scatter and the ground wash use the same seeded irregular boundary. Foliage thins, shrinks, and loses saturation toward that boundary. A transparent procedural pigment wash blends into the existing floor, and dark foliage roots share its palette. Broad oval leaves create overlapping painted dabs while sparse upright ribbons break the silhouette. The palette and clustered placement carry the lighting style; foliage uses intentionally unshaded materials rather than expensive real-time shadows.

## Rendering budget

One patch has exactly three geometry surfaces: an opaque tuft MultiMesh, an opaque groundcover MultiMesh, and one transparent ground wash. Shared low-poly meshes are cached across patches. There are no textures, per-blade nodes, particles, alpha-cutout foliage cards, shadow-map passes, or per-frame mesh uploads. Materials are independent per patch, so palette and player uniforms do not leak between instances.

The default seed/settings generate 232 tufts and 963 groundcover instances, totaling 37,242 triangles. The demo measured nine total draw calls and approximately 38,000 primitives including the existing player and world on Godot 4.4.1's Metal Mobile renderer. This is a structural budget, not an iOS frame-rate guarantee. For a lower-end device, start around 8 tufts and 30 leaves per square meter. Candidate counts are capped at 12,000 per layer as a guard against oversized authoring settings.

Wind and player bending run in the vertex shader. Bounds include an animation margin to prevent premature culling. At distance, custom haze returns the foliage toward the void palette. For large scenes, compose multiple independently culled patches and profile on the intended phone.

## Demo and checks

`scenes/memories/foliage_demo.tscn` contains one meadow patch and is the current memory in `scenes/world/memory_world.tscn`. The original `blank_void.tscn` remains available.

```sh
godot --headless --path . --script tests/grass_patch_smoke.gd
godot --headless --path . --script tests/scene_smoke.gd
```

The grass check covers repeatable generation, seed variation, the geometry budget, independent palette materials, zero-density layers, and disabled interaction processing. The scene check covers the existing player controls and camera.

## Trees

`painterly_tree.tscn` adds a reusable single-tree generator using the same foliage palettes. See [the tree authoring guide](TREES.md).

## Bushes

`painterly_bush.tscn` creates low, spreading shrubs using the same leaf geometry, palette resources, and wind shader as trees. See [the bush authoring guide](BUSHES.md).
