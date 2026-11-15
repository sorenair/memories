extends SceneTree
var failures := 0
func _initialize() -> void:
	call_deferred("run")
func check(value: bool,message: String) -> void:
	if not value:
		failures+=1
		push_error(message)
func walk_to(actor: MemoryExplorer,target: Vector3) -> bool:
	for frame in range(600):
		var offset := Vector3(target.x-actor.global_position.x,0,target.z-actor.global_position.z)
		if offset.length()<0.11:
			return true
		await physics_frame
		actor.velocity=offset.normalized()*2.3+Vector3.DOWN*1.0
		actor.move_and_slide()
	push_error("Traversal stopped at %s heading to %s"%[actor.global_position,target])
	return false
func run() -> void:
	var study: Node3D=load("res://tests/scenes/tokyo_temples_test.tscn").instantiate()
	root.add_child(study)
	current_scene=study
	await process_frame
	await process_frame
	var setup: Node3D=study.subject
	var actor: MemoryExplorer=study.get_node("Explorer")
	actor.set_physics_process(false)
	var budgets := {}
	for name in ["MeijiHall","MeijiTorii","SensoHall","HozomonGate","Pagoda"]:
		var prop: PainterlyTokyoPiece=setup.get_node(name)
		var mesh: Mesh=prop._generated_root.get_node("PaintedProp").mesh
		var arrays := mesh.surface_get_arrays(0)
		var finite := true
		for p: Vector3 in arrays[Mesh.ARRAY_VERTEX]:
			finite=finite and p.is_finite()
		for n: Vector3 in arrays[Mesh.ARRAY_NORMAL]:
			finite=finite and n.is_finite() and n.length_squared()>0.1
		var triangles: int=mesh.surface_get_array_index_len(0)/3
		budgets[name]=triangles
		check(finite and triangles<24000,"Each temple prop must remain a finite compact opaque mesh with valid normals")
		check(mesh.get_surface_count()==1 and not prop.is_processing(),"Static temple exteriors must use one opaque surface and no CPU update callback")
		prop.rebuild()
		var again: Array=prop._generated_root.get_node("PaintedProp").mesh.surface_get_arrays(0)
		check(again[Mesh.ARRAY_VERTEX]==arrays[Mesh.ARRAY_VERTEX] and again[Mesh.ARRAY_COLOR]==arrays[Mesh.ARRAY_COLOR],"Temple geometry and paint must reproduce their seed")
		prop.recall_enabled=true
		var effect: Node=prop.get_recall_controller()
		effect.set_process(false)
		effect.seek(0.45)
		prop.rebuild()
		check(prop.get_recall_controller()==effect and is_equal_approx(effect.progress,0.45),"Temple rebuilds must preserve recall progress")
		prop.recall_enabled=false
		var packed := PackedScene.new()
		check(packed.pack(prop)==OK,"Tokyo scenery must pack as reusable authoring parameters")
		var copy := packed.instantiate()
		check(copy.get_children().is_empty(),"Generated Tokyo geometry must not serialize")
		copy.free()
	var torii: PainterlyTorii=setup.get_node("MeijiTorii")
	check(not torii.excludes_ground_point(torii.global_position),"Torii exclusions must leave their passage open")
	actor.global_position=torii.to_global(Vector3(0,0.03,2))
	actor.reset_physics_interpolation()
	check(await walk_to(actor,torii.to_global(Vector3(0,0,-1.5))),"Explorer must walk underneath the wooden torii")
	var gate: PainterlySensoGate=setup.get_node("HozomonGate")
	actor.global_position=gate.to_global(Vector3(0,0.03,2.5))
	actor.reset_physics_interpolation()
	check(await walk_to(actor,gate.to_global(Vector3(0,0,-1.7))),"Explorer must fit the center passage below the red lantern")
	for name in ["MeijiHall","SensoHall"]:
		var hall: PainterlyJapaneseHall=setup.get_node(name)
		actor.global_position=hall.get_anchor(&"Approach").global_position+Vector3.UP*0.03
		actor.reset_physics_interpolation()
		check(await walk_to(actor,hall.get_anchor(&"PrayerFront").global_position),"Worship hall steps must lead onto the veranda")
		check(actor.global_position.y>0.40,"Hall veranda must support the real explorer")
		check(await walk_to(actor,hall.get_anchor(&"Approach").global_position),"Explorer must descend the worship hall steps")
		check(actor.global_position.y<0.08,"Hall approach must return to ground level")
	study.free()
	await process_frame
	study=load("res://tests/scenes/tokyo_city_test.tscn").instantiate()
	root.add_child(study)
	current_scene=study
	await process_frame
	await process_frame
	setup=study.subject
	actor=study.get_node("Explorer")
	actor.set_physics_process(false)
	var tower: PainterlyCityTower=setup.get_node("BackLeftTower")
	check(tower._display_material.shader==tower.DISPLAY and not tower.is_processing(),"City screens must reuse the existing GPU-only concert display")
	for profile in range(3):
		tower.profile=profile
		tower.rebuild()
		var visual: Mesh=tower._generated_root.get_node("PaintedProp").mesh
		check(visual.get_surface_count()==1 and visual.surface_get_array_index_len(0)/3<24000,"All modular tower forms must stay batched and compact")
	var screen: MeshInstance3D=tower._generated_root.get_node("Billboard")
	tower.screen_speed=0
	check(tower._generated_root.get_node("Billboard")==screen,"Billboard speed edits must preserve its geometry")
	tower.recall_enabled=true
	var effect: Node=tower.get_recall_controller()
	effect.set_process(false)
	effect.seek(0.50)
	check(is_equal_approx(tower._display_material.get_shader_parameter("assembly_progress"),0.5),"Tower recall must include its animated billboard")
	tower.rebuild()
	check(is_equal_approx(effect.progress,0.50),"Tower rebuild must preserve recall")
	tower.recall_enabled=false
	tower.screen_enabled=false
	tower.rebuild()
	check(not tower._generated_root.has_node("Billboard") and not tower._generated_root.has_node("BillboardHalo"),"Disabling screens must remove both screen and halo layers")
	var crossing: PainterlyScrambleCrossing=setup.get_node("ScrambleCrossing")
	check(crossing.excludes_ground_point(Vector3.ZERO) and crossing.has_node("Generated/Collision"),"Crossing must expose supported road ground and planting exclusions")
	actor.position=Vector3(0,0.03,8)
	actor.reset_physics_interpolation()
	check(await walk_to(actor,Vector3(0,0,-7)),"The authored city must retain a traversable center route past the standing crowd")
	check(actor.global_position.y<0.08 and actor.is_on_floor(),"The crossing must keep the explorer supported")
	for prop in [tower,crossing]:
		prop.collision_enabled=false
		prop.rebuild()
		check(not prop._generated_root.has_node("Collision"),"Tokyo props must support decorative placement without collision")
	print("Tokyo component checks: ","PASS" if failures==0 else "FAIL"," | temple triangles: ",budgets)
	study.free()
	await process_frame
	quit(failures)
