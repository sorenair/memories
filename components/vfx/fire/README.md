# Painterly fire

Instance `painterly_fire.tscn` with its origin at the flame's base. The demo contains a small example named `ClearingFire` near the entry. It is a visual effect; a log pile, fire bowl, torch, collision, heat, and damage are separate scenery/gameplay choices.

The flame uses a warm pale core, yellow body, orange/red tips, three connected curling tongues, and broad rising cutouts. Curved, moving color bands supply the painted character. Small round embers rise, drift, and cool toward red. A subtle ground wash and narrow silhouette halo suggest warmth without requiring bloom or changing the world's lighting.

| Inspector field | Effect |
| --- | --- |
| Flame Size | Approximate base width X and flame height Y in meters. |
| Intensity | Strength and fullness, 0–1; zero hides all batches. |
| Animation Speed | Speed of curling, flicker, glow, and rising embers. Zero freezes everything. |
| Wind | Horizontal lean, -0.6 to 0.6 in the camera-facing flame plane. |
| Fire Seed | Repeatable motion phase and ember variation. |
| Core / Flame / Tip Color | Three editable palette colors, with the innermost heart slightly lightened automatically. |
| Ember Count | Allocated ember pool, 0–64; zero removes that batch. |
| Glow Strength | Halo and ground-wash strength; zero hides the ground wash. |

Size, colors, speed, wind, glow, and intensity update uniforms without regenerating geometry. Seed and ember count rebuild the small batches. Generated children stay internal; the scene saves only authoring controls. Use Flame Size for dimensions and keep the root upright. The flame is an upright camera-facing graphic, while embers face the camera fully. It is intended for the game's elevated camera and normal side views, rather than an exactly overhead camera.

## Rendering

All motion runs on the GPU. The default uses three draws and **184 triangles**: one flame quad, one ground-wash quad, and 18 ten-triangle ember discs. It requires no textures, frame scripts, physics particles, screen/depth sampling, extra reflection passes, or dynamic lights. Shape and palette are procedural; flame and embers preserve their vivid unshaded colors like the foliage. Bounds include both the flame and the full rising ember plume.

Normal depth testing occludes the effect behind scenery. The halo is alpha blending, not bloom. The ground wash is flat at local Y=0.025; it does not conform to uneven terrain or illuminate unshaded foliage. Place it on a flat surface and disable Glow Strength if the wash is unsuitable. Fire is not automatically extinguished by the rain component. Physical-phone performance has not been profiled.

```sh
godot --headless --path . --script tests/fire_component.gd
godot --path . --script tests/fire_motion_render.gd
```

Checks cover saved controls, optional embers, culling bounds, zero-intensity/glow modes, geometry preservation during appearance edits, frozen animation, visible animated change, and visibility from another camera angle. The demo also passes the scene movement check.

`docs/fire-study.png` is an isolated dark-background preview. `docs/fire-clearing.png` shows the example in the memory.

`docs/fire-motion.gif` is a four-second actual-engine animation preview.
