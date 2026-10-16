# Painterly rain

Instance `painterly_rain.tscn` under a memory's Environment. Its origin defines the center of a rectangular rain volume and the base surface level. Fine, soft-edged strokes fall through world space, with varied length, speed, phase, and brightness. Small ground splashes and broader pond ripples add contact without a screen-wide mist overlay.

The demo's `ClearingRain` covers 26×32 m above the platform, with 1,200 allocated drops, Intensity 0.7, and 160 impact slots. It keeps the existing lighting, palettes, water, and foliage intact.

| Inspector control | Purpose |
| --- | --- |
| Footprint / Rain Height | Coverage in local X/Z and height above the ground. Cover the memory plus a margin for wind. |
| Rain Seed | Repeatable drop and impact distribution. |
| Drop Count | Maximum allocated streaks, 0–4,000. Zero removes both rain batches. |
| Intensity | Fraction of drops and impact slots enabled, 0–1. Zero hides both batches. |
| Fall Speed | Overall motion speed, nominally meters/second. Zero freezes streaks, flutter, and splashes. |
| Wind | Local X/Z drift in meters/second, limited to magnitude 3. |
| Streak Length / Width | Physical size of the strokes. Keep width small to avoid an intrusive curtain. |
| Rain Color / Highlight Color / Opacity | Muted body color, pale highlight, and overall transparency. |
| Splash Count / Splash Opacity | Independent impact budget and visibility. Count zero disables impacts only. |
| Ground Height | Flat surface level relative to the rain node. |
| Platform | Optional relative NodePath; impact positions outside its outline are rejected. |
| Water Bodies | Relative paths to water components; impacts inside them use broader, longer-lived ripples and the pond's surface height. |
| Visibility Distance | Culling distance for each batch. |

Drops naturally occlude against scenery through normal depth testing. Impacts use precomputed flat-ground / registered-water positions, not per-drop physics or depth-buffer collision. Rocks and foliage hide impacts beneath them; rain does not accumulate, wet materials, make sound, or splash on arbitrary roofs and rock tops. Water ripple impacts are decorative and are not individually synchronized with falling streaks.

Use **Refresh rain volume** after moving the component or editing its referenced platform/water shapes. Local control changes rebuild automatically. The volume is memory-local, so it does not chase the player or visibly recenter. For larger memories, size and position multiple volumes deliberately. Keep transforms upright and author coverage with Footprint rather than node scaling.

## Budget and validation

The effect uses at most **two MultiMesh draws**, two triangles per drop or impact slot, and no textures, screen/depth reads, per-frame script callbacks, raycasts, or physics particles. Shader animation loops preseeded instances; tapered ends hide streak resets. Impacts use short expanding, broken rings and soft center flashes. The demo allocates 2,720 triangles in total, with a small transparent screen footprint. Zero intensity hides the batches; zero Drop Count removes them. Bounds include full height and wind displacement.

```sh
godot --headless --path . --script tests/rain_component.gd
godot --path . --script tests/rain_motion_render.gd
```

Component checks cover budgets, Inspector updates, persistence, internal generated nodes, and disabled modes. Real-renderer captured frames verify moving streaks, independently animated impacts, a frozen mode, and complete disabling. The effect has been checked using Godot's Mobile renderer on desktop; physical phone performance still requires profiling.

`docs/rain-motion.gif` is an actual-engine motion preview of the demo; `docs/rain-clearing.png` is a still frame.
