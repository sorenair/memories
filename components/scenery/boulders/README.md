# Painterly procedural boulder

Instance `components/scenery/boulders/painterly_boulder.tscn` under a memory's `Environment`. Its origin is the ground contact point. This component generates **one contiguous stone**, with one optional convex collision hull and a soft contact-shadow plane. It does not scatter pebbles or other rocks.

The Inspector provides live editor previews. Generated children are internal; scenes save parameters instead of geometry. **Regenerate boulder** rebuilds explicitly. The current demo contains one `MeadowBoulder`.

## Shape

| Field | Effect |
| --- | --- |
| Boulder Seed | Repeatable profile, proportions, slant, crown cuts, major fracture faces, and plane paint. Automatic cycles through six families across consecutive seeds. |
| Shape Profile | Automatic, Block, Slab, Upright, Wedge, Shard, or Weathered. Explicit selection fixes the family while seeds vary its details. |
| Variability | Strength of seeded proportion changes and lean; default 0.85. Lower values keep the silhouette closer to nominal dimensions. |
| Dimensions | Nominal X/Y/Z size in meters. Default 1.8 × 1.25 × 1.4. Profiles and seed variation modify these base proportions. Slabs are broader and flatter, while upright and shard profiles grow taller and narrower. |
| Roundness | Controls corner-cut depth: angular blocks through more heavily beveled stones. All settings retain clean planes. |
| Roughness | Seeded variation in cutting-plane angles and offsets; no surface noise deformation. |
| Burial | Fraction of the nominal height embedded beneath the ground, default 0.12. |
| Solid | One convex hull blocks player movement; disable for decoration. |
| Visibility Distance | Whole-component culling distance, default 55 m. |

Place the origin at the ground surface. Rotate around Y freely. Use Dimensions to change proportions. The base is deliberately buried, with darkened contact pigment and a feathered shadow, so it feels embedded in the scene. Existing grass can overlap the lower silhouette naturally. The convex hull approximates small surface dents and includes the buried part; it is not intended for cave-like concavities.

## Colors and paint

**Stone Colors → Palette Preset** offers Granite, Sandstone, Slate, Terracotta, Chalk, and Dream Violet. Expand **Palette** to edit Base, Shadow, Mid, and Highlight colors. Editing a preset switches to Custom without changing other instances. Directly assigning a shared `StonePalette` resource also selects Custom. Preset selections and custom resources save with the scene.

**Plane Variation** adds a restrained color variation between physical faces. The stone is sculpted by intersecting seeded cutting planes. Each resulting polygon has one normal and one painted tone across its internal triangles, producing broad clean faces like illustrated stone references. The cloudy noise texture and smooth blob-like shading have been removed. Lighting remains coherent when the stone rotates.

Color and paint changes update material uniforms directly and preserve the mesh and collision. Shape changes rebuild both the visible stone and its hull.

## Budget and future reuse

The boulder has **48 triangles** at the default seed and shape settings, plus a two-triangle contact plane, for two draw surfaces. There are no textures, particles, real-time shadow passes, or per-frame script updates. Stone lighting and per-face paint values are evaluated in the vertex shader; the fragment shader handles only contact tint and distance haze. No noise-texture sampling or procedural noise function is used. Geometry generation runs only on creation and authoring changes.

The current full demo measured **21 draw calls and about 71,900 primitives** on Godot 4.4.1's Metal Mobile renderer, including the existing foliage, player, and ground. Counts reflect the current demo settings; physical iOS performance has not been measured.

Different families introduce unequal shoulders, sloping crowns, flatter slabs, narrower leaning forms, and one or two dominant cut faces. Each remains a single convex stone with clean plane shading.

`boulder_geometry.gd` is independent of the component scene and material setup. Its `create_mesh(seed, dimensions, roundness, roughness, burial, profile = AUTO, variability = 0.85)` method can be reused by a later small-rock cluster component. No rock-cluster component is implemented in this increment.

## Validation

```sh
godot --headless --path . --script tests/boulder_smoke.gd
```

Checks cover one closed manifold stone after welding hard-normal shading splits, finite vertices and unit face normals, outward winding, triangle budget, buried base, repeatable shape, seed variation, material updates without mesh regeneration, palette scene packing, actual swept player collision, and optional disabled collision.

`docs/boulder-demo.png` shows the playable composition; `docs/boulder-detail.png` shows the stone more closely.

`tests/boulder_variations.gd` checks 36 combinations spanning all six automatic families, corner rounding, and cut roughness for closed topology and nondegenerate faces. It also verifies substantial differences in seed height/aspect ratio and explicit profile selection. `docs/boulder-variations.png` is a labeled render comparison; the playable demo retains one boulder.

For a group of smaller stones, use the [inherited rock cluster component](../rock_clusters/README.md). It shares this generator and palette system while merging the group into two draw surfaces.

## Proximity recall

Enable **Recall → Recall Enabled** on the component root to manifest the stone on
approach. It defaults to off; editor previews remain complete. All demo boulders and
the inherited pond rock cluster enable it and discover nearby explorers independently.

The default solid effect scans upward from the buried base with a soft irregular white
edge, resolving the original stone colors behind it. It shares the tree trunk's scan
shader logic and takes 2.4 seconds. The contact shadow develops during recall; collision
is enabled when the stone is complete. **Solid** still controls whether any collider
exists. Either grounded explorer can trigger it, and it stays recalled for that visit.

The component owns its internal `SolidRecall` controller. No scene effect nodes are
needed. Toggle off to restore normal materials immediately. Palette changes remain
live, geometry rebuilds preserve animation state, and no extra mesh surfaces or
per-vertex CPU updates are added. Enabled instances perform proximity/state updates;
disabled instances retain the original no-process behavior.

Use `res://scenes/effects/boulder_recall_test.tscn` (F6) to replay/pause/scrub the effect.
`tests/solid_recall.gd` checks discovery, stable geometry, collision, palette updates,
rebuilds and empty/repopulated rock clusters. See [the effects guide](../../../scenes/effects/README.md).
