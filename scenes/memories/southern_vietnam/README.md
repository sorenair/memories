# Southern Vietnam · June 20, 2026

**Bai Mon / Mui Dien → sand dunes → Saigon**, the final three-zone Vietnam memory.
Recall it after Central Vietnam, or open
`res://scenes/world/southern_vietnam_world.tscn` with F6.

The confirmed context is June 20 and these three places. The dune location,
time of day and personal wording were not supplied. The scene keeps the shared
soft daylight and explicitly marked placeholder notes. It is a compressed memory
composition, with quiet coast and open dunes giving way to a crowded city.

## Zones and reused components

- **Bai Mon:** `bai_mon_zone.tscn` reuses the Da Nang crescent and sand component,
  with a brighter blue cove and jade shallows. Jungle foliage frames the beach
  walk. **HeadlandWalk** climbs flagstones set into the coastal ridge, and
  **ToDunes** descends on an earthen tread. Both paths feather into the terrain
  at their ends. The lighthouse and first fragment sit on the shared upper landing.
- **Dunes:** `dunes_zone.tscn` uses a single 30 × 30 m **PainterlySandPatch**, with
  an irregular windward outline, sculpted crests, and the existing two-player
  footprint field. **DuneRoute** is hidden and supplies route hints. Tufts, dry
  shrubs and low stones guide the walk across the actual sand to a faded exit.
- **Saigon:** `saigon_zone.tscn` stages shorter warm-toned street fronts against
  a cooler skyline. Wide, faded setts carry the walk into a moving crowd framed
  by palms and understory. The hidden **CityRoute** leaves a narrow winding lane
  for both explorers.

The [Vietnam scenery kit](../../../components/scenery/vietnam/README.md) contains
only the new supporting headland and skyline profiles. Buildings remain closed
exteriors and their tops may crop during close street exploration.

One hidden **Environment/VietnamFloor** supports all connections and safe outer
boundaries. `walk_outline.tres` merges the crescent, routes, headland, dune field
and city. After extending paths, regenerate it with:

```sh
godot --headless --path . --script tools/rebuild_southern_vietnam_floor.gd
```

## Authoring

Edit **Fragment → Note Title / Notes** in each zone:

| Zone | Placeholder title |
| --- | --- |
| Bai Mon | Above the cove |
| Dunes | Between the dunes |
| Saigon | Among the city towers |

`../../../scripts/southern_vietnam_memory.gd` samples actual sand height for Entry,
the dune fragment, dry planting, rocks and requested guidance. Hints follow the
same authored curves, including both cliff routes. Align the lighthouse, upper
paths and first fragment if changing **Headland → Cliff Height**. Keep a flat
landing before either path crosses the rock edge. The guest's 1.2 m X arrival
offset remains supported on the crescent.

The standard walking size is **4.7**. Framing opens to **10** midway around the
cove, **17.2** on the lighthouse landing, **9.7** near the dune fragment, and
**11.4** in the middle of the Saigon crowd. Each view holds briefly as the
explorer steps out of it, then eases back to the walking camera. Controls are exported from
`../../../scripts/southern_vietnam_camera.gd`.

Recall is enabled throughout. **HeadlandRecall** reveals the elevated lighthouse
from the reachable beach; **CityRecall** reveals the skyline from the avenue.
Foliage responds to both explorers. Each zone owns a quiet ambient bed: surf,
open-air wind and city crowd, all reused placeholder recordings. Music remains
available on Memory/Audio and fragments use the shared SFX cue. LAN shares avatars
and movement; notes, recall, audio, scenic motion and footprints remain local.

## Verification and views

```sh
godot --headless --path . --script tests/vietnam_components.gd
godot --headless --path . --fixed-fps 60 --script tests/southern_vietnam_memory.gd
godot --path . --fixed-fps 60 --script tests/southern_vietnam_memory.gd -- --capture
godot --headless --path . --script tests/memory_effects.gd
```

The real-explorer check walks both directions, climbs and descends the headland,
follows sculpted sand, creates footprints, reads/taps each fragment, requests all
hints, and checks paired arrival, finite support, camera reveals, ambience, scenic
recall and timeline avatar choice. Separate `-- host` / `-- guest` processes use
UDP **24755** for LAN checks; production IP entry stays on 24680. Native Mobile
previews live in `docs/previews/southern_vietnam-memory-*.png`. Physical phone/Wi-Fi
performance is unmeasured. Existing headless material and macOS shader-cache/exit
resource warnings may appear.

[Before and after](../../../docs/previews/southern-vietnam-polish-comparison.jpg)

![Southern Vietnam composition](../../../docs/previews/southern_vietnam-memory-overview.png)
