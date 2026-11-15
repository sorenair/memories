# Sculpted fire: art direction

Updated 2026-11-14 after review of the spherical-body attempt. Scope:
`components/vfx/sculpted_fire/`; the original fire remains a separate component.

## Target

Follow the supplied flame-loop sheet and layered campfire references: a dense,
luminous lower flame that stretches into large, unequal, curling tongues. Those
tongues must form much of the silhouette. Lower-body fullness should come from
connected, flowing flame mass. A smooth sphere with little spikes attached is
the wrong structure, even if it has animated colors.

Use a readable hierarchy: red outer sheets, orange flame, pale gold heat and a
restrained cream-white center. Color shapes should rise and bend with the fire;
avoid isolated lava-like spots or an unchanging vertical highlight stripe.
Smoke rolls more slowly, and embers remain readable through its density.

## Current revision

- Lowered the persistent body and enlarged the curling strokes. A bending,
  tapered spine and three overlapping tongues now form the upper mass. Their
  curls grow, turn over, thin and break away on staggered burst clocks.
- **Body Fullness** now fills the lower portion, with a default of **0.72**.
  Its full range stays below the upper tongues. It does not grow a tall orb.
- Simplified the palette into elongated, rising heat shapes with a broad gold
  heart and a smaller cream-hot center. Removed the strong round color patches.
- Corrected an underlying projection error: orthographic cameras now trace
  parallel rays. Godot's `VIEW` is a fragment-to-camera vector for both camera
  types, so it cannot be used directly as an orthographic tracing direction.
  See the [spatial shader built-ins](https://docs.godotengine.org/en/4.4/tutorials/shaders/shader_reference/spatial_shader.html#fragment-built-ins).
- Added an orthographic camera-dolly regression check. Surface stepping now
  accounts for tongue taper and wind, with a bounded 128-step maximum.

The smoke retains faint connecting volume and eroding, rolling brush billows.
Three detached flame tips share the main tongues' profiles. Embers inherit the
plume's drift and fade before shrinking into pixel dust.

## Review the next pass against these criteria

1. **Silhouette first:** inspect several cycles with smoke, sparks and glow
   hidden. Keep a full lower portion, asymmetry, large curling tongues and
   fleeting openings. Reject a dominant sphere, straight repeated spikes,
   rigid handles, long-lived perfect rings and exposed mesh intersections.
2. **Continuity:** tongues should stretch, fold, neck and disappear naturally.
   Their roots should blend into the body. Avoid empty intervals, synchronized
   pulsing and detached pieces that compete with the main flame.
3. **Heat:** preserve flowing red/orange regions and readable inner gold on
   light and dark backgrounds. Emission accents the design; bloom must not be
   necessary or erase the shape.
4. **Composite:** review smoke alone and together with the fire. Avoid folded
   tubing, countable solid puffs and quad edges. Keep sparks distinct from
   flame fragments and make the fire readable at gameplay scale.

Use `tests/scenes/sculpted_fire_test.tscn` with F6. Review four angles,
perspective and orthographic views, close-up and gameplay size. The component
and render checks cover saved controls, density/fullness changes, recall,
freeze, maximum wind, scene occlusion and orthographic size invariance.
Profile representative instances on target hardware after geometry changes.
Passing technical checks does not establish artistic approval.

## Reference breakdowns

- [Cyanilux — Fire/Flame Shader Breakdown](https://www.cyanilux.com/tutorials/fire-shader-breakdown/):
  directional flow, tip distortion and graphic color bands.
- [Alex Starovoyt — Stylized Fire Spell](https://discofish.artstation.com/projects/eRDOkP):
  simple animated mesh, scrolling masks and appearance control.
- [Sheila Stipnieks — Stylized Fire Breakdown](https://sheilastipnieks.artstation.com/projects/D5oPoA):
  layered emitters and fire/smoke erosion.

Review the [current close-up](previews/sculpted-fire-curl-detail.gif),
[composite](previews/sculpted-fire-motion.gif),
[isolated smoke](previews/sculpted-fire-smoke-motion.gif) and
[previous/reworked comparison](previews/sculpted-fire-comparison.gif).
