# Como Conservatory — January 14, 2026

Run `scenes/world/como_conservatory_world.tscn` with F6, or recall **Como Conservatory** from the timeline. Stable ID: `como_conservatory`; three standard zones in order: **FlowerGarden → Jungle → Bonsai**.

## Brief and layout

Confirmed: Como Conservatory in Minnesota, January 14, 2026; a long two-lane flower garden with a central water row, fountain and cypresses, a dense jungle room, and a minimal room with three bonsai pedestals. The supplied photograph guides the teal barrel-vault ribs, vertical cypress silhouettes, stone edging, and pink/red flowering beds. This is a selective memory composition, not a measured reconstruction. Personal wording and the precise species/display arrangement on that date remain unspecified.

- **Flower garden:** arrive on a wide landing before the reflecting rill. Either 2.15 m lane leads between low inner blossoms and larger outer beds. Eight cypresses punctuate eighteen flowering bushes. Flush stone banks and matching entry/fountain end caps enclose the blue rill; water and masonry collision protect it. Larger flower masses, ferns and low leaves fill the beds while keeping the two lanes clear. Crossings at both ends connect the lanes; a marble fountain anchors the far end. The fragment stands beside the fountain on the right lane.
- **Jungle:** a bent passage leads into six broadly crowned trees, four palms, three bamboo screens, sixteen bush groups, fifty-two tropical broadleaf/fern groups, low leaves, and a blue pool. One continuous Bézier ribbon curves through the planting, with its fragment attached to a point along the trail. Taller planting sits back from the route; lower foliage frames the camera-facing edge. There is no overhead wireframe in this room.
- **Bonsai:** a short connection crosses the white space into three separated displays: upright, windswept, and half cascade, each with its own tray and pedestal. The fragment sits in the open viewing area before them. There is no overhead wireframe, crowd or extra planting bed. Walk up to each pedestal for an intimate view.

One invisible custom-outline **MemoryPlatform** supports every room and connecting path, including the guest arrival 1.2 m to the right. Individual paths and garden edging provide visible ground; the shared floor creates no gray carpet or internal collision rims. The unsupported gaps between rooms remain void. Exit is a marker in the bonsai viewing area; use the inherited timeline button to return.

## Reuse and style

The component library was reviewed before building. Flower bushes, columnar cypresses, broadleaf/willow trees, bushes, grass, water, marble fountain, stone walls, bonsai, paving, fragments, requested guidance, audio, and shared world/LAN behavior are reused. Seeds, dimensions and the existing conservatory palette produce variation without copying generated geometry.

The flower garden alone retains `components/scenery/conservatory/frame/painterly_greenhouse_frame.tscn`: a few thin teal barrel-vault ribs and longitudinal members, built with the existing painted scenery workflow. There is no opaque roof or complete glass shell over the explorer. Size, eave height, roof rise, rib count, color, collision and recall anchor are editable. Open View Side omits the near/east half so roof members do not cross the player or displays. The garden frame recalls from a reachable approach marker; other scenery uses proximity recall, and foliage responds to both explorers. The jungle and bonsai rooms have no frame.

The camera starts at First Meeting's 3.5 orthographic size. The garden opens only to 4.8, jungle exploration stays at 3.5, and individual bonsai views use 4.2. Fixed yaw and exponential blending preserve movement directions and work on the return route. The camera favors the explorer and nearby plants rather than fitting the entire room.

The new reusable `components/groundcover/paving/painterly_curved_path.tscn` is a Path3D with editable Curve3D handles. It generates one continuous painterly ribbon, matching walking collision and planting exclusions. `scripts/conservatory_memory.gd` places the jungle fragment at **Jungle Fragment Ratio** and derives both requested guidance legs from the same curve. Editing the trail therefore updates the route, collision, note position and hints together. Large plants are authored independently; keep their stems outside the path when reshaping it. See [curved-path authoring](../../../components/groundcover/paving/README.md#curved-paths).

## Editing

| Change | Location |
| --- | --- |
| Date, title, timeline order | `UI/memory_lane/memory_lane.gd`, `MEMORIES` |
| Entry, room positions, shared floor and connecting paths | `scenes/memories/como_conservatory.tscn` |
| Plants, fountain/rill, walls and local paths | Each zone scene's **Scenery** |
| Jungle bends / width | Jungle **Scenery/WindingPath → Curve / Path Width**; edit native Bézier handles |
| Fragment position along the trail | Memory root **Jungle Fragment Ratio**; personal text stays on Jungle/Fragment |
| Personal text | Each zone's **Fragment → Interaction → Note Title / Notes**; all three contain distinct explicit placeholders |
| Ambience/balance | Zone root **Ambience Stream / Volume dB / Size / Blend Distance** |
| Future soundtrack / fragment cue | Memory **Audio**; music is currently unassigned |
| Camera sizes and reveals | `scripts/conservatory_camera.gd` |

Garden water and jungle air/leaf/drip beds are original synthetic placeholders, reproducible with `tools/generate_conservatory_audio.py`. The bonsai room reuses the quiet room bed. These are artistic sound beds, not recordings of the visit. Zone ambience blends through the shared mixer; fragment cues use SFX. LAN shares avatar choice/movement while sound, notes, recall and scenic animation remain local.

## Validation and previews

```sh
godot --headless --path . --script tests/curved_path.gd
godot --headless --path . --fixed-fps 60 --script tests/como_conservatory.gd
godot --path . --fixed-fps 60 --resolution 1600x738 --script tests/como_conservatory.gd -- --capture
godot --headless --path . --script tests/memory_lane_smoke.gd
godot --headless --path . --script tests/memory_effects.gd
```

The scene check walks both flower lanes and both water crossings, pushes against the rill bank and both end caps, follows the actual curved jungle centerline to the three displays, activates every fragment, requests guidance for each leg, approaches all three bonsai pedestals, and walks back to arrival. It checks grounded joins, supported paired spawns, audio, camera changes, dated timeline recall, and character choice. Add `-- host` / `-- guest` in separate processes for the local LAN presence/walking check; omit `--fixed-fps` in that mode.

Rendered scene previews live in `docs/previews/como-conservatory-{arrival,flowers,fountain,jungle-entry,jungle,jungle-exit,bonsai,overview}.png`. Component-study previews retain their separate `conservatory-*` names. Local tests do not establish physical iOS frame rate or physical network behavior.
