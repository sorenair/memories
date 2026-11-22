# Dry-garden pieces

The garden components reuse the established painted-prop, generated collision,
ground-exclusion and assembled-recall framework. The [Duluth autumn memory](../../../scenes/memories/duluth_autumn/README.md)
combines them with existing boulders, woodland understory and autumn trees.

| Scene | Authoring controls |
| --- | --- |
| `painterly_raked_gravel.tscn` | Footprint, up to three Rock Centers in local X/Z, Rake Spacing, Rake Strength, Body Color, Edge Color, Rim Variation, Prop Seed |
| `painterly_stone_lantern.tscn` | Lantern Height, Body / Accent / Trim Colors, collision and recall |
| `painterly_peace_bell.tscn` | Body / Accent / Trim Colors for timber, roof, and fittings, plus Strike Sound, collision, and recall |
| `painterly_enger_tower.tscn` | Body / Accent / Trim Colors for stone and the lookout roof, plus collision and recall |

The gravel is one 80-triangle opaque bed with an irregular, ivory-feathered edge.
Its shader draws filtered concentric rake grooves around the nearest rock center.
Pattern/paint edits update uniforms without rebuilding geometry. Place existing
boulders at the matching centers; the bed itself adds no stones or collision.
Supply a memory floor underneath. `get_ground_outline()` and
`excludes_ground_point()` let surrounding planting stay off the bed.

The lantern has a tapered pedestal, open chamber, broad four-sided roof and rounded
finial, all in one matte stone batch. A simple exterior collider preserves walking
clearance. Its small interior accent stays unlit. Height scales geometry, collision
and the Approach marker together.

The Peace Bell pavilion uses an open timber frame, layered roof, and recessed bronze bell with a hanging wooden striker. Its column and bell colliders leave the sides open for viewing. The tap interaction moves the striker and bell only while ringing, with the gong routed through the SFX bus.

The Enger Tower exterior has window openings, an octagonal landing, and a rooftop lookout rail. The Roof anchor can be used to check camera framing.

All roots are ground level. **Recall Enabled / Recall Anchor** keep independent
proximity discovery and preserve progress through rebuilds. Generated meshes,
anchors and physics remain internal. Static garden pieces need no CPU animation,
mesh uploads or extra textures. Physical phone performance is unmeasured.

Open `res://tests/scenes/zen_garden_test.tscn` with F6 for a simple study with the
existing boulders and explorer. The generic component stage can also load either
source scene on its own. `tests/garden_components.gd` checks compact finite meshes,
normals, deterministic rebuilds, collision/exclusions, parameter changes, packing
and recall. The rendered memory previews are in `docs/previews/duluth_autumn-memory-*`.
