# Tokyo scenery kit

Seven reusable scene presets cover Meiji Jingu, Sensō-ji and a Shibuya-inspired city. They use broad matte pigment, softly curved roof meshes and the existing assembled-recall/collision framework. Geometry previews live in the editor. Roots sit at ground level and face local **+Z**.

## Components

| Scene | Main exported controls | Placement anchors |
| --- | --- | --- |
| `shrines/meiji_wooden_torii.tscn` | Opening width, gate height | Passage, Approach |
| `shrines/meiji_worship_hall.tscn` | Footprint, wall height, roof rise | Approach, PrayerFront |
| `shrines/sensoji_main_hall.tscn` | Footprint, wall height, roof rise | Approach, PrayerFront |
| `shrines/sensoji_hozomon_gate.tscn` | Gate width, gate height | Passage, Approach |
| `shrines/sensoji_pagoda.tscn` | Base width, tower height | Approach |
| `city/painterly_city_tower.tscn` | Profile, footprint, floors, floor height, lit fraction, sign text, billboard controls | Entrance, Roof |
| `city/painterly_scramble_crossing.tscn` | Extent, road width, asphalt color, diagonal and signal toggles | Center, NorthApproach, DiagonalApproach |

All props also expose **Prop Seed**, body/accent/trim/roof colors, pigment strength, glow strength, visibility distance, collision and contact-shadow toggles, and optional recall with an approach anchor. Use dimensions rather than nonuniform root scaling when possible. Generated meshes, colliders and anchors are internal children; only authoring parameters serialize. `get_anchor(&"Approach")` returns a generated `Marker3D`.

The two halls share one generator. **Hall Style** changes their structural details; use the corresponding scene preset for its starting palette. Meiji has dark timber, an aged copper-colored roof, a prominent curved front gable, gold curtain and pale paper streamers. Sensō-ji has vermilion framing, pale panels and a taller gray roof. Both have closed bodies with accessible front verandas; their short stairs use a continuous ramp collider. They do not contain enterable interiors.

The wooden torii and Hōzōmon gate have clear ground-level passages. Hōzōmon adds two roofs, lattice guardian bays and three hanging lanterns, with clearance below the central lantern for the explorer. Lanterns are intentionally unlettered. The pagoda has five graduated roofs and a gold finial; it is a sealed scenic object. These are stylized landmark exteriors with compressed proportions, not survey-accurate replicas.

## City authoring

Choose **Slab**, **Setback Tower**, or **Chamfered Corner** for different silhouettes. Footprint and floor count provide the largest changes; seeds vary window lighting and subtle paint. Accent color tints the illuminated windows, sign ribbon and billboard palette. Sign text is optional and limited to 20 characters.

Billboards reuse the [concert display shader](../concert/README.md), including its evolving graphic families and painterly transitions. **Screen Speed = 0** freezes the pattern; **Screen Enabled** removes both display and halo, while **Halo Enabled** can remove just the translucent glow. `seek_time(seconds)` provides deterministic previews; pass `-1` to resume the shader clock. There are no per-tower CPU animation callbacks or real-time light nodes. Building collision encloses the full footprint; rooftops and interiors are scenery, not playable floors. The Roof marker is a placement hook, not a promise of roof access.

The crossing has four zebra crossings around the junction and an optional diagonal, pale corner pads, optional static pedestrian signal posts, and broad painted asphalt arms that fade toward the ivory void. It supplies a flat ground collider and groundcover exclusions. Place and rotate tower instances outside its walking space to make street walls; replace the study crowd with independently arranged groups as needed. It is a reusable scramble-crossing composition, not a measured Shibuya street map. Signal lights do not simulate traffic phases, and the existing crowd remains standing with subtle motion.

Keep the shared memory platform underneath a composed scene to provide its outer floor and safe perimeter. The component studies are inspection layouts; they are not timeline memories or a proposed route between the real locations.

## Preview and validation

Open either inherited component stage and press **F6**:

- [`tests/scenes/tokyo_temples_test.tscn`](../../../tests/scenes/tokyo_temples_test.tscn): Meiji torii and worship hall, Sensō-ji main hall, pagoda and Hōzōmon, with existing foliage and the explorer for scale.
- [`tests/scenes/tokyo_city_test.tscn`](../../../tests/scenes/tokyo_city_test.tscn): five varied towers around the crossing, animated screens, the existing crowd and restrained light washes. A central walking route remains clear.

Run `Godot --headless --path . --script tests/tokyo_components.gd` for deterministic geometry, finite normals, recall/rebuild/serialization, collision toggles and actual explorer traversal through the gates, along the crossing and up/down both hall steps. `tests/tokyo_render.gd` captures the studies in the Mobile renderer and checks that billboard patterns move and freeze correctly. Captures live in `docs/previews/tokyo-*.png`.

Default temple triangle counts are 2,292 (torii), 6,096 (Meiji hall), 4,860 (Sensō-ji hall), 7,768 (Hōzōmon), and 8,848 (pagoda). Each uses one opaque mesh surface, plus an optional contact-shadow plane. Towers similarly batch their static geometry into one surface, plus optional display/halo/shadow layers; the crossing adds one asphalt plane. Roof curves and rounded posts avoid conspicuous cylindrical facets. These are geometry budgets and desktop Mobile-render checks, not a phone performance benchmark.

## Reference sources

Architectural anchors were checked against the sites' own material:

- [Meiji Jingu precinct map](https://www.meijijingu.or.jp/en/map/) and [sanctuary photographs](https://www.meijijingu.or.jp/en/whattosee/sanctuary/): timber torii, dark wooden worship hall, copper roof and curved front gable.
- [Sensō-ji official guide](https://www.senso-ji.jp/english/), [five-story pagoda](https://www.senso-ji.jp/guide/guide06.html), and [Hōzōmon](https://www.senso-ji.jp/guide/guide03.html): the main hall, graduated pagoda and two-story lantern gate are separate structures, so the kit includes all three.
- [GO TOKYO: Shibuya Crossing](https://www.gotokyo.org/en/spot/78/), [Shibuya district](https://www.gotokyo.org/en/destinations/western-tokyo/shibuya/index.html), and [QFRONT](https://www.gotokyo.org/jp/spot/366/index.html): scramble-crossing, dense facade and large display references.

Reference photographs were used only for inspection and are not bundled. All supplied geometry, paint and billboard imagery are procedural; signs use generic wording rather than reproduced brands or advertisements.
