# Foliage recall

Grass, bush and tree components expose one **Recall → Recall Enabled** checkbox
(`recall_enabled`) on their root node. It defaults to off. Enable it on any instance
to hide that foliage at runtime and recall it when a grounded explorer approaches.
No adapter node or extra script needs to be added by the scene author. Editor previews
stay fully visible. Turning the toggle off restores the original materials immediately.

Enabled components own an internal `RecallEffect` node using `GrassRecall`,
`BushRecall` or `TreeRecall`. They preserve the effect's state when rebuilding geometry. Standalone
components automatically discover explorers within their footprint plus a 1.4 m
margin, and play a 3.2 second recall (4.5 seconds for trees). Completed foliage stays present for that visit;
reloading resets it. Sound, saved discovery and multiplayer synchronization are not
implemented yet.

## Demo

Both demo grass patches, all 13 bushes, and all 11 trees have recall enabled. Each checks its own
footprint independently: a grounded explorer within the footprint plus a 1.4 m margin
starts that component's animation. The check accounts for placement,
rotation and scaling. Either explorer can trigger discovery. Airborne arrivals do not
trigger it. Distant foliage stays hidden even while nearby foliage recalls.

There is no shared wave or propagation between components. Once triggered, a component
finishes recalling even if the player walks away and remains recalled for that visit.
A grass patch is one discovery unit: approaching its edge recalls that whole patch.
Compose several smaller patches if a meadow needs more gradual exploration.
Other scenery remains present.

## Studies

Open `res://scenes/effects/recall_test.tscn` for grass or
`res://scenes/effects/bush_recall_test.tscn` for a bush, or
`res://scenes/effects/tree_recall_test.tscn` for a tree, and press F6.
These scenes enable the component checkbox and drive its internal controller with
study controls and a fixed elevated camera.

- **Replay / R:** restart immediately.
- **Play / Pause / Space:** pause or resume (replay if complete).
- **Reset / Explore:** clear recall and return to the starting point.
- **Scrub:** pause and inspect any point.
- **Playback speed:** 0.25×–2×.

## Rendering

The same irregular world-space field drives pigment, growth and color. Ground pigment
blooms first. Grass leaves widen from their anchors, then tufts grow upward. Bush leaf
sprays rise from the ground and unfurl, with lower masses preceding the top. Trees first reveal their trunk/branches upward, then reuse the bush leaf shader for
a short lift/unfurl at each canopy spray, overlapping the finishing wood to avoid
a pause between stages. Their shadow grows with recall, trunk
collision waits for the wood, and falling leaves wait for the complete canopy. Wind and
explorer disturbance resolve into the normal foliage motion. Completed shaders match
the original appearance.

Grass retains three geometry surfaces, bushes two, and trees their original bark,
canopy, ground shadow and optional falling leaves. There are no extra meshes,
particles, per-leaf CPU updates or per-frame scatter rebuilds. Visible foliage stays
opaque; hidden foliage is discarded. Only the existing pigment wash uses transparency.
The recall shaders extend the original shading; base tree/foliage shaders stay unchanged.

Component scripts manage internal controller creation and rebinding through
`components/effects/recall/component_recall.gd`. `get_recall_controller()` exposes the
internal effect for study controls. Adapters support `reset`, `play`, `replay`,
`seek` and state restoration; grass/bush adapters also expose `apply_wave`. External drivers disable `auto_discover` before taking control.

## Validation

```sh
godot --headless --path . --script tests/foliage_recall_toggle.gd
godot --headless --path . --script tests/demo_grass_recall.gd
godot --headless --path . --script tests/grass_recall.gd
godot --headless --path . --script tests/bush_recall.gd
godot --headless --path . --script tests/tree_recall.gd
# Render empty, growing and complete states in /tmp:
godot --path . --script tests/grass_recall.gd -- --capture
godot --path . --script tests/bush_recall.gd -- --capture
godot --path . --script tests/tree_recall.gd -- --capture
```

Checks cover toggles, independent proximity discovery, material rebinding,
completion, stable scatter, distant foliage remaining hidden, interaction and isolation from regular
foliage. Rendering has been checked on Metal Mobile; phone performance still needs
profiling on the target device.

## Default solid recall / boulders

The upward scan with a cream-white edge is the default visual treatment for solid
components. Tree bark and stone materials share `shaders/solid_recall.gdshaderinc`:
it clips unrecalled fragments above a rising height and blends the resolving edge
from white into the original material. It leaves the mesh's shape and shading intact,
uses no transparency or new geometry, and restores the full original color at completion.

Boulders and inherited rock clusters expose **Recall → Recall Enabled**, default off.
The demo enables all four individual boulders and the pond rock cluster. Discovery is
independent and uses actual mesh bounds plus a 1.4 m margin. Recall lasts 2.4 seconds,
with the contact shadow developing as the scan rises. Collision is disabled while
hidden/recalling and enabled on completion, respecting the component's **Solid** toggle.
Rebuilds preserve progress, live palette updates work, and empty clusters are supported.

Open `res://scenes/effects/boulder_recall_test.tscn` and press F6 for the same replay,
pause, speed and scrub controls. Run `tests/solid_recall.gd`, adding `-- --capture`
with the renderer to write empty, partial and complete images to `/tmp/boulder-recall-*.png`.

For another solid component, extend its existing material with the shared scan include
and provide the `SolidRecall` adapter with `get_recall_shader`, `get_recall_mesh`,
`get_recall_shadow_material` and `get_recall_collision_body`. Its regular shading stays
component-specific; the scan and lifecycle are shared.
