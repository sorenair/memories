# Painterly bungalow

Instance `painterly_house.tscn`. The origin is the center of the footprint at ground level; the front door faces **local +Z**. It previews and regenerates in the Godot editor.

This is a constrained exterior house family modeled after the first-meeting reference: cream walls, a gray hipped shingle roof, a front dormer, paired sash windows, a centered paneled door, raised foundation, steps, and dark railings. It uses broad toon tones, broad warm plaster washes, soft eave/foundation shade, slightly irregular staggered shingle courses, and opaque painted window reflections with quiet curtain/interior shapes. No generated interiors, textures, lights, or transparent glass.

| Controls | Effect |
| --- | --- |
| Footprint / Wall Height | Overall exterior proportions |
| Foundation Height | Raised floor and stair rise |
| Roof Height / Overhang | Roof pitch and eave reach |
| Dormer / Side Windows | Include or remove these features |
| Door Width / Stair Width | Entrance proportions |
| Step Count / Depth / Railings | Front stair treatment |
| Wall, Trim, Roof, Wood, Glass, Foundation, Rail Colors | Architectural palette |
| Pigment Strength / Window Warmth | Broad brush wash strength and warm interior pigment |
| Porch Lamp | Small amber fixture above the door; merged painted geometry, no dynamic light |
| House Seed | Quiet shingle/plaster pigment variation |
| Shingle Size | Roof detail density |
| Collision Enabled | Solid exterior and walkable stair ramp |

The mesh is regenerated deterministically from these parameters. All exterior details are merged into **one opaque surface / draw call** using vertex-painted colors and shared soft toon shading. The default house is **4,006 triangles**. Smaller shingles and larger dimensions increase the count. There are no per-window, per-shingle, or per-railing-post scene nodes and no shadow-map passes.

Generated nodes remain internal. `FrontDoor` is a marker on the top step, clear of the building collider; `Approach` is a marker on the ground in front. The door is decorative and closed. Exterior collision stops players from entering the solid shell. The steps use a simple sloped collider underneath the stepped visual mesh so CharacterBody explorers can climb without snagging.

`excludes_ground_point(world_point)` and `ground_exclusion_changed` integrate with grass and other groundcover exclusion lists. The footprint and stairs stay clear when dimensions or placement change. Plants, vines, fences, paths, and characters are separate components; the house does not bundle a yard or narrative behavior.

The authored house setting now lives in **`res://scenes/memories/first_meeting.tscn`**, using the shared memory framework. Run the project and recall First Meeting, or open **`res://scenes/world/first_meeting_world.tscn` and press F6** to play it directly, including player, camera, controls, collision, and LAN support. The former standalone house study has been promoted into this memory.

This kit is appropriate for variations on this bungalow: proportions, colors, roof pitch, dormer presence, and entrance details. Unusual floor plans, distinctive roof intersections, interiors, and exact architectural ornament are better added as authored modules or Blender meshes rather than forcing every house into these parameters.

Run `godot --headless --path . --script res://tests/house.gd` for deterministic generation, optional details, vertex validity, triangle budget, ground exclusions, walkable stairs, and exterior collision checks.

Plaster, roofing, glass, and lamp paint are tagged within the shared mesh so the broad pigment washes do not muddy the window details. Shingle variation changes tiny course edges and pigment while preserving the structural roof contour. The lamp uses a small fixed emission value and does not require bloom or additional passes.
