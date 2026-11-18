extends SceneTree
## Walk the shrine and temple verandas, forest paths and crowded city crossing.
const WORLD := "res://scenes/world/tokyo_world.tscn"
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
func check(value: bool,message: String) -> void:
	if not value:
		failures += 1
		push_error(message)

func walk_to(player: MemoryExplorer,point: Vector3) -> bool:
	for frame in 1000:
		var offset := Vector2(point.x-player.global_position.x,point.z-player.global_position.z)
		if offset.length()<0.09:
			driver.axis = Vector2.ZERO
			for settle in 8: await physics_frame
			check(player.is_on_floor(),"Tokyo route joins must remain supported")
			return true
		driver.axis = offset.normalized()*minf(1.0,offset.length()*1.25)
		await physics_frame
	driver.axis = Vector2.ZERO
	push_error("Tokyo walk stopped at %s on the way to %s" % [player.global_position,point])
	return false

func capture(name: String) -> void:
	if not "--capture" in OS.get_cmdline_user_args(): return
	await create_timer(1.3).timeout
	RenderingServer.force_draw(false)
	root.get_texture().get_image().save_png("res://docs/previews/tokyo-memory-"+name+".png")

func walk_trail(player: MemoryExplorer,trail: PainterlyCurvedPath,from: float,to: float) -> void:
	var length := trail.get_path_length()
	var end := trail.to_global(trail.point_at(length*to))
	var direction := signf(to-from)
	for frame in 2400:
		var distance := trail.curve.get_closest_offset(trail.to_local(player.global_position))
		var remaining := Vector2(end.x-player.global_position.x,end.z-player.global_position.z)
		if remaining.length()<0.09:
			driver.axis = Vector2.ZERO
			for settle in 8: await physics_frame
			check(player.is_on_floor(),"Both directions of the curved campus path must be supported")
			return
		var lookahead := clampf(distance+direction*0.55,minf(from,to)*length,maxf(from,to)*length)
		var target := trail.to_global(trail.point_at(lookahead))
		var offset := Vector2(target.x-player.global_position.x,target.z-player.global_position.z)
		driver.axis = offset.normalized()*minf(1.0,remaining.length()*1.25)
		await physics_frame
	driver.axis = Vector2.ZERO
	check(false,"Explorer must be able to follow the full curved campus route")

