extends SceneTree
var failures := 0
func _initialize() -> void:
	call_deferred("run")
func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)
func run() -> void:
	var stage: Node3D = load("res://tests/scenes/mountain_goat_test.tscn").instantiate()
	root.add_child(stage)
	current_scene = stage
	await process_frame
	await process_frame
	var goat: PainterlyMountainGoat = stage.subject.get_node("Goat")
	var actor: MemoryExplorer = stage.get_node("Explorer")
	actor.set_physics_process(false)
	stage.get_node("Partner").set_physics_process(false)
	var mesh: Mesh = goat._generated_root.get_node("PaintedProp").mesh
	var arrays := mesh.surface_get_arrays(0)
	var valid := true
	for p: Vector3 in arrays[Mesh.ARRAY_VERTEX]: valid = valid and p.is_finite()
	for n: Vector3 in arrays[Mesh.ARRAY_NORMAL]: valid = valid and n.is_finite() and n.length_squared()>0.9
	var triangles: int = mesh.surface_get_array_index_len(0)/3
	check(valid and mesh.get_surface_count()==1 and triangles<16000,"Goat must use finite smooth geometry in one compact painted mesh")
	check(goat._goat_data.bounds.encloses(mesh.get_aabb()),"Goat motion bounds must include its rest silhouette")
	goat.rebuild()
	check(goat._generated_root.get_node("PaintedProp").mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]==arrays[Mesh.ARRAY_VERTEX],"Same seed must rebuild identical goat anatomy")
	mesh = goat._generated_root.get_node("PaintedProp").mesh
	goat.idle_pose = 2
	goat.idle_motion = 0.4
	goat.idle_speed = 0.8
	goat.seek_time(4.2)
	check(goat._generated_root.get_node("PaintedProp").mesh==mesh and not goat.is_processing() and not goat.is_physics_processing(),"Goat idles must not rebuild geometry or require CPU callbacks")
	# Runtime changes preserve recall/collision, as with the other scenic components.
	goat.recall_enabled = true
	var effect: Node = goat.get_recall_controller()
	effect.set_process(false)
	effect.seek(0.5)
	goat.rebuild()
	check(effect==goat.get_recall_controller() and is_equal_approx(effect.progress,0.5),"Goat rebuild must preserve recall progress")
	check(is_equal_approx(goat._material.get_shader_parameter("assembly_progress"),0.5),"Goat paint must participate in assembled recall")
	check(goat._generated_root.get_node("Collision").get_child_count()==1,"Goat must retain a coarse torso collider during recall")
	goat.recall_enabled = false
	actor.position = goat.get_anchor(&"Approach").global_position+Vector3.UP*0.03
	actor.reset_physics_interpolation()
	for i in range(90):
		await physics_frame
		actor.velocity = goat.global_basis*Vector3(0,0,-2.5)+Vector3.DOWN
		actor.move_and_slide()
	check(goat.to_local(actor.global_position).z>0.70*goat._goat_data.morph.z,"Goat torso must block an approaching explorer")
	var old_bounds := mesh.get_aabb()
	goat.goat_size = 1.5
	goat.rebuild()
	check(goat._generated_root.get_node("PaintedProp").mesh.get_aabb().size.is_equal_approx(old_bounds.size*1.5),"Goat size must scale all anatomy consistently")
	goat.fluffiness = 1
	goat.horn_length = 1.4
	goat.rebuild()
	check(goat._goat_data.bounds.encloses(goat._generated_root.get_node("PaintedProp").mesh.get_aabb()),"Largest horns and fluff must remain inside the culling bounds")
	goat.fluffiness = 0
	goat.rebuild()
	check(goat._generated_root.get_node("PaintedProp").mesh.surface_get_array_index_len(0)/3<triangles,"Low fluff must remove the optional shaggy coat locks")
	goat.collision_enabled = false
	goat.rebuild()
	check(not goat._generated_root.has_node("Collision"),"Decorative goats must support collision off")
	var packed := PackedScene.new()
	check(packed.pack(goat)==OK,"Goat export settings must pack")
	var copy: PainterlyMountainGoat = packed.instantiate()
	check(copy.get_children().is_empty() and is_equal_approx(copy.goat_size,1.5),"Only authored settings must serialize, with no generated meshes or physics")
	copy.free()
	print("Mountain goat component checks: ","PASS" if failures==0 else "FAIL"," | opaque triangles: ",triangles)
	stage.free()
	await process_frame
	quit(failures)
