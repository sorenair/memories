extends SceneTree
var failures := 0
func _initialize() -> void:
	call_deferred("run")

func check(value: bool,message: String) -> void:
	if not value:
		failures+=1
		push_error(message)

func walk(actor: MemoryExplorer,local_direction: Vector3,frames: int) -> void:
	for frame in range(frames):
		await physics_frame
		actor.velocity=local_direction+Vector3.DOWN*0.8
		actor.move_and_slide()

func walk_to(actor: MemoryExplorer,target: Vector3) -> bool:
	for frame in range(480):
		var offset := Vector3(target.x-actor.global_position.x,0,target.z-actor.global_position.z)
		if offset.length()<0.10:
			return true
		await physics_frame
		actor.velocity=offset.normalized()*1.8+Vector3.DOWN*0.8
		actor.move_and_slide()
	push_error("Walking stopped at %s heading to %s"%[actor.global_position,target])
	return false

func run() -> void:
	var study: Node3D=load("res://tests/scenes/campus_landmarks_test.tscn").instantiate()
	root.add_child(study)
	current_scene=study
	await process_frame
	await process_frame
	var setup: Node3D=study.subject
	var arches: PainterlyCampusArches=setup.get_node("CampusArches")
	var portico: PainterlyClassicalPortico=setup.get_node("ClassicalPortico")
	var cherry: PainterlyTree=setup.get_node("CherryBlossomTree")
	var actor: MemoryExplorer=study.get_node("Explorer")
	actor.set_physics_process(false)
	var space := study.get_world_3d().direct_space_state
	await physics_frame
	for index in range(2):
		var p := arches.to_global(arches.passage_center(index))
		var ray := PhysicsRayQueryParameters3D.create(p+Vector3(0,0.9,1.2),p+Vector3(0,0.9,-1.2),1)
		check(space.intersect_ray(ray).is_empty(),"Neither stone arch may have an invisible collider across its opening")
		check(not arches.excludes_ground_point(p),"Arch ground exclusions must preserve each walkable opening")
		actor.global_position=p+Vector3(0,0.03,1.5)
		actor.reset_physics_interpolation()
		await walk(actor,Vector3(0,0,-1.8),100)
		check(actor.global_position.z<p.z-1.2,"The real explorer must fit and walk through both arches")
	check(arches.excludes_ground_point(arches.global_position),"The center stone pier must exclude groundcover")
	var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(arches.global_position+Vector3(0,0.9,1.2),arches.global_position+Vector3(0,0.9,-1.2),1))
	check(not hit.is_empty(),"The center pier must remain solid")
	var arrays: Array=arches.get_node("Visual").mesh.surface_get_arrays(0)
	arches.rebuild()
	var rebuilt: Array=arches.get_node("Visual").mesh.surface_get_arrays(0)
	check(arrays[Mesh.ARRAY_VERTEX]==rebuilt[Mesh.ARRAY_VERTEX] and arrays[Mesh.ARRAY_COLOR]==rebuilt[Mesh.ARRAY_COLOR],"Arch stone courses and paint must reproduce their seed")
	# Treads and their small beveled risers must share exact visible/physical heights.
	var profile := portico.stair_profile()
	for i in range(profile.size()-1):
		var z := (profile[i].x+profile[i+1].x)*0.5
		var top := portico.to_global(Vector3(0,3,z))
		var floor_hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(top,top+Vector3.DOWN*3.2,1))
		check(not floor_hit.is_empty() and absf(floor_hit.position.y-portico.stair_height_at(z))<0.006,"Every stair tread/bevel must have collision matching its visible height")
	actor.global_position=portico.to_global(Vector3(0,0.03,portico.stair_front()+0.45))
	actor.reset_physics_interpolation()
	var climbed := await walk_to(actor,portico.to_global(Vector3(0,portico.landing_height(),-0.10)))
	check(climbed and actor.global_position.y>portico.landing_height()-0.04,"Explorer must ascend all portico stairs and pass between the central columns")
	var descended := await walk_to(actor,portico.to_global(Vector3(0,0,portico.stair_front()+0.45)))
	check(descended and actor.global_position.y<0.08,"Explorer must descend the portico stairs without snagging")
	for prop in [arches,portico]:
		prop.recall_enabled=true
		var effect: Node=prop.get_recall_controller()
		effect.set_process(false)
		effect.seek(0.45)
		prop.rebuild()
		check(prop.get_recall_controller()==effect and is_equal_approx(effect.progress,0.45),"Landmark edits must preserve recall progress")
		prop.recall_enabled=false
		var packed := PackedScene.new()
		check(packed.pack(prop)==OK,"Landmarks must serialize as configurable components")
		var copy := packed.instantiate()
		check(copy.get_children().is_empty(),"Generated landmark meshes/collision must not serialize")
		copy.free()
		prop.collision_enabled=false
		prop.rebuild()
		for child in prop.get_children(true):
			check(not child is StaticBody3D,"Disabling landmark collision must remove all previous solids")
	check(cherry.get_script()==load("res://components/foliage/painterly_tree.gd"),"The cherry preset must reuse the existing tree generator")
	check(cherry.tree_type==0 and cherry.get_node("Canopy").multimesh.instance_count>800,"Cherry must use a full broadleaf crown rather than a new sparse leaf system")
	check(cherry.palette.leaf_color.r>cherry.palette.leaf_color.g and cherry.palette.sun_color.b>0.8,"Cherry preset must preserve its pink/cream blossom palette")
	check(cherry.falling_leaf_count>0 and cherry.falling_leaf_rate>0,"Cherry preset must retain the existing falling-petal effect")
	portico.step_count=12
	portico.column_count=6
	portico.frieze_text="COMMENCEMENT"
	portico.rebuild()
	check(portico.stair_profile().size()==26 and is_equal_approx(portico.landing_height(),12*portico.step_rise),"Stair count edits must update landing height and geometry together")
	check(not arches.is_processing() and not portico.is_processing(),"Static architectural pieces must need no CPU frame callbacks")
	print("Campus landmarks: ","PASS" if failures==0 else "FAIL")
	study.free()
	await process_frame
	quit(failures)