func read_fragment(world: Node3D,fragment: MemoryFragment) -> void:
	var camera: Camera3D = world.get_node("CameraRig/Camera3D")
	check(world.get_node("InteractionController").pick_interactable(camera.unproject_position(fragment.get_interaction_tap_position()))==fragment,"Each note must be visible and tappable from its walking approach")
	check(fragment.try_activate(world.get_node("Explorer")),"Each shrine, temple and city fragment must be within reach")
	world.get_node("Controls/FragmentInteraction").advance_note()
	await create_timer(0.3).timeout

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
	var floor: MemoryPlatform = memory.get_node("Environment/TokyoFloor")
	var forest: PainterlyCurvedPath = zones[0].get_node("Scenery/ForestWalk")
	var asakusa: PainterlyCurvedPath = zones[0].get_node("Scenery/ToAsakusa")
	var temple: PainterlyCurvedPath = zones[1].get_node("Scenery/TempleWalk")
	var to_city: PainterlyCurvedPath = zones[1].get_node("Scenery/ToShibuya")
	var crossing: PainterlyCurvedPath = zones[2].get_node("Scenery/CrossingRoute")
	var meiji: PainterlyJapaneseHall = zones[0].get_node("Scenery/WorshipHall")
	var senso: PainterlyJapaneseHall = zones[1].get_node("Scenery/MainHall")
	var camera: Camera3D = world.get_node("CameraRig/Camera3D")
	if "--views-only" in args:
		await capture_views(world,memory,camera)
		world.free()
		await process_frame
		print("Tokyo memory views: captured")
		quit()
		return
	check(memory.memory_id==&"tokyo" and zones.size()==3,"Tokyo needs three ordered zones and its own multiplayer identity")
	check(zones[0].zone_id==&"meiji_shrine" and zones[1].zone_id==&"sensoji" and zones[2].zone_id==&"shibuya_crossing","The three places must follow their requested story order")
	check(player.is_on_floor() and floor.contains_ground_point(player.global_position+Vector3.RIGHT*1.2,0.5),"Both arrivals must be supported on the forest approach")
	check(world._bounded_memory and not world.get_node("DreamSurface").visible,"Tokyo needs finite ground in the memory void")
	check(zones[0].find_children("ForestTree*","PainterlyTree",true,false).size() == 16 and zones[1].find_children("TempleTree*","PainterlyTree",true,false).size() == 10,"Both shrine and temple must retain their green tree canopies")
	check(absf(camera.size - 4.5) < 0.15 and zones[0].ambience.playing,"Arrival should begin close with a quiet forest bed")
	for route in [forest,asakusa,temple,to_city,crossing]:
		for index in 61:
			var point: Vector3 = route.to_global(route.point_at(route.get_path_length()*index/60.0))
			check(floor.contains_ground_point(point,0.4),"Every curve must remain safely inside the finite floor: "+str(route.get_path()))
	await capture("arrival")
	check(world.get_node("GuidanceController").request_guidance(),"The first requested hint must lead through the wooden torii")
	check(await walk_to(player,Vector3(-10,0,22)),"The forest approach must have room between trees")
	await create_timer(2.0).timeout
	check(camera.size>5.5 and camera.size<8.7,"The torii reveal must follow movement from an intimate arrival")
	check(zones[0].get_node("Scenery/Torii").get_recall_controller().progress>0.99,"The wooden gate must be present during its camera reveal")
	check(await walk_to(player,Vector3(-10,0,20)),"The full torii reveal must remain on the forest route")
	await create_timer(2.0).timeout
	check(absf(camera.size - 8.4) < 0.15,"The torii framing must hold across the approach")
	await capture("meiji-torii")
	await walk_trail(player,forest,0,1)
	await create_timer(2.0).timeout
	await capture("meiji-hall")
	check(await walk_to(player,zones[0].get_fragment().global_position),"The explorer must climb the shrine veranda steps")
	check(player.global_position.y>0.42,"The first fragment must stand on the real raised veranda")
	await create_timer(1.2).timeout
	check(absf(camera.size - 4.5) < 0.25,"The camera should return to walking zoom beside the shrine fragment")
	await read_fragment(world,zones[0].get_fragment())
	check(world.get_node("GuidanceController").request_guidance(),"The second requested hint must leave the veranda and enter the lantern gate")
	check(await walk_to(player,meiji.get_anchor(&"Approach").global_position),"Shrine steps must also descend cleanly")
	await walk_trail(player,asakusa,0,1)
	check(await walk_to(player,Vector3(10,0,5.0)),"The Senso-ji lantern approach must remain clear")
	await create_timer(2.0).timeout
	check(camera.size>10.0,"The two-story lantern gate must have its own landmark framing")
	await capture("sensoji-gate")
	await walk_trail(player,temple,0,1)
	await create_timer(2.0).timeout
	var pagoda: PainterlyPagoda = zones[1].get_node("Scenery/Pagoda")
	check(pagoda.get_recall_controller().progress>0.99,"The pagoda should recall from the accessible temple courtyard")
	check(zones[1].ambience.playing,"The temple should have a blended ambient bed")
	await capture("sensoji-courtyard")
	check(await walk_to(player,zones[1].get_fragment().global_position),"The real explorer must climb the main hall's central steps")
	check(player.global_position.y>0.42,"The temple note must be on supported veranda ground")
	await create_timer(1.2).timeout
	await read_fragment(world,zones[1].get_fragment())
	check(world.get_node("GuidanceController").request_guidance(),"The final hint must descend and lead across the city")
	check(await walk_to(player,senso.get_anchor(&"Approach").global_position),"Temple exit must descend without a ledge")
	await walk_trail(player,to_city,0,1)
	await create_timer(2.0).timeout
	var crowd: PainterlyCrowd = zones[2].get_node("Scenery/CrossingCrowd")
	check(crowd.generated_count>=65,"The scramble crossing should feel populated")
	for pose in crowd._placements:
		check(not crossing.excludes_ground_point(crowd.to_global(pose.origin)),"Crowd hitboxes must preserve the narrow winding crossing route")
	for tower: PainterlyCityTower in zones[2].find_children("*Tower","PainterlyCityTower",true,false):
		check(tower.get_recall_controller().progress>0.99 and tower._display_material!=null,"City facades and screens must recall from the reachable crossing arrival")
	check(zones[2].ambience.playing and absf(camera.size - 4.5) < 0.15,"Arrival at the city curb should keep the walking zoom while the crowd bed blends in")
	await capture("shibuya-arrival")
	var center_ratio := crossing.curve.get_closest_offset(Vector3.ZERO) / crossing.get_path_length()
	await walk_trail(player,crossing,0,center_ratio)
	await create_timer(2.0).timeout
	check(absf(camera.size - 10.7) < 0.15,"The center of the junction should reveal the crossing and its screens")
	await capture("shibuya-center")
	await walk_trail(player,crossing,center_ratio,1)
	await create_timer(1.7).timeout
	check(absf(camera.size - 4.5) < 0.25,"The crossing reveal must release at the far-corner fragment")
	await capture("shibuya-crossing")
	await read_fragment(world,zones[2].get_fragment())
	check(not world.get_node("GuidanceController").request_guidance(),"Completed Tokyo notes should leave no automatic or repeated hint")
	# Walk the entire composition in reverse, including both real stair flights.
	await walk_trail(player,crossing,1,0)
	await walk_trail(player,to_city,1,0)
	check(await walk_to(player,zones[1].get_fragment().global_position),"The temple's returning stair ascent must work")
	check(await walk_to(player,senso.get_anchor(&"Approach").global_position),"The temple's returning stair descent must work")
	await walk_trail(player,temple,1,0)
	await walk_trail(player,asakusa,1,0)
	check(await walk_to(player,zones[0].get_fragment().global_position),"The shrine's returning stair ascent must work")
	check(await walk_to(player,meiji.get_anchor(&"Approach").global_position),"The shrine's returning stair descent must work")
	await walk_trail(player,forest,1,0)
	await create_timer(3.0).timeout
	check(absf(camera.size - 4.5) < 0.15,"Returning to the forest arrival must restore the intimate camera")
	if "--capture" in args: await capture_views(world,memory,camera)
	world.free()
	await process_frame
	change_scene_to_file("res://UI/memory_lane/memory_lane.tscn")
	await process_frame
	await process_frame
	check(current_scene.MEMORIES[9].date=="MAY 28, 2026" and current_scene.MEMORIES[9].scene==WORLD,"Tokyo must appear between Graduation and Vineyard on the requested date")
	MemoryExplorer.preferred_avatar = MemoryExplorer.Avatar.VIVIAN
	current_scene.select_memory(9)
	current_scene.recall()
	while current_scene==null or current_scene.scene_file_path!=WORLD: await process_frame
	if current_scene.has_node("MemoryArrival"): await current_scene.get_node("MemoryArrival").finished
	for frame in 8: await physics_frame
	check(current_scene.get_node("Explorer").avatar==MemoryExplorer.Avatar.VIVIAN and current_scene.get_node("Explorer").is_on_floor(),"Timeline recall must preserve avatar choice and a grounded forest arrival")
	current_scene.free()
	await create_timer(0.25).timeout
	print("Tokyo memory: ","PASS" if failures==0 else "FAIL")
	quit(failures)

