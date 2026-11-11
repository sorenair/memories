extends SceneTree
var failures := 0
func _initialize() -> void:
	call_deferred("run")
func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)
func run() -> void:
	var fence: PainterlyYardFence = load("res://components/scenery/fences/painterly_yard_fence.tscn").instantiate()
	root.add_child(fence)
	check(fence.get_children().is_empty(), "Generated fence must not serialize into authoring scenes")
	var visual: MeshInstance3D = fence.get_node("Fence")
	var mesh: ArrayMesh = visual.mesh
	check(mesh.get_surface_count() == 1, "Fence must be one opaque draw surface")
	check(visual.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF, "Fence must avoid shadow-map passes")
	var vertices: PackedVector3Array = mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	var triangles := vertices.size() / 3
	check(triangles < 5000, "Default fence must remain under 5k triangles")
	var finite := true
	for point in vertices:
		finite = finite and point.is_finite()
	check(finite, "Fence vertices must be finite")
	var bounds := mesh.get_aabb()
	check(bounds.size.x >= fence.length and bounds.size.y >= fence.height, "Visual must cover the requested span")
	check(bounds.position.x >= -fence.length * 0.5 - fence.post_radius * 1.25 and bounds.end.x <= fence.length * 0.5 + fence.post_radius * 1.25, "Mesh must stay within its capped-post silhouette")
	check(bounds.position.y > -0.001 and bounds.end.y <= fence.height + fence.post_radius, "Fence must sit on the ground without protruding wire ends")
	var shape: BoxShape3D = fence.get_node("FenceCollision/CollisionShape3D").shape
	check(is_equal_approx(shape.size.x, fence.length) and is_equal_approx(shape.size.y, fence.height), "Collision must match the exact fence span")
	fence.rebuild()
	check(fence.get_node("Fence").mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX] == vertices, "Fence generation must be deterministic")
	fence.length = 6.5
	fence.height = 1.2
	fence.rebuild()
	var changed: MeshInstance3D = fence.get_node("Fence")
	check(changed.mesh.get_aabb().size.x > bounds.size.x and changed.mesh.get_aabb().size.y > bounds.size.y, "Length and height must resize geometry")
	shape = fence.get_node("FenceCollision/CollisionShape3D").shape
	check(is_equal_approx(shape.size.x, 6.5) and is_equal_approx(shape.size.y, 1.2), "Collision must follow edited dimensions")
	fence.collision_enabled = false
	fence.rebuild()
	check(not fence.has_node("FenceCollision"), "Decorative fence must allow collision to be disabled")
	fence.length = 0.5
	fence.height = 0.4
	fence.diamond_size = 0.4
	fence.rebuild()
	check(fence.get_node("Fence").mesh.get_aabb().size.x > 0.4, "Small sparse panels must still generate")
	fence.queue_free()
	await process_frame
	print("Yard fence: ", "PASS" if failures == 0 else "FAIL", " | default triangles: ", triangles)
	quit(failures)
