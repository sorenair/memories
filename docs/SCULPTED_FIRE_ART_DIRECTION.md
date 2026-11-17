# Sculpted fire: art direction

Updated 2026-11-16 after another reference comparison and spark rework. Scope:
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

## Reference comparison and refinement — November 16

**Fire:** the supplied drawings have longer, stretched folds and deliberate heat
bands. The previous flow pass improved asymmetry, but some upper lobes were still
round and its heat transitions were blurry. The current pass stretches the field
vertically, moves it upward faster, limits density-driven expansion and adds
small asymmetric root distortion. Sharper gold/cream transitions improve the
graphic heat shapes. Keep the full low body; do not return to a tall orb.

**Sparks:** rounded teardrops read as beads; the subsequent pointed loft meshes
read as miniature darts because they retained a fixed body while drifting.
The campfire reference has transient hot marks with much less solid presence.
[Marina's ember study](https://realtimevfx.com/t/marina-vfx-50-weeks-of-stylized-vfx-between-art-emotion-code/29826)
uses warped glowing fragment shapes, while
[Jordan Jaminet's breakdown](https://jaminet.artstation.com/projects/4nGAW)
uses intermittent ember bursts to reduce repetition. My design inference is that
changing emission rhythm and the fragment's visible history matters more than
adding another point to its mesh.

The new implementation uses narrow irregular hot fragments with short
camera-facing ribbons reconstructed from their recent 3D paths. Quick outward
pops mix with slower fluttering embers, with per-birth direction, size and
brightness changes. Trails cool to orange and fade; their maximum reach is
capped relative to fragment size. **Spark Trail Length** defaults to **0.035
seconds**; zero leaves only the hot fragments. **Spark Variation** remains
**0.65**, and Burstiness **0.35**. No CPU animation or history buffer is needed.

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
Watch the occasional leaf-like upper flame cap and the stability of the hot heart
in later reviews; these remain artistic judgments, not solved by a passing test.

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
freeze, maximum wind, scene occlusion, orthographic size invariance, trail length
and isolated overhead ember visibility.
Profile representative instances on target hardware after geometry changes.
Passing technical checks does not establish artistic approval.

## Reference breakdowns

- [Cyanilux — Fire/Flame Shader Breakdown](https://www.cyanilux.com/tutorials/fire-shader-breakdown/):
  directional flow, tip distortion and graphic color bands.
- [Alex Starovoyt — Stylized Fire Spell](https://discofish.artstation.com/projects/eRDOkP):
  simple animated mesh, scrolling masks and appearance control.
- [Sheila Stipnieks — Stylized Fire Breakdown](https://sheilastipnieks.artstation.com/projects/D5oPoA):
  layered emitters and fire/smoke erosion.

Review the [flame comparison](previews/sculpted-fire-reference-pass.gif),
[ember comparison](previews/sculpted-fire-ember-comparison.gif),
[composite](previews/sculpted-fire-motion.gif) and
[isolated smoke](previews/sculpted-fire-smoke-motion.gif).
