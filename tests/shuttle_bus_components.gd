extends SceneTree
var failures := 0
func _initialize() -> void:
	call_deferred("run")
func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)
func run() -> void:
	var stage: Node3D = load("res://tests/scenes/shuttle_bus_test.tscn").instantiate()
	root.add_child(stage)
	current_scene = stage
	await process_frame
	await process_frame
	var bus: PainterlyShuttleBus = stage.subject
	var actor: MemoryExplorer = stage.get_node("Explorer")
	actor.set_physics_process(false)
	stage.get_node("Partner").set_physics_process(false)
	var budgets := {}
	for bays in range(4,8):
		bus.passenger_bays = bays
		bus.rebuild()
		var mesh: Mesh = bus._generated_root.get_node("PaintedProp").mesh
		var a := mesh.surface_get_arrays(0)
		var valid := true
		for p: Vector3 in a[Mesh.ARRAY_VERTEX]: valid = valid and p.is_finite()
		for n: Vector3 in a[Mesh.ARRAY_NORMAL]: valid = valid and n.is_finite() and n.length_squared()>0.9
		var triangles: int = mesh.surface_get_array_index_len(0)/3
		budgets[bays] = triangles
		check(valid and mesh.get_surface_count()==1 and triangles<18000,"All bus lengths must use finite compact geometry in one opaque batch")
		bus.rebuild()
		check(bus._generated_root.get_node("PaintedProp").mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]==a[Mesh.ARRAY_VERTEX],"Bus geometry must rebuild deterministically")
		check(bus._generated_root.get_node("Collision").get_child_count()==1 and bus.excludes_ground_point(bus.global_position),"Bus must provide exterior collision and groundcover exclusion")
	bus.passenger_bays = 5
	bus.rebuild()
	var mesh: Mesh = bus._generated_root.get_node("PaintedProp").mesh
	bus.headlights_enabled = true
	check(bus._generated_root.get_node("PaintedProp").mesh==mesh and not bus.is_processing(),"Bus headlight edits must retain static geometry")
	check(bus._material.get_shader_parameter("light_strength")>0,"Headlight toggle must set the existing vehicle lens shader")
	var bounds := mesh.get_aabb()
	var door: Vector3 = bus.get_anchor(&"Door").position
	var shape: BoxShape3D = bus._generated_root.get_node("Collision").get_child(0).shape
	var size := shape.size
	bus.vehicle_scale = 1.4
	bus.rebuild()
	check(bus._generated_root.get_node("PaintedProp").mesh.get_aabb().size.is_equal_approx(bounds.size*1.4),"Scale must include wheels, roof pod and all body panels")
	check(bus.get_anchor(&"Door").position.is_equal_approx(door*1.4) and bus._generated_root.get_node("Collision").get_child(0).shape.size.is_equal_approx(size*1.4),"Scale must include boarding anchors and exterior collision")
	bus.vehicle_scale = 1.0
	bus.recall_enabled = true
	bus.rebuild()
	var effect: Node = bus.get_recall_controller()
	effect.set_process(false)
	effect.seek(0.5)
	bus.rebuild()
	check(effect==bus.get_recall_controller() and is_equal_approx(effect.progress,0.5) and is_equal_approx(bus._material.get_shader_parameter("assembly_progress"),0.5),"Bus must preserve shared recall progress across rebuilds")
	bus.recall_enabled = false
	actor.position = bus.get_anchor(&"Boarding").global_position+Vector3.UP*0.03
	actor.reset_physics_interpolation()
	for i in range(100):
		await physics_frame
		actor.velocity = Vector3(-2.4,-1,0)
		actor.move_and_slide()
	check(bus.to_local(actor.global_position).x>1.30,"Closed shuttle entry must block an approaching explorer")
	bus.roof_pod_enabled = false
	bus.mountain_graphic_enabled = false
	bus.destination_text = ""
	bus.rebuild()
	check(bus._generated_root.get_node("PaintedProp").mesh.get_aabb().size.y<bounds.size.y,"Roof pod toggle must remove the raised equipment")
	bus.destination_text = "A VERY LONG DESTINATION FOR THIS TRAIL"
	check(bus.destination_text.length()==24,"Destination text must be bounded to the sign width")
	bus.collision_enabled = false
	bus.rebuild()
	check(not bus._generated_root.has_node("Collision"),"Distant buses must support collision off")
	var packed := PackedScene.new()
	check(packed.pack(bus)==OK,"Shuttle export settings must pack")
	var copy := packed.instantiate()
	check(copy.get_children().is_empty(),"Generated bus geometry and physics must remain internal")
	copy.free()
	print("Shuttle bus component checks: ","PASS" if failures==0 else "FAIL"," | triangles by window bays: ",budgets)
	stage.free()
	await process_frame
	quit(failures)
