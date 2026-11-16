extends SceneTree
var failures := 0
func _initialize() -> void:
	call_deferred("run")
func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)
func mesh_ok(mesh: Mesh, budget: int) -> bool:
	if mesh.get_surface_count() != 1 or mesh.surface_get_array_index_len(0) / 3 > budget:
		return false
	var arrays := mesh.surface_get_arrays(0)
	for point: Vector3 in arrays[Mesh.ARRAY_VERTEX]:
		if not point.is_finite():
			return false
	for n: Vector3 in arrays[Mesh.ARRAY_NORMAL]:
		if not n.is_finite() or n.length_squared() < 0.1:
			return false
	return true
func walk_to(actor: MemoryExplorer, target: Vector3) -> bool:
	for frame in range(750):
		var delta := Vector3(target.x - actor.position.x, 0, target.z - actor.position.z)
		if delta.length() < 0.10:
			return true
		await physics_frame
		actor.velocity = delta.normalized() * 2.6 + Vector3.DOWN
		actor.move_and_slide()
	push_error("Walk stopped at %s while heading to %s" % [actor.position, target])
	return false
func run() -> void:
	var stage: Node3D = load("res://tests/scenes/sailing_test.tscn").instantiate()
	root.add_child(stage)
	current_scene = stage
	await process_frame
	await process_frame
	var dock: PainterlyWoodenDock = stage.subject.get_node("Dock")
	var boat: PainterlyEnsign = stage.subject.get_node("Ensign")
	var actor: MemoryExplorer = stage.get_node("Explorer")
	actor.set_physics_process(false)
	var budgets := {}
	for prop in [dock, boat]:
		check(not prop.is_processing(), "Sailing props must have no CPU animation callback")
		var original: Array = prop._generated_root.get_node("PaintedProp").mesh.surface_get_arrays(0)
		prop.rebuild()
		var again: Array = prop._generated_root.get_node("PaintedProp").mesh.surface_get_arrays(0)
		check(original[Mesh.ARRAY_VERTEX] == again[Mesh.ARRAY_VERTEX] and original[Mesh.ARRAY_COLOR] == again[Mesh.ARRAY_COLOR], "Sailing geometry must reproduce its seed")
		for child in prop._generated_root.get_children():
			if child is MeshInstance3D and child.name != "ContactShadow":
				check(mesh_ok(child.mesh, 18000), "%s/%s must have finite vertices, valid normals and compact opaque batches" % [prop.name, child.name])
				budgets[str(prop.name) + "/" + str(child.name)] = child.mesh.surface_get_array_index_len(0) / 3
		prop.recall_enabled = true
		var effect: Node = prop.get_recall_controller()
		effect.set_process(false)
		effect.seek(0.4)
		prop.rebuild()
		check(prop.get_recall_controller() == effect and is_equal_approx(effect.progress, 0.4), "Sailing rebuilds must preserve recall progress")
		prop.recall_enabled = false
		var packed := PackedScene.new()
		check(packed.pack(prop) == OK, "Sailing components must pack")
		var copy := packed.instantiate()
		check(copy.get_children().is_empty(), "Generated meshes and colliders must remain internal")
		copy.free()
	for layout in range(3):
		dock.layout = layout
		dock.rebuild()
		check(mesh_ok(dock._generated_root.get_node("PaintedProp").mesh, 18000), "Each dock layout must generate a compact valid mesh")
		actor.position = dock.get_anchor(&"Approach").global_position
		actor.reset_physics_interpolation()
		check(await walk_to(actor, Vector3(0, 0, 0)), "Explorer must climb the dock ramp")
		check(actor.position.y > dock.deck_height - 0.03 and actor.is_on_floor(), "Dock must support the explorer above the waterline")
		var end := dock.get_anchor(&"DeckEnd").global_position
		check(await walk_to(actor, Vector3(0, 0, end.z)), "Main pier must reach the landing without snagging")
		check(await walk_to(actor, end), "Both T and L landing connections must be walkable")
		check(dock.excludes_ground_point(end), "Dock must exclude planting on its deck")
		check(await walk_to(actor, Vector3(0, 0, end.z)), "Explorer must return from the landing")
		check(await walk_to(actor, dock.get_anchor(&"Approach").global_position), "Explorer must descend to shore")
		check(actor.position.y < 0.08, "Shore approach must return to ground level")
	dock.rail_sides = 3
	dock.rebuild()
	check(dock._generated_root.get_node("Collision").get_child_count() > 5, "Optional rails must include collision")
	var mesh: Mesh = boat._generated_root.get_node("Sails").mesh
	boat.wind_strength = 0.06
	boat.bob_amount = 0.04
	check(boat._generated_root.get_node("Sails").mesh == mesh, "Motion edits must not regenerate boat meshes")
	boat.recall_enabled = true
	var recall: Node = boat.get_recall_controller()
	recall.set_process(false)
	recall.seek(0.5)
	for name in ["PaintedProp", "Rigging", "Sails"]:
		check(is_equal_approx(boat._generated_root.get_node(name).material_override.get_shader_parameter("assembly_progress"), 0.5), "Hull, rig and cloth must share the recall reveal")
	boat.recall_enabled = false
	boat.sails_enabled = false
	boat.fenders_enabled = false
	boat.rebuild()
	check(not boat._generated_root.has_node("Sails"), "Bare-rig option must remove the sail mesh")
	for prop in [dock, boat]:
		prop.collision_enabled = false
		prop.rebuild()
		check(not prop._generated_root.has_node("Collision"), "Decorative instances must support disabling collision")
	print("Sailing component checks: ", "PASS" if failures == 0 else "FAIL", " | triangles: ", budgets)
	stage.free()
	await process_frame
	quit(failures)
