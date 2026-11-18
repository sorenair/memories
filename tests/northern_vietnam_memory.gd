extends SceneTree
## Walk the shrine and temple verandas, forest paths and crowded city crossing.
const WORLD := "res://scenes/world/northern_vietnam_world.tscn"
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
			check(player.is_on_floor(),"Northern Vietnam route joins must remain supported")
			return true
		driver.axis = offset.normalized()*minf(1.0,offset.length()*1.25)
		await physics_frame
	driver.axis = Vector2.ZERO
	push_error("Northern Vietnam walk stopped at %s on the way to %s" % [player.global_position,point])
	return false

func capture(name: String) -> void:
	if not "--capture" in OS.get_cmdline_user_args(): return
	await create_timer(1.3).timeout
	RenderingServer.force_draw(false)
	root.get_texture().get_image().save_png("res://docs/previews/northern_vietnam-memory-"+name+".png")

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
			check(player.is_on_floor(),"Both directions of the curved Vietnam path must be supported")
			return
		var lookahead := clampf(distance+direction*0.55,minf(from,to)*length,maxf(from,to)*length)
		var target := trail.to_global(trail.point_at(lookahead))
		var offset := Vector2(target.x-player.global_position.x,target.z-player.global_position.z)
		driver.axis = offset.normalized()*minf(1.0,remaining.length()*1.25)
		await physics_frame
	driver.axis = Vector2.ZERO
	check(false,"Explorer stopped on "+str(trail.get_path())+" at "+str(player.global_position)+" heading to "+str(end))

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
	root.content_scale_size = Vector2i(1600,900)
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
	var camera: Camera3D = world.get_node("CameraRig/Camera3D")
	if "--views-only" in args:
		await capture_views(world,memory,camera)
		world.free()
		print("Northern Vietnam views: captured")
		quit()
		return
	var floor: MemoryPlatform = memory.get_node("Environment/VietnamFloor")
	check(zones.size()==3 and memory.memory_id==&"northern_vietnam","Three ordered zones need a stable shared memory ID")
	check(player.is_on_floor() and floor.contains_ground_point(player.global_position+Vector3.RIGHT*1.2,0.3),"Both arrivals must be supported")
	check(absf(camera.size - 4.7) < 0.15,"Arrival should begin at the everyday walking zoom")
	for trail: PainterlyCurvedPath in [zones[0].get_node("Scenery/LaneRoute"),zones[0].get_node("Scenery/ToLake"),zones[1].get_node("Scenery/LakeWalk"),zones[1].get_node("Scenery/ToBay"),zones[2].get_node("Scenery/ShoreApproach")]:
		for index in 61:
			check(floor.contains_ground_point(trail.to_global(trail.point_at(trail.get_path_length()*index/60.0)),0.3),"All authored path samples must remain inside finite support: "+trail.name)
	await capture("arrival")
	check(await walk_to(player,Vector3(0.2,0,14)),"The Old Quarter lane must remain open through the crowd")
	await create_timer(2.0).timeout
	check(absf(camera.size - 6.1) < 0.15,"The street viewpoint should frame the storefronts from the fragment")
	await capture("old-quarter-street")
	check(world.get_node("GuidanceController").request_guidance(),"The first requested hint must reach the street fragment")
	await read_fragment(world,zones[0].get_fragment())
	check(world.get_node("GuidanceController").request_guidance(),"The second requested hint must cross the bridge to the island")
	check(await walk_to(player,Vector3(0,0,5)),"Old Quarter exit must remain clear")
	var lake_trail: PainterlyCurvedPath = zones[0].get_node("Scenery/ToLake")
	await walk_trail(player,lake_trail,0,0.88)
	await capture("lake-connector")
	await walk_trail(player,lake_trail,0.88,1)
	await create_timer(2.0).timeout
	check(absf(camera.size - 13.4) < 0.15,"The lake arrival should frame the bridge and island")
	var temple := zones[1].get_node("Scenery/NgocSonTemple")
	check(temple.get_recall_controller().progress > 0.99,"The temple must be visible from the reachable bridge approach")
	await capture("lake-arrival")
	await walk_trail(player,zones[1].get_node("Scenery/LakeWalk"),0,1)
	var bridge: PainterlyRedBridge = zones[1].get_node("Scenery/RedBridge")
	for z in [4.5,2.5,0.0,-2.5,-4.5]:
		check(await walk_to(player,bridge.to_global(Vector3(0,0,z))),"The real explorer must cross the arched deck")
		check(absf(player.global_position.y-bridge.surface_height(z))<0.12,"The bridge must support its actual curved surface")
	check(await walk_to(player,zones[1].get_fragment().global_position),"The island note must be accessible beyond the bridge")
	await create_timer(2.0).timeout
	check(absf(camera.size - 4.7) < 0.15,"The island note should restore the everyday walking zoom")
	await capture("island-temple")
	await read_fragment(world,zones[1].get_fragment())
	check(world.get_node("GuidanceController").request_guidance(),"The final hint must return over the bridge and continue to the bay")
	for z in [-4.5,-2.5,0.0,2.5,4.5]: check(await walk_to(player,bridge.to_global(Vector3(0,0,z))),"Bridge must be walkable in reverse")
	check(await walk_to(player,Vector3(18,0,3)),"The shoreline join must stay supported")
	var bank_trail: PainterlyCurvedPath = zones[1].get_node("Scenery/ToBay")
	await walk_trail(player,bank_trail,0,0.51)
	await create_timer(1.7).timeout
	check(absf(camera.size - 4.7) < 0.15,"The planted bank connector must return to walking zoom")
	await capture("bank-walk")
	await walk_trail(player,bank_trail,0.51,1)
	await capture("shore-turn")
	await walk_trail(player,zones[2].get_node("Scenery/ShoreApproach"),0,1)
	var dock: PainterlyWoodenDock = zones[2].get_node("Scenery/LookoutDock")
	check(await walk_to(player,dock.get_anchor(&"ShoreJoin").global_position),"The dock ramp must be accessible")
	await create_timer(1.5).timeout
	check(absf(camera.size - 4.7) < 0.15,"The dock ramp should keep the close walking view until the explorer reaches the overlook")
	await capture("dock-approach")
	check(await walk_to(player,zones[2].get_fragment().global_position),"The real explorer must reach the bay overlook")
	check(player.global_position.y>0.5,"The bay note belongs on the real raised dock")
	await create_timer(3.0).timeout
	check(absf(camera.size - 22.8) < 0.15,"The overlook must reveal the karsts while retaining the player")
	var bay_water: PainterlyWater = zones[2].get_node("Scenery/Bay")
	check(bay_water._obstacle_regions.size() >= 8,"Painted shallows must follow the authored karst waterlines")
	for i in 8: check(zones[2].get_node("Scenery/Karst"+str(i+1)).get_recall_controller().progress>0.99,"All scenic karsts must recall from the accessible dock")
	await capture("bay-overlook")
	await read_fragment(world,zones[2].get_fragment())
	check(world.get_node("GuidanceController").get_next_fragment()==null,"All three memory fragments must complete")
	check(zones[2].ambience.playing,"The bay should have its own quiet ambient bed")
	check(await walk_to(player,dock.get_anchor(&"ShoreJoin").global_position),"Return along the dock must remain clear")
	check(await walk_to(player,dock.get_anchor(&"Approach").global_position),"The dock ramp must descend cleanly")
	await walk_trail(player,zones[2].get_node("Scenery/ShoreApproach"),1,0)
	await walk_trail(player,zones[1].get_node("Scenery/ToBay"),1,0)
	await walk_trail(player,zones[0].get_node("Scenery/ToLake"),1,0)
	check(await walk_to(player,memory.get_entry_transform().origin),"The route must also return to the lane arrival")
	await create_timer(2.0).timeout
	check(absf(camera.size - 4.7) < 0.15,"Returning to arrival must restore close framing")
	if "--capture" in args: await capture_views(world,memory,camera)
	world.free()
	await process_frame
	change_scene_to_file("res://UI/memory_lane/memory_lane.tscn")
	await process_frame
	await process_frame
	check(current_scene.MEMORIES[10].date=="JUN 6, 2026" and current_scene.MEMORIES[10].scene==WORLD,"Northern Vietnam must appear after Tokyo on June 6")
	MemoryExplorer.preferred_avatar = MemoryExplorer.Avatar.VIVIAN
	current_scene.select_memory(10)
	current_scene.recall()
	while current_scene==null or current_scene.scene_file_path!=WORLD: await process_frame
	if current_scene.has_node("MemoryArrival"): await current_scene.get_node("MemoryArrival").finished
	for frame in 8: await physics_frame
	check(current_scene.get_node("Explorer").avatar==MemoryExplorer.Avatar.VIVIAN and current_scene.get_node("Explorer").is_on_floor(),"Timeline must preserve avatar choice and grounded arrival")
	current_scene.free()
	await create_timer(0.25).timeout
	print("Northern Vietnam memory: ","PASS" if failures==0 else "FAIL")
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
	for view in [Vector4(0,2,13,25),Vector4(18,1,-8,28),Vector4(45,3,-36,31),Vector4(23,3,-8,68)]:
		rig.position = Vector3(view.x,view.y,view.z)
		camera.size = view.w
		await capture(["old-quarter-overview","lake-overview","bay-overview","overview"][[25,28,31,68].find(int(view.w))])

