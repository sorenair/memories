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
		var offset := Vector3(target.x-actor.position.x,0,target.z-actor.position.z)
		if offset.length()<0.12:
			return true
		await physics_frame
		actor.velocity=offset.normalized()*2.4+Vector3.DOWN
		actor.move_and_slide()
	return false
func run() -> void:
	var stage: Node3D=load("res://tests/scenes/backpacking_test.tscn").instantiate()
	root.add_child(stage)
	current_scene=stage
	await process_frame
	await process_frame
	var car: PainterlyFourRunner=stage.subject.get_node("FourRunner")
	var tent: PainterlyStormbreakTent=stage.subject.get_node("Tent")
	var stove: PainterlyBackpackingStove=stage.subject.get_node("Stove")
	var actor: MemoryExplorer=stage.get_node("Explorer")
	actor.set_physics_process(false)
	var budgets := {}
	for prop in [car,tent,stove]:
		var mesh: Mesh=prop._generated_root.get_node("PaintedProp").mesh
		var arrays:=mesh.surface_get_arrays(0)
		var valid:=true
		for p: Vector3 in arrays[Mesh.ARRAY_VERTEX]:
			valid=valid and p.is_finite()
		for n: Vector3 in arrays[Mesh.ARRAY_NORMAL]:
			valid=valid and n.is_finite() and n.length_squared()>0.1
		var triangles: int=mesh.surface_get_array_index_len(0)/3
		budgets[prop.name]=triangles
		check(valid and mesh.get_surface_count()==1 and triangles<24000,"Each backpacking prop must use finite smooth geometry in one compact opaque batch")
		check(not prop.is_processing(),"Backpacking props must not require CPU animation callbacks")
		prop.rebuild()
		var again: Array=prop._generated_root.get_node("PaintedProp").mesh.surface_get_arrays(0)
		check(again[Mesh.ARRAY_VERTEX]==arrays[Mesh.ARRAY_VERTEX] and again[Mesh.ARRAY_COLOR]==arrays[Mesh.ARRAY_COLOR],"Backpacking geometry must regenerate deterministically")
		check(prop.excludes_ground_point(prop.global_position),"Each prop must support grass exclusions")
		prop.recall_enabled=true
		var effect: Node=prop.get_recall_controller()
		effect.set_process(false)
		effect.seek(0.5)
		prop.rebuild()
		check(prop.get_recall_controller()==effect and is_equal_approx(effect.progress,0.5),"Rebuild must preserve backpacking recall progress")
		if prop==stove:
			check(is_equal_approx(stove._steam_material.get_shader_parameter("assembly_progress"),0.5),"Stove steam must share the assembled recall")
		prop.recall_enabled=false
		var packed:=PackedScene.new()
		check(packed.pack(prop)==OK,"Backpacking prop settings must pack")
		var copy:=packed.instantiate()
		check(copy.get_children().is_empty(),"Generated camping meshes and physics must not serialize")
		copy.free()
	actor.position=Vector3(0,0.03,3.8)
	actor.reset_physics_interpolation()
	check(await walk_to(actor,Vector3(0,0,-3.7)),"The camping study must retain an open walking approach between car and tent")
	actor.position=car.get_anchor(&"Front").global_position+Vector3.UP*0.03
	actor.reset_physics_interpolation()
	for i in range(120):
		await physics_frame
		actor.velocity=car.global_basis*Vector3(0,0,-2.5)+Vector3.DOWN
		actor.move_and_slide()
	check(car.to_local(actor.global_position).z>2.5,"The parked vehicle must block players at its exterior")
	actor.position=tent.get_anchor(&"Approach").global_position+Vector3.UP*0.03
	actor.reset_physics_interpolation()
	for i in range(90):
		await physics_frame
		actor.velocity=tent.global_basis*Vector3(0,0,-2.5)+Vector3.DOWN
		actor.move_and_slide()
	check(tent.to_local(actor.global_position).z>0.8 or actor.position.y>0.7,"The closed tent must not admit players through its fly at ground level")
	var cloth: Mesh=tent._generated_root.get_node("PaintedProp").mesh
	tent.wind_strength=0.02
	check(tent._generated_root.get_node("PaintedProp").mesh==cloth,"Wind edits must retain the tent mesh")
	var original: Mesh=stove._generated_root.get_node("PaintedProp").mesh
	stove.burner_on=false
	stove.steam_strength=0.2
	check(stove._generated_root.get_node("PaintedProp").mesh==original and stove._steam_material.get_shader_parameter("steam_strength")==0.0,"Switching cooking off must preserve geometry and stop steam")
	var size: Vector3=original.get_aabb().size
	stove.gear_scale=1.5
	stove.rebuild()
	check(stove._generated_root.get_node("PaintedProp").mesh.get_aabb().size.is_equal_approx(size*1.5),"Stove scale must apply consistently to bottle, pot, hose and legs")
	stove.pot_enabled=false
	stove.rebuild()
	check(not stove._generated_root.has_node("CookingSteam") and stove._generated_root.get_node("PaintedProp").mesh.get_aabb().size.y<size.y*1.5,"Bare stove mode must remove pot and steam")
	tent.guy_lines_enabled=false
	tent.brand_mark_enabled=false
	tent.rebuild()
	car.roof_rack_enabled=false
	car.rebuild()
	for prop in [car,tent,stove]:
		prop.collision_enabled=false
		prop.rebuild()
		check(not prop._generated_root.has_node("Collision"),"Decorative camping props must support disabling collision")
	print("Backpacking component checks: ","PASS" if failures==0 else "FAIL"," | opaque triangles: ",budgets)
	stage.free()
	await process_frame
	quit(failures)
