# Component test scenes

`res://tests/scenes/component_test.tscn` is the reusable 3D test stage. Open it and
press **F6**. Its current subject is the painterly smoke / steam emitter. Choose another
component through Subject Scene.

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
`tests/light_wash.gd` exercises the generic stage, including swapping its subject to
another component while preserving the camera and player.
