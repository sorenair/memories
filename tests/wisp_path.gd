extends SceneTree
var failures: int = 0
func _initialize() -> void:
	call_deferred("run")
func check(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		failures += 1
func run() -> void:
	var path: DreamWispPath = load("res://components/guidance/wisps/dream_wisp_path.tscn").instantiate()
	root.add_child(path)
	check(path._length > 5.0 and path._strokes.multimesh.instance_count == path.wisp_count, "Default route must produce the requested wisps")
	check(path.get_children().is_empty(), "Generated strokes must remain internal")
	check(not path.is_processing() and not path.is_physics_processing(), "Animation must not require frame callbacks")
	var mesh := path._strokes.multimesh.mesh
	check(mesh.get_faces().size()/3 == 24, "Each stroke must retain its small geometry budget")
	var bounds := path._strokes.custom_aabb.grow(0.001)
	for index in range(128):
		var center := path.curve.sample_baked(path._length * index / 127.0, true) + Vector3.UP * path.float_height
		check(bounds.has_point(center), "Shader-driven route must remain inside culling bounds")
	var original_length := path._length
	path.curve.set_point_position(2, Vector3(2,0,-7))
	await process_frame
	await process_frame
	check(path._length > original_length + 1.0, "Editing curve handles must rebuild the lookup")
	var strokes_id := path._strokes.get_instance_id()
	path.opacity = 0.27
	path.drift_speed = 0.0
	check(path._strokes.get_instance_id() == strokes_id and path._material.get_shader_parameter("opacity") == 0.27, "Appearance changes must preserve geometry")
	var packed := PackedScene.new()
	check(packed.pack(path) == OK, "Wisp route must save")
	var restored: DreamWispPath = packed.instantiate()
	root.add_child(restored)
	check(is_equal_approx(restored._length,path._length) and restored.opacity == path.opacity, "Curve and controls must survive saving")
	restored.free()
	path.wisp_count = 0
	path.rebuild()
	check(path._strokes == null, "Zero count must remove the render surface")
	path.wisp_count = 32
	path.rebuild()
	check(path._strokes.multimesh.instance_count == 32, "Maximum count must remain one batch")
	path.curve = Curve3D.new()
	await process_frame
	await process_frame
	check(path._strokes == null, "Empty routes must clear generated geometry")
	path.free()
	print("Wisp path checks: ", "PASS" if failures == 0 else "FAIL")
	quit(failures)
