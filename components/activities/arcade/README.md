# Painterly arcade components

Three activity props for memories, sharing a muted painted palette, broad pigment washes, soft toon lighting, and brass/wood details. Open or instance their scenes directly. Local **+Z is the front**, and the origin sits at ground level. Generated visuals, contact shadows, collision, and placement hooks preview in the editor and regenerate from exported settings.

| Scene | Details | Default triangles |
| --- | --- | ---: |
| `pinball/painterly_pinball.tscn` | Sloping painted playfield, three bumpers, raised orbit, flippers, shooter guide, moving silver ball, live score display, and coin door. | 4,875 + 170 moving/display |
| `punching_bag/painterly_punching_bag.tscn` | Vintage boxing cabinet, animated stitched leather speed bag, painted impact, and live strength counter. | 577 + 1,442 moving/display |
| `mechanical_band/painterly_mechanical_band.tscn` | One complete rig: guitar and mechanical pick, kick and pedal beater, snare and striker, upright piano with mechanical fingers, gears, cables, and a four-button console. | 9,415 |

`bar_corner/painterly_arcade_corner.tscn` provides an optional roofless room setting: painted plank floor, back/left walls, warm bulbs, a bar ledge, bottles, and stools. It adds 4,965 triangles and one opaque draw. Its front and right side stay open for the elevated camera. This optional room is retained in the library; First Meeting uses the wallless glade described below.

## Inspector

- **Prop Scale:** uniform size adjustment; visuals, collider dimensions, and anchors follow together.
- **Cabinet / Accent / Metal / Cream Color:** shared vertex-paint palette. The boxing cabinet defaults to warm red; pinball and band use dusty teal, copper, cream, and brass.
- **Pigment Strength / Prop Seed:** broad paint variation. Seeded details regenerate consistently.
- **Collision Enabled:** simple solid cabinet/stage boxes, or scenery-only placement.
- **Regenerate Component:** explicit refresh; exports already refresh automatically in the editor.

Round bag and guitar silhouettes are smoothly sampled. Flat cabinet and piano planes retain their intentional stylization. Static lettering is baked into the same mesh. Pinball and punching bag share a texture-free shader for their changing scores, with separate six- and three-digit displays and no runtime text-mesh rebuilds.

[Pinball](pinball/README.md) and [punching bag](punching_bag/README.md) use the shared action button and E near their front controls. Each becomes unavailable during its run and returns after completing its score result. Pinball launches a contained ball; punching bag adds anticipation, a painted impact, damped leather motion, and a three-digit strength counter. Both process only during a run and retain direct start/request/completion hooks. The mechanical band remains static, with one opaque draw and one contact-shadow draw. All three avoid real-time shadow maps and runtime audio.

## Future interaction hooks

`get_anchor(id)` returns an internal Marker3D. Use its global position for later proximity, tap targets, and effect placement. Query again after regenerating a component.

| Component | Anchor names |
| --- | --- |
| Pinball | `Play`, `Ball` |
| Punching bag | `Punch`, `BagPivot` |
| Mechanical band | `Play`, `Guitar`, `Kick`, `Snare`, `Piano`, `GuitarButton`, `KickButton`, `SnareButton`, `PianoButton` |

```gdscript
var button_position: Vector3 = band.get_anchor(&"KickButton").global_position
```

## First Meeting placement

`scenes/memories/first_meeting.tscn` groups the activities under **Environment/Arcade**, centered at world `(15, 0, 1)`, east of the original house. They form a loose triangle in the white void, each nestled into a small autumn foliage pocket. A broken suspended light strand and fading traces of floorboards suggest the bar; there are no room walls or continuous arcade floor. The house sidewalk dissolves into a few faint paving impressions and scattered leaves. The band faces diagonally into the open foreground. The 34 × 19 m platform, original arrival, shared camera, timeline identity, and LAN setup are preserved.

[Pinball](../../../docs/arcade-pinball.png) · [Punching bag](../../../docs/arcade-punching_bag.png) · [Band](../../../docs/arcade-mechanical_band.png) · [In the memory](../../../docs/first-meeting-arcade.png)

The decorative [arcade echoes component](echoes/README.md) provides the suspended lights, faint floor traces, and pigment pools without collision. The decorative scenery is independent of activity behavior. Pinball and punching bag now use shared-controller interactions and random scores; the band remains static.

For an interactive inspection stage, assign any component scene to **Subject Scene** in `tests/scenes/component_test.tscn` and run F6. Select Pinball or Punching Bag and press **Preview pinball run** or **Preview punch** in its Inspector to test directly without the gameplay HUD.

```sh
godot --headless --path . --script tests/arcade_components.gd
godot --headless --path . --script tests/pinball.gd
godot --headless --path . --script tests/pinball_interaction.gd
godot --headless --path . --script tests/punching_bag.gd
godot --headless --path . --script tests/punching_bag_interaction.gd
godot --headless --path . --script tests/first_meeting_arcade.gd
godot --headless --path . --script tests/arcade_echoes.gd
```

Checks cover mesh budgets, deterministic regeneration, saving/reloading, optional collision, scaled placement hooks, platform coverage, and actual player traversal from the house sidewalk to all three activities. Visual verification used Godot 4.4.1's Mobile renderer on Apple M1, including normal gameplay camera scale.
