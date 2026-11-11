extends SceneTree
const GEOMETRY = preload("res://components/foliage/leaf_litter/leaf_litter_geometry.gd")
var failures := 0
func _initialize() -> void:
	call_deferred("run")
func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)
func run() -> void:
	var litter: Node3D = load("res://components/foliage/leaf_litter/painterly_leaf_litter.tscn").instantiate()
	root.add_child(litter)
	check(litter.get_children().is_empty(), "Generated leaf nodes must not serialize")
	var batch: MultiMeshInstance3D = litter.get_node("Leaves")
	check(batch.multimesh.instance_count == litter.leaf_count, "Litter must generate its exact leaf count")
	check(batch.multimesh.mesh.get_surface_count() == 1 and batch.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF, "Litter must use one surface without shadow-map passes")
	var points: PackedVector3Array = batch.multimesh.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	check(points.size() / 3 * litter.leaf_count < 2000, "Default litter must stay under 2k triangles")
	# Inspect the actual generated outline: a rounded resting leaf must not have
	# the alternating inward spikes and outward tips of the old star silhouette.
	var rim: Array[Vector2] = []
	for point in points:
		if Vector2(point.x, point.z).length_squared() > 0.01:
			var flat := Vector2(point.x, point.z)
			if not rim.has(flat):
				rim.append(flat)
	rim.sort_custom(func(a: Vector2, b: Vector2) -> bool: return a.angle() < b.angle())
	var convex := true
	var max_turn := 0.0
	for index in range(rim.size()):
		var previous: Vector2 = rim[posmod(index - 1, rim.size())]
		var point: Vector2 = rim[index]
		var next: Vector2 = rim[(index + 1) % rim.size()]
		var before := point - previous
		var after := next - point
		convex = convex and before.cross(after) >= -0.00001
		max_turn = maxf(max_turn, absf(before.angle_to(after)))
	check(rim.size() >= 20 and convex and max_turn < 0.50, "Leaf outline must be smoothly rounded without sharp serrations")
	var colors: PackedColorArray = batch.multimesh.mesh.surface_get_arrays(0)[Mesh.ARRAY_COLOR]
	var uniform_pigment := true
	for color in colors:
		uniform_pigment = uniform_pigment and color.is_equal_approx(colors[0])
	check(uniform_pigment, "Mesh faces must not introduce individual triangular paint wedges")
	var layout := GEOMETRY.create_layout(litter.leaf_seed, litter.leaf_count, litter.footprint, litter.size_range, litter.edge_bias)
	var repeated := GEOMETRY.create_layout(litter.leaf_seed, litter.leaf_count, litter.footprint, litter.size_range, litter.edge_bias)
	check(layout.transforms == repeated.transforms and layout.colors == repeated.colors, "Seed must reproduce transforms and paint")
	var changed := GEOMETRY.create_layout(litter.leaf_seed + 1, litter.leaf_count, litter.footprint, litter.size_range, litter.edge_bias)
	check(layout.transforms != changed.transforms, "A different seed must vary the scatter")
	var bounds_valid := true
	for transform: Transform3D in layout.transforms:
		for point in points:
			bounds_valid = bounds_valid and batch.multimesh.custom_aabb.has_point(transform * point)
	check(bounds_valid, "Culling bounds must cover every leaf")
	var edge_layout := GEOMETRY.create_layout(litter.leaf_seed, litter.leaf_count, litter.footprint, litter.size_range, 1.0)
	var plain_edge_distance := 0.0
	var biased_edge_distance := 0.0
	for index in range(litter.leaf_count):
		var a: Vector3 = layout.transforms[index].origin
		var b: Vector3 = edge_layout.transforms[index].origin
		plain_edge_distance += maxf(absf(a.x) / litter.footprint.x, absf(a.z) / litter.footprint.y)
		biased_edge_distance += maxf(absf(b.x) / litter.footprint.x, absf(b.z) / litter.footprint.y)
	check(biased_edge_distance > plain_edge_distance, "Edge bias must concentrate leaves toward the rectangle perimeter")
	litter.leaf_count = 0
	litter.rebuild()
	check(litter.get_node("Leaves").multimesh.instance_count == 0, "Zero count must generate no leaves")
	litter.queue_free()
	await process_frame
	print("Leaf litter: ", "PASS" if failures == 0 else "FAIL", " | default triangles: ", points.size() / 3 * 70)
	quit(failures)
