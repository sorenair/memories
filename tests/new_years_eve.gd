extends SceneTree
## Exercise the actual walking route, stage ramp, story, audio, and timeline recall.
const WORLD := "res://scenes/world/new_years_eve_world.tscn"
var failures := 0
class WalkingInput extends Node:
	var axis := Vector2.ZERO
	func get_movement() -> Vector2: return axis
var driver: WalkingInput
class LanBarrier extends Node:
	var partner_ready := false
	var partner_done := false
	@rpc("any_peer", "reliable")
	func ready_mark() -> void: partner_ready = true
	@rpc("any_peer", "reliable")
	func done_mark() -> void: partner_done = true

func _initialize() -> void: call_deferred("run")
func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)

func walk_to(player: MemoryExplorer, point: Vector3) -> bool:
	for frame in 1000:
		var offset := Vector2(point.x-player.global_position.x,point.z-player.global_position.z)
		if offset.length()<0.09:
			driver.axis = Vector2.ZERO
			for settle in 8: await physics_frame
			return true
		driver.axis = offset.normalized()*minf(1.0,offset.length()*1.25)
		await physics_frame
	driver.axis = Vector2.ZERO
	push_error("Concert walk stopped at %s on the way to %s" % [player.global_position,point])
	return false

func capture(name: String) -> void:
	if not "--capture" in OS.get_cmdline_user_args(): return
	await create_timer(1.2).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/previews/new-years-eve-"+name+".png")

func verify_dj(dj: PainterlyDJBooth) -> void:
	var hand: MeshInstance3D = dj._arms[0].hand
	var before := hand.transform
	await create_timer(0.23).timeout
	check(not hand.transform.is_equal_approx(before),"The DJ must visibly work the decks during normal playback")
	var strength := dj.performance_strength
	dj.performance_strength = 1.0
	# Check actual posed vertices through complete scratch cycles: hands remain
	# on their own record and the connected arms clear both console and platters.
	for frame in 48:
		dj.seek_time(frame/12.0)
		for i in dj._arms.size():
			var arm := dj._arms[i]
			var platter := dj._platters[i]
			check((arm.upper.transform*(Vector3.UP*PainterlyDJBooth.ARM_LENGTH)).distance_to(arm.fore.position)<0.0001
				and (arm.fore.transform*(Vector3.UP*PainterlyDJBooth.ARM_LENGTH)).distance_to(arm.hand.position)<0.0001,"Both DJ arms must stay joined at elbow and wrist")
			var contact: Vector3 = arm.hand.position-platter.position
			check(Vector2(contact.x,contact.z).length()<0.20,"Each hand must stay over its own record")
			for part: MeshInstance3D in [arm.upper,arm.fore,arm.hand]:
				var points: PackedVector3Array = part.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
				for vertex in points:
					var at: Vector3 = part.transform*vertex
					if absf(at.x)<1.24 and at.z>0.07 and at.z<0.83:
						if at.y<0.94:
							check(false,"DJ arms must not pass through the console")
							return
						if Vector2(at.x-platter.position.x,at.z-platter.position.z).length()<0.23 and at.y<0.978:
							check(false,"DJ hands and forearms must clear the platter surface")
							return
	dj.performance_strength = strength

