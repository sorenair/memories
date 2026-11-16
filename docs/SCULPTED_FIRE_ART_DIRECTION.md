# Sculpted fire: art direction

Updated 2026-11-15 after reworking flame motion and spark shapes. Scope:
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

- Replaced literal ellipse-shaped tongues with a moving 3D curl/density field.
  The old structure made the same handles repeat even when its timing varied.
  A rising field now bends and pinches one tapered upper volume, creating
  asymmetric tongues, fleeting gaps and detached pieces without prescribed loops.
- **Body Fullness** fills the low root, with a default of **0.72**. The upper
  envelope narrows in actual height so detached pieces do not become large balls.
  The plume narrows into the rounded root at ground level, avoiding a flat,
  cylindrical lower rim.
- Red/orange edges surround nested gold and cream heat shapes derived from
  interior thickness. This replaces the fixed highlight and normal-lit spots.
- Three small field-driven flamelets provide brief accents, subordinate to the
  main silhouette. All fires share one original offline-baked 64³ Texture3D;
  animation and sampling run on the GPU.
- Corrected an underlying projection error: orthographic cameras now trace
  parallel rays. Godot's `VIEW` is a fragment-to-camera vector for both camera
  types, so it cannot be used directly as an orthographic tracing direction.
  See the [spatial shader built-ins](https://docs.godotengine.org/en/4.4/tutorials/shaders/shader_reference/spatial_shader.html#fragment-built-ins).
- Added an orthographic camera-dolly regression check. Surface stepping now
  uses bounded adaptive steps with a 128-step maximum and surface refinement.

The field approach follows the upward distortion principle in the
[Cyanilux breakdown](https://www.cyanilux.com/tutorials/fire-shader-breakdown/),
extended here to an original 3D volume rather than a flat fire card. It trades
perfectly art-directed loops for more varied flow; review the result over several
cycles rather than approving a single pose.

## Supporting-layer critique and revision — November 15

**Fire:** regular handles were the main remaining mismatch, not just a timing
issue. The current revision changes their construction as described above. Judge
whether the upper flow stretches and folds convincingly while the base remains
full. Watch for excessive detached blobs or tips that appear to hit a flat ceiling.

**Sparks:** the previous mixture of faceted chips, pinpoints and long needles
looked like confetti; tightly uniform rounded teardrops then looked like spheres.
The current revision uses one pointed stroke language with thin cross sections,
hot gold heads, orange/red trailing ends, and varied length, width and bend.
**Spark Variation** defaults to **0.65**. Preserve readable short flecks alongside
longer streaks; avoid both glowing beads and a uniform rain of needles. Default
Burstiness remains **0.35**.

**Smoke:** the previous soft, mottled dabs read as blurred stains; simply
sharpening them exposed overlapping discs. The guide's connected plume and
gameplay readability require larger, deliberate forms. Smoke now uses seven
smoothly fused 3D billows, broad toon shading and a readable scalloped outline.
Billows expand and roll together, then fade; faint upper wisps finish the edge.
The base develops above the hottest body so the fire stays readable.
**Smoke Definition** (default **0.8**) adjusts edge clarity and shading bands.

Review these changes in motion on both backgrounds. The plume should look like
one rolling cloud, with clear ember silhouettes through it. Avoid repeated solid
balls, ghostly overlaps, noisy erosion and shading that makes the smoke rocky.

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
[flame comparison](previews/sculpted-fire-flow-comparison.gif) and
[revised sparks](previews/sculpted-fire-flow-sparks.gif).
