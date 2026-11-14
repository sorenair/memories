# Painterly paving

Instance `painterly_paving.tscn` for a soft, remembered sidewalk or house approach. Local Z follows the path. First Meeting uses a rotated strip for the sidewalk and a short strip leading to the stairs.

The mesh has gently varied slab widths, rounded worn corners, slight misalignment, broad pigment washes, and quiet joints. A shared shader dissolves the sides and ends through large brush cells. A faint underpainting softens the seams. All visuals share one small mesh/material per strip, with no runtime frame callbacks or shadow passes.

Inspector controls: **Footprint**, **Slab Length**, **Paving Seed**, **Irregularity**, **Paving Color**, **End Fade** (negative/positive Z, in meters), **Edge Softness**, and **Breakup Size**. Set either fade length to zero for a solid connection to stairs or another strip.

Collision is a continuous shallow box, keeping arrival height and walking smooth while the visual pigment breaks apart. The shared groundcover exclusion API keeps the center clear and lets foliage overlap the eroded margins.

## Curved paths

Use `painterly_curved_path.tscn` for a genuinely winding route. It is a **Path3D**:
select the root and edit its **Curve** with Godot's native points and Bézier
handles. A small default S curve appears when no curve is supplied. Keep the
points at floor height and leave enough bend radius for the chosen width;
self-intersecting or very tight folded ribbons are not resolved automatically.
Curve tilts do not bank the surface.

**Path Width**, **Sample Spacing**, **Slab Length**, seed, color, irregularity,
end fades, edge softness and breakup size control its appearance. One mesh bends
the slabs and underpainting continuously along the curve. The existing paving
shader uses across/along UV meters for this component; straight paving retains
its original X/Z mapping. There are no runtime animation callbacks or per-frame
mesh uploads.

One static, two-sided triangle collider follows the ribbon instead of creating
a rectangular walking box around it. Geometry, collision and groundcover
exclusion regenerate when curve handles change. Use the shared MemoryPlatform
for the memory's overall supported ground and safe perimeter.

`get_path_length()` and `point_at(distance)` expose local centerline positions.
`get_route_points(from_ratio, to_ratio, spacing, height)` returns world points
along either direction for guidance or an authored walking sequence. Convert
those points to the consuming guide's local space. Como's
`scripts/conservatory_memory.gd` attaches its jungle fragment and both guidance
legs to this single curve, so moving a handle cannot leave them on the old route.

```sh
godot --headless --path . --script tests/curved_path.gd
godot --headless --path . --fixed-fps 60 --script tests/como_conservatory.gd
```

Checks cover support along the center and both passing lanes of a transformed
S curve, absence of rectangular collision across the void, foliage exclusions,
seeded paint, live handle edits, serialization and clearing the curve. The full
Como check walks the actual explorer down the trail and back.
