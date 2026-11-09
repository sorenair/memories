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
	var patch: PainterlyFlowerPatch = load("res://components/foliage/flowers/painterly_flower_patch.tscn").instantiate()
	root.add_child(patch)
	check(patch.get_children().is_empty(), "Generated flowers must not serialize into the authoring scene")
	var batch: MultiMeshInstance3D = patch.get_node("Flowers")
	check(batch.multimesh.instance_count == patch.flower_count, "Patch must generate requested bloom count")
	check(batch.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF, "Flowers must avoid shadow-map passes")
	var original := batch.multimesh.buffer.duplicate()
	var mesh: ArrayMesh = batch.multimesh.mesh
	var vertices: PackedVector3Array = mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	check(vertices.size() / 3 < 130, "Each flower must remain lightweight")
	var bounds_valid := true
	var min_scale := INF
	var max_scale := 0.0
	for index in range(batch.multimesh.instance_count):
		var transform := batch.multimesh.get_instance_transform(index)
		min_scale = minf(min_scale, transform.basis.x.length())
		max_scale = maxf(max_scale, transform.basis.x.length())
		for vertex in vertices:
			bounds_valid = bounds_valid and batch.custom_aabb.has_point(transform * vertex)
	check(bounds_valid, "Bounds must contain every flower")
	check(max_scale / min_scale > 2.5, "Patch should include a wide range of crown sizes")
	patch.rebuild()
	check(patch.get_node("Flowers").multimesh.buffer == original, "Seeded placement must reproduce exactly")
	patch.patch_seed += 1
	patch.rebuild()
	check(patch.get_node("Flowers").multimesh.buffer != original, "Changing seed must vary the clusters")
	var before_palette: PackedFloat32Array = patch.get_node("Flowers").multimesh.buffer.duplicate()
	patch.bloom_palette = 2
	check(patch.get_node("Flowers").multimesh.buffer == before_palette, "Color changes must preserve placement")
	patch.flower_count = 0
	patch.rebuild()
	check(patch.get_node("Flowers").multimesh.instance_count == 0, "Zero count must remove all blooms")
	var water: PainterlyWater = load("res://components/scenery/water/painterly_water.tscn").instantiate()
	water.name = "Water"
	root.add_child(water)
	water.footprint = Vector2(8, 8)
	water.rebuild()
	patch.flower_count = 25
	patch.ground_exclusions = [NodePath("../Water")]
	patch.rebuild()
	check(patch.get_node("Flowers").multimesh.instance_count == 0, "Water exclusions must keep blooms off the pond")
	var demo: Node = load("res://scenes/memories/foliage_demo.tscn").instantiate()
	check(demo.get_node("Environment/SummerSpring").find_children("*", "PainterlyFlowerPatch", false, false).size() == 3, "Summer zone must contain three flower patches")
	demo.free()
	patch.queue_free()
	water.queue_free()
	await process_frame
	print("Flower patch: ", "PASS" if failures == 0 else "FAIL")
	quit(failures)
