# Foliage palettes

Select a grass patch, tree, or bush instance (or open its component scene and select the root). In the Inspector, open **Foliage Colors → Palette Preset**. Changes appear immediately in the editor and use the same controls on all three components.

| Preset | Color direction |
| --- | --- |
| Summer Meadow | Existing greens and warm yellow highlights; the original look. |
| Spring | Fresh greens with mint shadows and pale lime highlights. |
| Autumn Gold | Rust shadows, amber foliage, and golden highlights. |
| Autumn Red | Plum shadows, red-orange foliage, and peach highlights. |
| Winter Frost | Blue-gray shadows, icy foliage, and pale ivory highlights. |
| Dream Lavender | Deep violet shadows, lavender leaves, and lilac highlights. |
| Dream Blue | Deep blue shadows, teal-blue foliage, and pale cyan highlights. |
| Dream Rose | Plum shadows, rose foliage, and blush highlights. |
| Dusk | Existing muted blue-gray palette. |
| Custom | Use or edit your own four-color `GrassPalette` resource. |

Each preset changes the existing four-color palette: **Root Color**, **Shade Color**, **Leaf Color**, and **Sun Color**. The shaders continue using their existing clustered distribution, root-to-tip mixes, painted highlights, and subtle pigment variation. Tree bark keeps its separate wood colors; only its existing root pigment picks up the foliage palette.

Palette selection does not regenerate geometry, reposition leaves, change density, or reset wind/player interaction. It updates shader uniforms in place, including the ground pigment under grass and bushes. The meadow remains Summer Meadow by default. Winter Frost recolors existing foliage; it does not remove leaves or add snow geometry.

## Custom colors

Expand **Palette** beneath the selector and edit its four color fields. Editing a built-in preset automatically changes the selector to **Custom**. Preset resources are copied per instance, so these edits do not recolor other components.

For a reusable custom palette, save that resource as a `.tres` file and assign it to other components' **Palette** fields. Direct resource assignment selects Custom automatically. Explicitly shared custom resources update all components that use them when edited. Use Godot's **Make Unique** resource action if you want an independent variation.

Preset selections and custom colors persist when scenes are saved. Presets save their selection and recreate a local resource on load; Custom saves the supplied resource. Built-in resources live under `components/foliage/palettes/`, and their shared selector order is in `shared/foliage_palettes.gd`.

## Previews and validation

Rendered examples are `docs/palette-summer.png`, `docs/palette-autumn.png`, `docs/palette-winter.png`, and `docs/palette-dream.png`. They show the same foliage geometry and color distribution with different palettes. The demo scene's saved palette remains summer.

```sh
godot --path . --script tests/foliage_palettes.gd
```

The check exercises every preset on all three component types, verifies that geometry nodes and full MultiMesh buffers remain unchanged, confirms material and ground-pigment colors update, checks scene packing for presets and Custom, and verifies that local edits do not affect another instance. A real rendering device is needed for MultiMesh buffer readback.
