extends SceneTree
var failures := 0
func _initialize() -> void:
	call_deferred("run")
func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)
func walk_to(actor: MemoryExplorer, target: Vector3) -> bool:
	for frame in range(600):
		var offset := Vector3(target.x - actor.position.x, 0, target.z - actor.position.z)
		if offset.length() < 0.1:
			return true
		await physics_frame
		actor.velocity = offset.normalized() * 2.1 + Vector3.DOWN
		actor.move_and_slide()
	push_error("Lighthouse traversal stopped at %s heading to %s" % [actor.position, target])
	return false
func run() -> void:
	var stage: Node3D = load("res://tests/scenes/lighthouse_test.tscn").instantiate()
	root.add_child(stage)
	current_scene = stage
	await process_frame
	await process_frame
	var tower: PainterlyLighthouse = stage.subject
	var actor: MemoryExplorer = stage.get_node("Explorer")
	actor.set_physics_process(false)
	var mesh: Mesh = tower._generated_root.get_node("PaintedProp").mesh
	var arrays := mesh.surface_get_arrays(0)
	var triangles: int = mesh.surface_get_array_index_len(0) / 3
	var valid := true
	for p: Vector3 in arrays[Mesh.ARRAY_VERTEX]:
		valid = valid and p.is_finite()
	for n: Vector3 in arrays[Mesh.ARRAY_NORMAL]:
		valid = valid and n.is_finite() and n.length_squared() > 0.1
	check(valid and triangles < 16000 and mesh.get_surface_count() == 1, "Lighthouse must have finite smooth geometry in a compact opaque batch")
	check(not tower.is_processing(), "Beacon animation must not need CPU frame callbacks")
	tower.rebuild()
	check(tower._generated_root.get_node("PaintedProp").mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX] == arrays[Mesh.ARRAY_VERTEX], "Lighthouse must regenerate deterministically")
	actor.position = tower.get_anchor(&"Approach").position
	actor.reset_physics_interpolation()
	check(await walk_to(actor, tower.get_anchor(&"Door").position), "Explorer must climb the entry steps to the closed door")
	check(actor.position.y > 0.26 and actor.is_on_floor(), "Entry plinth must support the explorer")
	check(await walk_to(actor, tower.get_anchor(&"Approach").position), "Explorer must descend the lighthouse steps")
	check(actor.position.y < 0.08, "Lighthouse approach must return to ground")
	actor.position = Vector3(0, 0.03, 3.5)
	actor.reset_physics_interpolation()
	for i in range(180):
		await physics_frame
		actor.velocity = Vector3(0, -1, -2.2)
		actor.move_and_slide()
	check(actor.position.z > tower.base_radius + 0.20, "The tower's closed exterior must block entry")
	check(tower.excludes_ground_point(Vector3.ZERO) and not tower.excludes_ground_point(Vector3(2, 0, 2)), "Ground exclusion must follow the round plinth and entry steps")
	var outline := PackedVector2Array()
	for p: Vector3 in tower.get_ground_outline():
		outline.append(Vector2(p.x, p.z))
	check(Geometry2D.is_point_in_polygon(Vector2(0, tower.base_radius * 1.36 + 0.4), outline), "Public ground outline must include the approach steps")
	var beam: MeshInstance3D = tower._generated_root.get_node("BeaconBeam")
	tower.beam_length = 14
	tower.rotation_speed = 0.05
	tower.beacon_strength = 0.8
	check(tower._generated_root.get_node("BeaconBeam") == beam and beam.custom_aabb.size.x > 28, "Beacon edits must retain geometry and update its rotating culling bounds")
	tower.recall_enabled = true
	var effect: Node = tower.get_recall_controller()
	effect.set_process(false)
	effect.seek(0.5)
	for name in ["PaintedProp", "LanternGlazing", "LanternGlow", "BeaconBeam"]:
		check(is_equal_approx(tower._generated_root.get_node(name).material_override.get_shader_parameter("assembly_progress"), 0.5), "Recall must include every lighthouse material")
	tower.rebuild()
	check(tower.get_recall_controller() == effect and is_equal_approx(effect.progress, 0.5), "Rebuilds must preserve lighthouse recall")
	tower.recall_enabled = false
	var packed := PackedScene.new()
	check(packed.pack(tower) == OK, "Lighthouse settings must pack as a reusable scene")
	var copy := packed.instantiate()
	check(copy.get_children().is_empty(), "Generated lighthouse geometry and physics must not serialize")
	copy.free()
	tower.gallery_enabled = false
	tower.beacon_enabled = false
	tower.rebuild()
	check(not tower._generated_root.has_node("BeaconBeam") and not tower._generated_root.has_node("LanternGlow"), "Beacon-off variants must remove the halo and beam")
	tower.collision_enabled = false
	tower.rebuild()
	check(not tower._generated_root.has_node("Collision"), "Distant scenic lighthouses must support collision-free placement")
	print("Lighthouse component checks: ", "PASS" if failures == 0 else "FAIL", " | opaque triangles: ", triangles)
	stage.free()
	await process_frame
	quit(failures)
