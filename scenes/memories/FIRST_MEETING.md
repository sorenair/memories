# First Meeting — November 12, 2025

Edit `first_meeting.tscn` for scenery. Run `scenes/world/first_meeting_world.tscn` with F6, or Recall the first timeline entry. It uses exactly the demo's orthographic size, camera transform, and centered follow; there is no per-memory zoom or framing override. Reference framing is for overview inspection, not gameplay.

The scene retains the bungalow, big autumn tree, short front walk, and sidewalk meeting spot from the original concept. Its current visual improvements are:

- A low, pale diamond fence, with a 2.3 m opening centered on the walk and a right-hand side fence. Both player spawns fit safely outside it and can enter together.
- Fuller orange meadow dabs, orange shrubs with red accents, and smooth, softly folded oval leaves scattered over paving, stair treads, and the lower roof slope. Each leaf-litter patch is one opaque draw with tiny optional GPU flutter.
- Broad house pigment, irregular shingles, opaque curtain/window paint, and a small warm porch lamp, still merged into one house mesh.
- A fuller orange/red doorway vine arch and corner creeper. The main autumn tree sits within the front yard, left of the walk and behind the fence. Birds have been removed from this memory.

The main route is Entry `(0.1, 0.04, 6.4)` and guest spawn `+1.2 m X` → gate at Z=5.25, X=-0.55…1.75 → front walk → stairs / closed door. The gate remains open; fence mesh spans have simple collision. Paving collision is only a few centimeters high so feet and contact shadows sit on it.

Tests: `first_meeting.gd` checks the shared framework and exact camera parity with the demo. `first_meeting_layout.gd` walks both spawns through the gate, verifies closed fence collision, and climbs the stairs. The two-process `lan_multiplayer.gd -- host` / `-- guest` check uses safe, separate routes through the gate and along the sidewalk.

## Arcade bar, after the house

Past the house, the arcade is remembered as an open autumn glade rather than an enclosed room. Under `Environment/Arcade`, centered at `(15, 0, 1)`, pinball, punching bag, and the band form a loose triangle with clear white space between them. Small gold/red foliage islands soften their bases. Two slender birches and an interrupted suspended strand of warm bulbs quietly connect the stations.

The house sidewalk gives way to faint, separated paving impressions and scattered leaves. A few fading floorboard strokes and soft pigment pools suggest traces of the bar around the activities. The original rectangular arcade floor, walls, bar furniture, and hedge-like perimeter are no longer placed in this memory. All walking ground is the existing finite platform.

The reusable activities are **Pinball**, **PunchingBag**, and **MechanicalBand**. Their painted models are preserved; pinball adds a shooter guide, movable ball, and live score display. The band remains one component containing guitar, kick, snare, piano, mechanisms, and four control buttons. Pinball is registered with the shared `InteractionController`: approach its front controls and use the action circle or E to launch the ball. Its exported Interaction Range defaults to 1.35 m; it becomes unavailable while running and available again after `score_awarded(score)`. Direct `start_interaction()` / `interaction_requested` hooks remain available for previews. Punching bag uses the same action circle/E near its front approach, with anticipation, a painted hit, damped leather swing, and a random three-digit strength result. It stays busy until the bag settles. The band remains static for the next pass. See [the component guide](../../components/activities/arcade/README.md).

`Environment/Arcade/Echoes` owns only decorative floor traces, suspended bulbs/halos, and pale surface pigment; it adds no collision. The arcade props are grounded directly on the platform. House, original arrival, gate, camera, and 34 × 19 m platform remain unchanged. Exit sits in the arcade's open foreground.

`tests/arcade_components.gd` checks the approved props. `tests/arcade_echoes.gd` checks the lightweight decorative kit. `tests/first_meeting_arcade.gd` verifies platform coverage, absence of room blockers, and real walking from the original arrival to every activity anchor across the open glade.

[Expanded memory overview](../../docs/first-meeting-expanded.png) · [Arcade glade](../../docs/first-meeting-arcade.png)
