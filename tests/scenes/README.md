# Component test scenes

`res://tests/scenes/component_test.tscn` is the reusable 3D test stage. Open it and
press **F6**. Its current subject is the painterly 3D memory fragment. Choose another
component through Subject Scene. The stage includes the shared fragment note UI,
so walking close, tapping, and dismissing a note also exercises collection.

To test another component, select the **ComponentTest** root and drag its `.tscn`
into **Subject → Subject Scene**. The component previews in the editor and spawns
under SubjectMount when run. Its generated instance is internal and is not saved
into this stage. Edit the source component scene or create a variant to save specific
component settings. Clearing Subject Scene leaves an empty, valid stage.

## Inspector

- **Subject Position / Subject Rotation Degrees:** placement within the stage.
- **Recall Mode:** use the component scene's setting, force recall enabled, or force
  it disabled. Components without a recall controller ignore the override.
- **Floor Color:** backdrop/ground tone; runtime also offers three quick presets.
- **Show Wall:** optional flat wall at Z=-3.2, centered at Y=2.5, 12 m wide and 5 m tall.
- **Camera Size / Camera Focus:** orthographic framing for small or large subjects.

The stage supplies a ground collider, elevated fixed camera, existing explorer,
keyboard/controller/touch movement, ambient/sun lighting, and simple study controls.
It does not change the project's main scene or load a memory/timeline.

## Runtime controls

- **WASD / arrows / joystick:** move the explorer.
- **Reload Subject / R:** replace only the component; camera, stage and player stay.
- **Show / Hide Subject / V:** compare the effect against the bare stage.
- **Replay Recall:** enabled when the subject exposes a recall controller.
- **Floor selector:** Neutral, White or Dark.
- **Show Back Wall:** toggle the receiving wall.
- **Recall selector:** test recall without changing the component's saved checkbox.

New test scenes should live here and reuse/inherit this stage where possible. The
existing component-specific scripts in `tests/` remain useful for automated checks.

`sculpted_fire_test.tscn` previews the separate [3D painterly fire](../../components/vfx/sculpted_fire/README.md), with curved flame volumes, rolling smoke and sparks. Its source scene exposes grouped fire/smoke/spark controls; the stage supplies light/dark backgrounds and recall replay.
`tests/light_wash.gd` exercises the generic stage, including swapping its subject to
another component while preserving the camera and player.

`concert_test.tscn` inherits this stage with the [concert kit](../../components/scenery/concert/README.md): stage/ramp, two speaker stacks, moving-head lights, an animated visual screen, and an audience with a central walking approach. It uses a warm-white floor and a wider three-quarter view. Run with F6, or assign one of the kit's four component scenes to the generic stage for an isolated study.

`postcard_cabin_test.tscn` inherits the same stage for the [closed trailer cabin exterior](../../components/buildings/postcard_cabin/README.md), with a warm-white floor and an explorer for scale. Run with F6 to inspect the picture window, walk the entry steps and test recall.

`conservatory_test.tscn` previews the [conservatory component library](../../components/scenery/conservatory/README.md): flowering bushes, straight/curved stone walls, an animated marble fountain, and potted bonsai. Three flower treatments, three masonry styles and three bonsai forms sit beside the explorer. Run with F6; use the generic stage with one component for isolated recall/parameter checks.

`jungle_test.tscn` previews the [jungle foliage library](../../components/foliage/jungle/README.md): feather/fan palms, tropical broadleaf clumps, ferns and bamboo, layered with existing groundcover and shrubs around the conservatory fountain. Run with F6 to walk the central approach, or test an individual plant in the generic stage.

`bar_test.tscn` previews the [bar props](../../components/activities/bar/README.md): an interactive pool table and modern electronic jukebox. Walk near any side of the table and tap the felt/cabinet to break the rack; wait for the balls to settle before tapping again. This inherited stage includes the shared tap controller and in-range outline. The jukebox is an animated visual prop, with music playback left for later.

`neighborhood_house_test.tscn` provides an F6 study for the reusable bungalow,
front-gable, side-gable and stacked-porch house family. Select its source component
for profile and proportion editing; `tests/neighborhood_house.gd` covers its
geometry, stairs, exclusion footprint and solid exterior collision.

`graduation_test.tscn` previews the [commencement kit](../../components/scenery/graduation/README.md): an open draped stage, animated banners, lectern, diploma presentation table, folding chair rows, seated graduates and a waiting group. Run with F6 to walk the clear central aisle and stage ramp. Each prop and the graduate crowd can also be studied individually in the generic stage.

`campus_landmarks_test.tscn` previews the [graduation landmarks](../../components/scenery/graduation/LANDMARKS.md): freestanding twin stone arches, an inherited cherry blossom tree preset and an open classical portico with broad stairs. Walk through either arch and climb the center of the stairs to the columned landing. The original museum portico remains available in its own memory.

`tokyo_temples_test.tscn` previews the [Tokyo landmark kit](../../components/scenery/tokyo/README.md): Meiji's wooden torii and worship hall, plus Sensō-ji's main hall, five-story pagoda and Hōzōmon lantern gate. Walk through the gates or climb the hall steps to their closed fronts. `tokyo_city_test.tscn` studies the same kit's scramble crossing and five varied modular towers, with animated billboards and the existing standing crowd. Both inherit the shared F6 component stage; they are separate studies, not timeline memories.

`sailing_test.tscn` previews the [sailing kit](../../components/scenery/sailing/README.md): a T-shaped wooden dock with walkable shore ramp, an Ensign sailboat with gently moving sails/hull, and the existing lake and shoreline foliage. Run with F6 to walk from shore to the landing, or assign either component to the generic stage for isolated parameter/recall studies. The boat is a scenic prop with exterior collision, not a controllable vehicle.

`sand_test.tscn` previews [painterly sand](../../components/groundcover/sand/README.md) in two forms: wind-shaped dune ridges and softer rolling hills. Walk onto the raised terrain to leave temporary footprints. Both configurations use real surface collision, inherited snow footprint tracking and editable sand colors. The generic stage can also load a single sand patch for isolated recall checks.

`lighthouse_test.tscn` previews the [painterly lighthouse](../../components/scenery/lighthouse/README.md), with a smooth tapered tower, lantern gallery and rotating painted beacon. Walk up its entry steps to the closed door; use the background selector to inspect the soft beam against a dark setting. Height, radius, colors, windows and beacon controls live on the source component.
