# Dream wisp routes

Instance `dream_wisp_path.tscn` in a memory to add a quiet directional guide. It is a Path3D: select it and edit its Curve with the 3D viewport handles. Wisps travel from the first point toward the last. The demo's `Environment/ClearingWisps` leads from the pond-side entrance into the forest clearing.

The strokes are soft, tapered, translucent brush marks with a pale pearl center and muted blue edges. They drift, flutter, and breathe gently, fading before wrapping back to the start. Irregular spacing and varied dimensions keep the guide from becoming a dotted line. Normal scene depth hides them behind rocks and trees; there is no collision or gameplay dependency.

| Inspector control | Purpose |
| --- | --- |
| Curve | Route in local space. Height changes are supported. |
| Wisp Count | Number of strokes, 0–32; start with 5–8 for a small clearing. |
| Wisp Seed | Repeatable irregular spacing, proportions, and animation phases. |
| Stroke Length / Width | Length and half-width in local meters. Short routes automatically limit stroke length. |
| Drift Speed | Approximate forward speed in meters/second. Zero freezes all animation. |
| Float Height | Vertical offset above the curve. Place the curve at ground level and set this above the grass. |
| Wander | Small side drift and vertical flutter. |
| Wisp Color / Edge Color | Pearl body and muted edge tint; retain some contrast against the memory's ground. |
| Opacity | Overall translucency. |
| Visibility Distance | Culling distance. |

The scene's default curve is local to each instance, so editing one route does not change other instances. For a fork, use two components with separate curves. This component supplies visual guidance only; navigation, destination tracking, and player-triggered visibility are not implemented.

All wisps share one MultiMesh, one translucent material, and a 24-triangle ribbon mesh per stroke (168 triangles for the demo's seven). A 256-sample float texture stores the route (~4 KiB). Motion runs entirely in the vertex/fragment shader, with no particles, per-frame script callbacks, or geometry uploads. Route edits rebuild the lookup; appearance edits only update uniforms. Generated nodes stay internal and do not serialize.

The route has bounds covering its full shader-driven motion so it stays visible even when the component origin is outside the camera. Keep curves smooth and stroke counts sparse; intersecting transparent ribbons cannot sort individually within the batch. Very long or intricately curved routes are better split into components. Performance has been checked on the desktop Mobile renderer, not a physical phone.

```sh
godot --headless --path . --script tests/wisp_path.gd
godot --path . --script tests/wisp_motion_render.gd
```

Checks cover curve editing, settings persistence, generated-node isolation, culling bounds, geometry budgets, and empty routes. Captured-frame tests verify actual visibility, animated drift, and the frozen mode.
