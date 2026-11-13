extends SceneTree
## Walk the real market; optional host/guest mode checks both avatars over LAN.
const WORLD := "res://scenes/world/christmas_market_world.tscn"
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
	push_error("Market walk stopped at %s on the way to %s" % [player.global_position,point])
	return false
func capture(name: String) -> void:
	if not "--capture" in OS.get_cmdline_user_args(): return
	await create_timer(1.3).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/previews/christmas-market-"+name+".png")
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
	var floor: MemoryPlatform = memory.get_node("Environment/MarketFloor")
	var snow: PainterlySnowPatch = memory.get_node("Environment/ContinuousSnow")
	var camera: Camera3D = world.get_node("CameraRig/Camera3D")
	check(memory.memory_id==&"christmas_market" and zones.size()==2,"Christmas market must have two standard zones and a stable LAN identity")
	check(player.is_on_floor() and floor.contains_ground_point(player.global_position,0.5)
		and floor.contains_ground_point(player.global_position+Vector3.RIGHT*1.2,0.5),"Both explorers must arrive safely on the lane")
	check(world._bounded_memory and not world.get_node("DreamSurface").visible,"The market must use finite ground in the void")
	check(snow.custom_outline==floor.custom_outline and snow._custom_shape,"One continuous snow surface must follow the complete walking floor")
	for at in [Vector3(0,0,5),Vector3(0,0,-5.5),Vector3(-4.5,0,-9.8),Vector3(-6,0,-11.4),Vector3(-6,0,-15)]:
		check(snow.excludes_ground_point(at),"Snow must connect the lane and music clearing without internal seams")
	check(not snow.excludes_ground_point(Vector3(-4,0,2)) and not snow.excludes_ground_point(Vector3(-4.8,0,-19)),"Snow must exclude hut interiors and the stage")
	check(not floor.contains_ground_point(Vector3(5,0,-18)),"Open space beside the gathering must remain void")
	check(camera.size<3.7,"The market must start with an intimate camera")
	await capture("arrival")
	var huts := memory.find_children("*","PainterlyMarketHut",true,false)
	var goods := {}
	for hut in huts: goods[hut.goods] = true
	check(huts.size()==6 and goods.size()==3,"The huts must include bakery, gifts, and drinks rather than identical empty booths")
	var stage: PainterlyMarketStage = zones[1].get_node("Scenery/AcousticStage")
	for crowd: PainterlyCrowd in memory.find_children("*","PainterlyCrowd",true,false):
		check(crowd.generated_count==crowd.count,"Every authored visitor group must fit its reserved area")
		for pose: Transform3D in crowd._placements:
			for hut in huts:
				check(not hut.excludes_ground_point(crowd.to_global(pose.origin)),"Market visitors must stay outside the hut walls and counters")
	check(stage._musicians.size()==3 and stage.is_processing(),"The live stage must contain three animated musicians")
	var before := stage._musicians[0].transform
	await create_timer(0.3).timeout
	check(not before.is_equal_approx(stage._musicians[0].transform),"The acoustic performers must visibly play rather than remain statues")
	check(memory.get_audio().music.playing and memory.get_audio().music.bus==&"Music" and zones[0].ambience.playing,"Music and local ambience must play simultaneously on their standard buses")
	check(world.get_node("GuidanceController").request_guidance(),"Guidance must reach the market-lane fragment")
	for point in [Vector3(0,0,2.5),Vector3(0,0,-1),Vector3(-0.75,0,-2.6)]:
		check(await walk_to(player,point),"The market lane must be walkable between the hut counters")
	await capture("stalls")
	for zone: MemoryZone in zones:
		check(zone.ambience_stream!=null and zone.get_fragment()!=null,"Every zone must own a story fragment and ambient bed")
	check(zones[0].get_fragment().try_activate(player),"The first fragment must activate from the lane")
	world.get_node("Controls/FragmentInteraction").advance_note()
	await create_timer(0.3).timeout
	check(world.get_node("GuidanceController").request_guidance(),"Requested guidance must follow the bent passage to the music")
	for point in [Vector3(0,0,-5.5),Vector3(-2.8,0,-7.4),Vector3(-4.5,0,-9.8),Vector3(-6,0,-11.4),Vector3(-6,0,-14)]:
		check(await walk_to(player,point),"The two zones must share a clear, supported connecting route")
		check(player.is_on_floor(),"The player must stay grounded across the snow joins")
	await create_timer(1.0).timeout
	check(camera.size>7.3 and camera.size<7.6,"The tree and music should receive a modest wider composition")
	check(snow._stamp_count>20,"Walking through both zones must leave a continuous footprint history")
	check(zones[1].ambience.playing and memory.get_audio().music.playing,"The music gathering must blend its crowd bed alongside music")
	await capture("music")
	check(zones[1].get_fragment().try_activate(player),"The gathering fragment must be reachable without entering the stage or tree")
	world.get_node("Controls/FragmentInteraction").advance_note()
	await create_timer(0.2).timeout
	for point in [Vector3(-6,0,-11.4),Vector3(-4.5,0,-9.8),Vector3(-2.8,0,-7.4),Vector3(0,0,-5.5),Vector3(0,0,1),Vector3(0,0,5.4)]:
		check(await walk_to(player,point),"The whole route must also work in reverse")
	await create_timer(1.0).timeout
	check(camera.size<3.7,"Returning to arrival must restore the close camera")
	if "--capture" in args:
		var rig: Node3D = world.get_node("CameraRig")
		rig.set_process(false)
		rig.position = Vector3(-3.5,1.5,-7.5)
		camera.size = 32.0
		for child in world.get_node("Controls").get_children():
			if child is CanvasItem: child.hide()
		await capture("overview")
	world.free()
	await process_frame
	change_scene_to_file("res://UI/memory_lane/memory_lane.tscn")
	await process_frame
	await process_frame
	check(current_scene.MEMORIES[3].date=="DEC 19, 2025" and current_scene.MEMORIES[3].scene==WORLD,"Christmas market must be the dated fourth authored timeline memory")
	MemoryExplorer.preferred_avatar = MemoryExplorer.Avatar.VIVIAN
	current_scene.select_memory(3)
	current_scene.recall()
	while current_scene==null or current_scene.scene_file_path!=WORLD: await process_frame
	if current_scene.has_node("MemoryArrival"): await current_scene.get_node("MemoryArrival").finished
	for frame in 6: await physics_frame
	check(current_scene.get_node("Explorer").avatar==MemoryExplorer.Avatar.VIVIAN and current_scene.get_node("Explorer").is_on_floor(),"Timeline recall must preserve Vivian's choice and a safe snowy arrival")
	current_scene.free()
	await create_timer(0.25).timeout
	print("Christmas market memory: ","PASS" if failures==0 else "FAIL")
	quit(failures)

