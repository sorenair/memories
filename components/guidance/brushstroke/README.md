# Living brushstroke

Instance `living_brushstroke.tscn` for a luminous white ribbon of moving pigment with a soft surrounding halo. It gathers into a small mark at the start, opens into a broad flowing gesture in the middle, then narrows and releases into a few fine strands near the destination. Bristle gaps and pressure change during the pass. The paint dissolves, and a quiet interval separates passes. Both the component and summer demo default to a white monochrome palette.

Set **Endpoints → Start Point / End Point** in the Inspector. Both coordinates are local to this component, including height above the ground. The editor displays the animated result. Arc Height adds a soft rise, and Curve Bend adds an asymmetric S-shaped sweep. The default gesture needs no Curve3D, textures, particles, or scene references. Coincident endpoints safely hide it; a vertical route is also supported. An optional **Route Curve** replaces the two-point shape with an arc-length sampled Curve3D for authored navigation.

```gdscript
# Convert world-space destinations to the component's local coordinates.
brushstroke.set_points(brushstroke.to_local(from_world), brushstroke.to_local(to_world))
```

Endpoint edits update the shader and culling bounds without rebuilding geometry. The component is a visual guide; memories decide when and where to show it.

| Inspector controls | Purpose |
| --- | --- |
| Start Point / End Point | Direction and elevation of the gesture. Keep it roughly 2–5 m long for a small clearing. |
| Arc Height / Curve Bend | Gentle rise and lateral sweep; both ends stay anchored. |
| Stroke Width | Full ribbon width in local meters. Default 0.42 m. |
| Pigment / Edge / Highlight Color | Body pigment, shaded paint, and warm bristle accents. |
| Opacity | Overall pigment strength; the newest paint receives a small local lift. |
| Glow Strength | White emission and a soft local halo. Works on Mobile without scene-wide bloom; 0 removes both. |
| Evolution Strength | Amount of gathering, blooming, changing pressure, and filament breakup from start to end. 0 holds a consistent shape; default 1. |
| Stroke Seed | Repeatable pigment variation and cycle offset. |
| Travel Duration | Seconds for the brush head to reach the second point. |
| Trail Duration | Seconds for paint behind the head to dissolve. |
| Rest Duration | Quiet pause after the last paint has faded. |
| Playback Speed / Motion Amount | Overall timing and subtle airborne sway. Speed 0 holds a seeded still pose. |
| Surface Wash Enabled / Height / Opacity | Optional, very faint planar pigment directly below the route. Place the height just above flat ground; it does not project onto uneven terrain or foliage. |
| Detail / Visibility Distance | Ribbon tessellation and distance culling. |

Default cost: **1,344 triangles, two translucent draw calls** (one if the surface wash is disabled). The halo occupies the same ribbon sheet and adds no draw calls, particles, or textures. Movement and pigment evolution run on the GPU. There are no per-frame script callbacks or CPU mesh uploads. Only tessellation changes rebuild geometry. Normal scene depth lets rocks, trunks, and other scenery occlude the paint. Bounds cover the full route, width, and sway, including routes offset from the component origin. Keep guidance sparse to limit transparent overdraw on phones.

The foliage demo retains a brushstroke under `Environment/SummerSpring/LivingBrushstroke`, passing across the clearing between the fire and vine wall, but this old automatic decoration is hidden during gameplay. The previous `ClearingWisps` also stays hidden. Standalone `LivingBrushstroke` instances retain the repeating visual behavior described above.

Verified using Godot 4.4.1's Mobile renderer on Apple M1. Physical-phone performance is not measured. Preview: [component](../../../docs/living-brushstroke.png), [in the demo](../../../docs/living-brushstroke-demo.png).

```sh
godot --headless --path . --script tests/living_brushstroke.gd
godot --path . --windowed --resolution 1200x700 --script tests/living_brushstroke_render.gd
```

Contract checks cover endpoint edits, bounds, narrow near-vertical and coincident routes, saved settings, shader propagation, mesh budgets, and demo integration. Captured-frame checks verify visible pigment, live motion, a still pose, disappearance during the resting interval, a second camera angle, glow on/off, and actual silhouette evolution on a straight route. The middle of the gesture must be appreciably broader than its birth and release; translation alone cannot satisfy that check.

## Fragment routes

Memory guidance is requested explicitly: tap or click the bottom-right **Find next fragment** circle, or press **E**. The shared world `GuidanceController` takes a snapshot of the local player's position and sends one finite white brushstroke toward the first unfinished fragment in the memory's authored order. The circle stays faint and disabled while the brushstroke travels and fades at the fragment; further requests are ignored until the pass finishes. The paint fades after arrival; it does not repeat or start automatically on entry or after a note closes. Open notes and movement locks block requests. The circle is faint and disabled when the memory has no fragments or all its fragments are finished.

Set `MemoryScene.guidance_fragments` to an `Array[NodePath]` relative to the memory root to choose the fragment order. An empty array uses each zone’s Fragment in Zones child order, or scene-order discovery for legacy memories. Finishing a fragment's final note page advances the next requested destination; opening or paging through a note does not request a new hint.

`fragment_brushstroke_guide.tscn` defines an authored safe route using **Start Anchor**, **End Anchor**, and local-space **Waypoints**. These route definitions stay hidden at runtime until the controller requests a hint. The controller joins the player's starting position to the route backbone or uses a bounded obstacle-aware fallback. The rendered hint starts at the captured player position even if the player moves afterward. Anchor references follow moved fragment instances at their mean orb height; adjust waypoints when changing scenery. **Meters Per Second**, **Trail Duration**, **Stroke Width**, and the inherited paint appearance controls remain editable. `wait_for_start_note` and `gesture_interval` are no longer part of memory guidance.

First Meeting authors `Environment/Guidance/ArrivalBrushstroke` from Entry to HouseFragment and `HouseToArcade` through the open gate, sidewalk, foreground, and arcade center. The fragment order is HouseFragment, then ArcadeFragment. The routes add no collision or gameplay lock. Use `tests/first_meeting_guidance.gd` to validate requests, completion order, cleanup, and safe routing against the memory scenery.
