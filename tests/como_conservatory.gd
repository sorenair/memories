extends SceneTree
## Exercise both garden lanes, protected water, winding joins and quiet displays.
const WORLD := "res://scenes/world/como_conservatory_world.tscn"
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
			check(player.is_on_floor(),"Every garden/room join must remain supported")
			return true
		driver.axis = offset.normalized()*minf(1.0,offset.length()*1.25)
		await physics_frame
	driver.axis = Vector2.ZERO
	push_error("Conservatory walk stopped at %s on the way to %s" % [player.global_position,point])
	return false

func capture(name: String) -> void:
	if not "--capture" in OS.get_cmdline_user_args(): return
	await create_timer(1.3).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/previews/como-conservatory-"+name+".png")

func walk_trail(player: MemoryExplorer,trail: PainterlyCurvedPath,from: float,to: float) -> void:
	var length := trail.get_path_length()
	var end := trail.to_global(trail.point_at(length*to))
	var direction := signf(to-from)
	var entry_captured := false
	for frame in 2400:
		var local := trail.to_local(player.global_position)
		var distance := trail.curve.get_closest_offset(local)
		var remaining := Vector2(end.x-player.global_position.x,end.z-player.global_position.z)
		if remaining.length()<0.09:
			driver.axis = Vector2.ZERO
			for settle in 8: await physics_frame
			check(player.is_on_floor(),"The curved path must support both directions")
			return
		var lookahead := clampf(distance+direction*0.65,minf(from,to)*length,maxf(from,to)*length)
		var target := trail.to_global(trail.point_at(lookahead))
		var offset := Vector2(target.x-player.global_position.x,target.z-player.global_position.z)
		driver.axis = offset.normalized()*minf(1.0,remaining.length()*1.25)
		if not entry_captured and from==0.0 and distance>length*0.25:
			entry_captured = true
			driver.axis = Vector2.ZERO
			await capture("jungle-entry")
		await physics_frame
	driver.axis = Vector2.ZERO
	check(false,"The explorer must follow the complete Bezier path without getting stuck")

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
	var floor: MemoryPlatform = memory.get_node("Environment/ConservatoryFloor")
	var camera: Camera3D = world.get_node("CameraRig/Camera3D")
	var trail: PainterlyCurvedPath = memory.get_node("Zones/Jungle/Scenery/WindingPath")
	check(memory.memory_id==&"como_conservatory" and zones.size()==3,"Como must have three standard zones and its own LAN identity")
	check(player.is_on_floor() and floor.contains_ground_point(player.global_position,0.5)
		and floor.contains_ground_point(player.global_position+Vector3.RIGHT*1.2,0.5),"Both explorers must arrive safely before the water channel")
	check(world._bounded_memory and not world.get_node("DreamSurface").visible
		and not floor.contains_ground_point(Vector3(6,0,-16)),"The three rooms must preserve unsupported pockets of memory void")
	check(camera.size<3.7,"The conservatory should begin at First Meeting's intimate scale")
	check(memory.find_children("*","PainterlyFlowerBush",true,false).size()>=16,"The formal garden needs substantial flowering beds")
	check(zones[2].find_children("*","PainterlyBonsai",true,false).size()==3,"The quiet room must contain exactly three bonsai pedestals")
	for zone: MemoryZone in zones:
		check(zone.ambience_stream!=null and zone.get_fragment()!=null,"Every room must contain its own ambient bed and story fragment")
	check(zones[0].ambience.playing,"Water ambience must accompany the flower garden")
	driver.axis = Vector2(0,-1)
	await create_timer(1.0).timeout
	driver.axis = Vector2.ZERO
	check(player.global_position.z>8.35,"The water row must have a solid, visible entry end cap")
	check(await walk_to(player,Vector3(0,0,10.3)),"The end cap must leave the arrival crossing clear")
	await capture("arrival")
	check(world.get_node("GuidanceController").request_guidance(),"Guidance must choose a lane around the rill")
	for point in [Vector3(2.7,0,9.4),Vector3(2.7,0,4)]:
		check(await walk_to(player,point),"The right flower-garden lane must be clear")
	await capture("flowers")
	driver.axis = Vector2(-1,0)
	await create_timer(0.9).timeout
	driver.axis = Vector2.ZERO
	check(player.global_position.x>1.0,"Stone edging must keep explorers out of the central water channel")
	for point in [Vector3(2.7,0,4),Vector3(2.7,0,0),Vector3(2.7,0,-5.4)]:
		check(await walk_to(player,point),"The path must continue beside the rill to the fountain")
	await create_timer(1.0).timeout
	check(camera.size>4.6 and camera.size<4.9,"The garden reveal must retain an intimate scale")
	await capture("fountain")
	check(zones[0].get_fragment().try_activate(player),"The garden fragment must be reachable beside the fountain")
	world.get_node("Controls/FragmentInteraction").advance_note()
	await create_timer(0.2).timeout
	for point in [Vector3(2.7,0,-4.7),Vector3(0,0,-4.7)]:
		check(await walk_to(player,point),"The fountain end of the rill must be approachable")
	driver.axis = Vector2(0,1)
	await create_timer(0.6).timeout
	driver.axis = Vector2.ZERO
	check(player.global_position.z< -4.35,"The water row must have a solid fountain-side end cap")
	check(await walk_to(player,Vector3(2.7,0,-4.7)),"The rear end cap must preserve the side lane")
	for point in [Vector3(2.7,0,-8.9),Vector3(-2.7,0,-8.9),Vector3(-2.7,0,-5),Vector3(-2.7,0,4),Vector3(-2.7,0,9.4),Vector3(0,0,10.3),Vector3(2.7,0,9.4),Vector3(2.7,0,-8.9)]:
		check(await walk_to(player,point),"Both lanes and the crossings at the ends of the water must be explorable")
	check(world.get_node("GuidanceController").request_guidance(),"Guidance must follow the connected passage into the jungle")
	for point in [Vector3(0,0,-8.9),Vector3(0,0,-12.5),trail.to_global(trail.point_at(0.0))]:
		check(await walk_to(player,point),"The winding jungle route must be clear of water, tree trunks and floor rims")
	await walk_trail(player,trail,0.0,memory.jungle_fragment_ratio)
	await create_timer(1.0).timeout
	check(camera.size>3.4 and camera.size<3.7,"The jungle camera must stay at the close exploration scale")
	check(zones[1].ambience.playing,"Leaf/air ambience must accompany the jungle room")
	await capture("jungle")
	check(zones[1].get_fragment().try_activate(player),"The jungle fragment must be reachable from its path")
	world.get_node("Controls/FragmentInteraction").advance_note()
	await create_timer(0.2).timeout
	check(world.get_node("GuidanceController").request_guidance(),"Guidance must continue through the void to the bonsai room")
	await walk_trail(player,trail,memory.jungle_fragment_ratio,1.0)
	await capture("jungle-exit")
	for point in [Vector3(7,0,-24.5),Vector3(10,0,-24.5),Vector3(13,0,-24.5),Vector3(13,0,-23.3)]:
		check(await walk_to(player,point),"The bonsai displays must have a supported, uncluttered approach")
	await create_timer(1.0).timeout
	check(camera.size>4.0 and camera.size<4.4 and zones[2].ambience.playing,"The bonsai room must use quiet local audio and closer individual display views")
	check(zones[2].get_fragment().try_activate(player),"The final fragment must be reachable before the three pedestals")
	world.get_node("Controls/FragmentInteraction").advance_note()
	await create_timer(0.2).timeout
	for point in [Vector3(10.3,0,-24.8),Vector3(13,0,-25.6),Vector3(15.8,0,-24.5),Vector3(13,0,-24.5)]:
		check(await walk_to(player,point),"All three bonsai must have an accessible intimate viewing position")
		if point==Vector3(13,0,-25.6): await capture("bonsai")
	for point in [Vector3(7,0,-24.5),trail.to_global(trail.point_at(trail.get_path_length()))]:
		check(await walk_to(player,point),"The bonsai connection must work in reverse")
	await walk_trail(player,trail,1.0,0.0)
	for point in [Vector3(0,0,-12.5),Vector3(0,0,-8.9),Vector3(-2.7,0,-8.9),Vector3(-2.7,0,9.4),Vector3(0,0,10.3)]:
		check(await walk_to(player,point),"All three rooms must remain explorable in reverse")
	await create_timer(1.0).timeout
	check(camera.size<3.7,"Returning to arrival must restore the intimate camera")
	if "--capture" in args:
		var rig: Node3D = world.get_node("CameraRig")
		rig.set_process(false)
		rig.position = Vector3(3.0,2,-8.5)
		camera.size = 43.0
		for child in world.get_node("Controls").get_children():
			if child is CanvasItem: child.hide()
		await capture("overview")
	world.free()
	await process_frame
	change_scene_to_file("res://UI/memory_lane/memory_lane.tscn")
	await process_frame
	await process_frame
	check(current_scene.MEMORIES[5].date=="JAN 14, 2026" and current_scene.MEMORIES[5].scene==WORLD,"Como must be the dated sixth authored timeline memory")
	MemoryExplorer.preferred_avatar = MemoryExplorer.Avatar.VIVIAN
	current_scene.select_memory(5)
	current_scene.recall()
	while current_scene==null or current_scene.scene_file_path!=WORLD: await process_frame
	if current_scene.has_node("MemoryArrival"): await current_scene.get_node("MemoryArrival").finished
	for frame in 8: await physics_frame
	check(current_scene.get_node("Explorer").avatar==MemoryExplorer.Avatar.VIVIAN and current_scene.get_node("Explorer").is_on_floor(),"Timeline recall must preserve character choice and a safe conservatory arrival")
	current_scene.free()
	await create_timer(0.25).timeout
	print("Como Conservatory memory: ","PASS" if failures==0 else "FAIL")
	quit(failures)

