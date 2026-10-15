extends SceneTree
## Requires graphics: godot --path . --script tests/bush_smoke.gd
var failures: int = 0
func _initialize() -> void:
	call_deferred("run")
func check(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		failures += 1
func run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Run without --headless: this test reads MultiMesh buffers from the renderer.")
		quit(1)
		return
	var bush: PainterlyBush = load("res://components/foliage/painterly_bush.tscn").instantiate()
	root.add_child(bush)
	check(bush.get_children().is_empty(), "Generated bushes must save parameters instead of geometry nodes")
	check(bush.get_children(true).size() == 2, "Bush must use exactly two geometry nodes")
	var batch: MultiMeshInstance3D = bush.get_node("Foliage")
	var multimesh := batch.multimesh
	var buffer := multimesh.buffer.duplicate()
	check(multimesh.instance_count == bush.mass_count * bush.sprays_per_mass, "Bush density must match the authored budget")
	var vertices: PackedVector3Array = multimesh.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	var triangles := vertices.size() / 3 * multimesh.instance_count
	check(triangles < 7000, "Default bush must stay under 7k triangles")
	check(vertices.size() > 0 and multimesh.mesh.get_aabb().size.y > 0.3, "Foliage must use curved dimensional leaf sprays")
	var bounds_valid := true
	var min_position := Vector3.INF
	var max_position := -Vector3.INF
	for index in range(multimesh.instance_count):
		var placement := multimesh.get_instance_transform(index)
		min_position = min_position.min(placement.origin)
		max_position = max_position.max(placement.origin)
		for vertex in vertices:
			bounds_valid = bounds_valid and multimesh.custom_aabb.has_point(placement * vertex)
	check(bounds_valid, "Culling bounds must include all leaf sprays")
	check((max_position - min_position).y > bush.bush_height * 0.3, "Foliage must occupy volume throughout the bush")
	check(batch.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF, "Bush must avoid shadow-map passes")
	bush.rebuild()
	check(bush.get_node("Foliage").multimesh.buffer == buffer, "Seed must reproduce geometry and colors")
	bush.bush_seed += 1
	bush.rebuild()
	check(bush.get_node("Foliage").multimesh.buffer != buffer, "Different seeds must produce different shrubs")
	var other: PainterlyBush = load("res://components/foliage/painterly_bush.tscn").instantiate()
	other.palette = load("res://components/foliage/palettes/dusk.tres")
	root.add_child(other)
	check(other.get_node("Foliage").material_override != bush.get_node("Foliage").material_override, "Bush materials must remain independent")
	check(other.get_node("Foliage").material_override.get_shader_parameter("leaf_color") == other.palette.leaf_color, "Shared palette resources must control foliage")
	var tree: PainterlyTree = load("res://components/foliage/painterly_tree.tscn").instantiate()
	root.add_child(tree)
	check(tree.get_node("Canopy").multimesh.mesh == multimesh.mesh, "Tree and bush must share one leaf mesh")
	bush.wind_strength = 0.0
	check(bush.get_node("Foliage").material_override.get_shader_parameter("wind_strength") == 0.0, "Wind controls must update without regenerating the bush")
	bush.sprays_per_mass = 0
	bush.rebuild()
	check(bush.get_node("Foliage").multimesh.instance_count == 0, "Zero density must remove foliage")
	check(not bush.get_node("GroundPigment").visible, "Zero density must also remove the ground wash")
	print("Bush smoke checks: ", "PASS" if failures == 0 else "FAIL", " | default triangles: ", triangles)
	quit(failures)
