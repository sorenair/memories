# Authoring memories with zones

For composition, visual style, and a complete new-memory workflow, start with the [memory design guide](../../docs/MEMORY_DESIGN_GUIDE.md).

A memory is an ordered collection of places. Each place uses `memory_zone.tscn`: a movable **MemoryZone** with **Scenery**, one **Fragment**, and an **Ambience** player. First Meeting is the working example; its two authored zone scenes are `first_meeting/house_zone.tscn` and `first_meeting/arcade_zone.tscn`.

```text
Memory                         memory_base.tscn
├── Entry / Exit                shared arrival and departure markers
├── Environment                 shared platform and connecting paths/guidance
├── Audio                       soundtrack, optional global bed, and effect cues
└── Zones                       children in story order
    ├── House                   first_meeting/house_zone.tscn
    │   ├── Scenery             house, garden, fence, walkway, foliage
    │   ├── Fragment            local position, title, and note pages
    │   └── Ambience            local wind bed → Ambience bus
    └── Arcade                  first_meeting/arcade_zone.tscn
        ├── Scenery             machines and surrounding scenery
        ├── Fragment            local position, title, and note pages
        └── Ambience            local arcade bed → Ambience bus
```

The world wrapper owns the explorer, partner, camera, controls, and LAN session. Keep these out of zones. Shared ground can span multiple zones; moving a zone moves its scenery, fragment, and ambience bounds together. Existing proximity-recall components still resolve independently. Zones do not create walls or lock exploration to story order.

## Create a memory

1. Create an inherited scene from `memory_base.tscn`, set a unique **Memory Id** and **Display Name**, and save it in your memory's folder.
2. For each place, create an inherited scene from `memory_zone.tscn`. Set **Zone Id** and **Display Name** on its root. Add components under **Scenery**, position **Fragment**, and edit its **Interaction → Note Title / Notes**. Each Notes array entry is one page.
3. Assign the zone root's **Ambience Stream**, **Ambience Volume dB**, **Ambience Size**, and **Ambience Blend Distance**. Save this zone scene and instance it under the memory's **Zones** node. Instance more zones in the order the story should visit them.
4. Add shared ground under **Environment** and position **Entry** and **Exit** on supported ground. Size a finite platform to cover both explorers' spawns, the zones, and the routes between them.
5. Select **Audio** to assign memory-wide music and the optional fragment activation cue. Categories use the shared [audio mixer](../../audio/README.md).
6. Inherit `scenes/world/memory_world_base.tscn`, add your memory content as a child named **Memory**, and save the wrapper. Add its path to `MEMORIES` in `UI/memory_lane/memory_lane.gd`.

For a prebuilt starting point, `memory_template.tscn` contains shared ground, Entry/Exit, and one complete zone. Inherit it and enable **Editable Children** on **FirstZone** to customize Scenery and Fragment, then instance additional authored zone scenes under Zones. First Meeting demonstrates a larger composition without requiring you to copy its house or arcade art.

## Ambience blending

A zone's **Ambience Size** is a full-volume rectangle centered on its origin, measured in local X/Z meters. **Ambience Blend Distance** is the smooth falloff outside that rectangle. Bounds follow the zone's position, rotation, and scale; they are audio coverage, not a collision boundary. Tune **Ambience Response Seconds** for how quickly the mix follows movement.

The memory's Audio node receives the **local explorer** from the shared world. It computes zone weights from that explorer's position, normalizes overlapping beds to avoid doubled gain, and smooths changes. A bed starts when approached and stops after fading to silence. Missing ambience clips are silent and do not reduce other zones' gain. Neither the elevated camera nor the LAN partner drives your mix.

Music and one-shot effects continue across zone boundaries. All zone ambience follows the existing Ambience fader, memory fade, and scene lifetime. Selecting a fragment never abruptly changes the soundscape. Each LAN device mixes its own local beds; audio assets are not streamed over the network.

## Story order and guidance

By default `MemoryScene.get_guidance_fragments()` returns each zone's Fragment in **Zones child order**. Reorder those children to change story order. **Guidance Fragments** on the memory root remains an optional explicit override, using paths such as `Zones/House/Fragment`.

The existing **Find next fragment** action still sends a finite hint only when requested. Author shared routes under Environment/Guidance where a path crosses zones. First Meeting preserves its safe gate/sidewalk routes; their anchors now point into the zones. Notes and completed fragments behave as before.

The original `Environment`, `Interactions`, `RevealClusters`, and `SignatureInteraction` containers remain available for shared or legacy content. Seasonal Demo still uses its original layout and fragment discovery; future memories should use Zones.

## Verify

```sh
godot --headless --path . --script tests/memory_zones.gd
godot --headless --path . --script tests/first_meeting_guidance.gd
godot --headless --path . --script tests/memory_audio.gd
```

These checks cover the two real zones, template structure, story order, local-player audio blending and silence outside bounds, fragment guidance, and audio/scene lifetime.
