extends SceneTree
## Reusable shell variants, recall, groundcover and real explorer collision.
var failures := 0
const CABIN = preload("res://components/buildings/postcard_cabin/painterly_postcard_cabin.tscn")

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)

func run() -> void:
	var cabin: PainterlyPostcardCabin = CABIN.instantiate()
	root.add_child(cabin)
	var visual: MeshInstance3D = cabin._generated.get_node("Exterior")
	var arrays: Array = visual.mesh.surface_get_arrays(0)
	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	var triangles := indices.size() / 3
	check(visual.mesh.get_surface_count() == 1 and triangles < 6000, "Default cabin must remain a single economical opaque mesh")
	check(cabin.get_children().is_empty() and not cabin.is_processing(), "Generated geometry must be internal and require no CPU frame callback")
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	for vertex in vertices:
		check(vertex.is_finite(), "Cabin geometry must contain only finite coordinates")
	cabin.rebuild()
	check(cabin._generated.get_node("Exterior").mesh.surface_get_arrays(0)[Mesh.ARRAY_COLOR] == arrays[Mesh.ARRAY_COLOR], "Repeated generation must reproduce seeded siding pigment")
	cabin.cabin_seed += 1
	cabin.rebuild()
	check(cabin._generated.get_node("Exterior").mesh.surface_get_arrays(0)[Mesh.ARRAY_COLOR] != arrays[Mesh.ARRAY_COLOR], "Different seeds must vary siding color without altering its structural form")
	var generated := cabin._generated
	cabin.window_warmth = 0.3
	cabin.pigment_strength = 0.8
	check(cabin._generated == generated, "Window and pigment tuning must update uniforms without rebuilding geometry")
	check(cabin.excludes_ground_point(Vector3.ZERO) and cabin.excludes_ground_point(cabin.get_anchor(&"FrontDoor").position), "Cabin and entry steps must exclude grass")
	cabin.position = Vector3(4, 0, 2)
	cabin.rotation.y = 0.7
	check(cabin.excludes_ground_point(cabin.to_global(Vector3.ZERO)) and not cabin.excludes_ground_point(Vector3(-10, 0, -10)), "Groundcover exclusion must follow placement and rotation")
	cabin.position = Vector3.ZERO
	cabin.rotation = Vector3.ZERO
	cabin.recall_enabled = true
	var recall: Node = cabin.get_recall_controller()
	recall.set_process(false)
	recall.seek(0.35)
	cabin.rebuild()
	check(cabin.get_recall_controller() == recall and is_equal_approx(recall.progress, 0.35), "Cabin regeneration must preserve recall progress")
	check(cabin._generated.has_node("BuildingCollision/SolidExterior"), "Recall must preserve the closed shell collider")
	cabin.recall_enabled = false
	check(cabin._material.get_shader_parameter("assembly_progress") == 1.0, "Disabling recall must restore the whole cabin")
	# Approach the closed entry with the actual game explorer, then retreat.
	var ground := StaticBody3D.new()
	var collision := CollisionShape3D.new()
	collision.shape = WorldBoundaryShape3D.new()
	ground.add_child(collision)
	root.add_child(ground)
	var actor: MemoryExplorer = load("res://scenes/player/explorer.tscn").instantiate()
	actor.position = cabin.get_anchor(&"Approach").position + Vector3(0, 0.02, 0.3)
	root.add_child(actor)
	actor.set_physics_process(false)
	var rise := 0.0
	for frame in range(170):
		await physics_frame
		actor.velocity = Vector3(0, -2.0, -1.8)
		actor.move_and_slide()
		rise = maxf(rise, actor.position.y)
	check(rise > cabin.floor_height * 0.65, "Explorer must climb the cabin steps without snagging")
	check(actor.position.z >= cabin.footprint.y * 0.5 + 0.18, "The closed exterior must stop explorers entering through the door")
	for frame in range(110):
		await physics_frame
		actor.velocity = Vector3(0, -2.0, 1.8)
		actor.move_and_slide()
	check(actor.position.y < 0.08, "Explorer must descend the steps back to the ground")
	# Compact flat-roof variant and removed optional details must remain valid.
	cabin.footprint = Vector2(4.5, 2.4)
	cabin.roof_rise = 0
	cabin.steps_enabled = false
	cabin.wheels_enabled = false
	cabin.side_window_enabled = false
	cabin.porch_lamp_enabled = false
	cabin.rebuild()
	check(not cabin._generated.has_node("BuildingCollision/StairRamp"), "Removing steps must also remove their old collision")
	check(not cabin.excludes_ground_point(Vector3(cabin.door_offset * cabin.footprint.x, 0, cabin.footprint.y * 0.5 + 0.5)), "Removing steps must restore plantable ground in front")
	check(cabin._generated.get_node("Exterior").mesh.surface_get_arrays(0)[Mesh.ARRAY_INDEX].size() < indices.size(), "Optional details must be removed from the generated mesh")
	var packed := PackedScene.new()
	check(packed.pack(cabin) == OK, "Configured cabins must pack as reusable scenes")
	var restored: PainterlyPostcardCabin = packed.instantiate()
	root.add_child(restored)
	check(restored.footprint == Vector2(4.5, 2.4) and not restored.wheels_enabled and restored.get_children().is_empty(), "Saved scenes must retain settings without serializing generated nodes")
	cabin.collision_enabled = false
	cabin.rebuild()
	check(not cabin._generated.has_node("BuildingCollision"), "Scenery-only cabins must allow collision to be disabled")
	print("Postcard cabin checks: ", "PASS" if failures == 0 else "FAIL", " | default triangles: ", triangles)
	cabin.free()
	restored.free()
	actor.free()
	ground.free()
	await process_frame
	quit(failures)
