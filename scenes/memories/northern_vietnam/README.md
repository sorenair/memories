# Northern Vietnam · June 6, 2026

Three connected memory clusters: **Hanoi Old Quarter → Hoan Kiem Lake → Ha Long Bay**.
Open `res://scenes/world/northern_vietnam_world.tscn` with F6, or recall Northern
Vietnam after Tokyo on the timeline. The three clusters compress the journey
from Hanoi to the bay.

## Brief and layout

The confirmed context is northern Vietnam on June 6. The composition moves from
an intimate, inhabited street to a leafy island temple and then an open limestone
seascape. Personal stories and time of day were not supplied; notes remain explicit
placeholders and lighting uses the shared soft daylight.

- **Old Quarter:** ten narrow shophouses sit among layered curbside shrubs and
  tropical leaves. Four uneven gatherings use varied facing, stances and
  shader-driven sway, with a shared lane past the fragment. **ToLake** is visible
  at the street turn. Warm setts curve between planting pockets and dissolve
  before the lake landing.
- **Hoan Kiem:** Thê Húc bridge begins at the dry bank. A lakeside bench faces the
  water, and low planting frames Turtle Tower's islet. On Jade Island the bridge
  meets the walk-through Đắc Nguyệt Lâu gate and opens into a small courtyard
  framed by a tiled hall and open Trấn Ba pavilion. The composition takes its
  architectural cues from the site's arrangement and the round gate window.
  [Hanoi Department of Culture and Sports](https://sovhtt.hanoi.gov.vn/en/hoan-kiem-lake-ngoc-son-temple-special-national-monuments-famous-scenic-spots-capital/)
  · [Vietnam Pictorial photo reference](https://vietnam.vnanet.vn/spanish/print/templo-ngoc-son-20767.html)
- **Ha Long:** an existing timber dock opens into a T-shaped overlook over
  tropical blue water painted with the shared water shader's broad pigment
  shapes and soft highlights. Eight limestone formations mix split ridges, slender spires and
  shelved bluffs, with deeper greens in the foreground and cooler cliffs at
  the back. Mint shallows follow the rock contours around the open channels.

The scene reuses **PainterlyWater, PainterlyCurvedPath, PainterlyPaving, PainterlyStreet,
PainterlyCrowd, PainterlyWoodenDock**, broadleaf trees, bushes, grass, and the existing
palm/bamboo/broadleaf/fern kit. New silhouettes are the [Vietnam scenery kit](../../../components/scenery/vietnam/README.md).
One hidden concave **Environment/VietnamFloor** supports the lane, bank, bridge,
island and dock, with safe outer boundaries and no internal platform rims. Water
entry blocking is off where bridge/dock cross the shore; the finite floor and real
rails constrain walking. Both arrivals fit, including the guest's 1.2 m offset.

## Authoring

Each zone owns **Scenery, Fragment, Ambience**. Edit the local **Fragment → Note
Title / Notes** in these files for personal wording:

| Zone scene | Placeholder title |
| --- | --- |
| `old_quarter_zone.tscn` | Along the narrow streets |
| `hoan_kiem_zone.tscn` | On the lake |
| `ha_long_zone.tscn` | Between the limestone islands |

Edit `lake_water.tres` and `bay_water.tres` for the water palettes. The bay
has its own `bay_foliage.tres` palette for the shore and crown trees. All 144
foliage components respond to both explorers within the 197 recallable pieces. Move **BridgeView** with the
near bridge landing and **BayView** with the dock when rearranging the overlooks.

`../../../scripts/northern_vietnam_memory.gd` derives requested hint routes from the
same authored curves, samples the bridge's arched surface, and uses the dock's
placement anchors. When changing bridge or dock dimensions, align adjacent paths,
fragment and finite floor as well. No hint starts automatically after a note.

`../../../scripts/northern_vietnam_camera.gd` uses **4.7** for everyday walking,
including the island note and dock approach. It tips overhead in the island
courtyard to keep the explorer readable between the roofs. It holds **6.1** at
the street fragment, **13.4** at the bridge landing and **22.8** at the end of the
dock. Each reveal eases in and out with fixed yaw.

Quiet existing street, jungle and open-air recordings are temporary ambience beds,
not location recordings. Tune each zone's **Ambience Stream / Volume / Size / Blend
Distance**. Music remains available on Memory/Audio; fragment cues use SFX. The
shared LAN session synchronizes avatar identity and movement; scenic motion, notes,
recall and audio remain local.

## Checks and previews

```sh
godot --headless --path . --script tests/vietnam_components.gd
godot --headless --path . --fixed-fps 60 --script tests/northern_vietnam_memory.gd
godot --path . --fixed-fps 60 --script tests/northern_vietnam_memory.gd -- --capture
godot --headless --path . --script tests/memory_effects.gd
```

The memory check walks both directions with the actual explorer, crosses the
arched bridge, climbs/descends the dock ramp, reads and taps all three fragments,
requests hints, verifies paired arrival, finite support, scenic recall, camera
transitions, ambience and timeline avatar choice. Separate `-- host` / `-- guest`
processes exercise the shared LAN framework on isolated UDP **24735**. Production
IP entry stays on 24680. Physical phone/Wi-Fi performance is not measured.

The Vietnam component tests, full route in both directions, targeted recall and
foliage audit, and two-process LAN avatar and movement checks pass.

Native Mobile-renderer previews live in `docs/previews/northern_vietnam-memory-*.png`.
Existing macOS shader-cache case and shutdown-resource warnings may appear.

[Before and after at four gameplay stops](../../../docs/previews/northern-vietnam-polish-comparison.jpg).
The before captures use the earlier camera and scenery after repairing the scene
load and clearing the bench from the bank route. The later
[path and karst revision](../../../docs/previews/northern-vietnam-paths-karsts.jpg)
shows the approach and overlook in the walking camera.

[Old Quarter exit](../../../docs/previews/northern_vietnam-memory-old-quarter-exit.png)
· [Bridge and temple approach](../../../docs/previews/northern_vietnam-memory-lake-arrival.png)
· [Hạ Long overlook](../../../docs/previews/northern_vietnam-memory-bay-overlook.png)

![Northern Vietnam composition](../../../docs/previews/northern_vietnam-memory-overview.png)
