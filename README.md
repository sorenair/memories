# memories

A shared relationship timeline told through small, dreamlike 3D memories. The first demo memory is a painterly forest clearing with eleven procedural trees, grass, bushes, and boulders in a white dreamscape.

## Play

Open `project.godot` in Godot 4.4 or newer and press **F6** with `scenes/world/memory_world.tscn` open, or **F5** to run the project.

- **WASD / arrow keys:** walk, relative to the screen.
- **Controller left stick:** analog movement.
- **Touch and drag:** a floating movement stick appears beneath your finger; release to stop.

The current scene contains a simple character, seamless ground, a reusable procedural foliage patch, and a procedural tree. It has gentle acceleration, deceleration, turning, a small walking motion, an elevated orthographic follow camera, warm ambient lighting, distance fog, and a soft contact shadow. The grass is present from startup, with gentle wind and local player bending; it has no recollection or transition effects. The surface follows the player over an infinite collision plane, so long walks do not expose an edge.

The game launches fullscreen at a fixed landscape phone aspect ratio (1920 × 886). Extra screen area is letterboxed in black, preserving proportions. A small black FPS counter appears at the top right of the game area. Rendering is uncapped with VSync disabled for performance testing. Movement stays on fixed physics ticks; physics interpolation smooths the character between them. The render-frame camera and grass sample the same interpolated player position. Reset player physics interpolation when teleporting or spawning after entering the scene tree.

## Foliage components

Instance `components/foliage/painterly_grass_patch.tscn` in a memory to add grass. Size, seed, density, height, palette, wind, and culling distance are editable in the Inspector with live editor previews. See [the foliage authoring guide](components/foliage/README.md) for controls and rendering budgets. The demo is `scenes/memories/foliage_demo.tscn`.

Instance `components/foliage/painterly_tree.tscn` to add a single tree. Choose Broadleaf, Spreading Oak, Slender Birch, Weeping Willow, Layered Pine, or Columnar Cypress under **Tree Shape → Tree Type**. Seeds, proportions, branches, canopy detail, bark, wind, and trunk collision are editable with live previews. Trees share the grass palette resources. See [the tree authoring guide](components/foliage/TREES.md).

Instance `components/foliage/painterly_bush.tscn` to add a low, spreading shrub. Seed, footprint, height, density, palette, wind, and culling distance are editable with live previews. See [the bush authoring guide](components/foliage/BUSHES.md).

Use **Foliage Colors → Palette Preset** on any grass, tree, or bush instance for seasonal and dreamlike color schemes. See [the palette guide](components/foliage/PALETTES.md).

## Scenery components

Instance `components/scenery/boulders/painterly_boulder.tscn` for one seeded, painterly stone with six varied shape profiles, stone palettes, and convex collision. See [the boulder guide](components/scenery/boulders/README.md). The demo contains boulders and a reusable rock cluster beside the pond.

## Create another memory

1. In Godot, create an **inherited scene** from `scenes/memories/memory_base.tscn` and save it under `scenes/memories/`.
2. Set its unique `memory_id` and `display_name` in the Inspector.
3. Position `Entry` at the spawn point and `Exit` at the intended connection to the next memory. Both are invisible markers.
4. Put scenery under `Environment`. The empty `RevealClusters`, `Interactions`, and `SignatureInteraction` containers reserve consistent places for future systems.
5. Replace the `Memory` instance in `scenes/world/memory_world.tscn` with the new memory. Keep its node name `Memory`; the world uses its entry transform to spawn the explorer.

`blank_void.tscn` demonstrates inheritance without adding content. The world scene owns presentation, ground, controls, player, and camera, so memory content can share the same foundation. Each future memory can inherit the content template instead of duplicating player or camera code.

## Tune the foundation

- `Explorer` instance: `walk_speed`, `acceleration`, `turn_speed`.
- `CameraRig`: `follow_speed`; `Camera3D`: size, position, rotation, projection.
- `WorldEnvironment` and `Sun`: palette, haze, and lighting.
- `shaders/dream_surface.gdshader`: faint surface pigment.

The Mobile renderer is preserved. The scene uses no volumetric fog, particles, or real-time shadow maps; water uses one shared procedural paint-mask texture. The soft contact shadow is a single transparent quad. iOS export, device performance, multiplayer, persistence, memory transitions, discovery effects, and interactions are future work; the named containers do not implement those systems yet.

## Validate

```sh
godot --headless --path . --editor --quit
godot --headless --path . --script tests/scene_smoke.gd
godot --headless --path . --script tests/grass_patch_smoke.gd
godot --path . --script tests/tree_smoke.gd
godot --path . --script tests/bush_smoke.gd
```

The smoke check exercises scene loading, grounded movement, camera-relative direction, diagonal speed, stopping, camera follow, touch normalization/release, and walking beyond the initial surface. It exits nonzero on failure.

`docs/first-scene.png` is a preview rendered with Godot 4.4.1's Mobile renderer on macOS. Touch input is checked synthetically; physical iOS hardware has not been tested.

`docs/foliage-demo.png` shows the current grass demo rendered with the Mobile renderer.

For a rendered movement timing check, run `godot --path . --script tests/movement_render_smoke.gd`. It compares physics movement updates with interpolated player updates at the actual render rate.

`docs/tree-demo.png` shows the current meadow and tree demo.

`docs/bush-demo.png` shows the current meadow with a tree and three reusable bushes.

`docs/forest-clearing-overview.png` shows the current clearing: an irregular horseshoe of autumn broadleaf, oak, and birch trees, with taller crowns at the back and an open entrance facing the player. Tree seeds, rotations, proportions, and density are authored on individual instances in `scenes/memories/foliage_demo.tscn`. The expanded meadow uses shorter grass and reduced per-area density to connect the tree bases.

Instance `components/scenery/water/painterly_water.tscn` for painterly ponds and modular stream sections. Shape, seed, painted depth, caustic light, flow, and seasonal/dream palettes have live Inspector controls. The demo pond integrates with grass exclusions and optional shoreline collision. See [the water authoring guide](components/scenery/water/README.md).

The pond is framed by low shoreline shrubs, a willow and side trees, with short groundcover extending the meadow around it. The player’s approach stays open and the foreground shrubs stay low to preserve water visibility. `docs/pond-clearing.png` shows the current gameplay composition.

Instance `components/scenery/rock_clusters/painterly_rock_cluster.tscn` for smaller clustered stones inheriting the boulder generator. **Cluster → Rock Count, Rock Scale, Size Variation, and Cluster Footprint** control the group. See [the rock cluster guide](components/scenery/rock_clusters/README.md).
