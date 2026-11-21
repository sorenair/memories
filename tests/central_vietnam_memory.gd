extends SceneTree
## Walk the limestone temple clearing, rising bunds and open imperial gate.
const WORLD := "res://scenes/world/central_vietnam_world.tscn"
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
			check(player.is_on_floor(),"Central Vietnam route joins must remain supported")
			return true
		driver.axis = offset.normalized()*minf(1.0,offset.length()*1.25)
		await physics_frame
	driver.axis = Vector2.ZERO
	push_error("Central Vietnam walk stopped at %s on the way to %s" % [player.global_position,point])
	return false

func capture(name: String) -> void:
	if not "--capture" in OS.get_cmdline_user_args(): return
	await create_timer(1.3).timeout
	RenderingServer.force_draw(false)
	root.get_texture().get_image().save_png("res://docs/previews/central_vietnam-memory-"+name+".png")

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
	check(fragment.try_activate(world.get_node("Explorer")),"Each mountain, field and courtyard fragment must be within reach")
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
	for frame in 12: await physics_frame
	var memory: MemoryScene = world.get_node("Memory")
	var zones := memory.get_zones()
	var camera: Camera3D = world.get_node("CameraRig/Camera3D")
	if "--views-only" in args:
		await capture_views(world,memory,camera)
		world.free()
		print("Central Vietnam views: captured")
		quit()
		return
	var floor: MemoryPlatform = memory.get_node("Environment/VietnamFloor")
	var approach: PainterlyCurvedPath = zones[0].get_node("Scenery/MountainRoute")
	var fields_path: PainterlyCurvedPath = zones[0].get_node("Scenery/ToFields")
	var bund: PainterlyCurvedPath = zones[1].get_node("Scenery/BundWalk")
	var shrine: PainterlyCurvedPath = zones[1].get_node("Scenery/ShrineVisit")
	var hue_path: PainterlyCurvedPath = zones[1].get_node("Scenery/ToHue")
	var gate_walk: PainterlyCurvedPath = zones[2].get_node("Scenery/GateApproach")
	check(zones.size()==3 and memory.memory_id==&"central_vietnam","Central Vietnam needs three ordered zones and a distinct LAN identity")
	check(player.is_on_floor() and floor.contains_ground_point(player.global_position+Vector3.RIGHT*1.2,0.5),"Both arrivals must fit on supported jungle path")
	check(absf(player.global_position.y-approach.to_global(approach.point_at(0)).y)<0.08,"Arrival must sit on the flagstone path")
	check(absf(camera.size - 4.7) < 0.15,"The mountain arrival must begin at the walking zoom")
	for trail in [approach,fields_path,bund,shrine,hue_path,gate_walk]:
		for index in 81:
			check(floor.contains_ground_point(trail.to_global(trail.point_at(trail.get_path_length()*index/80.0)),0.3),"Every path sample must stay inside the finite floor: "+trail.name)
	check(world.get_node("GuidanceController").request_guidance(),"The first requested hint must follow the jungle approach to its temple fragment")
	await capture("mountain-arrival")
	var note_ratio := approach.curve.get_closest_offset(approach.to_local(zones[0].get_fragment().global_position))/approach.get_path_length()
	await walk_trail(player,approach,0,note_ratio)
	check(absf(player.global_position.y-0.035)<0.08,"The temple approach must remain grounded")
	check(zones[0].zone_id==&"marble_mountains" and not zones[0].has_node("Scenery/Sea") and not zones[0].has_node("Scenery/CrescentSand"),"Marble Mountains must replace the beach")
	check(zones[0].get_node("Scenery/NestledTemple").roof_color.g>zones[0].get_node("Scenery/NestledTemple").roof_color.r,"The nestled temple must have a green roof")
	check(zones[0].get_node("Scenery/GoldenBudai").position.x > 3.5,"The seated gold sculpture should flank the temple on its right")
	await create_timer(2.5).timeout
	check(absf(camera.size - 17.6) < 0.15,"The clearing should reveal the temple and limestone peaks")
	check(zones[0].ambience.playing,"The mountains should play their jungle ambient bed")
	await capture("mountain-temple")
	await read_fragment(world,zones[0].get_fragment())
	check(world.get_node("GuidanceController").request_guidance(),"The next requested hint must climb to the field shrine")
	await walk_trail(player,approach,note_ratio,1)
	await walk_trail(player,fields_path,0,0.87)
	await capture("field-transition")
	await walk_trail(player,fields_path,0.87,1)
	var terraces: PainterlyRiceTerraces = zones[1].get_node("Scenery/RiceTerraces")
	check(terraces.paddy_contours.size() >= 10 and not terraces._paddy_faces.is_empty(),"Organic field plots must supply solid bank geometry")
	var middle := bund.curve.get_closest_offset(Vector3(0.4, 0.60, 4.24)) / bund.get_path_length()
	await walk_trail(player,bund,0,middle)
	await create_timer(2.0).timeout
	check(player.global_position.y > 0.5 and absf(camera.size - 4.7) < 0.15,"Exploration between the paddies must feel close and stay on the rising bund")
	await capture("rice-bund")
	var turn := bund.curve.get_closest_offset(bund.to_local(shrine.to_global(shrine.point_at(0.0)))) / bund.get_path_length()
	await walk_trail(player,bund,middle,turn)
	await walk_trail(player,shrine,0,1)
	check(absf(player.global_position.y - 0.808) < 0.14,"The dry clearing must support the walk around the shrine")
	check(zones[1].get_node("Scenery/GoldenCenser/CenserFlame").intensity > 0.5,"The shrine censer should hold an active sculpted flame")
	await capture("rice-shrine")
	await read_fragment(world,zones[1].get_fragment())
	check(world.get_node("GuidanceController").request_guidance(),"The final hint must return to the bund and pass through the imperial gate")
	await walk_trail(player,shrine,1,0)
	await walk_trail(player,bund,turn,1)
	check(player.global_position.y>1.35,"The real explorer must climb the raised field path")
	await create_timer(3.0).timeout
	check(absf(camera.size - 14.0) < 0.15,"The elevated bund should reveal the stepped rice contours")
	check(zones[1].ambience.playing,"The fields should have a separate ambient bed")
	check(zones[1].get_node("Scenery/RiceTerraces").get_recall_controller().progress>0.99,"Scenic rice shelves should recall from a reachable front bund")
	await capture("rice-overlook")
	await walk_trail(player,hue_path,0,0.89)
	await capture("hue-transition")
	await walk_trail(player,hue_path,0.89,1)
	check(await walk_to(player,zones[2].to_global(Vector3(0,0,10))),"The gate approach must remain clear")
	await create_timer(2.5).timeout
	check(camera.size>10.8 and camera.size<12.5,"The gate should open to its landmark framing after approach")
	await capture("hue-gate")
	var visitors := 0
	for group: PainterlyCrowd in zones[2].find_children("PalaceVisitors*", "PainterlyCrowd", true, false):
		visitors += group.generated_count
		check(group.dance_bounce > 0.0 and not group.collision_enabled,"Keep the animated palace visitors clear of two-player movement")
		for pose in group._placements:
			var position := zones[2].to_local(group.to_global(pose.origin))
			if position.z < 0.5:
				check(absf(position.x) > 1.75 and absf(position.x) < 4.1,"Keep courtyard visitors beside the central walk and out of the ponds")
	check(visitors >= 55,"The gate apron and palace court should both feel populated")
	for z in [7.0,5.0,3.0,-1.0,-7.0]: check(await walk_to(player,zones[2].to_global(Vector3(0,0,z))),"The real explorer must walk through the central imperial arch")
	await create_timer(2.5).timeout
	check(camera.size>8.0 and camera.size<9.3,"The palace courtyard should frame the note and hall together")
	check(zones[2].ambience.playing,"The imperial court should have its own ambient bed")
	await capture("hue-courtyard")
	await read_fragment(world,zones[2].get_fragment())
	check(world.get_node("GuidanceController").get_next_fragment()==null,"All three notes should finish without an automatic hint")
	await walk_trail(player,gate_walk,1,0)
	await walk_trail(player,hue_path,1,0)
	await walk_trail(player,bund,1,0)
	await walk_trail(player,fields_path,1,0)
	await walk_trail(player,approach,1,0)
	await create_timer(2.0).timeout
	check(absf(camera.size - 4.7) < 0.15,"Returning to arrival must restore the intimate camera")
	if "--capture" in args: await capture_views(world,memory,camera)
	world.free()
	await process_frame
	change_scene_to_file("res://UI/memory_lane/memory_lane.tscn")
	await process_frame
	await process_frame
	check(current_scene.MEMORIES[11].date=="JUN 15, 2026" and current_scene.MEMORIES[11].scene==WORLD,"Central Vietnam must follow Northern Vietnam on June 15")
	MemoryExplorer.preferred_avatar = MemoryExplorer.Avatar.VIVIAN
	current_scene.select_memory(11)
	current_scene.recall()
	while current_scene==null or current_scene.scene_file_path!=WORLD: await process_frame
	if current_scene.has_node("MemoryArrival"): await current_scene.get_node("MemoryArrival").finished
	for frame in 12: await physics_frame
	check(current_scene.get_node("Explorer").avatar==MemoryExplorer.Avatar.VIVIAN and current_scene.get_node("Explorer").is_on_floor(),"Timeline recall must retain the chosen avatar and grounded jungle arrival")
	current_scene.free()
	await create_timer(0.25).timeout
	print("Central Vietnam memory: ","PASS" if failures==0 else "FAIL")
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
	var names := ["mountains-overview","rice-overview","hue-overview","overview"]
	var views := [Vector4(0,4.0,13,34),Vector4(28,1.5,-15,27),Vector4(54,2.1,-42,28),Vector4(25,3,-12,80)]
	for index in views.size():
		var view: Vector4 = views[index]
		rig.position = Vector3(view.x,view.y,view.z)
		camera.size = view.w
		await capture(names[index])

