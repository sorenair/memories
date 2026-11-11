extends SceneTree
var failures := 0
func _initialize() -> void:
	call_deferred("run")
func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)
func run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Requires graphics for MultiMesh readback")
		quit(1)
		return
	var vine: PainterlyWallVine = load("res://components/foliage/vines/painterly_wall_vine.tscn").instantiate()
	root.add_child(vine)
	check(vine.get_children().is_empty(), "Generated vine must not serialize into memory scenes")
	check(vine.get_children(true).size() == 2, "Vine must use just stems and one leaf batch")
	var leaves: MultiMeshInstance3D = vine.get_node("Foliage")
	check(leaves.multimesh.instance_count == vine.leaf_spray_count, "Density must generate the requested sprays")
	var initial := leaves.multimesh.buffer.duplicate()
	var vertices: PackedVector3Array = leaves.multimesh.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	var bounds_valid := true
	var positive := 0
	for index in range(leaves.multimesh.instance_count):
		var transform := leaves.multimesh.get_instance_transform(index)
		if transform.origin.y > 0:
			positive += 1
		for point in vertices:
			bounds_valid = bounds_valid and leaves.multimesh.custom_aabb.has_point(transform * point)
	check(bounds_valid, "Culling bounds must cover every leaf")
	check(positive > vine.leaf_spray_count * 0.9, "Climbing growth must extend upward")
	var stem_points: PackedVector3Array = vine.get_node("Stems").mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	var triangles := vertices.size() / 3 * vine.leaf_spray_count + stem_points.size() / 3
	check(triangles < 10000, "Default vine must remain under 10k triangles")
	check(leaves.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF, "Vine must avoid shadow-map passes")
	vine.rebuild()
	check(vine.get_node("Foliage").multimesh.buffer == initial, "Same seed must reproduce leaf placement")
	vine.palette_preset = 3
	vine.palette = vine.palette.duplicate()
	check(vine.palette_preset == 3, "Deserializing a matching preset resource must preserve the autumn selection")
	check(vine.get_node("Foliage").multimesh.buffer == initial, "Palette changes must preserve placement")
	vine.vine_seed += 1
	vine.rebuild()
	check(vine.get_node("Foliage").multimesh.buffer != initial, "Seed must vary the growth shape")
	vine.growth_mode = 1
	vine.rebuild()
	var mean_y := 0.0
	leaves = vine.get_node("Foliage")
	for index in range(leaves.multimesh.instance_count):
		mean_y += leaves.multimesh.get_instance_transform(index).origin.y
	check(mean_y / vine.leaf_spray_count < -0.4, "Hanging mode must grow below its origin")
	var player := Node3D.new()
	root.add_child(player)
	player.add_to_group(&"explorers")
	player.position = Vector3(0, 0, 0.3)
	vine._process(0.02)
	check(vine._weights[0] > 0 and vine._weights[0] < 0.5, "Player response must ease in")
	player.position.x = 0.5
	vine._process(0.02)
	check(vine._positions[0].x > 0 and vine._positions[0].x < 0.5, "Player positions must be smoothly filtered")
	vine.react_to_explorers = false
	vine._process(1.0)
	check(vine._weights[0] < 0.001, "Disabling disturbance must release the vine")
	vine.leaf_spray_count = 0
	vine.rebuild()
	check(vine.get_node("Foliage").multimesh.instance_count == 0 and not vine.get_node("Stems").visible, "Zero density must leave an empty component")
	var demo: Node = load("res://scenes/memories/foliage_demo.tscn").instantiate()
	check(demo.has_node("Environment/SummerSpring/ClimbingVine"), "Demo must include a climbing vine")
	demo.free()
	vine.queue_free()
	player.queue_free()
	await process_frame
	print("Wall vine: ", "PASS" if failures == 0 else "FAIL", " | default triangles: ", triangles)
	quit(failures)
