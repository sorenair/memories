# Duluth in the Fall · October 12, 2026

Three autumn zones connect a **short winding hike and rock lookout → red-and-white
lighthouse by Lake Superior → Japanese zen garden**. Recall it after Labor Day in Colorado,
or run `res://scenes/world/duluth_autumn_world.tscn` with F6.

The date, Duluth, fall colors, rock lookout, striped lighthouse and garden are
confirmed by the brief. Specific park/lighthouse names, time of day and personal
wording were not supplied. Layout distances are compressed for exploration; each
note is explicitly marked as a placeholder. The shared daylight and ivory void
keep the existing memory style.

## Zones and pieces

- **Trail:** `trail_zone.tscn` uses the continuous curved earth trail, autumn gold/red
  broadleaf/birch/oak trees, bushes, grass, falling leaves and resting leaf litter.
  **ForestTrail** winds into **LookoutClimb**, whose flat first section prevents a
  raised ribbon edge crossing the approaching trail. The existing headland model,
  recolored as gray rock, supports a 2.4 m high landing. Distant autumn crowns recall
  from **LookoutReveal**. The first fragment is on the open rock. **ToLighthouse**
  leaves the opposite edge at full height before descending into the next zone.
- **Lighthouse:** `lighthouse_zone.tscn` reuses the existing lighthouse with its new
  optional shaft stripes, blue painterly water, recolored sand for an irregular
  rocky bank, existing boulders and a few autumn shore plants. **ShoreWalk** reaches
  the second fragment west of the closed tower; **AroundLighthouse** passes around
  its rear and **ToGarden** continues through fragments of the void. The roof and
  beacon remain scenic. The modest beam and horizontal paint preserve a clear,
  readable tower silhouette.
- **Garden:** `garden_zone.tscn` combines two small new [dry-garden pieces](../../../components/scenery/gardens/README.md)
  with reused boulders, moss-colored bushes/grass, bamboo, autumn trees, pines and
  partial low stone walls. **RakedGravel** draws filtered rings around the three
  rock islands; **StoneLantern** supplies the quiet architectural accent. The third
  fragment sits at the front of the bed. **GardenCircuit** provides an optional
  perimeter stroll with clearance around the lantern and tree trunks.

The [surface-path family](../../../components/groundcover/paths/README.md) gives
the hike continuous earth rather than sidewalk slabs. Shore connections use
gravel; the lighthouse circuit and garden use irregular flagstones. The original
curves, heights and requested-guidance links are preserved.

The lighthouse's **Stripes Enabled** defaults off, preserving existing scenes.
Duluth sets six alternating ivory/red bands. **Stripe Color / Stripe Count** edit
paint in place; openings, plinth, gallery and fittings retain their own materials.
The new [boulder Recall Anchor](../../../components/scenery/boulders/README.md) lets
all garden stones reveal from the same reachable viewing point. Empty anchors keep
ordinary local discovery, including inherited rock clusters.

## Editing and framework

Edit **Fragment → Note Title / Notes** within each zone:

| Zone | Placeholder title |
| --- | --- |
| Trail | Above the autumn trees |
| Lighthouse | Beside the striped lighthouse |
| Garden | A quiet garden |

`../../../scripts/duluth_autumn_camera.gd` keeps forest walking at **3.5**, opens
to **14** on the rock, **18** at the lighthouse, and **10** for the garden. Transitions
respond to position/height, ease smoothly in either direction, and retain fixed yaw.
The tower's foot and roof both fit in the actual shore view. Revisit framing when
changing tower height or zone positions.

Each zone owns a quiet ambient bed: `autumn_wind`, `central_vietnam_surf`, and
`vineyard_rows` respectively. The latter two are reused placeholder wave/garden
recordings; change **Ambience Stream** on the zone root. Memory/Audio retains the
music slot and shared fragment SFX. Blending follows the local explorer.

All 104 recallable pieces have recall enabled; 81 foliage pieces react to both
explorers. **LookoutReveal**, **ShoreReveal** and **GardenReveal** are accessible
triggers for distant scenery. The gravel and lighthouse paint animate only through
their existing recall/beacon shaders; rake-pattern and stripe color/count edits do not rebuild meshes.
LAN shares avatar choice and walking. Notes, recall, foliage rendering, audio and
scenic motion remain local to each device.

One hidden **Environment/AutumnFloor** supports all connections and safe outer
boundaries. The curves provide actual raised walking collision. Keep summit paths
at **2.4**, with a flat landing before crossing the rock edge. Keep a flat section
at the forest/climb join, including its Curve3D handles. Entry and the guest's
**+1.2 m X** fallback both have clear supported space.

Hints are requested and follow the same path curves, derived by
`../../../scripts/duluth_autumn_memory.gd`. After extending routes or moving zones,
regenerate the finite floor and check it with the actual explorer:

```sh
godot --headless --path . --script tools/rebuild_duluth_floor.gd
```

## Verification

```sh
godot --headless --path . --fixed-fps 60 --script tests/duluth_autumn_memory.gd
godot --path . --fixed-fps 60 --script tests/duluth_autumn_memory.gd -- --capture
godot --headless --path . --script tests/garden_components.gd
godot --headless --path . --script tests/lighthouse_components.gd
godot --headless --path . --script tests/memory_effects.gd
```

The real-explorer check walks both directions, the full optional garden circuit,
climb and descent; taps/reads every note; requests all hints; and checks finite
support, paired arrival, camera reveals, lake/stone recall, ambience and timeline
avatar selection. Component checks cover bounded finite geometry, normals,
seeded rebuilds, packing, collision, shader controls and recall preservation.
Separate `-- host` / `-- guest` processes use isolated UDP **24785**; production
IP-entry LAN stays on 24680. Physical phone/Wi-Fi performance remains unmeasured.
Existing macOS shader-cache and Godot shutdown-resource warnings may appear.

The rendered walkthrough, headless route/fragment/camera check, component checks,
full 18-world recall/foliage audit, timeline smoke test, garden study launch and
two-process LAN host/guest checks pass.

Native Mobile previews live in `docs/previews/duluth_autumn-memory-*.png`.
The separate `tests/scenes/zen_garden_test.tscn` offers an F6 component study.

![Duluth autumn composition](../../../docs/previews/duluth_autumn-memory-overview.png)