func run_lan(host: bool) -> void:
	var barrier := LanBarrier.new()
	barrier.name = "Northern VietnamLanBarrier"
	root.add_child(barrier)
	var avatar := MemoryExplorer.Avatar.VIVIAN if host else MemoryExplorer.Avatar.SOREN
	MemoryExplorer.preferred_avatar = avatar
	var session := root.get_node("LanSession")
	var peer := ENetMultiplayerPeer.new()
	var error := peer.create_server(24735,1) if host else peer.create_client("127.0.0.1",24735)
	check(error==OK,"The isolated northern_vietnam test transport must open")
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
	check(session.partner_id!=0,"The test clients must pair before recalling the northern_vietnam")
	if not host:
		while session.partner_memory!="northern_vietnam" and Time.get_ticks_msec()<deadline: await process_frame
	var world := load(WORLD).instantiate() as Node3D
	root.add_child(world)
	current_scene = world
	for frame in 8: await physics_frame
	deadline = Time.get_ticks_msec()+30000
	while Time.get_ticks_msec()<deadline:
		await process_frame
		if session.shares_memory() and world.has_node("Partner") and world.get_node("Partner").visible: break
	check(session.shares_memory() and world.has_node("Partner"),"Matching northern_vietnam memories must show the partner")
	if world.has_node("Partner"):
		barrier.ready_mark.rpc()
		while not barrier.partner_ready and Time.get_ticks_msec()<deadline: await process_frame
		check(barrier.partner_ready,"Both northern_vietnam clients must be ready before walking")
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
			check(partner.visible and partner.avatar!=avatar and partner.position.distance_to(initial)>0.25,"Both avatar choices and walking must replicate through the northern_vietnam arrival")
			check(player.is_on_floor(),"Both LAN arrivals must remain grounded on the northern_vietnam path")
			barrier.done_mark.rpc()
			while not barrier.partner_done and Time.get_ticks_msec()<deadline: await process_frame
			check(barrier.partner_done,"Both northern_vietnam clients must finish their movement check")
			await create_timer(0.2).timeout
	session.leave()
	await process_frame
	world.free()
	await create_timer(0.3).timeout
	print("Northern Vietnam LAN ","host" if host else "guest",": ","PASS" if failures==0 else "FAIL")
	quit(failures)
