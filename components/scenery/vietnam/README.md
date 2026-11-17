# Northern Vietnam scenery kit

Four reusable procedural components share the existing opaque vertex-paint,
generated-child, collision, placement-anchor and assembled-recall framework.
All roots sit at ground level and face local **+Z**. Generated geometry stays internal;
scene files save parameters. There are no per-frame geometry rebuilds or new textures.

| Scene | Main authoring controls | Anchors |
| --- | --- | --- |
| `buildings/painterly_hanoi_house.tscn` | Footprint, floors (1–5), floor height, parapet/tiled gable/stepped terrace, balconies, awning | Approach |
| `bridge/painterly_red_bridge.tscn` | Length, width, arch rise | Shore (+Z), Island (−Z) |
| `temple/painterly_lake_temple.tscn` | Ngoc Son Pavilion / Turtle Tower, footprint | Approach |
| `karst/painterly_limestone_karst.tscn` | Footprint, height, crown lobes, seed | — |

All expose body/accent/trim/roof colors, seed, pigment, collision, contact shadow,
visibility distance and recall with an optional reachable anchor. Prefer dimensions
over nonuniform scaling. The new kit reuses the established mathematical curved-roof
helper and matte paint shader; its architectural proportions and assemblies are new.

**Shophouses** are solid scenic exteriors with narrow fronts, shuttered upper windows,
railed balconies, small planters and striped shop awnings. There is no cutaway or
enterable shop. Leave clearance beyond awnings and bring foreground rows back if
the fixed camera hides the lane. Balcony interiors and roofs are not playable.

**Red footbridge** has individual planks, curved rails, posts and continuous convex
walking segments. `surface_height(z)` exposes the same arch profile used by collision
and guidance. Both ends meet at Y=0.06. Match adjacent paving to that datum and keep
ordinary water-shore blocking off across the bridge. The shared guide planner
recognizes BridgeRamp segments as supported slopes.

**Lake landmarks** are compact interpretations: the pavilion has ochre walls,
vermilion posts and layered terracotta roofs; Turtle Tower has three pale tiers and
inset openings. Both are closed scenery. Supply island ground and foliage separately.

**Karsts** use seeded fluted rings and uneven domed crowns, broad stratified stone
colors, and vegetation masses batched into the same opaque mesh. Peaks controls
crown lobes, not a precise peak count. Additional existing jungle plants can sit on
selected ledges; use the same accessible recall anchor. Disable collision on distant
islands. This is a static scenic component, not climbable terrain or a rock simulation.

Default opaque geometry budgets are roughly **2.2k triangles** per shophouse
(3.3k with the tiled roof), **4.4k** for the bridge, **3.4k / 3.8k** for the two
lake landmarks and **6.4k** per karst. Each uses one static painted surface, plus an
optional contact-shadow plane.

`tests/vietnam_components.gd` checks finite normals/vertices, seeded generation,
variants, mesh budget, collision toggles, recall persistence and scene serialization.
`tests/northern_vietnam_memory.gd` exercises the real bridge in both directions and
captures the composed kit in the Mobile renderer. Phone performance needs profiling.

