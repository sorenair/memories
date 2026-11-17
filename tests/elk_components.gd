extends SceneTree
const BUILDER = preload("res://components/animals/elk/elk_geometry.gd")
var failures := 0
func _initialize() -> void:
	call_deferred("run")
func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)
func run() -> void:
	var stage: Node3D = load("res://tests/scenes/elk_test.tscn").instantiate()
	root.add_child(stage)
	current_scene = stage
	await process_frame
	await process_frame
	var bull: PainterlyElk = stage.subject.get_node("Bull")
	var herd: PainterlyElkHerd = stage.subject.get_node("Herd")
	var actor: MemoryExplorer = stage.get_node("Explorer")
	actor.set_physics_process(false)
	stage.get_node("Partner").set_physics_process(false)
	var budgets := {}
	var heights: Array[float] = []
	var original: PackedVector3Array
	for type in range(4):
		var c := bull._config()
		c.elk_type = type
		var data: Dictionary = BUILDER.new().elk(c)
		var mesh: Mesh = data.mesh
		var arrays := mesh.surface_get_arrays(0)
		var valid := true
		for p: Vector3 in arrays[Mesh.ARRAY_VERTEX]: valid = valid and p.is_finite()
		for n: Vector3 in arrays[Mesh.ARRAY_NORMAL]: valid = valid and n.is_finite() and n.length_squared() > 0.9
		var triangles: int = mesh.surface_get_array_index_len(0)/3
		budgets[type] = triangles
		heights.append(mesh.get_aabb().size.y)
		check(valid and mesh.get_surface_count() == 1 and triangles < 14000,"Elk must use finite smooth geometry in one bounded opaque batch")
		check(data.bounds.encloses(mesh.get_aabb()),"Motion bounds must contain the entire rest mesh")
		var again: Dictionary = BUILDER.new().elk(c)
		check(again.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX] == arrays[Mesh.ARRAY_VERTEX],"Same seed and type must rebuild identical elk")
		if type == 0: original = arrays[Mesh.ARRAY_VERTEX]
	check(heights[0] > heights[3] and heights[3] > heights[1] and heights[1] > heights[2],"Bull, young bull, cow and calf must have distinct silhouettes")
	var c := bull._config()
	c.prop_seed += 1
	check(BUILDER.new().elk(c).mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX] != original,"Seed must vary anatomy, stance and antlers")
	c.antler_size = 1.5
	c.antler_spread = 1.6
	var large: Dictionary = BUILDER.new().elk(c)
	check(large.bounds.encloses(large.mesh.get_aabb()),"Largest antlers must remain inside the culling bounds")
	var mesh: Mesh = bull._generated_root.get_node("PaintedProp").mesh
	bull.idle_motion = 0.5
	bull.idle_speed = 0.8
	bull.idle_pose = 2
	bull.seek_time(4.0)
	check(bull._generated_root.get_node("PaintedProp").mesh == mesh and not bull.is_processing() and not bull.is_physics_processing(),"Shader idles must retain geometry and require no CPU callbacks")
	check(bull._generated_root.get_node("Collision").get_child_count() == 1,"Single elk must have one torso collider, without antler collision")
	check(herd.generated_count == herd.count,"Study herd must fit its requested count")
	var variants := {}
	var poses := {}
	var phases := {}
	var before := herd.placements.duplicate(true)
	for i in range(herd.generated_count):
		var a: Dictionary = herd.placements[i]
		variants[a.variant] = true
		poses[a.custom.g] = true
		phases[a.custom.r] = true
		for j in range(i):
			check(a.transform.origin.distance_to(herd.placements[j].transform.origin) >= herd.minimum_spacing*herd.elk_size-0.001,"Herd placement must respect minimum spacing")
	check(variants.size() >= 4 and poses.size() >= 2 and phases.size() == herd.generated_count,"Study herd must vary silhouettes, idle poses and phases")
	check(herd._generated_root.get_node("Collision").get_child_count() == herd.generated_count,"Each herd member must have a torso collider")
	var opaque_draws := 0
	for visual in herd._generated_root.get_children():
		if visual is MultiMeshInstance3D and not str(visual.name).begins_with("Contact_"):
			opaque_draws += 1
			check(visual.multimesh.use_custom_data and visual.material_override == herd._material,"Herd batches must share one material with custom idle data")
	check(opaque_draws <= 6 and not herd.is_processing(),"Herd must use at most six opaque batches and no CPU animation")
	herd.rebuild()
	check(herd.placements == before,"Herd placements and individual variations must regenerate deterministically")
	for prop in [bull,herd]:
		prop.recall_enabled = true
		var effect: Node = prop.get_recall_controller()
		effect.set_process(false)
		effect.seek(0.5)
		prop.rebuild()
		check(effect == prop.get_recall_controller() and is_equal_approx(effect.progress,0.5),"Elk rebuild must preserve recall progress")
		check(is_equal_approx(prop._material.get_shader_parameter("assembly_progress"),0.5),"All elk paint must participate in shared recall")
		prop.recall_enabled = false
		var packed := PackedScene.new()
		check(packed.pack(prop) == OK,"Elk settings must pack")
		var copy := packed.instantiate()
		check(copy.get_children().is_empty(),"Generated animal meshes and physics must remain internal")
		copy.free()
	# Test actual explorer collision from the single elk's authored approach point.
	actor.position = bull.get_anchor(&"Approach").global_position+Vector3.UP*0.03
	actor.reset_physics_interpolation()
	for i in range(110):
		await physics_frame
		actor.velocity = bull.global_basis*Vector3(0,0,-2.5)+Vector3.DOWN
		actor.move_and_slide()
	check(bull.to_local(actor.global_position).z > 0.95,"Elk torso must block an approaching explorer")
	# Extreme crowding is bounded; do not overlap animals to force the requested count.
	herd.count = 48
	herd.footprint = Vector2(2,2)
	herd.rebuild()
	check(herd.generated_count < herd.count and not herd._get_configuration_warnings().is_empty(),"Overfull footprints must report a limited count")
	for prop in [bull,herd]:
		prop.collision_enabled = false
		prop.rebuild()
		check(not prop._generated_root.has_node("Collision"),"Decorative elk must support collision off")
	print("Elk component checks: ","PASS" if failures == 0 else "FAIL"," | triangles by type: ",budgets," | study opaque draws: ",opaque_draws)
	stage.free()
	await process_frame
	quit(failures)