func capture_views(world: Node3D,memory: MemoryScene,camera: Camera3D) -> void:
	for prop in memory.find_children("*","Node3D",true,false):
		if prop.has_method("get_recall_controller"):
			var effect: Node = prop.get_recall_controller()
			if effect: effect.seek(1.0)
	var rig: Node3D = world.get_node("CameraRig")
	rig.set_process(false)
	for child in world.get_node("Controls").get_children():
		if child is CanvasItem: child.hide()
	rig.position = Vector3(-10,1.8,15)
	camera.size = 23.0
	await capture("meiji-overview")
	rig.position = Vector3(13,2.6,-4)
	camera.size = 26.0
	await capture("sensoji-overview")
	rig.position = Vector3(34,5.5,-29)
	camera.size = 31.0
	await capture("shibuya-overview")
	rig.position = Vector3(9,3,-3)
	camera.size = 66.0
	await capture("overview")

func run_lan(host: bool) -> void:
	var barrier := LanBarrier.new()
	barrier.name = "TokyoLanBarrier"
	root.add_child(barrier)
	var avatar := MemoryExplorer.Avatar.VIVIAN if host else MemoryExplorer.Avatar.SOREN
	MemoryExplorer.preferred_avatar = avatar
	var session := root.get_node("LanSession")
	var peer := ENetMultiplayerPeer.new()
	var error := peer.create_server(24725,1) if host else peer.create_client("127.0.0.1",24725)
	check(error==OK,"The isolated tokyo test transport must open")
	if error!=OK:
		quit(failures)
		return
	session.set_avatar(avatar)
	session.state = session.State.HOSTING if host else session.State.JOINING
	session._peer = peer
	session.multiplayer.multiplayer_peer = peer
	if not host:
		session._join_deadline = Time.get_ticks_msec()+10000
		session.set_process(true)
	var deadline := Time.get_ticks_msec()+30000
	while session.partner_id==0 and Time.get_ticks_msec()<deadline: await process_frame
	check(session.partner_id!=0,"The test clients must pair before recalling the tokyo")
	if not host:
		while session.partner_memory!="tokyo" and Time.get_ticks_msec()<deadline: await process_frame
	var world := load(WORLD).instantiate() as Node3D
	root.add_child(world)
	current_scene = world
	for frame in 8: await physics_frame
	deadline = Time.get_ticks_msec()+30000
	while Time.get_ticks_msec()<deadline:
		await process_frame
		if session.shares_memory() and world.has_node("Partner") and world.get_node("Partner").visible: break
	check(session.shares_memory() and world.has_node("Partner"),"Matching tokyo memories must show the partner")
	if world.has_node("Partner"):
		barrier.ready_mark.rpc()
		while not barrier.partner_ready and Time.get_ticks_msec()<deadline: await process_frame
		check(barrier.partner_ready,"Both tokyo clients must be ready before walking")
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
			check(partner.visible and partner.avatar!=avatar and partner.position.distance_to(initial)>0.25,"Both avatar choices and walking must replicate through the tokyo arrival")
			check(player.is_on_floor(),"Both LAN arrivals must remain grounded on the tokyo path")
			barrier.done_mark.rpc()
			while not barrier.partner_done and Time.get_ticks_msec()<deadline: await process_frame
			check(barrier.partner_done,"Both tokyo clients must finish their movement check")
			await create_timer(0.2).timeout
	session.leave()
	await process_frame
	world.free()
	await create_timer(0.3).timeout
	print("Tokyo LAN ","host" if host else "guest",": ","PASS" if failures==0 else "FAIL")
	quit(failures)
