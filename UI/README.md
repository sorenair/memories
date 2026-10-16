# Memory Lane

In-game movement uses one fixed bottom-left joystick, defined in `res://scripts/exploration_input.gd`. Its fine outline and center circle are translucent at rest, smoothly become opaque when held, and fade back while recentering on release. A small deadzone prevents thumb jitter; movement strength beyond it is analog. Only touches beginning on or just outside the ring activate movement, and additional fingers cannot steal the stick. Release, cancellation, focus loss, and resizing clear movement. Keyboard/controller input remains available; mouse dragging supports desktop preview. Radius, thumb size, edge padding, and deadzone are editable on ExplorationInput. Run `godot --headless --path . --script tests/touch_joystick_smoke.gd` for focused control checks.

Run the project (F5) to open `memory_lane/memory_lane.tscn`, or open that scene and use F6. The close-scale menu is text-only for now. Whole-story zoom and diorama previews are deferred.

- Drag horizontally with a finger or mouse to move the uniformly spaced memory marks beneath the fixed selection point; release to snap.
- Tap a nearby mark or date to select it. Left/right arrow keys also select memories.
- Tap **Recall →**, click it, or press Enter to fade into `res://scenes/world/memory_world.tscn`. All memories currently share this destination. Recall arrives just outside the clearing, with the static scenery visible toward the upper right and within a short walk.

The illustrative titles and dates live in `MEMORIES` in `memory_lane.gd`. The initial selection is Museum date. The warm-white screen uses system serif fonts (Georgia, Noto Serif, DejaVu Serif, then Godot's fallback), with no image assets. Layout adapts to the Control's available size; the project retains its existing landscape viewport and stretch settings. Touch is handled directly, including when mouse emulation is disabled. Actual iOS hardware has not been tested.

On first entry, a 1.8-second entrance reveals the central point, unfolds the thread outward with soft leading edges, settles neighboring marks and dates, then fades in the title and Recall. Touch, mouse click, or keyboard navigation finishes the entrance immediately. Reopening the menu within the same application session uses a shorter 0.4-second fade. Animation timings are defined in `memory_lane.gd`; resizing preserves the current animation stage.

Recall fades the UI to warm white over 0.45 seconds. The destination consumes a one-shot arrival request, spawns the player 10 units away from the memory entry, and positions the camera at the landing point before the first frame. The same warm-white veil survives the scene swap, preventing a frame of mismatched background color. `memory_arrival/memory_arrival.gd` blends that veil into the rendered world over 1.8 seconds, fades the player in at the arrival point, and gently introduces its contact shadow. The 1.95-second arrival pauses movement and touch controls, then restores the original opaque materials and normal movement. The player and camera remain stationary throughout the fade. Scenery remains static; manifestation is deferred.

Tune `recalled_spawn_offset` on the MemoryWorld node. Running the world directly with F6 retains its normal entry beside the demo scenery and skips the Recall arrival sequence.

Check input, snapping, portrait layout, Recall arrival, and movement handoff with:

```sh
godot --headless --path . --script tests/memory_lane_smoke.gd
```
