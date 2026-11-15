# Painterly bar props

Reusable props sharing the arcade library's softened edges, matte toon paint,
broad pigment washes, simple solid collision and soft contact shadows. Local **+Z
is the front**; the origin is at floor level. Both preview and regenerate in the
editor, keep generated children internal, and support the existing component recall.

| Scene | Details |
| --- | --- |
| `pool/painterly_pool_table.tscn` | Walnut cabinet, teal felt, six pocket openings, ivory sights, chalk, hanging rack, cue and sixteen numbered solids/stripes. |
| `jukebox/painterly_jukebox.tscn` | Modern electronic cabinet with a portrait music display, painted album tiles, animated equalizer graphics, speaker grille and restrained illuminated trim. |
| `counter/painterly_bar_counter.tscn` | Freestanding paneled counter, rounded wood top, brass footrest and round upholstered stools. |

Open **`tests/scenes/bar_test.tscn`** and press **F6**. Walk near any side of the
table and tap its felt/cabinet to play. This study includes the shared tap controller
and explorer for scale. `bar_study.tscn` is just the two-prop composition, ready to
assign to another component stage. These scenes do not register a new memory.

## Pool interaction

The table joins `memory_interactables` and implements `can_interact(actor)` and
`try_activate(actor)`. The existing world controller supplies mesh picking,
occlusion and the white in-range outline. Instance the table under a memory zone's
Scenery; the shared world already provides the controller.

Each accepted tap restores a complete rack, pulls the cue back, then launches the
cue ball into the triangle. Equal-mass ball collisions, cushion rebounds, rolling
friction and all six pockets determine the result. Pocketed balls sink out of view;
the remaining balls stay where they settle. Further taps are rejected while the
shot is running. Once it settles, another tap reracks and starts a fresh break.

For another interaction system or an authored event:

```gdscript
table.interaction_requested.emit() # Standalone start hook; no actor/range check.
# Or check an explorer and start through the same contract as the tap controller:
table.try_activate(explorer)
```

`start_interaction(seed_value = -1)` also returns whether a run started. Supplying a
nonnegative seed makes a break reproducible; the default chooses a fresh random
aim variation. **Preview pool break** exercises the same behavior in the Inspector.

Signals: `interaction_started`, `ball_pocketed(ball_number)` (0 is the cue ball),
`interaction_finished(pocketed_balls, scratched)` and `interaction_cancelled`.
Completion reports actual object-ball pockets, excluding the cue ball, with a
separate scratch flag; `last_pocketed_count` and `last_scratched` retain that result.
Regenerating during a shot cancels it, rebuilds and restores the rack.

This is a short break-shot toy: it does not implement aiming, subsequent shots,
turns, eight-ball rules or a win/lose screen. Like the other scenic activities,
simulation and effects are local to each device; LAN does not replicate shots.

## Inspector controls

Shared controls: **Prop Scale**, cabinet/accent/metal/cream colors, **Pigment
Strength**, **Prop Seed**, **Collision Enabled** and **Recall Enabled**. Scaling
updates geometry, balls, pockets, explorer collision and placement anchors together.

Pool adds **Cloth Color**, **Interaction Range** (world metres from the nearest
table edge), **Launch Speed** and **Sound Volume dB**. The `Play` and `Rack` anchors
are available through `get_anchor()`.

Jukebox adds **Screen Title**, **Screen Accent**, **Animation Speed** and **Screen
Brightness**. Speed zero freezes the display. It is currently a visual scenery
component: the animated graphics are synthetic, with no playlist or music playback.
The `Screen` and `Approach` anchors are available for future interaction. `seek_time()`
supports deterministic captures; a negative value restores the shader clock.

## Runtime cost and sound

Pool uses a fixed 240 Hz local 2D solver for sixteen disks with render interpolation;
the balls render in one MultiMesh with one shared texture-free material. No rigid
bodies or per-frame mesh regeneration are needed. CPU frame callbacks stop when the
shot settles. The jukebox animates entirely in its opaque display shader with no
CPU frame callback or video texture. Real device performance still needs profiling.

The three short, original pool cues use the shared bounded audio helper and **SFX**
bus. Regenerate them with `python3 tools/generate_pool_audio.py`. No external
recordings, album covers or song assets are required.

## Verification

```sh
godot --headless --path . --script tests/pool_simulation.gd
godot --headless --path . --script tests/bar_components.gd
godot --path . --script tests/bar_render.gd --windowed --resolution 1440x900 --rendering-method mobile
```

Checks cover multiple seeded breaks, containment, energy, pocket capture, matching
30/144 FPS results, the real tap picker/controller, repeat-input blocking, settling,
scaled/rotated range, recall, regeneration and serialization. The Mobile render
checks visible ball motion and display animation.

[Overview](../../../docs/previews/bar-components-overview.png) ·
[Pool break](../../../docs/previews/pool-table-break.gif) ·
[Electronic jukebox](../../../docs/previews/electronic-jukebox.png)

## Freestanding counter

`counter/painterly_bar_counter.tscn` contains the counter and stools only. It has
no room shell, floor or bundled decoration. Local X runs along the counter; the
stools sit on its +Z side. Origin is ground center. **Counter Length / Depth /
Height**, **Stool Count** and **Stool Color** preview in the editor. Stool count is
capped by the available counter length to preserve spacing. Each stool has a
`Stool1`/`Stool2`/etc. approach marker; `Approach` marks the middle of the row.

All parts share one opaque mesh/material and a soft contact shadow, with one
solid collider for the counter and one per stool. Shared prop scale, palette,
collision and recall controls remain available. An optional **Recall Anchor**
allows the counter to resolve from a nearby zone arrival. The first authored use is
[Mifflin's open bar cluster](../../../scenes/memories/mifflin/README.md); its
walkthrough checks the gap between pool and stools and solid stool collision.