func run() -> void:
	var args := OS.get_cmdline_user_args()
	if "host" in args or "guest" in args:
		await run_lan("host" in args)
		return
	root.content_scale_size = Vector2i(1600,738)
	var world := load(WORLD).instantiate() as Node3D
	root.add_child(world)
	current_scene = world
	var player: MemoryExplorer = world.get_node("Explorer")
	driver = WalkingInput.new()
	world.add_child(driver)
	player.movement_camera = null
	player.movement_input = driver
	world.get_node("Controls/FPSLabel").hide()
	for frame in 8: await physics_frame
	var memory: MemoryScene = world.get_node("Memory")
	var zones := memory.get_zones()
	var floor: MemoryPlatform = memory.get_node("Environment/ConcertFloor")
	var camera: Camera3D = world.get_node("CameraRig/Camera3D")
	check(memory.memory_id==&"new_years_eve" and zones.size()==1,"The concert must use one standard zone and its own LAN identity")
	check(player.is_on_floor() and floor.contains_ground_point(player.global_position,0.5)
		and floor.contains_ground_point(player.global_position+Vector3.RIGHT*1.2,0.5),"Both explorers must start on supported ground behind the audience")
	check(world._bounded_memory and not world.get_node("DreamSurface").visible,"The concert must emerge from finite ground in the void")
	check(camera.size<3.7,"Arrival behind the crowd should be intimate")
	await capture("arrival")
	var people := 0
	for crowd: PainterlyCrowd in memory.find_children("*","PainterlyCrowd",true,false):
		check(crowd.generated_count==crowd.count,"The complete authored audience must fit its area")
		people += crowd.generated_count
		for pose: Transform3D in crowd._placements:
			var at := crowd.to_global(pose.origin)
			check(absf(at.x)>1.6,"The central path must remain clear of audience hitboxes")
			check(floor.contains_ground_point(at,0.2),"Every audience member must stand on the remembered floor")
	check(people>=200,"The stage approach must have a substantial crowd")
	check(memory.get_audio().music.playing and memory.get_audio().music.bus==&"Music"
		and zones[0].ambience.playing,"Original electronic music and crowd ambience must mix on their standard buses")
	check(world.get_node("GuidanceController").request_guidance(),"Requested guidance must lead through the crowd to the fragment")
	for point in [Vector3(0,0,10),Vector3(0,0,5.9),Vector3(-4,0,5.9),Vector3(0,0,5.9)]:
		check(await walk_to(player,point),"The central aisle and middle cross-passage must be walkable")
		check(player.is_on_floor(),"The explorer must remain grounded in the audience")
	await capture("crowd")
	for point in [Vector3(0,0,1),Vector3(0,0,-3),Vector3(0,0,-5.0)]:
		check(await walk_to(player,point),"The path must reach the front viewing area without crossing the crowd")
	await create_timer(1.0).timeout
	check(camera.size>10.2 and camera.size<10.6,"The stage approach should open the composition smoothly")
	var scenery := zones[0].get_node("Scenery")
	var rig: PainterlyRaveLights = scenery.get_node("StageLights")
	var before := rig._heads[0].transform
	await create_timer(0.4).timeout
	check(not before.is_equal_approx(rig._heads[0].transform),"The stage lights must sweep toward the audience")
	check(scenery.get_node("PaintedScreen")._display_material!=null,"The stage screen must have its animated pigment material")
	for name in ["Stage","PaintedScreen","StageLights","DJBooth","LeftMainSpeaker","RightMainSpeaker"]:
		var prop: PainterlyConcertComponent = scenery.get_node(name)
		check(prop._material.get_shader_parameter("assembly_progress")>=0.99,"Stage hardware must finish recalling before the front viewing area: "+name)
	await verify_dj(scenery.get_node("DJBooth"))
	await capture("stage")
	check(zones[0].get_fragment().try_activate(player),"The single fragment must be reachable from the viewing apron")
	world.get_node("Controls/FragmentInteraction").advance_note()
	await create_timer(0.3).timeout
	for point in [Vector3(0,0,-6.7),Vector3(0,0,-10.8),Vector3(-3,0,-10.8),Vector3(-3,0,-12.8)]:
		check(await walk_to(player,point),"The continuous ramp and stage must be walkable around the console")
		check(player.is_on_floor(),"Ramp and deck must support the player")
	check(player.global_position.y>0.4,"The ramp must lift the player onto the stage deck")
	await capture("dj")
	for point in [Vector3(-3,0,-10.8),Vector3(0,0,-10.8),Vector3(0,0,-6.7),Vector3(0,0,0),Vector3(0,0,15.2)]:
		check(await walk_to(player,point),"The concert route must also work in reverse")
	await create_timer(1.0).timeout
	check(camera.size<3.7,"Returning to the rear should restore the intimate arrival camera")
	if "--capture" in OS.get_cmdline_user_args():
		var camera_rig: Node3D = world.get_node("CameraRig")
		camera_rig.set_process(false)
		camera_rig.position = Vector3(0,1.5,0)
		camera.size = 32.0
		for child in world.get_node("Controls").get_children():
			if child is CanvasItem: child.hide()
		await capture("overview")
	world.free()
	await process_frame
	change_scene_to_file("res://UI/memory_lane/memory_lane.tscn")
	await process_frame
	await process_frame
	check(current_scene.MEMORIES[4].date=="DEC 31, 2025" and current_scene.MEMORIES[4].scene==WORLD,"New Year's Eve must be the dated fifth authored memory")
	MemoryExplorer.preferred_avatar = MemoryExplorer.Avatar.VIVIAN
	current_scene.select_memory(4)
	current_scene.recall()
	while current_scene==null or current_scene.scene_file_path!=WORLD: await process_frame
	if current_scene.has_node("MemoryArrival"): await current_scene.get_node("MemoryArrival").finished
	for frame in 8: await physics_frame
	check(current_scene.get_node("Explorer").avatar==MemoryExplorer.Avatar.VIVIAN
		and current_scene.get_node("Explorer").is_on_floor(),"Timeline recall must preserve the chosen character and safe arrival")
	current_scene.free()
	await create_timer(0.25).timeout
	print("New Year's Eve memory: ","PASS" if failures==0 else "FAIL")
	quit(failures)

