# Central Vietnam · June 15, 2026

**Da Nang · Marble Mountains → terraced rice fields → Hue Imperial City**, in three
zones. Recall **Central Vietnam** after Northern Vietnam, or open
`res://scenes/world/central_vietnam_world.tscn` with F6.

## Brief and reuse

The Da Nang beat is a lush limestone grove with a green-tiled temple nestled in
its clearing. Six faceted limestone formations, elevated broadleaf crowns,
palms, bamboo, broad tropical leaves, ferns and low bushes carry that identity.
A winding flagstone approach opens into the small temple court, then turns out
towards the fields. The front remains open to the ivory void.

The composition draws on the pagodas among the limestone peaks described by
[Vietnam Tourism](https://vietnam.travel/things-to-do/around-marble-mountains/).
It is a compressed, stylized recollection, not a surveyed reproduction of a
particular pagoda. Green roof tiles are the author's requested color. Personal
wording, the rice field's precise location and time of day remain unspecified;
notes are explicitly placeholders and the world uses shared soft daylight.

The memory reuses the limestone karsts, water, jungle planting, surface paths,
rice terraces, sculpted fire and crowd components. The devotional scenery
profiles add the seated gold statue, field shrine and bronze censer.

## Layout

- **Marble Mountains:** `marble_mountains_zone.tscn` replaces the beach. Six solid
  ridges, spires and shelved bluffs frame the **NestledTemple**. **MountainRoute**
  follows a walkable flagstone curve from the jungle arrival, past the fragment
  in front of the temple, and onto **ToFields**. **TempleCourt** adds broad stone
  paving, with a player-scale golden Budai on a lotus base to the temple's
  right. Exit planting guides the route where the flagstone and earth fade
  apart. The temple, statue and cliffs recall from **MountainView**.
- **Rice:** `rice_zone.tscn` has eleven individually shaped, flooded paddies
  at staggered levels. **BundWalk** winds between the plots and climbs to the
  overlook. Halfway up, **ShrineVisit** wraps around an open, four-post shrine
  on a dry terrace and leads to the relocated fragment beside the burning
  censer. **ToHue** descends the earthen bank before its tread fades. Paddies,
  banks and the dry clearing share one terrain mesh and collider.
- **Hue:** `hue_zone.tscn` approaches the **MeridianGate** through its open central
  arch, then reaches a lotus-pond court and **ThaiHoaHall**. Worn masonry courses,
  glazed eaves, warm roofs, scarlet lattice and low stone balustrades take cues
  from the Imperial City. Flowering bushes and ferns soften the court and gate
  apron. Animated visitors gather to the sides of both. The fragment is in
  front of the hall. [Vietnam Tourism's Huế virtual tour](https://vietnam.travel/sites/default/files/360Tour/Hue/index.htm)

**Environment/VietnamFloor** is one hidden finite platform using
`walk_outline.tres`, formed from the solid mountain clearing, buffered
connections and the two other land clusters. It supplies outer support without
internal platform rims. The host and the guest's 1.2 m X spawn offset fit on the
arrival path. The guidance curves and finite floor carry walks across the
visible breaks. The rice bund and its banks share the same authored curves,
with a single static collider for the banks and paddy ground.

## Authoring

Edit **Fragment → Note Title / Notes** in the relevant zone:

| Zone | Placeholder title |
| --- | --- |
| Marble Mountains | A temple among the limestone |
| Rice | Along the rice terraces |
| Hue | Within the imperial walls |

`../../../scripts/central_vietnam_memory.gd` derives requested brushstroke routes
from the authored curves. The first route ends at the temple fragment; the next
continues along **MountainRoute**, **ToFields**, **BundWalk** and **ShrineVisit**.
The Huế hint leads back around the shrine to the bund. Update the
supported floor when extending a path; run `godot --headless --path . --script
tools/rebuild_central_vietnam_floor.gd` to regenerate its connected outline.
On **RiceTerraces**, edit **Paddy Contours** and **Dry Clearings** as closed,
level local curves.
**Bund Paths** references **BundWalk** and **ToHue**, which should meet on
the same grade and share a width. The bank rebuilds from those curves when
they change. Keep the paddy shoulders clear of the footpath. Align the
clearing, shrine approach and fragment when moving the detour.

The camera holds **4.7** for walking, including between the paddies. It widens
to **17.6** at the temple, **14.0** on the rice crest, **11.6** at the gate
and **8.8** in the palace court. The reveal areas and focus points live in
`../../../scripts/central_vietnam_camera.gd`.

Each zone has a quiet ambient bed. The mountain grove and fields reuse jungle
ambience as a placeholder, not a location recording. The previous beach surf and
sea palette remain available assets but are no longer used by this memory.
Music remains available on Memory/Audio and fragment chimes use SFX. LAN shares
avatar identity and movement; notes, recall, audio and scenic breeze remain local.

## Validation and views

```sh
godot --headless --path . --script tests/vietnam_components.gd
godot --headless --path . --fixed-fps 60 --script tests/central_vietnam_memory.gd
godot --path . --fixed-fps 60 --script tests/central_vietnam_memory.gd -- --capture
```

The real-explorer walkthrough covers both directions, supported arrival,
finite path containment, the temple fragment, the rising/descending field
routes and shrine detour, the central gate, all note tap targets, requested guidance, ambience,
camera changes and timeline avatar choice. Separate `-- host` / `-- guest`
processes use isolated UDP **24745** for partner presence and movement;
production IP entry stays on 24680. Native Mobile renders are saved in
`docs/previews/central_vietnam-memory-*.png`. Phone/Wi-Fi performance has not been
measured. Existing headless material and macOS shader-cache/exit resource warnings
may appear.

[Before and after](../../../docs/previews/central-vietnam-polish-comparison.jpg) ·
[Walking among the rice paddies](../../../docs/previews/central_vietnam-memory-rice-bund.png)

![Marble Mountains clearing](../../../docs/previews/central_vietnam-memory-mountains-overview.png)
