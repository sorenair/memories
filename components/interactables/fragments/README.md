# Memory fragments

Instance `memory_fragment.tscn` anywhere in a memory, with its origin on the ground. The fragment is a small knot of suspended light, wrapped in four open translucent brushstroke veils. Their pale violet/blue pigment, feathered edges and moving luminous threads drift around a tiny warm seed. The curves rise and slip through different 3D planes, leaving open space between them. A few solid flecks rise through the light. It rolls and bobs gently; after the final note closes, the strands unfurl upward and fade into the air. `scenes/world/memory_world.tscn` includes a single shared picker and note queue under `Controls/FragmentInteraction`.

Tap / click the orb while an explorer is within **Interaction Range**. Release must stay within the orb's generous screen target; drags and cancelled touches do not activate it. Joystick and GUI input have priority. Physics scenery blocks picking through objects. Range is measured from the fragment's ground origin to the explorer, independently of its visual bobbing.

| Inspector parameter | Purpose |
| --- | --- |
| Glow Color | Pearl, fleck, and soft light-wash tint; white by default |
| Orb Radius | Overall world-space size; retained for compatibility with authored fragments |
| Float Height / Bob Amount | Floating position and vertical drift |
| Animation Speed / Fragment Seed | Veil flow, rolling, fleck drift, light pulse, and distinct phase |
| Mote Count / Wisp Strength | Up to 16 solid drifting flecks and the outward reach of the collection release |
| Decay Duration | Seconds for the veils to unfurl and fade (default 0.65) |
| Interaction Range | Maximum player distance in meters |
| Tap Radius Pixels | Minimum viewport-pixel target radius, enlarged for close-up orbs |
| Once Per Visit | Consume after its final note is dismissed; resets when the scene is instantiated again |
| Note Title / Notes | Plain-text heading and ordered note pages; empty pages are skipped |

Notes from multiple fragments append to one queue. The **arrow** advances; the **X** dismisses its final page. The rounded warm-white reading panel uses a quiet uppercase heading, centered serif prose, and an icon-only action with a generous touch target. It fades in with a small upward settle, softly introduces each page, and dissolves on close. It sits between the thumb controls in landscape and above them in portrait; long prose scrolls inside the panel, keeping the action visible. Native touch dragging scrolls text without advancing a page; Enter/Space also advances. Walking remains available while a note is open. Return to the timeline discards the current scene's queue.

`activated(fragment)` and `note_requested(title, text)` signals let future content trigger journal entries, audio, or other small discoveries. `try_activate(explorer)` performs the same range and one-shot checks as tapping. A custom memory host needs one `fragment_interaction.tscn` Control under its CanvasLayer, an active Camera3D, and a CharacterBody3D explorer in the `explorers` group. Gameplay activation is runtime only; the orb also previews in the editor.

The light, curved veils and flecks share one indexed 3D mesh with 1,344 triangles. Geometry is cached across instances; activity/collection materials remain private. The body uses soft alpha blending with ordinary depth testing, so it can be seen through and scenery can occlude it. It does not write depth. The only camera-facing surface is the faint additive light wash; the actual strands and silhouette are 3D. There are two transparent visual batches, no textures, dynamic lights, screen/depth textures, shadow maps, or CPU particle simulation. Veil flow, pigment drift, fleck motion and release run in the shader; the small root bob and roll run on the CPU. Glow is restrained and works on Mobile without relying on bloom. Transparency overdraw still depends on screen coverage and overlap; the triangle count is not a device performance measurement.

The generic stage `tests/scenes/component_test.tscn` currently loads the fragment and includes its note queue. Press **F6**, walk close, tap it, and dismiss its note to see the release. Reload Subject restores a consumed fragment. For a close study, set **Camera Size** to 3.5 and **Camera Focus** to `(0, 1.15, 0)`. Existing memory instances automatically use the redesigned shared component; their positions, parameters and authored note text are preserved.

![Painterly 3D memory fragment](../../../docs/previews/memory-fragment-outlined.png)

Demo instances: `Memory/Environment/SummerSpring/SummerFragment` (two note pages) and `Memory/Environment/Winter/WinterFragment` (one page). The notes are placeholder prose and can be edited directly in each instance's Inspector.

Verification: `godot --headless --path . --script res://tests/fragments.gd` covers range, tapping, drag cancellation, one-shot use, multi-fragment queue ordering, native note-button touch, occlusion, and demo instance count.

`godot --headless --path . --script res://tests/fragment_note_ui.gd` checks content-driven panel sizing, portrait bounds, long-note scrolling, cancelled action touches, keyboard advance, and a new note arriving during the closing fade.

## Proximity states and reading

**Inactive** fragments have quieter veils, a dimmer seed, and faint flecks. Entering **Interaction Range** smoothly strengthens the light and the flowing brushstrokes: **Active**. Selection adds a subtle glint within the translucent strands. Tapping locks out duplicate interactions and keeps the fragment active while its pages are read, even if the explorer moves away.

The shared queue calls `finish_reading()` only when that fragment's final page is dismissed. It then enters **Decaying** and performs the collection release. Queued fragments finish independently; advancing from the last page of one fragment to the first page of another releases only the first. Empty note lists decay immediately. Custom note presenters should call `finish_reading()` when reading finishes. `state` and `state_changed(state)` expose the three states. Repeatable fragments return after their release; one-shot fragments remain hidden until the memory is reloaded.

An accepted tap briefly gathers and releases the light, brightens its seed, and pulses its surrounding wash. The 0.4-second feedback settles while the notes remain open; the separate collection release still waits for the final page to be dismissed. Rejected and duplicate taps do not trigger feedback.

`tests/fragment_visual.gd` checks actual mesh depth, geometry sharing and material isolation. Run it with `-- --capture` on the graphical renderer for motion, side-view, light/dark, collection and First Meeting captures in `/tmp/fragment-3d-*.png`.

Visual reference: the restrained luminous spirits and quiet cloud forms discussed in [Sky’s art direction](https://apps.apple.com/tw/story/id1465180456) and [Nicolas Oueijan’s Season of Flight work](https://www.nickoueijan.com/sky_season-of-flight). These informed the light/negative-space direction; the geometry and shaders are procedural project assets.

Soft lavender underpainting outlines the curved strands and the seed without adding a silhouette pass or a screen texture. It fades with the fragment and stays visible against pale scenery. The seed's base radius is 0.48 before the component's overall scale, a 60% increase over the previous 0.30; overall wisp size is unchanged.

The wisps orbit the settled core independently, taking about 20–26 seconds per revolution at default **Animation Speed**. Slight rate differences, traveling twists, gentle banking and radial breathing keep the flow varied and smooth. The shared parent only bobs and tilts; it does not counter-rotate the shader motion.

For an animation study, run `godot --path . --fixed-fps 24 --script tests/fragment_visual.gd -- --capture --motion`. It records six seconds of clean viewport frames to `/tmp/fragment-swirl-frames/`.

![Six-second swirl study](../../../docs/previews/memory-fragment-swirl.gif)
