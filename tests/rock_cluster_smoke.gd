extends SceneTree
## godot --headless --path . --script tests/rock_cluster_smoke.gd
var failures: int = 0
func _initialize() -> void:
	call_deferred("run")
func check(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		failures += 1
func run() -> void:
	# Use generator defaults for size-distribution checks; scene presets are editable.
	var cluster := PainterlyRockCluster.new()
	root.add_child(cluster)
	check(cluster is PainterlyBoulder, "Cluster must inherit the boulder generator")
	check(cluster.get_children().is_empty(), "Generated cluster meshes must not serialize")
	check(cluster._rock_bounds.size() == cluster.rock_count, "Every requested rock must be generated")
	check(cluster.get_node("ClusterCollision").get_child_count() == cluster.rock_count, "Every solid rock must have its own convex collision")
	var stones: MeshInstance3D = cluster.get_node("Stones")
	var mesh := stones.mesh
	check(mesh.get_surface_count() == 1, "All rocks must share one render surface")
	var faces: PackedVector3Array = mesh.get_faces()
	var original := faces.duplicate()
	check(faces.size() / 3 < cluster.rock_count * 200, "Cluster must preserve the small boulder geometry budget")
	check(cluster.get_node("ContactShadows").mesh.get_faces().size() / 3 == cluster.rock_count * 2, "Each rock must have a contact-shadow quad in the shared shadow surface")
	var finite := true
	for point in faces:
		finite = finite and point.is_finite()
	check(finite, "Cluster geometry must be finite")
	var min_size := INF
	var max_size := 0.0
	for bounds in cluster._rock_bounds:
		min_size = minf(min_size, bounds.size.length())
		max_size = maxf(max_size, bounds.size.length())
	check(max_size > min_size * 1.5, "Default cluster must contain noticeably different stone sizes")
	check(max_size < 1.8, "Default clustered stones must be smaller than a full boulder")
	cluster.rebuild()
	check(cluster.get_node("Stones").mesh.get_faces() == original, "Seeded cluster must reproduce geometry and placement")
	stones = cluster.get_node("Stones")
	cluster.palette_preset = 6
	check(cluster.get_node("Stones") == stones, "Palette edits must preserve geometry nodes")
	check(stones.material_override.get_shader_parameter("mid_color") == cluster.palette.mid_color, "Inherited palette must update the merged stones")
	var packed := PackedScene.new()
	check(packed.pack(cluster) == OK, "Cluster scene must pack")
	var restored: PainterlyRockCluster = packed.instantiate()
	root.add_child(restored)
	check(restored.rock_count == cluster.rock_count and restored.palette_preset == 6, "Rock count and inherited palette must persist")
	check(restored.get_node("Stones").mesh.get_faces() == original, "Saved cluster must restore the same seeded shape")
	restored.free()
	cluster.boulder_seed += 1
	cluster.rebuild()
	check(cluster.get_node("Stones").mesh.get_faces() != original, "New seed must change the cluster")
	cluster.rock_count = 1
	cluster.solid = false
	cluster.rebuild()
	check(cluster._rock_bounds.size() == 1 and not cluster.has_node("ClusterCollision"), "One rock and optional collision must be supported")
	cluster.rock_count = 40
	cluster.rebuild()
	check(cluster._rock_bounds.size() == 40 and cluster.get_children(true).size() == 2, "Large clusters must retain two geometry nodes")
	cluster.rock_count = 0
	cluster.rebuild()
	check(cluster.get_children(true).is_empty(), "Zero count must remove rocks, shadows, and collision")
	cluster.free()
	print("Rock cluster checks: ", "PASS" if failures == 0 else "FAIL", " | default triangles: ", original.size() / 3)
	quit(failures)
