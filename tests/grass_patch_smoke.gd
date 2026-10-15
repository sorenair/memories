extends SceneTree
## Tests authoring contracts and instancing budgets without a graphics device.
var failures: int = 0
func _initialize() -> void:
	call_deferred("run")
func check(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		failures += 1
func run() -> void:
	var patch := load("res://components/foliage/painterly_grass_patch.tscn").instantiate() as PainterlyGrassPatch
	root.add_child(patch)
	await process_frame
	var children := patch.get_children(true)
	check(children.size() == 3, "Patch must use exactly three generated geometry nodes")
	check(patch.get_children().is_empty(), "Generated geometry must remain internal to the component")
	var grass := patch.get_node("GrassTufts") as MultiMeshInstance3D
	var leaves := patch.get_node("PaintedLeaves") as MultiMeshInstance3D
	var count := grass.multimesh.instance_count
	check(count > 100 and leaves.multimesh.instance_count > 100, "Demo must contain a populated meadow")
	var first := grass.multimesh.get_instance_transform(0)
	var tenth := grass.multimesh.get_instance_transform(10)
	var tint := grass.multimesh.get_instance_custom_data(0)
	var primitives := 0
	for batch in [grass, leaves]:
		var vertices: PackedVector3Array = batch.multimesh.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
		primitives += vertices.size() / 3 * batch.multimesh.instance_count
		check(batch.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF, "Foliage must avoid shadow passes")
		check(batch.multimesh.custom_aabb.has_point(batch.multimesh.get_instance_transform(0).origin), "Culling bounds must include instances")
	check(primitives < 45000, "Default patch must stay below 45k triangles")
	patch.rebuild()
	grass = patch.get_node("GrassTufts")
	check(grass.multimesh.instance_count == count, "Seed must reproduce instance count")
	check(grass.multimesh.get_instance_transform(0).is_equal_approx(first), "Seed must reproduce placement")
	check(grass.multimesh.get_instance_custom_data(0).is_equal_approx(tint), "Seed must reproduce palette distribution")
	patch.patch_seed += 1
	await process_frame
	await process_frame
	grass = patch.get_node("GrassTufts")
	check(grass.multimesh.instance_count != count or not grass.multimesh.get_instance_transform(10).is_equal_approx(tenth), "New seed must change the patch")
	var other := load("res://components/foliage/painterly_grass_patch.tscn").instantiate() as PainterlyGrassPatch
	other.palette = load("res://components/foliage/palettes/dusk.tres")
	root.add_child(other)
	check(other.get_node("GrassTufts").material_override != grass.material_override, "Patches must have independent shader uniforms")
	check(other.get_node("GrassTufts").material_override.get_shader_parameter("leaf_color") == other.palette.leaf_color, "Palette preset must feed foliage")
	# Exercise smoothing math with synthetic transforms, independent of render interpolation.
	physics_interpolation = false
	patch.set_process(false)
	var explorer := Node3D.new()
	explorer.add_to_group("explorers")
	root.add_child(explorer)
	patch._process(0.0)
	explorer.position.x = 1.0
	explorer.reset_physics_interpolation()
	patch._process(1.0 / 60.0)
	var smoothed: Vector3 = patch.get_node("GrassTufts").material_override.get_shader_parameter("explorer_position")
	check(smoothed.x > 0.0 and smoothed.x < 0.3, "Bending must approach player gradually instead of snapping")
	for frame in range(60):
		patch._process(1.0 / 60.0)
	var settled: Vector3 = patch.get_node("GrassTufts").material_override.get_shader_parameter("explorer_position")
	check(settled.distance_to(explorer.position) < 0.001, "Bending must settle at the stationary player")
	patch._interaction_initialized = false
	explorer.position = Vector3.ZERO
	explorer.reset_physics_interpolation()
	patch._process(0.0)
	explorer.position.x = 1.0
	explorer.reset_physics_interpolation()
	for frame in range(30):
		patch._process(1.0 / 30.0)
	var low_fps: Vector3 = patch.get_node("GrassTufts").material_override.get_shader_parameter("explorer_position")
	check(low_fps.distance_to(settled) < 0.001, "Smoothing must be consistent at 30 and 60 FPS")
	explorer.position.x = 100.0
	explorer.reset_physics_interpolation()
	patch._process(1.0 / 60.0)
	check(patch._smoothed_explorer_position.is_equal_approx(explorer.position), "Teleports must reset the bend center")
	patch.tufts_per_square_meter = 0
	patch.leaves_per_square_meter = 0
	await process_frame
	await process_frame
	check(patch.get_node("GrassTufts").multimesh.instance_count == 0, "Zero density must remove grass")
	check(patch.get_node("PaintedLeaves").multimesh.instance_count == 0, "Zero density must remove leaves")
	patch.react_to_explorer = false
	check(not patch.is_processing(), "Disabled interaction must have no process callback")
	print("Grass patch smoke checks: ", "PASS" if failures == 0 else "FAIL", " | default triangles: ", primitives, " | tufts: ", count)
	quit(failures)
