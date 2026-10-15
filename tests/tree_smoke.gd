extends SceneTree
## Requires a rendering device for MultiMesh readback.
## godot --path . --script tests/tree_smoke.gd
var failures: int = 0
func _initialize() -> void:
	call_deferred("run")
func check(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		failures += 1
func bark_vertices(tree: Node) -> PackedVector3Array:
	return tree.get_node("TrunkAndBranches").mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
func run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Run without --headless: this test requires MultiMesh buffer readback from a real renderer.")
		quit(1)
		return
	var tree: PainterlyTree = load("res://components/foliage/painterly_tree.tscn").instantiate()
	root.add_child(tree)
	check(tree.get_children().is_empty(), "Generated children must not serialize into memory scenes")
	check(tree.get_children(true).size() == 4, "Tree must contain three geometry nodes and one collision body")
	var canopy := tree.get_node("Canopy") as MultiMeshInstance3D
	check(canopy != null, "Canopy must consist of instanced leaf geometry rather than a sphere mesh")
	var leaves: MultiMesh = canopy.multimesh
	var first_leaf := leaves.get_instance_transform(0)
	var first_tint := leaves.get_instance_custom_data(0)
	var original_buffer := leaves.buffer.duplicate()
	var original_bark := bark_vertices(tree)
	var leaf_vertices: PackedVector3Array = leaves.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	var triangles := (original_bark.size() + leaves.instance_count * leaf_vertices.size()) / 3
	check(triangles < 30000, "Default tree must stay below 30k triangles")
	check(leaves.instance_count == (tree.branch_count + 1) * tree.leaf_sprays_per_cluster, "Density must match leaf-mass count")
	check(leaves.mesh.get_aabb().size.y > 0.3, "Leaf sprays must have depth instead of being flat surface decals")
	var inside_bounds := true
	var min_position := Vector3.INF
	var max_position := -Vector3.INF
	for index in range(leaves.instance_count):
		var placement := leaves.get_instance_transform(index)
		check(placement.origin.is_finite(), "Leaf positions must be finite")
		min_position = min_position.min(placement.origin)
		max_position = max_position.max(placement.origin)
		for vertex in leaf_vertices:
			inside_bounds = inside_bounds and leaves.custom_aabb.has_point(placement * vertex)
	check(inside_bounds, "Culling bounds must include all leaf geometry")
	check(max_position.y - min_position.y > tree.tree_height * 0.2, "Leaf masses must occupy depth throughout the crown")
	for mesh_name in ["Canopy", "TrunkAndBranches", "SoftGroundShadow"]:
		check(tree.get_node(mesh_name).cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF, "Tree must avoid shadow-map passes")
	var shape: CapsuleShape3D = tree.get_node("TrunkCollision").get_child(0).shape
	check(shape.radius > tree.trunk_radius, "Trunk collision must cover the stem")
	tree.rebuild()
	check(bark_vertices(tree) == original_bark, "Seed must reproduce branching geometry")
	check(tree.get_node("Canopy").multimesh.buffer == original_buffer, "Seed must reproduce full foliage distribution and painted colors")
	check(tree.get_node("TrunkCollision").get_child_count() == 4, "Bent lower stem must use aligned segment collision")
	tree.trunk_bend = 0.0
	tree.rebuild()
	check(bark_vertices(tree) != original_bark, "Trunk bend control must change the stem geometry")
	check(tree.get_node("Canopy").multimesh.buffer == original_buffer, "Trunk variation must preserve foliage layout")
	tree.trunk_bend = 0.075
	tree.tree_seed += 1
	tree.rebuild()
	check(tree.get_node("Canopy").multimesh.buffer != original_buffer, "New seeds must produce different foliage distributions")
	var other: PainterlyTree = load("res://components/foliage/painterly_tree.tscn").instantiate()
	other.palette = load("res://components/foliage/palettes/dusk.tres")
	root.add_child(other)
	check(other.get_node("Canopy").material_override != tree.get_node("Canopy").material_override, "Trees must have independent materials")
	check(other.get_node("Canopy").material_override.get_shader_parameter("leaf_color") == other.palette.leaf_color, "Canopy must use the shared foliage palette")
	check(other.get_node("Canopy").multimesh.mesh == tree.get_node("Canopy").multimesh.mesh, "Trees must share the leaf mesh")
	check(other.get_node("Canopy").multimesh.get_instance_transform(0).is_equal_approx(first_leaf), "Palette changes must preserve leaf placement")
	check(other.get_node("Canopy").multimesh.get_instance_custom_data(0).is_equal_approx(first_tint), "Palette changes must preserve clump lighting")
	tree.leaf_sprays_per_cluster = 0
	tree.trunk_collision = false
	tree.rebuild()
	check(tree.get_node("Canopy").multimesh.instance_count == 0, "Zero density must remove the complete canopy")
	check(not tree.has_node("TrunkCollision"), "Decorative trees must support disabled collision")
	print("Tree smoke checks: ", "PASS" if failures == 0 else "FAIL", " | default triangles: ", triangles)
	quit(failures)
