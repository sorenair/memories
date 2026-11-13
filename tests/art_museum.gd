extends SceneTree
const WORLD := "res://scenes/world/art_museum_world.tscn"
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)
func walk_to(player: MemoryExplorer, point: Vector3) -> bool:
	for frame in 900:
		for action in [&"move_left",&"move_right",&"move_forward",&"move_back"]: Input.action_release(action)
		var offset := Vector2(point.x-player.global_position.x,point.z-player.global_position.z)
		if offset.length()<0.13:
			for action in [&"move_left",&"move_right",&"move_forward",&"move_back"]: Input.action_release(action)
			for settle in 3: await physics_frame
			return true
		if absf(offset.x)>0.08: Input.action_press("move_right" if offset.x>0 else "move_left")
		if absf(offset.y)>0.08: Input.action_press("move_back" if offset.y>0 else "move_forward")
		await physics_frame
	for action in [&"move_left",&"move_right",&"move_forward",&"move_back"]: Input.action_release(action)
	push_error("Walking stopped at %s heading toward %s" % [player.global_position,point])
	return false
func capture(name: String) -> void:
	if not "--capture" in OS.get_cmdline_user_args(): return
	await create_timer(1.2).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/previews/museum-"+name+".png")
func run() -> void:
	root.content_scale_size = Vector2i(1600,738)
	var world := load(WORLD).instantiate() as Node3D
	root.add_child(world)
	current_scene = world
	for frame in 5: await physics_frame
	var player: MemoryExplorer = world.get_node("Explorer")
	player.movement_camera = null
	player.walk_speed = 4.5
	world.get_node("Controls/FPSLabel").hide()
	var memory: MemoryScene = world.get_node("Memory")
	var platform: MemoryPlatform = memory.get_node("Environment/MuseumFloor")
	var zones := memory.get_zones()
	check(memory.memory_id==&"art_museum" and zones.size()==4,"Museum must contain four ordered standard zones")
	check(player.is_on_floor() and platform.contains_ground_point(player.global_position,0.5)
		and platform.contains_ground_point(player.global_position+Vector3.RIGHT*1.2,0.5),"Both explorers must have safe arrival positions")
	check(world._bounded_memory and not world.get_node("DreamSurface").visible,"Museum must use finite continuous ground")
	check(not platform.contains_ground_point(Vector3(-7,0,-18))
		and not platform.contains_ground_point(Vector3(7,0,-18)),"The room clusters must leave substantial void between them")
	await create_timer(1.0).timeout
	check(world.get_node("CameraRig/Camera3D").size<3.6,"Arrival must stay intimate while the explorer stands still")
	await capture("entrance")
	check(await walk_to(player,Vector3(0,0,5.4)),"The initial path must be walkable before the camera reveal")
	await create_timer(0.8).timeout
	check(player.global_position.z>4.5 and world.get_node("CameraRig/Camera3D").size<3.6,"The first stretch of path must retain the close arrival framing")
	check(await walk_to(player,Vector3(0,0,2.9)),"The approach must lead toward the portico")
	await create_timer(1.0).timeout
	check(world.get_node("CameraRig/Camera3D").size>5.0 and world.get_node("CameraRig/Camera3D").size<9.0,"The view must open gradually as the explorer approaches the portico")
	# Ray-check both stair flights against their actual tread heights.
	for step in [Vector2(3.1,0.1),Vector2(2.25,0.2),Vector2(0,0.3),Vector2(-2.25,0.2),Vector2(-3.1,0.1)]:
		var hit := world.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(0,1,step.x),Vector3(0,-0.2,step.x),1))
		check(not hit.is_empty() and absf(hit.position.y-step.y)<0.006,"Stair collision must match the visible tread at Z %s" % step.x)
	check(await walk_to(player,Vector3(0,0.3,0)),"The portico's center gap and stair ramp must be walkable")
	check(player.global_position.y>0.25 and player.is_on_floor(),"Portico steps must support the explorer")
	await create_timer(1.3).timeout
	check(world.get_node("CameraRig/Camera3D").size>9.3,"Reaching the columns must reveal the wider portico composition")
	await capture("portico")
	check(await walk_to(player,Vector3(0,0,-4.5)),"The gate must lead directly onto the gallery passage behind it")
	check(await walk_to(player,Vector3(0,0,4.1)),"The entrance fragment must remain reachable from the portico")
	var paths := [[],[Vector3(0,0,3.6),Vector3(0,0,0),Vector3(0,0,-3.6),Vector3(0,0,-6.5)],
		[Vector3(-4.5,0,-10.8),Vector3(-7.5,0,-10.8),Vector3(-11,0,-10.8),Vector3(-14.5,0,-13)],
		[Vector3(-14.5,0,-13),Vector3(-11,0,-10.8),Vector3(-7.5,0,-10.8),Vector3(-4.5,0,-10.8),Vector3(0,0,-10.8),Vector3(4.5,0,-10.8),Vector3(7.5,0,-10.8),Vector3(11,0,-10.8),Vector3(14.5,0,-13)]]
	for index in zones.size():
		var zone: MemoryZone = zones[index]
		check(zone.get_fragment()!=null and zone.ambience_stream!=null and zone.has_node("Scenery"),"Each zone must contain scenery, a fragment, and local ambience")
		check(world.get_node("GuidanceController").request_guidance(),"Guidance must find a safe route to zone %d" % index)
		for point in paths[index]:
			check(await walk_to(player,point),"The connecting route to zone %d must be continuous" % index)
			if index==2 and point.x==-7.5:
				await create_timer(0.9).timeout
				check(world.get_node("CameraRig/Camera3D").size<3.6,"The branch passage must settle at First Meeting's intimate camera scale")
		# The entrance fragment now sits between the columns; approach on the
		# centerline so the planner's wider clearance capsule stays off them.
		var approach_x := 0.0 if index==0 else 0.8
		check(await walk_to(player,zone.get_fragment().global_position+Vector3(approach_x,0,1.0)),"Every exhibit fragment must be approachable")
		check(player.is_on_floor(),"The explorer must stay supported at every exhibit")
		await capture(["forecourt","marble","paintings","crowded-room"][index])
		check(zone.get_fragment().try_activate(player),"Each zone's story fragment must activate")
		world.get_node("Controls/FragmentInteraction").advance_note()
		for frame in 4: await physics_frame
	check(world.get_node("CameraRig/Camera3D").size<4.9,"The camera must move close for exhibit exploration")
	var crowd: PainterlyCrowd = zones[3].get_node("Scenery/Visitors")
	check(crowd.generated_count==34 and not crowd.is_processing(),"Crowded room must reuse the existing batched GPU crowd")
	check(await walk_to(player,memory.get_node("Exit").global_position),"The crowd's reserved aisle must lead to the exit")
	# Return through the connectors to check both directions and camera restoration.
	for point in [Vector3(14.5,0,-13),Vector3(11,0,-10.8),Vector3(7.5,0,-10.8),Vector3(4.5,0,-10.8),Vector3(0,0,-9.4),Vector3(0,0,-6.5),Vector3(0,0,-3.6),Vector3(0,0,0),Vector3(0,0,3.6),Vector3(0,0,6)]:
		check(await walk_to(player,point),"The memory must be navigable in reverse")
	await create_timer(1.3).timeout
	check(world.get_node("CameraRig/Camera3D").size<3.6,"Returning to the start of the path must restore the intimate arrival framing")
	world.free()
	await process_frame
	change_scene_to_file("res://UI/memory_lane/memory_lane.tscn")
	await process_frame
	await process_frame
	check(current_scene.MEMORIES[2].date=="DEC 4, 2025" and current_scene.MEMORIES[2].scene==WORLD,"The museum must be the dated third timeline memory")
	current_scene.select_memory(2)
	current_scene.recall()
	await create_timer(0.7).timeout
	check(current_scene.scene_file_path==WORLD,"Timeline Recall must open the museum")
	if current_scene.has_node("MemoryArrival"): await current_scene.get_node("MemoryArrival").finished
	for frame in 5: await physics_frame
	check(current_scene.get_node("Explorer").is_on_floor(),"Recalled arrival must settle safely")
	check(current_scene.get_node("CameraRig/Camera3D").size<3.6,"Timeline recall must also arrive with the intimate camera")
	current_scene.free()
	await create_timer(0.2).timeout
	print("Art museum memory: ","PASS" if failures==0 else "FAIL")
	quit(failures)