func run_lan(host: bool) -> void:
	var barrier := LanBarrier.new()
	barrier.name = "MarketLanBarrier"
	root.add_child(barrier)
	var avatar := MemoryExplorer.Avatar.VIVIAN if host else MemoryExplorer.Avatar.SOREN
	MemoryExplorer.preferred_avatar = avatar
	var session := root.get_node("LanSession")
	if host: check(session.host(avatar),"The local test server must listen: %s" % session.status)
	else: session.join("127.0.0.1",avatar)
	# Match the product flow: pair before recalling a world, then let the host
	# enter first so the guest can use the supported second spawn immediately.
	var deadline := Time.get_ticks_msec()+30000
	while session.partner_id==0 and Time.get_ticks_msec()<deadline: await process_frame
	check(session.partner_id!=0,"The local test clients must pair before recalling the market")
	if not host:
		while session.partner_memory!="christmas_market" and Time.get_ticks_msec()<deadline: await process_frame
	var world := load(WORLD).instantiate() as Node3D
	root.add_child(world)
	current_scene = world
	for frame in 8: await physics_frame
	deadline = Time.get_ticks_msec()+30000
	while Time.get_ticks_msec()<deadline:
		await process_frame
		if session.shares_memory() and world.has_node("Partner") and world.get_node("Partner").visible: break
	check(session.shares_memory() and world.has_node("Partner"),"Both devices must enter the same Christmas market and see their partner: %s (state %s, peer %s)" % [session.status,session.state,session.partner_id])
	if world.has_node("Partner"):
		barrier.ready_mark.rpc()
		while not barrier.partner_ready and Time.get_ticks_msec()<deadline: await process_frame
		check(barrier.partner_ready,"Both clients must be ready before the walking check")
		if not barrier.partner_ready or not world.has_node("Partner"):
			session.leave()
			world.free()
			await create_timer(0.3).timeout
			quit(failures)
			return
		var partner: MemoryExplorer = world.get_node("Partner")
		var initial := partner.position
		Input.action_press("move_forward")
		await create_timer(1.0).timeout
		Input.action_release("move_forward")
		await create_timer(0.4).timeout
		for frame in 5: await physics_frame
		check(partner.avatar!=avatar and partner.position.distance_to(initial)>0.25,"Both avatar choices and walking must replicate in the market")
		check(world.get_node("Explorer").is_on_floor(),"The two LAN spawn positions must stay grounded at %s" % world.get_node("Explorer").global_position)
		barrier.done_mark.rpc()
		while not barrier.partner_done and Time.get_ticks_msec()<deadline: await process_frame
		await create_timer(0.2).timeout
	session.leave()
	await process_frame
	world.free()
	await create_timer(0.3).timeout
	print("Christmas market LAN ","host" if host else "guest",": ","PASS" if failures==0 else "FAIL")
	quit(failures)