func run_lan(host: bool) -> void:
	var barrier := LanBarrier.new()
	barrier.name = "ConservatoryLanBarrier"
	root.add_child(barrier)
	var avatar := MemoryExplorer.Avatar.VIVIAN if host else MemoryExplorer.Avatar.SOREN
	MemoryExplorer.preferred_avatar = avatar
	var session := root.get_node("LanSession")
	if host: check(session.host(avatar),"The local conservatory server must listen: %s" % session.status)
	else: session.join("127.0.0.1",avatar)
	var deadline := Time.get_ticks_msec()+30000
	while session.partner_id==0 and Time.get_ticks_msec()<deadline: await process_frame
	check(session.partner_id!=0,"The test clients must pair before recalling the conservatory")
	if not host:
		while session.partner_memory!="como_conservatory" and Time.get_ticks_msec()<deadline: await process_frame
	var world := load(WORLD).instantiate() as Node3D
	root.add_child(world)
	current_scene = world
	for frame in 8: await physics_frame
	deadline = Time.get_ticks_msec()+30000
	while Time.get_ticks_msec()<deadline:
		await process_frame
		if session.shares_memory() and world.has_node("Partner") and world.get_node("Partner").visible: break
	check(session.shares_memory() and world.has_node("Partner"),"Matching conservatory memories must show the partner")
	if world.has_node("Partner"):
		barrier.ready_mark.rpc()
		while not barrier.partner_ready and Time.get_ticks_msec()<deadline: await process_frame
		check(barrier.partner_ready,"Both conservatory clients must be ready before walking")
		if barrier.partner_ready and world.has_node("Partner"):
			var player: MemoryExplorer = world.get_node("Explorer")
			var partner: MemoryExplorer = world.get_node("Partner")
			var initial := partner.position
			driver = WalkingInput.new()
			world.add_child(driver)
			player.movement_camera = null
			player.movement_input = driver
			driver.axis = Vector2(1,0)
			await create_timer(1.0).timeout
			driver.axis = Vector2.ZERO
			await create_timer(0.4).timeout
			for frame in 5: await physics_frame
			check(partner.visible and partner.avatar!=avatar and partner.position.distance_to(initial)>0.25,"Both avatar choices and walking must replicate through the garden arrival")
			check(player.is_on_floor(),"Both LAN arrivals must remain grounded behind the crowd")
			barrier.done_mark.rpc()
			while not barrier.partner_done and Time.get_ticks_msec()<deadline: await process_frame
			check(barrier.partner_done,"Both conservatory clients must finish their movement check")
			await create_timer(0.2).timeout
	session.leave()
	await process_frame
	world.free()
	await create_timer(0.3).timeout
	print("Como Conservatory LAN ","host" if host else "guest",": ","PASS" if failures==0 else "FAIL")
	quit(failures)
