# Painterly light wash

Instance `res://components/lighting/light_wash/painterly_light_wash.tscn` on a flat
surface. It previews in the editor and works with the project's unshaded materials.
It paints a local pool of light; it does not illuminate nearby objects, cast shadows,
or project across arbitrary geometry. Place a wash on each receiving floor or wall.

## Controls

- **Wash Shape:** Pool, Soft Rectangle, or Window Panes.
- **Footprint:** width and depth for floor washes; width and height for wall washes.
- **Light Color / Intensity:** tint and opacity. The pale warm default works as a
  lamp/window pool. Try restrained cool or colored washes for other moods.
- **Softness:** feathered boundary. Higher values produce a broader falloff.
- **Paint Variation / Wash Seed:** subtle, repeatable pigment variation.
- **Window Grid / Pane Gap:** number of panes and spacing of the unlit dividers.
- **Motion:** Steady, Candle Flicker, or Slow Pulse. Speed zero freezes motion;
  Amount controls its depth. Animation runs entirely in the shader.
- **Surface:** Floor or Wall. For a wall, keep the root at floor level against the
  wall, choose Wall, and set Wall Center Height. Rotate the root around Y to match
  the wall direction; its painted face points along local +Z.
- **Surface Offset:** small separation along the receiving surface's normal to
  avoid z-fighting. This is not a projected decal, so match the receiving plane.
- **Visibility Distance:** whole-wash culling distance.

**Recall → Recall Enabled** defaults to off. When enabled, proximity fades the wash
in over 1.6 seconds, using the same global distance from
`components/effects/recall/recall_settings.tres` as the other components. It stays
present for the visit; rebuilds preserve progress and disabling recall restores full
visibility. Keep the root at floor level in both placement modes for discovery.

## Test stage

Open `res://tests/scenes/component_test.tscn` and press F6. Set **Subject Scene** to the light wash scene to study it. The stage currently
shows the smoke / steam emitter. Edit the component scene's root parameters to author a wash, or
save a variant and assign it to the stage's **Subject Scene**.

Use the Neutral/White/Dark floor selector to judge the tint against different
backgrounds. Bright surfaces show a color wash rather than added brightness;
neutral/dark surfaces make the pool especially clear. Enable the back wall to check
wall placement, and set Subject Position Z to -3.2 to place a wall wash against it.

## Budget and checks

Each wash is one two-triangle transparent surface with its own material. It has
no textures, collisions, real-time lights, shadow passes, or CPU animation callback.
Generated geometry and optional recall controller are internal; scenes save authoring
parameters. Appearance changes preserve the mesh; footprint changes rebuild the quad.
Avoid stacking many full-screen transparent washes and profile on the target phone.

```sh
godot --headless --path . --script tests/light_wash.gd
godot --path . --script tests/light_wash.gd -- --capture
```

Checks cover the geometry budget, independent materials, live appearance, floor/wall
placement, recall and rebuild state, and generic stage swapping/controls. Actual
Metal Mobile captures of all shapes and a wall wash are written to
`/tmp/light-wash-shape-{0,1,2}.png` and `/tmp/light-wash-wall.png`.
