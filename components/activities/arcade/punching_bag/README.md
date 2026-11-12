# Punching-bag interaction

A short leather thump plays once when the visual windup ends, followed by a soft two-tone cue when the strength result is finalized. **Sound → Sound Volume dB** sets the machine's level (default −10 dB); both cues use **SFX** and the memory fade. Busy/rejected presses add no sound, and regeneration stops active cues. Sounds also work in the Inspector preview.

Approach the front of the machine and tap or click the machine. A brief anticipation leads into a painted impact, a small squash of the leather, and a damped swing around its mounting point. The amber counter climbs to a random three-digit strength score while the bag settles back to its resting pose. The machine stays unavailable until the sequence ends, then becomes available again automatically.

The component registers in `memory_interactables` and implements `can_interact(actor)` / `try_activate(actor)`, matching pinball and the existing `InteractionController`. Range is measured in world space from the authored front approach at floor level. Hidden, paused, busy, and out-of-range machines are unavailable; the controller handles movement locks and modal UI gates.

## Inspector controls

- **Interaction Range:** reach from the front approach; default 1.35 m.
- **Swing Duration:** total anticipation/swing/settle time; default 2.8 seconds, adjustable from 1.8–5 seconds.
- **Swing Angle:** maximum swing strength in degrees; default 28, adjustable from 10–35. Stronger results produce a larger deflection.
- **Score Range:** inclusive strength-score limits, clamped to 0–999; default 300–999.
- **Preview punch:** directly test the sequence in the editor without the gameplay HUD.
- Existing palette and Prop Scale controls still apply to the entire machine.

## Script hooks

```gdscript
bag.start_interaction() # true if accepted; false while busy or not ready
bag.score_awarded.connect(func(score: int): print("Strength: ", score))
```

`interaction_requested` also calls the same direct start method. `interaction_started` marks an accepted punch; `score_awarded(score)` is the single successful completion event after the resting pose, `last_score`, and score display are ready. `is_playing()` exposes the busy state. Regenerating the component during a run cancels it, emits `interaction_cancelled`, restores its pose, and preserves the previous completed score. Loading a scene never triggers a punch automatically.

## Rendering and motion

The cabinet stays one static painted mesh. The original smooth leather mesh, seam, and stitching are generated separately under `BagSwing`, with its pivot at the existing mount. The bounded analytical swing is primarily sideways with a small backward deflection, so the bag clears the cabinet column and hood even at maximum strength. Motion is independent of render-frame partitioning and uses no Rigidbody simulation. The pivot disables physics interpolation to avoid double interpolation during render-frame animation.

A small transient shader quad paints the impact dabs. The three-digit score uses the same texture-free score shader as pinball, with a per-material digit count. No text geometry is rebuilt during a punch. Frame callbacks stop completely at rest. The static cabinet is 577 triangles, the moving leather is 1,440, and score/shadow each add two triangles: four steady draws, with one additional two-triangle impact draw for 0.3 seconds.

```sh
godot --headless --path . --script tests/punching_bag.gd
godot --headless --path . --script tests/punching_bag_interaction.gd
godot --path . --windowed --resolution 1400x900 --script tests/punching_bag_render.gd
```

Checks cover direct touch/click activation on the actual machine, range and busy gates, reavailability, score variation and completion events, mesh reuse, cancellation, saved settings, frame-independent motion, maximum-swing clearance in both directions, and visible feedback in the Mobile renderer and First Meeting.

[Impact preview](../../../../docs/previews/punching-bag-impact.png) · [Completed result](../../../../docs/previews/punching-bag-interaction.png).
