extends SceneTree
var failures := 0
var climbed := 0.0
func _initialize() -> void:
	call_deferred("run")
func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)
func walk_to(actor: MemoryExplorer, target: Vector3) -> bool:
	for frame in range(900):
		var offset := Vector3(target.x - actor.position.x, 0, target.z - actor.position.z)
		if offset.length() < 0.1:
			return true
		await physics_frame
		actor.velocity = offset.normalized() * 2.8 + Vector3.DOWN
		actor.move_and_slide()
		climbed = maxf(climbed, actor.position.y)
	push_error("Sand traversal stopped at %s heading to %s" % [actor.position, target])
	return false
func run() -> void:
	var stage: Node3D = load("res://tests/scenes/sand_test.tscn").instantiate()
	root.add_child(stage)
	current_scene = stage
	await process_frame
	await process_frame
	var patch: PainterlySandPatch = stage.subject.get_node("WindDunes")
	var actor: MemoryExplorer = stage.get_node("Explorer")
	actor.set_physics_process(false)
	var mesh: Mesh = patch.get_node("SandSurface").mesh
	var faces := mesh.get_faces()
	var valid := true
	for i in range(0, faces.size(), 3):
		valid = valid and faces[i].is_finite() and (faces[i+1] - faces[i]).cross(faces[i+2] - faces[i]).y > 0.000000001
	check(valid and faces.size() / 3 < 16000, "Sand must have finite noncollapsed upward geometry within budget")
	check(patch.get_node("SandCollision").get_child(0).shape.get_faces() == faces, "Dune collision must match the rendered base terrain")
	var min_height := INF
	var max_height := 0.0
	for p: Vector3 in mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]:
		min_height = minf(min_height, p.y)
		max_height = maxf(max_height, p.y)
	check(max_height - min_height > 0.8, "Default dunes must have real meter-scale relief")
	check(patch.get_children().is_empty(), "Generated sand geometry, collision and fields must remain internal")
	patch.rebuild()
	check(patch.get_node("SandSurface").mesh.get_faces() == faces, "Dunes must regenerate deterministically")
	await physics_frame
	var hit := stage.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(-2, 5, 0), Vector3(-2, -1, 0)))
	check(not hit.is_empty() and hit.collider == patch.get_node("SandCollision") and absf(hit.position.y - patch.get_surface_height(Vector3(-2, 0, 0))) < 0.04, "Surface sampling must agree with actual physics height")
	actor.position = Vector3(-2, 0.03, 6.8)
	actor.reset_physics_interpolation()
	check(await walk_to(actor, Vector3(-2, 0, -4.8)), "Explorer must climb across dune shoulders and descend")
	check(climbed > 0.65 and actor.is_on_floor(), "Explorer must actually stand on raised dunes")
	check(patch._stamp_count > 8, "Walking the dunes must create automatic footsteps at changing heights")
	var stamps := patch._stamp_count
	for i in range(10):
		await physics_frame
	check(patch._stamp_count == stamps, "Standing on a slope must not emit extra footsteps")
	var point := Vector3(0, 0, 0)
	point.y = patch.get_surface_height(point)
	check(patch.stamp_footprint(point, Vector3.FORWARD), "Explicit stamps must accept the actual sand height")
	check(not patch.stamp_footprint(point + Vector3.UP, Vector3.FORWARD), "Airborne stamps must be rejected")
	var visual := patch.get_node("SandSurface")
	patch.sand_color = Color("e7cca3")
	patch.footprint_linger = 20
	check(patch.get_node("SandSurface") == visual and patch._stamp_count == stamps + 1, "Paint and lifetime edits must preserve geometry and trail history")
	patch.recall_enabled = true
	var recall: Node = patch.get_recall_controller()
	recall.set_process(false)
	recall.seek(0.4)
	patch.rebuild()
	check(patch.get_recall_controller() == recall and is_equal_approx(recall.progress, 0.4) and patch.has_node("SandCollision"), "Rebuilds must preserve recall and keep terrain support present")
	patch.recall_enabled = false
	var packed := PackedScene.new()
	check(packed.pack(patch) == OK, "Sand settings must save as reusable scenes")
	var copy: PainterlySandPatch = packed.instantiate()
	root.add_child(copy)
	check(copy._stamp_count == 0 and copy.footprint_linger == 20 and copy.dune_height == patch.dune_height, "Sand saves settings without runtime trails")
	copy.free()
	# A transformed, off-center concave outline exercises inherited coverage/UVs.
	var custom: PainterlySandPatch = load("res://components/groundcover/sand/painterly_sand_patch.tscn").instantiate()
	custom.track_footprints = false
	custom.patch_size = Vector2(8, 8)
	custom.mesh_detail = 48
	custom.position = Vector3(30, 1.0, 0)
	custom.rotation.y = 0.35
	var outline := Curve2D.new()
	for p in [Vector2(2,-3), Vector2(8,-3), Vector2(8,0), Vector2(5,0), Vector2(5,5), Vector2(2,5)]:
		outline.add_point(p)
	custom.custom_outline = outline
	root.add_child(custom)
	var area := 0.0
	var custom_faces: PackedVector3Array = custom.get_node("SandSurface").mesh.get_faces()
	for i in range(0, custom_faces.size(), 3):
		area += (custom_faces[i+1] - custom_faces[i]).cross(custom_faces[i+2] - custom_faces[i]).y * 0.5
	check(absf(area - 33) < 0.01, "Custom dunes must retain the exact concave outline without bridging gaps")
	var inside := custom.to_global(Vector3(3, 0, 3))
	inside.y = custom.get_surface_height(inside)
	check(custom.stamp_footprint(inside, custom.global_basis * Vector3.FORWARD) and not custom.excludes_ground_point(custom.to_global(Vector3(7, 0, 3))), "Rotated custom dunes must stamp inside their arms and reject the cutout")
	# Native water outlines must carve both mesh and collision, not only the shader.
	var pond: PainterlyWater = load("res://components/scenery/water/painterly_water.tscn").instantiate()
	pond.name = "TestPond"
	pond.position = Vector3(30, 1, 0)
	pond.footprint = Vector2(3, 3)
	pond.block_water_entry = false
	root.add_child(pond)
	var cut: PainterlySandPatch = load("res://components/groundcover/sand/painterly_sand_patch.tscn").instantiate()
	cut.name = "CutSand"
	cut.position = pond.position
	cut.patch_size = Vector2(9, 9)
	cut.mesh_detail = 48
	cut.track_footprints = false
	cut.ground_exclusions = [NodePath("../TestPond")]
	root.add_child(cut)
	check(not cut.excludes_ground_point(pond.position) and not cut.stamp_footprint(pond.position, Vector3.FORWARD), "Pond cutouts must reject planting coverage and footsteps")
	for p: Vector3 in cut.get_node("SandSurface").mesh.get_faces():
		check(Vector2(p.x, p.z).length() > 1.0, "Pond cutout must be removed from physical terrain geometry")
	cut.terrain_form = 1
	cut.rebuild()
	check(cut.get_node("SandSurface").mesh.get_faces() != faces, "Rolling hills must offer a distinct terrain form")
	cut.collision_enabled = false
	cut.rebuild()
	check(not cut.has_node("SandCollision"), "Decorative sand must allow collision to be disabled")
	pond.footprint = Vector2(14, 14)
	pond.rebuild()
	cut.rebuild()
	check(not cut.has_node("SandSurface") and not cut.has_node("SandCollision"), "Fully excluded sand must become an empty valid surface")
	var groups := []
	for property in patch.get_property_list():
		if property.usage & PROPERTY_USAGE_GROUP:
			groups.append(property.name)
	print("Sand component checks: ", "PASS" if failures == 0 else "FAIL", " | triangles: ", faces.size() / 3, " | climbed: ", climbed, " | groups: ", groups)
	cut.free()
	pond.free()
	custom.free()
	stage.free()
	await process_frame
	quit(failures)
