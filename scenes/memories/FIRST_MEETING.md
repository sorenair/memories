# First Meeting — November 12, 2025

Edit `first_meeting.tscn` for the shared platform, routes, and zone placement. Edit `first_meeting/house_zone.tscn` or `first_meeting/arcade_zone.tscn` for scenery, fragments, and local ambience. See [the zone authoring guide](README.md). Run `scenes/world/first_meeting_world.tscn` with F6, or Recall the first timeline entry. It uses exactly the demo's orthographic size, camera transform, and centered follow; there is no per-memory zoom or framing override. Reference framing is for overview inspection, not gameplay.

The scene retains the bungalow, big autumn tree, short front walk, and sidewalk meeting spot from the original concept. Its current visual improvements are:

- A low, pale diamond fence, with a 2.3 m opening centered on the walk and a right-hand side fence. Both player spawns fit safely outside it and can enter together.
- Fuller orange meadow dabs, orange shrubs with red accents, and smooth, softly folded oval leaves scattered over paving, stair treads, and the lower roof slope. Each leaf-litter patch is one opaque draw with tiny optional GPU flutter.
- Broad house pigment, irregular shingles, opaque curtain/window paint, and a small warm porch lamp, still merged into one house mesh.
- A fuller orange/red doorway vine arch and corner creeper. The main autumn tree sits within the front yard, left of the walk and behind the fence. Birds have been removed from this memory.

The main route is Entry `(0.1, 0.04, 6.4)` and guest spawn `+1.2 m X` → gate at Z=5.25, X=-0.55…1.75 → front walk → stairs / closed door. The gate remains open; fence mesh spans have simple collision. Paving collision is only a few centimeters high so feet and contact shadows sit on it.

Tests: `first_meeting.gd` checks the shared framework and exact camera parity with the demo. `first_meeting_layout.gd` walks both spawns through the gate, verifies closed fence collision, and climbs the stairs. The two-process `lan_multiplayer.gd -- host` / `-- guest` check uses safe, separate routes through the gate and along the sidewalk.

## Memory fragments

Each zone contains one instance of the shared memory-fragment component:

- `Zones/House/Fragment` floats over the front walk just before the house steps, at `(0.6, 0.04, 3.6)`. Its placeholder heading is **Outside the house**.
- `Zones/Arcade/Fragment` sits in the middle of the triangle formed by Pinball, PunchingBag, and MechanicalBand, at world `(14.6333, 0.04, -0.1)` (local `(-0.3667, 0.04, -1.1)`). Its placeholder heading is **At the arcade**.

To replace the text, open the corresponding zone scene and select its **Fragment**, and edit **Interaction → Note Title** and **Notes** in the Inspector. Each Notes array entry is a separate page. Both instances have their own placeholder text; changing one does not change the other or the reusable component defaults.

Tap or click **Find next fragment** at the bottom right, or press **E**, to send one white painterly brushstroke from the player's current position toward the next unfinished fragment. First Meeting uses **Zones** child order: House, then Arcade. `MemoryScene.guidance_fragments` remains available as an explicit override. A request captures the player position and fades after reaching its destination. The circle remains faint and disabled until that stroke finishes; further requests cannot restart it. No hint starts automatically on entry or after reading notes. Open notes and movement locks block requests; after both fragments are finished, the circle is faint and disabled.

`Environment/Guidance` contains two hidden runtime route definitions. `ArrivalBrushstroke` runs from Entry through the gate toward the house fragment. `HouseToArcade` curves back through the gate, along the worn sidewalk, around the right fence, and into the arcade's open center. The shared `GuidanceController` joins a requested hint to these safe routes or uses a bounded obstacle-aware fallback. Start/end anchors follow the fragment instances; waypoints, speed, trail duration, width, and inherited brush appearance controls remain editable. The normal gameplay camera is unchanged. Validate with `tests/first_meeting_guidance.gd`.

## Audio

Select each zone root to assign its **Ambience Stream**, volume, size, and blend distance. House uses a quiet wind loop; Arcade uses a quiet cabinet/room hum. The beds blend around the local player and stop when out of range. Select the shared **Audio** node in `first_meeting.tscn` for the memory-wide soundtrack and **Fragment Sound** cue. Music is left empty for your chosen track. The mechanical band's four instruments use the **SFX** bus, so they can overlap the ambience and future soundtrack.

The shared mixer has **Master**, **Music**, **Ambience**, **SFX**, and **UI** controls, with a **Memory** bus for entry/exit fades. Edit `audio/default_bus_layout.tres` in Godot's Audio panel to balance categories. See [the audio guide](../../audio/README.md) for adding effects, runtime controls, and playback/transition behavior.

## Arcade bar, after the house

Past the house, the arcade is remembered as an open autumn glade rather than an enclosed room. Under `Zones/Arcade/Scenery/Machines`, centered at `(15, 0, 1)`, pinball, punching bag, and the band form a loose triangle with clear white space between them. Small gold/red foliage islands soften their bases. Two slender birches and an interrupted suspended strand of warm bulbs quietly connect the stations.

The house sidewalk gives way to faint, separated paving impressions and scattered leaves. A few fading floorboard strokes and soft pigment pools suggest traces of the bar around the activities. The original rectangular arcade floor, walls, bar furniture, and hedge-like perimeter are no longer placed in this memory. All walking ground is the existing finite platform.

The reusable activities are **Pinball**, **PunchingBag**, and **MechanicalBand**. Their painted models are preserved; pinball adds a shooter guide, movable ball, and live score display. The band remains one component containing guitar, kick, snare, piano, mechanisms, and four control buttons. Pinball is registered with the shared `InteractionController`: approach its front controls and tap or click the cabinet to launch the ball. Its exported Interaction Range defaults to 1.35 m; it becomes unavailable while running and available again after `score_awarded(score)`. Direct `start_interaction()` / `interaction_requested` hooks remain available for previews. Tap or click the punching bag near its front approach for anticipation, a painted hit, damped leather swing, and a random three-digit strength result. It stays busy until the bag settles. The band's four individual caps use the same controller, highlighting only the selected cap and playing the associated mechanism and short instrument sound. See [the component guide](../../components/activities/arcade/README.md).

`Zones/Arcade/Scenery/Machines/Echoes` owns only decorative floor traces, suspended bulbs/halos, and pale surface pigment; it adds no collision. The arcade props are grounded directly on the platform. House, original arrival, gate, camera, and 34 × 19 m platform remain unchanged. Exit sits in the arcade's open foreground.

`tests/arcade_components.gd` checks the approved props. `tests/arcade_echoes.gd` checks the lightweight decorative kit. `tests/first_meeting_arcade.gd` verifies platform coverage, absence of room blockers, and real walking from the original arrival to every activity anchor across the open glade.

[Expanded memory overview](../../docs/first-meeting-expanded.png) · [Arcade glade](../../docs/first-meeting-arcade.png)
