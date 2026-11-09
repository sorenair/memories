# Memory fragments

Instance `memory_fragment.tscn` anywhere in a memory, with its origin on the ground. A bright white, softly undulating orb with broad toon shading, a brushed rim, soft glow, and rising motes floats above that point. On collection it pulses brightly and bursts into outward-moving painted puffs and scattering motes. `scenes/world/memory_world.tscn` includes a single shared picker and note queue under `Controls/FragmentInteraction`.

Tap / click the orb while an explorer is within **Interaction Range**. Release must stay within the orb's generous screen target; drags and cancelled touches do not activate it. Joystick and GUI input have priority. Physics scenery blocks picking through objects. Range is measured from the fragment's ground origin to the explorer, independently of its visual bobbing.

| Inspector parameter | Purpose |
| --- | --- |
| Glow Color | Orb, mote, and soft halo tint; white by default |
| Orb Radius | World-space size |
| Float Height / Bob Amount | Floating position and vertical drift |
| Animation Speed / Fragment Seed | Dissolving ribbons, rising motes, halo pulse, and distinct phase |
| Mote Count / Wisp Strength | Number of rising white motes and collection-wisp opacity |
| Decay Duration | Seconds for the collection puff to burst and fade (default 0.65) |
| Interaction Range | Maximum player distance in meters |
| Tap Radius Pixels | Minimum viewport-pixel target radius, enlarged for close-up orbs |
| Once Per Visit | Consume after its final note is dismissed; resets when the scene is instantiated again |
| Note Title / Notes | Plain-text heading and ordered note pages; empty pages are skipped |

Notes from multiple fragments append to one queue. Continue advances; Close dismisses its final page. Walking remains available while a note is open. The panel supports native touch without mouse emulation and desktop mouse input. Return to the timeline discards the current scene's queue.

`activated(fragment)` and `note_requested(title, text)` signals let future content trigger journal entries, audio, or other small discoveries. `try_activate(explorer)` performs the same range and one-shot checks as tapping. A custom memory host needs one `fragment_interaction.tscn` Control under its CanvasLayer, an active Camera3D, and a CharacterBody3D explorer in the `explorers` group. Gameplay activation is runtime only; the orb also previews in the editor.

The visual uses two billboards: one translucent painted orb with up to 16 procedural motes and collection ribbons, and one soft additive halo. The breathing silhouette and broad light regions are shader-painted, without a sphere mesh or marble surface pattern. Two draw calls, no textures, lights, particle simulation, or shadow maps. Both materials animate on the GPU; only bobbing moves on the CPU. No screen/depth texture dependency. The halo supplies glow even when environment bloom is unavailable.

Demo instances: `Memory/Environment/SummerSpring/SummerFragment` (two note pages) and `Memory/Environment/Winter/WinterFragment` (one page). The notes are placeholder prose and can be edited directly in each instance's Inspector.

Verification: `godot --headless --path . --script res://tests/fragments.gd` covers range, tapping, drag cancellation, one-shot use, multi-fragment queue ordering, native note-button touch, occlusion, and demo instance count.

## Proximity states and reading

**Inactive** fragments are dimmer and translucent, with a faint halo and quiet motes. Entering **Interaction Range** smoothly brightens them to white, strengthens the breathing glow, and brings out the motes: **Active**. Tapping locks out duplicate interactions and keeps the fragment active while its pages are read, even if the explorer moves away.

The shared queue calls `finish_reading()` only when that fragment's final page is dismissed. It then enters **Decaying** and performs the collection puff. Queued fragments finish independently; advancing from the last page of one fragment to the first page of another releases only the first. Empty note lists decay immediately. Custom note presenters should call `finish_reading()` when reading finishes. `state` and `state_changed(state)` expose the three states. Repeatable fragments return after their puff; one-shot fragments remain hidden until the memory is reloaded.

An accepted tap briefly squashes and rebounds the orb, brightens its painted core, and flashes its halo. The 0.4-second feedback settles while the notes remain open; the separate collection puff still waits for the final page to be dismissed. Rejected and duplicate taps do not trigger feedback.
