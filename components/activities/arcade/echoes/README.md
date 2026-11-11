# Arcade echoes

Decorative surroundings for First Meeting's wallless arcade glade. `painterly_arcade_echoes.tscn` contributes a handful of fading floorboard/paving strokes, an interrupted strand of suspended bulbs, batched soft halos, and three pale pigment pools. It adds no walls, floor collider, furniture, audio, or interaction logic. The approved activity components supply the recognizable objects; autumn foliage and white space supply the surrounding memory.

The default local layout matches `Environment/Arcade` in First Meeting. Move the component with that group. Its placement is authored around the three stations; the lights' endpoints, count, sag, halo strength, floor-trace opacity, and seed are editable with live previews. Zero Light Count removes the bulb strand. Existing `PainterlyLightWash` components supply the subtle ground pigment.

The traces use vertex opacity and broad pigment variation, so they fade both across and along each mark. The lights have faint, incomplete wire segments and a restrained shader-only glow pulse. A single opaque bulb mesh, one transparent trace mesh, one halo MultiMesh, and three tiny ground washes render the setting: **3,156 mesh triangles plus 28 quad triangles** at defaults, six draw calls, and no per-frame script callbacks. No shadow maps or texture assets are required.

Generated nodes stay internal. Regeneration preserves any separately authored children, and saving stores configuration rather than generated geometry. The ordinary finite memory platform supports walking across both the painted marks and the unpainted white ground.

```sh
godot --headless --path . --script tests/arcade_echoes.gd
godot --headless --path . --script tests/first_meeting_arcade.gd
```

The former cutaway-room component remains available separately in `bar_corner/`; it is not instantiated in First Meeting. [Current glade preview](../../../../docs/first-meeting-arcade.png).