func run_lan(host: bool) -> void:
	var barrier := LanBarrier.new()
	barrier.name = "Central VietnamLanBarrier"
	root.add_child(barrier)
	var avatar := MemoryExplorer.Avatar.VIVIAN if host else MemoryExplorer.Avatar.SOREN
	MemoryExplorer.preferred_avatar = avatar
	var session := root.get_node("LanSession")
	var peer := ENetMultiplayerPeer.new()
	var error := peer.create_server(24745,1) if host else peer.create_client("127.0.0.1",24745)
	check(error==OK,"The isolated central_vietnam test transport must open")
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
	check(session.partner_id!=0,"The test clients must pair before recalling the central_vietnam")
	if not host:
		while session.partner_memory!="central_vietnam" and Time.get_ticks_msec()<deadline: await process_frame
	var world := load(WORLD).instantiate() as Node3D
	root.add_child(world)
	current_scene = world
	for frame in 8: await physics_frame
	deadline = Time.get_ticks_msec()+30000
	while Time.get_ticks_msec()<deadline:
		await process_frame
		if session.shares_memory() and world.has_node("Partner") and world.get_node("Partner").visible: break
	check(session.shares_memory() and world.has_node("Partner"),"Matching central_vietnam memories must show the partner")
	if world.has_node("Partner"):
		barrier.ready_mark.rpc()
		while not barrier.partner_ready and Time.get_ticks_msec()<deadline: await process_frame
		check(barrier.partner_ready,"Both central_vietnam clients must be ready before walking")
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
			check(partner.visible and partner.avatar!=avatar and partner.position.distance_to(initial)>0.25,"Both avatar choices and walking must replicate through the central_vietnam arrival")
			check(player.is_on_floor(),"Both LAN arrivals must remain grounded on the central_vietnam path")
			barrier.done_mark.rpc()
			while not barrier.partner_done and Time.get_ticks_msec()<deadline: await process_frame
			check(barrier.partner_done,"Both central_vietnam clients must finish their movement check")
			await create_timer(0.2).timeout
	session.leave()
	await process_frame
	world.free()
	await create_timer(0.3).timeout
	print("Central Vietnam LAN ","host" if host else "guest",": ","PASS" if failures==0 else "FAIL")
	quit(failures)
