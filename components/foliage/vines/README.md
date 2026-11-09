# Painterly wall vine

Instance `painterly_wall_vine.tscn` against a surface. **Local XY is the wall plane; local +Z faces outward.** Rotate the node to face the wall's outward normal. The origin is the growth root: bottom-center for Climbing, top-center for Hanging. Footprint is width and vertical reach.

This component reuses the bush/tree curved leaf-spray geometry, canopy shader, and seasonal palette resources. Overlapping leaf islands follow seeded branching curves, leaving irregular gaps and tapered ends. Thin, merged stems connect the growth. A shallow volume and restrained wind keep foliage attached to the wall rather than looking like a flat decal or round bush.

| Inspector control | Purpose |
| --- | --- |
| Vine Seed | Reproducible branches, leaf placement, and pigment variation |
| Footprint | Width and vertical reach in meters |
| Growth Mode | Climbing above the origin or hanging below it |
| Branch Count | Number of main growth strands |
| Leaf Spray Count | Exact density, 0–1,600; zero hides the whole component |
| Leaf Size | Base size of the shared three-leaf brush spray |
| Coverage Spread | Width of overlapping leaf islands around stems |
| Stem Radius | Thickness of the connecting tendrils |
| Surface Offset | Stand-off from the wall, allowing depth and wind clearance |
| Palette Preset / Palette | Same summer, spring, autumn, winter, dream, and custom colors as other foliage |
| Wind Strength / Speed | Gentle sway and flutter on the GPU |
| React to Explorers / Disturbance Strength | Smooth proximity response for up to two players; high foliage stays undisturbed |
| Visibility Distance | Culling distance for both batches |

Place the origin directly on the wall face and let Surface Offset provide clearance. This is authored planar growth, not automatic surface projection: split long or curved walls into smaller rotated components. For a horizontal creeping mat, rotate the plane onto the ground and reduce Surface Offset. There is no wall geometry, collision, pigment backing rectangle, or automatic reveal effect inside the component.

Two draw calls: one merged stem mesh and one instanced leaf batch. Default geometry is 7,920 triangles (240 × 30 leaf triangles + 720 stem triangles). Opaque foliage requires no textures, alpha cards, shadow maps, or per-leaf nodes. Palette and motion edits preserve placement. Density changes preserve the stem curves. Bounds include GPU motion.

The demo contains `SummerSpring/ClimbingVine` on a small stone wall at the back of the clearing. The wall is ordinary demo scenery and is separate from the reusable vine.

Run `godot --path . --script res://tests/wall_vine.gd` with a graphics device for deterministic placement, count, bounds, climbing/hanging modes, palette stability, smooth disturbance, and geometry-budget checks.
