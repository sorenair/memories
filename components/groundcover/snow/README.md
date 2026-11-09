# Painterly ground snow

Instance `painterly_snow_patch.tscn` on a memory's ground plane. A seeded, irregular patch of shallow rounded mounds replaces grass with soft white and blue painted shading. Its thin bank rolls down into the surrounding ground color. The demo's `Environment/Winter/SnowGround` covers the winter clearing and clips around its pond.

Players in the `explorers` group leave alternating shoe impressions as they walk. The impressions lower the rendered snow and change its local shading, then fill back in after a configurable delay. Standing still produces no new marks; large teleports do not draw a connecting trail. CharacterBody actors must be grounded. Each player has independent stride state.

| Inspector field | Effect |
| --- | --- |
| Patch Size / Patch Seed | Local width X, length Y, and repeatable outline/mound variation. |
| Snow Depth / Puffiness | Shallow snow thickness and soft mound relief. Defaults 0.065 / 0.07 m. |
| Ground Exclusions | Relative paths to ponds or other regions where snow should not cover the ground. |
| Mesh Detail | Outline/radial detail, 32–96. |
| Snow Color / Shade Color | Warm white highlights and cool, soft shadows. |
| Edge Color | Match the platform or ground to blend the bank into the memory. |
| Track Footprints | Enables automatic player tracking. Existing prints continue fading when disabled. |
| Footprint Linger | Seconds each impression stays at full strength before fading. Default **8 seconds**. |
| Footprint Fade Duration | Time it takes to fill in after the linger period. Default **2.5 seconds**. |
| Footprint Depth | Depth of the rendered depression; also drives well shading. |
| Footprint Size | Shoe width and length in meters. |
| Step Spacing | Travel distance between alternating marks. |
| Footprint Quality | Mobile 128², Balanced 256², or Detailed 512². |

Linger, fade, footprint depth, and colors update the material without rebuilding the patch or clearing its history. Shape, mound, mesh, field-quality, and exclusion changes regenerate it and clear existing footprints. Runtime trails are not serialized; scenes save the settings.

## Grass and placement

Add the snow instance to nearby grass patches' **Ground Exclusions**, relative to the grass node, such as `../WinterSnowPatch`. Snow provides the same `excludes_ground_point(world_point)` method and `ground_exclusion_changed` signal used by the water component. The autumn grass in the demo excludes the adjacent winter snow footprint. Shape and transform changes refresh their scatter automatically.

Snow is decorative groundcover and uses the existing flat platform/ground collider. Its shallow top allows shoes to sink slightly into the surface; it does not add bumpy walking collision. It does not conform to terrain. Assign ponds to Ground Exclusions to bake a cutout and a soft lowered snow bank; shape changes refresh the mask automatically. Use local Y=0 for the ground level. Keep the root upright; rotate around Y freely and author coverage with Patch Size rather than node scaling. Avoid overlapping thick centers of separate patches.

The public `stamp_footprint(world_point, world_forward)` method places an individual shoe impression for future animation events or other actors. Automatic tracking uses distance rather than animation-specific foot-bone events. New stamps upload on the next physics tick. Excluded surfaces reject footprints. Water provides a world-space `get_ground_outline()` for efficient native polygon masking; other components can fall back to `excludes_ground_point()`.

## Implementation and budget

The default patch has **4,032 triangles** and **one opaque draw surface**. Rounded geometry provides real relief; shader displacement and filtered normal gradients make the footprints read below it. There are no per-footprint nodes, decal draws, physics queries, or frame-by-frame mesh uploads.

A two-channel float field stores compression and a compression-weighted birth time. Weighted timestamps keep filtered edges from fading early, including after long play sessions. The shader computes each mark's age, so fading needs no CPU pixel sweep. The field updates only when new steps land, with all stamps in a physics tick batched into one upload. A lightweight physics callback tracks actors and advances game-time fading; it does not run in the editor.

Field storage is ~128 KiB / 512 KiB / 2 MiB on the GPU for the three quality levels, plus the matching CPU image. An additional static 128² coverage mask (~16 KiB) clips exclusions in the same opaque pass. Balanced is suitable for small 4–8 m patches. Split large areas into manageable patches so shoe impressions retain enough texels. Phone performance still requires device profiling.

```sh
godot --headless --path . --script tests/snow_ground.gd
godot --path . --script tests/snow_ground_render.gd
```

Checks cover finite geometry, budgets, grass exclusion shape, placement bounds, independent stride states, standing/teleport behavior, saved settings without trails, and actual explorer footsteps in the demo. Rendered checks verify visible impressions, unchanged appearance during the linger period, complete restoration after fading, and valid marks with later timestamps.

`docs/snow-ground-demo.png` shows a real player-made trail. `docs/snow-ground-motion.gif` demonstrates filling in with a shortened 2.5-second linger and 1.2-second fade for the preview; the saved demo retains the default timings. Preview foliage is fully populated without changing saved recall settings.