References: [Vietnam Tourism's Old Quarter guide](https://vietnam.travel/things-to-do/explore-old-quarter-your-way/)
for narrow streets and the lake's red bridge, temple and Turtle Tower;
[UNESCO's Ha Long Bay–Cat Ba description](https://whc.unesco.org/en/list/672/)
for the varied forested limestone silhouettes. No remote images are bundled.

## Central Vietnam additions

- **`imperial/painterly_meridian_gate.tscn`**: a Hue-inspired stone gate with three
  real arched passages, a central muted gold double roof and lower green wings.
  **`imperial/painterly_thai_hoa_hall.tscn`** shares the generator, selecting the
  hall profile with red columns, ochre walls, gold roof tiers and restrained ridge
  ornaments. Adjust **Footprint**, **Landmark** and the shared colors. Passage and
  Approach anchors locate the gate; the hall supplies Approach. They are compressed
  scenic exteriors, not survey-accurate replicas or enterable buildings. Golden
  roofs identify these imperial pieces separately from the Hanoi pavilion.
- **`terraces/painterly_rice_terraces.tscn`**: configurable **Footprint / Tier Count /
  Terrace Rise / Curvature / Plants per Square Meter** build curved earthen shelves
  with progressively narrower upper tiers. Blades, soil and contour bunds share a
  single opaque surface. Shader breeze pins roots; optional **React to Explorers**
  sends both player positions to the crop shader. No per-plant nodes, realtime
  shadows or per-frame geometry rebuilds are used. `edge_point(tier,x)` exposes
  the same contour function for neighboring paths. Convex ground cells follow
  each curved tier when collision is enabled. Terrace edges are steps; author a
  gently sloped path between levels rather than expecting automatic climbing.

Default geometry is approximately **14.2k triangles** for the gate, **4.6k** for the
hall and **21.5k** for six planted rice shelves; density and dimensions change the
crop budget. Each owns its ordinary recall controller and preserves progress on
rebuild. Rice remains visible in the editor and defaults to decorative collision-off
usage; the Central Vietnam memory enables terrain collision and a reachable recall
anchor. The shared guide planner recognizes sand and rice walking surfaces.

The [Central Vietnam memory](../../../scenes/memories/central_vietnam/README.md)
walks the sand, climbs/descends the actual field paths and crosses the gate. Reuse
`tests/vietnam_components.gd` for seeded geometry, finite normals, collision toggles,
recall and serialization. Native views live in `docs/previews/central_vietnam-memory-*.png`.
Mobile phone performance has not been profiled.

Architectural anchors were checked against
[UNESCO's Hue conservation mission](https://whc.unesco.org/document/224054) and
[Vietnam Airlines' Imperial Citadel guide](https://www.vietnamairlines.com/gb/en/plan-book/travel/travel-guide/hue-historic-citadel).
The beach interprets the user's requested crescent rather than reproducing a
measured coastline; [Vietnam Tourism's Da Nang overview](https://vietnam.travel/place-to-go/south-central-coast-central-highlands/da-nang/)
provides the sandy-coast/forested-peninsula context. No reference images are bundled.

## Southern Vietnam additions

**`coast/painterly_coastal_headland.tscn`** supplies the missing solid support for
the existing lighthouse. **Footprint / Cliff Height / Prop Seed** create an uneven
coastal rock outline with a flat green cap, broad painted faces and one convex
collision body. **Summit** locates the upper datum. Place the lighthouse separately
at that height; keep incoming/outgoing paths flat before crossing the rock edge.
Use existing curved paths for slopes. The component has **528 triangles**, one
opaque paint surface and ordinary recall; it has no runtime terrain simulation.

**`city/painterly_lotus_tower.tscn`** and
**`city/painterly_clustered_spire_tower.tscn`** inherit the existing modular city tower
and its paint, collision, anchors, recall, visibility and optional billboard layer.
**Skyline Form** selects a tapered rounded tower with projecting helipad or a
cluster of stepped shafts and a tall central spire. **Footprint / Floors / Floor
Height** set compressed dimensions; body/roof/trim colors control the glass and
facade bands. The normal slab Profile, window-lit fraction and storefront sign
fields are hidden because these profiles do not use them. There are no interiors
or accessible roofs. The presets default to unlit screens/halos and use roughly
**22.1k / 5.1k triangles**, each in one opaque surface plus an optional contact plane.
These are skyline interpretations, not measured replicas of specific buildings.

The [Southern Vietnam memory](../../../scenes/memories/southern_vietnam/README.md)
reuses the actual Da Nang crescent outline on PainterlySandPatch, existing liquid
water, jungle planting, lighthouse, dunes, roads, paving, generic towers and crowds.
Its real-explorer test traverses the cape in both directions, follows dune relief
with footprints, and reaches every fragment through the city. The kit's shared
geometry/recall/serialization checks include all three new presets. There is no
per-frame geometry upload; target-phone performance still requires profiling.

Reference anchors: [Vietnam's official Bai Mon/Mui Dien guide](https://vietnam.travel/things-to-do/phu-yen-undiscovered-nature-and-remote-culture/)
and [national tourism description of the cove](https://vietnamtourism.gov.vn/en/post/21372)
for the forested beach and elevated lighthouse; the official
[Vietnam city panorama guide](https://vietnam.travel/things-to-do/vietnam-360-degrees/)
for the lotus and bamboo-like skyline silhouettes. No remote imagery is bundled.

The lake pavilion also supports **Roof Tiles Enabled** for shallow, broad painted
tile relief. Central Vietnam uses this with a green roof for its Marble Mountains
clearing; the default pavilion and Turtle Tower presets retain their roof settings.
