# Christmas market — December 19, 2025

The fourth authored memory. Select **Christmas market — DEC 19, 2025** in Memory Lane, or run `scenes/world/christmas_market_world.tscn` with F6.

## Brief and composition

A small snowy market recalled through warm ivory space: wooden huts, soft yellow bulbs, decorated evergreens, and acoustic music. The confirmed date is December 19, 2025; no venue, personal anecdote, or exact real-world itinerary has been assumed. Both fragments contain explicit placeholder prose.

The plan has **two standard MemoryZones**:

| Zone scene | Experience | Fragment and ambience |
| --- | --- | --- |
| `market_lane_zone.tscn` | Arrive close, browse four angled huts selling baked goods, ornaments, and warm drinks beneath three festoon strands. | “Among the little market huts”; quiet wind. |
| `music_gathering_zone.tscn` | Follow the bend into a wider clearing with a decorated tree, three acoustic performers, two more huts, benches, and a few listeners. | “Under the lights, listening together”; soft crowd murmur. |

The passage bends left into the gathering, leaving a substantial pocket of white void beside it. Huts face partly toward the arrival path so their counters remain visible from the fixed elevated camera. The stage recalls only a rear canopy strip, keeping the performers visible. Six huts, five decorated pines, small visitor groups, and restrained light pools provide identity without enclosing a whole town square. Both zones also contain **WinterFoliage** groups: nine additional frosted pines/birches, eighteen low bush clusters, and fifteen sparse winter-grass patches. These reuse the existing foliage scenes with the Winter Frost palette, varied seeds, and restrained wind. Planting frames the huts and snow banks while leaving the walking route and fragments clear.

One **MarketFloor** and one **ContinuousSnow** share a custom outline. There are no internal platform rims or separate snow-patch seams. Snow excludes the six hut interiors and the stage. Roof snow belongs to the hut/stage meshes. Both explorers leave tracks in the same existing footprint field. The existing falling-snow component remains decorative, including its documented limitation that flakes do not collide with roofs.

Arrival is `(0, 0.04, 5.4)`; the LAN guest's 1.2 m right-hand spawn also has supported ground. Walk through the lane to the first fragment, then via `(0, -5.5) → (-2.8, -7.4) → (-4.5, -9.8) → (-6, -11.4)` in X/Z into the music clearing. The tree, benches, poles, counters, stage, and visitors have collision; the central route stays clear. Exit is the shared framework's marker, not a new completion system.

The camera starts at **3.5**, opens gently to **4.5** while browsing, then **7.5** at the gathering. It continues following the local explorer while they look around, with fixed yaw and smooth frame-rate independent transitions. Walking back restores the close arrival view.

## Reuse before new components

Planning searched the existing component scenes, READMEs, and exports as required by `docs/MEMORY_DESIGN_GUIDE.md`:

- Reused **MemoryScene / MemoryZone / MemoryPlatform**, fragments, requested brushstroke guidance, world controls, audio mixer, timeline/character arrival, and stable-ID LAN presence.
- Reused **PainterlySnowPatch** with a shared concave outline and footprints, **PainterlySnow** for flakes, **PainterlyTree**'s Layered Pine variant, **PainterlyCrowd** for batched visitors, **PainterlyLightWash** for warm snow pools, and the gallery component's existing bench variant.
- New **MarketHut**, **FestiveLights**, and **MarketStage** cover missing market-specific silhouettes. They reuse First Meeting's geometry builder and the existing batched painterly scenery material. Vendor and musician bodies/heads reuse the crowd's cached meshes, recolored with the same matte material. No new global shader or lighting system was added.
- The stage animates three body roots and two connected arms per performer. Instrument-specific wrist targets keep sleeves outside the instrument bodies; the violin bow translates across its string plane. Meshes stay static and only joint transforms change. Visitor idle motion and flakes remain on the GPU; trees retain their existing wind shader. The decorated pine is a scene composition of existing pine plus light trimming.

## Editing

- Open either zone scene and select **Fragment → Note Title / Notes** to replace its placeholder text.
- Select a hut under **Scenery**: **Goods** chooses Bakery, Handcrafted Gifts, or Warm Drinks; **Wood Color**, **Trim Color**, and **Paint Seed** change its finish. Rotate or move its accompanying warm light wash with the hut.
- Festoon instances expose **Span**, **Height**, **Sag**, and **Poles**. Tree trimming exposes **Height** and **Tree Radius**; the decorated pine scene keeps foliage and decoration together when scaled.
- **MusicGathering / Scenery / AcousticStage → Performance Strength** controls the small playing motion. Geometry and connected arm poses live in `components/scenery/christmas_market/painterly_market_stage.gd`.
- **Scenery / WinterFoliage** in either zone contains the added trees, bushes, and grass. Adjust the native components’ height/footprint, seed, density, wind, or Winter Frost palette there. Grass excludes the local huts and stage, and has no fallen-leaf layer. Keep trunks outside the central route.
- **Visitors / Listeners** use the crowd's existing count, palette, poses, and empty-area controls. Preserve the reserved central aisle and space around the stage/tree.
- Each zone root owns its ambient stream and blend bounds. **Memory / Audio** owns the shared music and fragment chime. The original placeholder waltz uses **Music**, the zone beds use **Ambience**, and fragment cues use **SFX** simultaneously.
- Replace **Audio → Music Stream** with your chosen recording later. Regenerate the current 15-second original acoustic loop with `python3 tools/generate_market_audio.py`. It is a newly composed placeholder, not a recording of the visit or a borrowed Christmas song. Wind and subdued crowd beds reuse existing assets.
- Edit **Environment / MarketFloor / Custom Outline** to change both connected ground and snow. Keep **ContinuousSnow → Ground Exclusions** aligned with the six huts and stage. Move the hidden **Guidance** waypoints when changing the passage.
- Camera sizes and framing live in `scripts/christmas_market_camera.gd` and the world wrapper.

Audio, scenic performance, footprints, and fragment progress remain local to each device, consistent with the shared memory framework. LAN shares avatar choice and walking/contact.

## Validation and previews

```sh
godot --headless --path . --fixed-fps 60 --script tests/christmas_market.gd
godot --headless --path . --script tests/market_performers.gd
godot --path . --windowed --resolution 1600x738 --script tests/christmas_market.gd -- --capture
# Run these in separate terminals, host first:
godot --headless --path . --script tests/christmas_market.gd -- host
godot --headless --path . --script tests/christmas_market.gd -- guest
```

The integration check walks both zones and the passage in both directions; checks safe spawns, continuous/excluded snow, footprints, guidance, both fragments, music plus ambience, visible performer motion, camera transitions, and Vivian's dated timeline recall. Two-process mode checks both avatars, partner movement, and supported LAN arrival. LAN passed with a headless pair and a rendered host plus headless guest. Two simultaneous rendered clients on this Mac were unreliable, so the reproducible LAN command above uses headless clients; physical-device networking and audio balance still need target-device review. Godot’s dummy renderer can emit null-material warnings during avatar teardown without failing the movement checks.

[Overview](../../../docs/previews/christmas-market-overview.png) · [Arrival](../../../docs/previews/christmas-market-arrival.png) · [Hut lane](../../../docs/previews/christmas-market-stalls.png) · [Music gathering](../../../docs/previews/christmas-market-music.png) · [Performers](../../../docs/previews/christmas-market-performers.png)
