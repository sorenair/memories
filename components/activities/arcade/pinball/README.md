# Pinball interaction

The machine now has a short, self-contained pinball run. The ball waits at the bottom-right launch chute, shoots upward, is deflected into the bumper field, and ricochets off the lower obstacles and rails. Reaching the lower catch ends the run; otherwise it gently settles at the configured time limit. A random score appears on the amber six-digit display and is emitted for the future UI.

## Shared interaction controller

At runtime the machine joins `memory_interactables` and implements `can_interact(actor)` / `try_activate(actor)`. The inherited `InteractionController` in `memory_world_base.tscn` discovers it, so tapping or clicking the cabinet while in range launches pinball in First Meeting. The front control anchor, projected onto the floor, defines the interaction point. Busy, hidden, paused, and out-of-range machines are unavailable; completion makes the target available again on the next controller refresh.

For scripted launches or authoring previews, the direct API remains available:

```gdscript
pinball.start_interaction() # true if accepted; false while busy or not ready
pinball.score_awarded.connect(func(score: int): print("Pinball score: ", score))
```

Alternatively emit `pinball.interaction_requested`. It is connected to the same start method when the component becomes ready. `interaction_started` marks an accepted launch. `score_awarded(score)` is the single successful completion event, emitted after `last_score` and the display are updated and the machine is idle. `is_playing()` exposes the busy state. Requests received during a run are ignored.

The Inspector's **Preview pinball run** button calls this hook directly, including in the editor. Loading a scene never starts a run automatically. Regenerating the component while playing cancels it, emits `interaction_cancelled`, and returns the ball to the launch chute without awarding a score.

## Controls

The machine plays a spring/clack on launch, a soft metallic ping on real bumper hits, and a two-tone result cue when the run ends. Hits within one rendered frame are coalesced, with at most two overlapping bumper voices. **Sound → Sound Volume dB** sets the machine's level (default −10 dB); all cues use **SFX** and the memory fade. Regeneration cancels active sounds along with the run. Cues also work in the Inspector preview.

- **Interaction Range:** world-space reach from the front controls; default 1.35 m.
- **Play Duration:** maximum run time, 2–8 seconds; default 5. A lower catch can finish sooner.
- **Launch Speed:** 1.8–3.0 local meters per second.
- **Score Range:** inclusive min/max, clamped to the six-digit display; default 100–9,900.
- Existing size and palette controls still apply to the whole machine.

`pinball_layout.gd` shares obstacle coordinates and dimensions between the visible geometry and simulation. A swept-circle solver advances on the local sloped X/Z playfield in substeps no larger than 1/240 second, preventing tunneling through bumpers, flippers, slingshots, guide rails, and small left-side posts. The overhead orbit wire is high enough for the actual sphere to pass underneath; the rest of the field is bounded. World placement, rotation, and Prop Scale transform the result together. The `Ball` anchor follows the moving sphere.

The ball is a separate painted sphere. The score uses one texture-free shader quad, updating an integer uniform rather than rebuilding text meshes. The cabinet stays batched and unchanged during play. Idle machines have no frame callbacks; active movement updates on render frames with physics interpolation disabled on the ball, avoiding double interpolation at high FPS. Default cost is 4,875 cabinet triangles, 168 ball triangles, two display triangles, and two contact-shadow triangles across four draw calls.

```sh
godot --headless --path . --script tests/pinball.gd
godot --headless --path . --script tests/pinball_interaction.gd
godot --headless --path . --script tests/interact_button.gd
godot --path . --windowed --resolution 1400x900 --script tests/pinball_render.gd
```

Checks include collision containment across 24 seeded launches at 30/60/144 FPS and coarse 170 ms frames, upper-field reach, repeat requests, score bounds/variation, one completion event per run, safe cancellation, saved settings, mesh reuse, transformed placement, and actual rendered movement/display changes. The shared-controller integration check uses the real First Meeting player and cabinet to exercise direct taps/clicks, front approach range, moving away before release, hidden targets, movement locks, busy-state dimming, and automatic reavailability.

[Rendered machine](../../../../docs/pinball-interaction.png).
