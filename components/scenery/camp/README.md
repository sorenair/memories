# Painterly camp props

Reusable exterior props use the existing conservatory piece builder, painted
material, contact shadow, solid collision and assembled recall framework. Both
origins sit at ground level. They preview and rebuild in the editor; generated
geometry stays internal.

| Scene | Shape and controls |
| --- | --- |
| `adirondack/painterly_adirondack_chair.tscn` | Raked slatted seat, tall fanned back, broad arms and runners. Front faces local +Z. Chair Color, Seat Width and Back Height control the silhouette. |
| `fire_pit/painterly_fire_pit.tscn` | Low open steel ring, crossed logs, coal bed, feet and optional half grate. Radius, Metal Color and Grill Enabled control the bowl. |

The [backpacking set](BACKPACKING.md) adds an orange Stormbreak-style tent with
subtle shader wind and a WhisperLite-style stove, pot and red fuel bottle with
optional flame/steam. It also links the gray 2018 4Runner in `components/vehicles/`.
Run `tests/scenes/backpacking_test.tscn` with F6 for all three beside the explorer.
These additions reuse the same painted-prop and assembled-recall conventions;
their controls, geometry and validation are covered in the separate guide.

The chair provides a `Front` marker; the pit provides `Approach` and `FireBase`.
Use `get_anchor()` for placement. Both implement `excludes_ground_point()` for
snow/groundcover exclusions. They are decorative props with solid collision;
seating interactions and fire damage are outside these components.

Each prop batches its painted parts into one opaque surface plus a contact
shadow, with no per-board or per-log animation. The chair uses a box collider;
the pit uses a cylinder that keeps explorers outside the flames. Shared base
controls provide collision, shadow, pigment and optional recall.

The pit scene instances the existing `components/vfx/fire/painterly_fire.tscn`
as `Fire` at its bowl. Tune that child's flame size, colors, speed and embers for
other compositions. The pit mirrors its **Recall Enabled** and optional **Recall
Anchor** onto the fire so they resolve from the same reachable approach. A
separate painted light wash can add warmth to the surrounding snow.

The first authored placement is [Postcard Cabin](../../../scenes/memories/postcard_cabin/README.md).
`tests/postcard_cabin_memory.gd` checks real walking clearance and the fire-ring
barrier; its native captures show both props at the game's exploration scale.
