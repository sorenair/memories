extends SceneTree
## Requires graphics: godot --path . --script tests/tree_variants.gd
var failures: int = 0
func _initialize() -> void:
	call_deferred("run")
func check(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		failures += 1
func run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Run without --headless: variant checks require MultiMesh readback.")
		quit(1)
		return
	var tree: PainterlyTree = load("res://components/foliage/painterly_tree.tscn").instantiate()
	root.add_child(tree)
	var signatures: Array[Vector3] = []
	for kind in range(6):
		tree.tree_type = kind
		tree.rebuild()
		var canopy: MultiMeshInstance3D = tree.get_node("Canopy")
		var multimesh := canopy.multimesh
		var original := multimesh.buffer.duplicate()
		var foliage: PackedVector3Array = multimesh.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
		var bark: PackedVector3Array = tree.get_node("TrunkAndBranches").mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
		var triangles := multimesh.instance_count * foliage.size() / 3 + bark.size() / 3
		check(triangles < 30000, "Default variant must remain below 30k triangles")
		check(multimesh.instance_count == (tree.branch_count + 1) * tree.leaf_sprays_per_cluster, "Variants must preserve the leaf-density budget")
		var bounds_valid := true
		var positions_valid := true
		for index in range(multimesh.instance_count):
			var placement := multimesh.get_instance_transform(index)
			positions_valid = positions_valid and placement.origin.is_finite()
			for point in foliage:
				bounds_valid = bounds_valid and multimesh.custom_aabb.has_point(placement * point)
		check(bounds_valid and positions_valid, "Every variant must have finite geometry within culling bounds")
		var bounds := multimesh.custom_aabb
		signatures.append(bounds.size)
		tree.rebuild()
		check(tree.get_node("Canopy").multimesh.buffer == original, "Variants must reproduce seeded geometry")
		tree.palette_preset = 6
		check(tree.get_node("Canopy").multimesh.buffer == original, "Palette changes must preserve variant geometry")
		tree.wind_strength = 0.07
		check(tree.get_node("Canopy").material_override.get_shader_parameter("wind_strength") == 0.07, "Every variant must support shared live wind controls")
		var packed := PackedScene.new()
		check(packed.pack(tree) == OK, "Variant must pack")
		var restored: PainterlyTree = packed.instantiate()
		root.add_child(restored)
		check(restored.tree_type == kind and restored.palette_preset == 6, "Tree type and palette must survive scene packing")
		restored.free()
		var expected_mesh := PainterlyLeafGeometry.needle_spray_mesh() if kind >= TreeVariants.Kind.PINE else PainterlyLeafGeometry.leaf_spray_mesh()
		check(multimesh.mesh == expected_mesh, "Tree types must reuse the appropriate shared leaf mesh")
		if kind == TreeVariants.Kind.BIRCH:
			check(tree.get_node("TrunkAndBranches").material_override.get_shader_parameter("birch_marks") > 0.0, "Birch must provide characteristic bark markings")
		print("Tree variant ", kind, " | triangles: ", triangles, " | foliage bounds: ", bounds.size)
	check(signatures[TreeVariants.Kind.OAK].x > signatures[TreeVariants.Kind.BIRCH].x * 1.8, "Oak and birch must have distinct crown widths")
	check(signatures[TreeVariants.Kind.PINE].x > signatures[TreeVariants.Kind.CYPRESS].x * 1.5, "Pine and cypress must have distinct silhouettes")
	tree.tree_type = TreeVariants.Kind.CYPRESS
	tree.leaf_sprays_per_cluster = 121
	tree.rebuild()
	check(tree.get_node("Canopy").multimesh.instance_count == (tree.branch_count + 1) * 121, "Tier density must preserve odd counts")
	tree.leaf_sprays_per_cluster = 0
	tree.rebuild()
	check(tree.get_node("Canopy").multimesh.instance_count == 0, "Zero density must remove evergreen foliage")
	print("Tree variant checks: ", "PASS" if failures == 0 else "FAIL")
	quit(failures)
