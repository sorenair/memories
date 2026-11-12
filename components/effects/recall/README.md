# Component recall

Enable **Recall Enabled** on each component instance to make it manifest as an
explorer approaches. The toggle is off in reusable component scenes so authoring
and isolated previews remain fully visible. Memories opt in explicitly; both
First Meeting and Seasonal Demo do so on their recallable scenery.

Change `recall_settings.tres` → **Proximity Distance** to adjust the shared reach
in world meters. Each component recalls independently and completes once started,
even if the player walks away. Either explorer can trigger recall.

Grass, bushes, trees, stones, water and lighting retain their specialized adapters.
`assembled_recall.gd` adds a coordinated upward white-edge scan to houses, fences,
arcade props, wall vines, and leaf litter. It gathers generated meshes and
MultiMeshes, finds their combined bounds, and updates opt-in uniforms in their
paint shaders. Moving parts share the same height scan; score displays resolve
with their cabinet. Contact shadows fade in with the object.

The assembly shader defaults to fully visible, preserving ordinary instances.
Rebuilding a recalled component rebinds new materials at its current progress;
disabling recall restores the paint, shadows and authored detail visibility.
Buildings, stairs and fences retain collision during the scan to keep navigation
safe. Overhead vines and roof leaves use horizontal proximity so they can be
discovered from the ground.

First Meeting keeps its platform, paving, and atmospheric arcade traces visible.
Its 40 recallable scenery components have `recall_enabled = true` in the memory
scene rather than relying on the timeline transition to turn effects on.

Regression checks:

```sh
godot --headless --path . --script tests/first_meeting_recall.gd
godot --path . --script tests/first_meeting_recall.gd -- --capture
godot --headless --path . --script tests/first_meeting.gd
```

The render check captures hidden, halfway, and completed states to
`/tmp/first-meeting-recall-{0.0,0.5,1.0}.png`.
