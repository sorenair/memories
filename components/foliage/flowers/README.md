# Painterly flower patches

Instance `painterly_flower_patch.tscn` at ground level. The patch previews and regenerates in the editor. It contains only rounded, cupped flower crowns and warm central disks, without stems or leaves. Low placement and loose clusters scatter painterly color accents across the grass. The defaults place crowns 0.16 m above the ground with a 0.06 m base radius, varied between 45% and 175% scale independently of their height. Adjust Crown Height to match the local grass surface.

| Inspector control | Purpose |
| --- | --- |
| Patch Seed | Reproducible cluster placement, scale, tint, and wind phases |
| Footprint | Elliptical maximum footprint, with irregular tapered edges |
| Flower Count | Maximum number of flowers, 0–600; exclusions reduce this count |
| Crown Height / Bloom Radius | Height above the ground and base blossom radius |
| Scale Range | Minimum and maximum crown size multipliers |
| Petal Count | 5–8 rounded petals per blossom |
| Bloom Palette | Cream/buttercup, rose, lavender, sunset, forget-me-not, or custom |
| Bloom Color A / B | Two mixed colors when Bloom Palette is Custom |
| Bloom Contrast | Blend strength against the meadow palette; lower values soften the accent |
| Center Color | Warm central disk color |
| Foliage Palette | Shared seasonal/dream meadow pigments used for color blending |
| Wind Strength / Speed | Anchored sway, with variation across blooms |
| React to Explorers | Smooth nearby bending for up to two explorers |
| Ground Exclusions | Water or other components exposing `excludes_ground_point(world_point)` |
| Visibility Distance | Culling distance for the entire patch |

Use several small patches to frame clearings and pond banks. Crowns sit among the meadow leaves; this component adds no ground plate or colored border. It contains no collision and is populated immediately. Bloom colors can change without regenerating placement. Exclusion providers with `ground_exclusion_changed` automatically trigger regeneration when edited.

The default flower is 40 triangles; a 40-flower patch is 1,600 triangles in **one draw call**. All geometry is opaque: no alpha textures, shadow-map passes, particle simulation, or per-flower nodes. Wind and bending deform vertices on the GPU. CPU work is limited to two smoothly filtered explorer positions per patch. Bounds include flower height, petals, and deformation margins.

The summer demo contains `CreamFlowers` beside the western tree/fire clearing, `RoseFlowers` near the fragment, and `LavenderFlowers` at the eastern pond approach. Each excludes the pond.

Run `godot --path . --script res://tests/flower_patch.gd` with a graphics device for count, seed, bounds, palette, exclusion, and demo-placement checks.