func run_lan(host: bool) -> void:
	var barrier := LanBarrier.new()
	barrier.name = "ConcertLanBarrier"
	root.add_child(barrier)
	var avatar := MemoryExplorer.Avatar.VIVIAN if host else MemoryExplorer.Avatar.SOREN
	MemoryExplorer.preferred_avatar = avatar
	var session := root.get_node("LanSession")
	if host: check(session.host(avatar),"The local concert server must listen: %s" % session.status)
	else: session.join("127.0.0.1",avatar)
	var deadline := Time.get_ticks_msec()+30000
	while session.partner_id==0 and Time.get_ticks_msec()<deadline: await process_frame
	check(session.partner_id!=0,"The test clients must pair before recalling the concert")
	if not host:
		while session.partner_memory!="new_years_eve" and Time.get_ticks_msec()<deadline: await process_frame
	var world := load(WORLD).instantiate() as Node3D
	root.add_child(world)
	current_scene = world
	for frame in 8: await physics_frame
	deadline = Time.get_ticks_msec()+30000
	while Time.get_ticks_msec()<deadline:
		await process_frame
		if session.shares_memory() and world.has_node("Partner") and world.get_node("Partner").visible: break
	check(session.shares_memory() and world.has_node("Partner"),"Matching concert memories must show the partner")
	if world.has_node("Partner"):
		barrier.ready_mark.rpc()
		while not barrier.partner_ready and Time.get_ticks_msec()<deadline: await process_frame
		check(barrier.partner_ready,"Both concert clients must be ready before walking")
		if barrier.partner_ready and world.has_node("Partner"):
			var player: MemoryExplorer = world.get_node("Explorer")
			var partner: MemoryExplorer = world.get_node("Partner")
			var initial := partner.position
			driver = WalkingInput.new()
			world.add_child(driver)
			player.movement_camera = null
			player.movement_input = driver
			driver.axis = Vector2(0,-1)
			await create_timer(1.0).timeout
			driver.axis = Vector2.ZERO
			await create_timer(0.4).timeout
			for frame in 5: await physics_frame
			check(partner.visible and partner.avatar!=avatar and partner.position.distance_to(initial)>0.25,"Both avatar choices and walking must replicate through the rear aisle")
			check(player.is_on_floor(),"Both LAN arrivals must remain grounded behind the crowd")
			barrier.done_mark.rpc()
			while not barrier.partner_done and Time.get_ticks_msec()<deadline: await process_frame
			check(barrier.partner_done,"Both concert clients must finish their movement check")
			await create_timer(0.2).timeout
	session.leave()
	await process_frame
	world.free()
	await create_timer(0.3).timeout
	print("New Year's Eve LAN ","host" if host else "guest",": ","PASS" if failures==0 else "FAIL")
	quit(failures)
