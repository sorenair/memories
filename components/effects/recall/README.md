# Component recall

Enable **Recall Enabled** on each component instance to make it manifest as an
explorer approaches. The toggle is off in reusable component scenes so authoring
and isolated previews remain fully visible. All current timeline memories opt in
on their recallable scenery. See the [per-memory audit](../../../docs/MEMORY_EFFECTS_AUDIT.md).

Change `recall_settings.tres` → **Proximity Distance** to adjust the shared reach
in world meters. Each component recalls independently and completes once started,
even if the player walks away. Both the local explorer and the visible LAN partner
can discover components. Progress belongs to the current world visit.

Grass, bushes, trees, stones, water and lighting retain their specialized adapters.
`assembled_recall.gd` adds a coordinated upward white-edge scan to houses, fences,
arcade props/traces, stadium and museum scenery, market huts/stage, festive lights,
concert props, crowds, flowers, wall vines, and leaf litter. It gathers generated
meshes and MultiMeshes, finds their combined bounds, and updates opt-in uniforms
in their paint shaders. Moving parts share the same height scan; score displays
resolve with their cabinet. Contact shadows fade in with the object. Fire and
smoke use `fade_recall.gd` for a smooth 1.8-second manifestation.

The assembly shader defaults to fully visible, preserving ordinary instances.
Rebuilding a recalled component rebinds new materials at its current progress;
disabling recall restores the paint, shadows and authored detail visibility.
Buildings, stairs and fences retain collision during the scan to keep navigation
safe. Overhead vines and roof leaves use horizontal proximity so they can be
discovered from the ground. Scenic components outside the walkable area can use
**Recall Anchor**, where exposed, to trigger from an accessible lookout. The
stadium field uses its viewing platform and the same global proximity distance.

Keep platforms, paving, snow cover, weather, fragment beacons and guidance
available during exploration. Nested components own their own recall; enable the
toggle on the nested foliage or decoration too, such as a decorated market pine.

## Foliage response

Enable **React to Explorer(s)** on grass, bushes, trees, wall vines, and flowers.
Both explorers can gently push nearby foliage; height filtering keeps foliage
on another floor and tall tree crowns undisturbed. Low tree leaves share the bush
response while wind continues through the upper canopy. Departing or hidden
players stop contributing.

`component_recall.gd.explorers()` filters the local `explorers` group and the remote
`foliage_explorers` group by visibility and viewport. Keep remote replicas out of
the input/interaction group; they participate through the foliage group instead.

## Regression checks

```sh
godot --headless --path . --script tests/memory_effects.gd
godot --path . --script tests/memory_effects.gd -- --capture
godot --headless --path . --script tests/recall_settings.gd
```

The catalog audit loads every current timeline world, including nested/generated
components, and checks distant/nearby triggers, completion, hidden actors, and
two-player foliage inputs. The render check captures hidden, held-halfway overview,
and nearby-completed states to `/tmp/memory-effects-{memory_id}-{phase}.png`.
