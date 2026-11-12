# Painterly ground snow

Instance `painterly_snow_patch.tscn` on a memory's ground plane. A seeded, irregular patch of shallow rounded mounds replaces grass with soft white and blue painted shading. Its thin bank rolls down into the surrounding ground color. The demo's `Environment/Winter/SnowGround` covers the winter clearing and clips around its pond.

Players in the `explorers` group leave alternating shoe impressions as they walk. The impressions lower the rendered snow and change its local shading, then fill back in after a configurable delay. Standing still produces no new marks; large teleports do not draw a connecting trail. CharacterBody actors must be grounded. Each player has independent stride state.

| Inspector field | Effect |
| --- | --- |
| Patch Size / Patch Seed | Oval width X, length Y, and repeatable outline/mound variation. With a custom outline, the seed still controls mound variation. |
| Custom Outline | Optional Curve2D in local X/Z meters, including concave landings and connecting aisles. Overrides oval size/outline. |
| Snow Depth / Puffiness | Shallow snow thickness and soft mound relief. Defaults 0.065 / 0.07 m. |
| Ground Exclusions | Relative paths to ponds or other regions where snow should not cover the ground. |
| Mesh Detail | Oval radial detail or custom shape grid detail along its longest side, 32–96. |
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

## Continuous areas

Assign **Custom Outline** to cover a connected, flat area with one snow mesh. A Curve2D's X/Y coordinates map to the snow's local X/Z meters. The last point closes back to the first automatically. Concave outlines work, so one surface can fill a landing, narrow connecting aisle, and wider viewing bay. The thin bank appears only around the outside perimeter; interior joins share the same snow height, shading, footprint texture, and player stride state.

A platform and its snow may share the same **Custom Outline** resource when their local X/Z origins align. The stadium uses `Scenery/WalkableSnow` and the deck's `DeckOutline` this way. Editing the shared curve rebuilds both previews. Use a simple, non-self-intersecting outline; retain **Ground Exclusions** for interior cutouts. Leave Custom Outline empty to keep the original oval geometry and behavior.

Footprint UVs and exclusion masks automatically fit the outline's bounds, including shapes away from the node origin. Use **Detailed (512)** for a broader connected area; the stadium uses this for its approximately 19 × 15 m footprint. This controls footprint resolution, while Mesh Detail controls the sculpted surface. The component still covers flat surfaces rather than vertical steps or terrain.

## Grass and placement

Add the snow instance to nearby grass patches' **Ground Exclusions**, relative to the grass node, such as `../WinterSnowPatch`. Snow provides the same `excludes_ground_point(world_point)` method and `ground_exclusion_changed` signal used by the water component. The autumn grass in the demo excludes the adjacent winter snow footprint. Shape and transform changes refresh their scatter automatically.

Snow is decorative groundcover and uses the existing flat platform/ground collider. Its shallow top allows shoes to sink slightly into the surface; it does not add bumpy walking collision. It does not conform to terrain. Assign ponds to Ground Exclusions to bake a cutout and a soft lowered snow bank; shape changes refresh the mask automatically. Use local Y=0 for the ground level. Keep the root upright; rotate around Y freely and author coverage with Patch Size rather than node scaling. Avoid overlapping thick centers of separate patches.

The public `stamp_footprint(world_point, world_forward)` method places an individual shoe impression for future animation events or other actors. Automatic tracking uses distance rather than animation-specific foot-bone events. New stamps upload on the next physics tick. Excluded surfaces reject footprints. Water provides a world-space `get_ground_outline()` for efficient native polygon masking; other components can fall back to `excludes_ground_point()`.

## Implementation and budget

The default patch has **4,032 triangles** and **one opaque draw surface**. Rounded geometry provides real relief; shader displacement and filtered normal gradients make the footprints read below it. There are no per-footprint nodes, decal draws, physics queries, or frame-by-frame mesh uploads.

A two-channel float field stores compression and a compression-weighted birth time. Weighted timestamps keep filtered edges from fading early, including after long play sessions. The shader computes each mark's age, so fading needs no CPU pixel sweep. The field updates only when new steps land, with all stamps in a physics tick batched into one upload. A lightweight physics callback tracks actors and advances game-time fading; it does not run in the editor.

Field storage is ~128 KiB / 512 KiB / 2 MiB on the GPU for the three quality levels, plus the matching CPU image. An additional static 128² coverage mask (~16 KiB) clips exclusions in the same opaque pass. Balanced is suitable for small 4–8 m patches. Choose Detailed for connected concave areas; very large areas may still need multiple surfaces to retain enough texels. Phone performance still requires device profiling.

```sh
godot --headless --path . --script tests/snow_ground.gd
godot --headless --path . --script tests/snow_outline.gd
godot --path . --script tests/snow_ground_render.gd
godot --path . --script tests/snow_ground_render.gd -- --outline
```

Checks cover finite geometry, budgets, grass exclusion shape, placement bounds, independent stride states, standing/teleport behavior, saved settings without trails, and actual explorer footsteps in the demo. Rendered checks verify visible impressions, unchanged appearance during the linger period, complete restoration after fading, and valid marks with later timestamps.

`docs/snow-ground-demo.png` shows a real player-made trail. `docs/snow-ground-motion.gif` demonstrates filling in with a shortened 2.5-second linger and 1.2-second fade for the preview; the saved demo retains the default timings. Preview foliage is fully populated without changing saved recall settings.
