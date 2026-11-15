# Painterly neighborhood houses

Instance `painterly_neighborhood_house.tscn` for a reusable exterior house family.
It extends the existing bungalow, using its window/shingle geometry helpers,
opaque vertex paint, seeded broad pigment, editor rebuilds, ground exclusions and
assembled recall. Front faces local **+Z**, origin is the ground footprint center.

| Profile | Silhouette |
| --- | --- |
| Bungalow | Original First Meeting house geometry, including optional dormer. |
| Front Gable | Ridge along local Z, gable window and optional covered porch. |
| Side Gable | Ridge along local X, broader side-facing roof and covered porch. |
| Porch Duplex | Front gable and a second scenic porch stacked above the lower porch. |

For the three new profiles, **Storeys** (1–3) and inherited **Wall Height** set
the building height. **Porch Enabled / Depth** add a full-width deck; inherited
stair, roof, window, rail, palette and seed controls tune the details. **Dormer**
applies to Bungalow. Use dimension controls rather than nonuniform Node3D scaling.

Each house uses one opaque mesh/surface and no per-board/window nodes or dynamic
lights. Default profile counts are 4,006 / 4,238 / 4,212 / 4,910 triangles. Solid
exterior collision, continuous stair ramps, porch guards and an open center keep
the lower entrance reachable. The stacked upper porch is scenic; interiors and
door opening are outside this component. `FrontDoor` and `Approach` markers,
`get_entrance_run()`, and `excludes_ground_point()` support scene composition.

Enable **Recall Enabled** on authored memory instances. Optional **Recall Anchor**
can point to a street approach so the full house resolves before reaching it.
All profiles use the original opaque bungalow paint. Houses have no per-frame
visibility updates.

Run `res://tests/scenes/neighborhood_house_test.tscn` with F6 for the editor study.
`tests/neighborhood_house.gd` checks all profiles, edits, real stair travel,
exclusions and solid exterior collision. The first full scene is
[Mifflin](../../../scenes/memories/mifflin/README.md).
