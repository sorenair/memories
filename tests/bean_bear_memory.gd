extends SceneTree
## Walk from the parked vehicle through woodland, up the overlook and down to camp.
const WORLD := "res://scenes/world/bean_bear_world.tscn"
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
			check(player.is_on_floor(),"Bean and Bear route joins must remain supported")
			return true
		driver.axis = offset.normalized()*minf(1.0,offset.length()*1.25)
		await physics_frame
	driver.axis = Vector2.ZERO
	push_error("Bean and Bear walk stopped at %s on the way to %s" % [player.global_position,point])
	return false

func capture(name: String) -> void:
	if not "--capture" in OS.get_cmdline_user_args(): return
	await create_timer(1.3).timeout
	RenderingServer.force_draw(false)
	root.get_texture().get_image().save_png("res://docs/previews/bean_bear-memory-"+name+".png")

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
			check(player.is_on_floor(),"Both directions of the forest trail must be supported")
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
	check(fragment.try_activate(world.get_node("Explorer")),"Each hiking and camping fragment must be within reach")
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
		print("Bean and Bear views: captured")
		quit()
		return
	var floor: MemoryPlatform = memory.get_node("Environment/ForestFloor")
	var forest: PainterlyCurvedPath = zones[0].get_node("Scenery/ForestTrail")
	var fork: PainterlyCurvedPath = zones[0].get_node("Scenery/BoulderFork")
	var climb: PainterlyCurvedPath = zones[1].get_node("Scenery/OverlookClimb")
	var overlook: PainterlyCurvedPath = zones[1].get_node("Scenery/LookoutSpur")
	var descent: PainterlyCurvedPath = zones[1].get_node("Scenery/ToCamp")
	var camp: PainterlyCurvedPath = zones[2].get_node("Scenery/CampWalk")
	var shore: PainterlyCurvedPath = zones[2].get_node("Scenery/ShoreSpur")
	check(zones.size()==3 and memory.memory_id==&"bean_bear","The hike, overlook and campsite need three ordered zones with their own memory identity")
	check(zones[0].zone_id==&"bean_bear_trailhead" and zones[1].zone_id==&"bean_bear_overlook" and zones[2].zone_id==&"bean_bear_campsite","Preserve trailhead, overlook and camp order")
	check(player.is_on_floor() and floor.contains_ground_point(player.global_position+Vector3.RIGHT*1.2,0.5),"Both arrivals must fit beside the parked 4Runner")
	check(camera.size<4.0,"The woodland arrival should start close")
	for trail in [forest,fork,climb,overlook,descent,camp,shore]:
		for index in 81:
			check(floor.contains_ground_point(trail.to_global(trail.point_at(trail.get_path_length()*index/80.0)),0.3),"Every authored trail must fit inside the finite floor: "+trail.name)
	check(world.get_node("GuidanceController").request_guidance(),"The first requested hint must enter the forest")
	await capture("trailhead-arrival")
	var ratio := forest.curve.get_closest_offset(forest.to_local(zones[0].get_fragment().global_position))/forest.get_path_length()
	await walk_trail(player,forest,0,ratio)
	await create_timer(2.0).timeout
	check(zones[0].ambience.playing,"The trail needs a quiet woodland ambient bed")
	check(zones[0].get_node("Scenery/FourRunner").get_recall_controller().progress>0.99,"The parked vehicle must recall beside the safe arrival")
	await capture("forest-walk")
	await read_fragment(world,zones[0].get_fragment())
	check(world.get_node("GuidanceController").request_guidance(),"The next hint must wind through the forest and climb onto the overlook")
	await walk_trail(player,forest,ratio,1)
	await walk_trail(player,climb,0,1)
	await walk_trail(player,overlook,0,1)
	await create_timer(4.0).timeout
	check(player.global_position.y>3.15 and player.global_position.y<3.4,"The actual explorer must climb onto the cliff landing")
	check(absf(camera.size - 20.0) < 0.2,"Only the lookout spur should open the wide lake reveal")
	check(zones[1].ambience.playing,"The overlook must have an open-air ambient bed")
	var near_lake: PainterlyWater = zones[1].get_node("Scenery/NearLake")
	check(not zones[1].has_node("Scenery/FarLake") and not zones[2].get_node("Scenery").visible,"Only the nearer lake should appear from the lookout")
	check(near_lake.get_recall_controller().progress>0.99 and camera.is_position_in_frustum(near_lake.global_position),"The lake must recall and fit in the overlook framing")
	for edge: Vector2 in near_lake._shape_data.outline:
		var screen := camera.unproject_position(near_lake.to_global(Vector3(edge.x,0,edge.y)))
		check(screen.y > 12 and screen.y < root.get_visible_rect().size.y - 12,"The lake's waterline must fit in the overlook reveal")
	var crow: PainterlyBird = zones[1].get_node("Scenery/LookoutCrow1")
	check(crow.palette_preset == 6 and crow.state != PainterlyBird.State.IDLE,"A black crow should take flight on the lookout spur")
	await capture("lake-overlook")
	await read_fragment(world,zones[1].get_fragment())
	check(world.get_node("GuidanceController").request_guidance(),"The final hint must descend to the lakeside campsite")
	await walk_trail(player,overlook,1,0)
	await walk_trail(player,descent,0,1)
	await walk_trail(player,camp,0,1)
	await create_timer(4.0).timeout
	check(player.is_on_floor() and player.global_position.y<0.12,"The campsite should return to lake-bank level")
	check(absf(camera.size - 9.4) < 0.2 and zones[2].ambience.playing and zones[2].get_node("Scenery").visible,"The camp needs its own framing and a quiet ambient bed")
	for name in ["Tent","Stove","FirePit"]:
		var gear: Node3D = zones[2].get_node("Scenery/"+name)
		check(gear.get_recall_controller().progress>0.99 and camera.is_position_in_frustum(gear.global_position),"All camping gear should be in frame and recalled: "+name)
	check(zones[2].get_node("Scenery/Stove").burner_on and zones[2].get_node("Scenery/Stove").steam_enabled,"The existing camp stove should feel alive beside the fire")
	await read_fragment(world,zones[2].get_fragment())
	check(world.get_node("GuidanceController").get_next_fragment()==null,"All three notes should finish without automatic hints")
	var camp_fragment := zones[2].get_fragment()
	await create_timer(camp_fragment.decay_duration + 0.15).timeout
	check(not camp_fragment.get_node("Orb").visible,
		"The campsite camera must keep the orb hidden after its final puff")
	var fire: PainterlyFirePit = zones[2].get_node("Scenery/FirePit")
	check(not fire.is_lit() and not fire.get_node("Fire").visible,"The sculpted campfire must start unlit")
	check(await walk_to(player,zones[2].to_global(Vector3(-1.60, 0, 0.22))),"The campfire needs a clear approach")
	check(world.get_node("InteractionController").pick_interactable(camera.unproject_position(fire.get_interaction_tap_position())) == fire,"The fire must be visible and tappable")
	check(fire.try_activate(player) and fire.is_lit() and fire.get_node("Fire").visible and fire.crackle.playing,"A tap should light the fire and play its crackle")
	await capture("lakeside-camp")
	check(fire.try_activate(player) and not fire.is_lit() and not fire.crackle.playing,"A second tap should extinguish the fire")
	check(await walk_to(player,zones[2].get_fragment().global_position),"Players must be able to return to the shore junction")
	await walk_trail(player,shore,0,1)
	await capture("camp-shore")
	await walk_trail(player,shore,1,0)
	await walk_trail(player,camp,1,0)
	await walk_trail(player,descent,1,0)
	await walk_trail(player,climb,1,0)
	await walk_trail(player,forest,1,ratio)
	await walk_trail(player,fork,1,0)
	var fork_start := forest.curve.get_closest_offset(forest.to_local(fork.to_global(fork.point_at(0.0)))) / forest.get_path_length()
	await walk_trail(player,forest,fork_start,0)
	await create_timer(2.0).timeout
	check(camera.size<4.0,"Returning to the parked car must restore close framing")
	if "--capture" in args: await capture_views(world,memory,camera)
	world.free()
	await process_frame
	change_scene_to_file("res://UI/memory_lane/memory_lane.tscn")
	await process_frame
	await process_frame
	check(current_scene.MEMORIES[13].date=="JUL 25, 2026" and current_scene.MEMORIES[13].scene==WORLD,"Bean and Bear Lakes must appear on July 25, before Vineyard")
	MemoryExplorer.preferred_avatar = MemoryExplorer.Avatar.VIVIAN
	current_scene.select_memory(13)
	current_scene.recall()
	while current_scene==null or current_scene.scene_file_path!=WORLD: await process_frame
	if current_scene.has_node("MemoryArrival"): await current_scene.get_node("MemoryArrival").finished
	for frame in 12: await physics_frame
	check(current_scene.get_node("Explorer").avatar==MemoryExplorer.Avatar.VIVIAN and current_scene.get_node("Explorer").is_on_floor(),"Timeline recall must retain avatar choice and a grounded forest arrival")
	current_scene.free()
	await create_timer(0.25).timeout
	print("Bean and Bear memory: ","PASS" if failures==0 else "FAIL")
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
	var names := ["trailhead-overview","overlook-overview","camp-overview","overview"]
	var views := [Vector4(4,1,13,33),Vector4(14,1,-17,40),Vector4(25,1,-24,20),Vector4(13,2,-5,63)]
	for index in views.size():
		var view: Vector4 = views[index]
		rig.position = Vector3(view.x,view.y,view.z)
		camera.size = view.w
		await capture(names[index])

func run_lan(host: bool) -> void:
	var barrier := LanBarrier.new()
	barrier.name = "Bean and BearLanBarrier"
	root.add_child(barrier)
	var avatar := MemoryExplorer.Avatar.VIVIAN if host else MemoryExplorer.Avatar.SOREN
	MemoryExplorer.preferred_avatar = avatar
	var session := root.get_node("LanSession")
	var peer := ENetMultiplayerPeer.new()
	var error := peer.create_server(24765,1) if host else peer.create_client("127.0.0.1",24765)
	check(error==OK,"The isolated bean_bear test transport must open")
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
	check(session.partner_id!=0,"The test clients must pair before recalling the bean_bear")
	if not host:
		while session.partner_memory!="bean_bear" and Time.get_ticks_msec()<deadline: await process_frame
	var world := load(WORLD).instantiate() as Node3D
	root.add_child(world)
	current_scene = world
	for frame in 8: await physics_frame
	deadline = Time.get_ticks_msec()+30000
	while Time.get_ticks_msec()<deadline:
		await process_frame
		if session.shares_memory() and world.has_node("Partner") and world.get_node("Partner").visible: break
	check(session.shares_memory() and world.has_node("Partner"),"Matching bean_bear memories must show the partner")
	if world.has_node("Partner"):
		barrier.ready_mark.rpc()
		while not barrier.partner_ready and Time.get_ticks_msec()<deadline: await process_frame
		check(barrier.partner_ready,"Both bean_bear clients must be ready before walking")
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
			check(partner.visible and partner.avatar!=avatar and partner.position.distance_to(initial)>0.25,"Both avatar choices and walking must replicate through the bean_bear arrival")
			check(player.is_on_floor(),"Both LAN arrivals must remain grounded on the bean_bear path")
			barrier.done_mark.rpc()
			while not barrier.partner_done and Time.get_ticks_msec()<deadline: await process_frame
			check(barrier.partner_done,"Both bean_bear clients must finish their movement check")
			await create_timer(0.2).timeout
	session.leave()
	await process_frame
	world.free()
	await create_timer(0.3).timeout
	print("Bean and Bear LAN ","host" if host else "guest",": ","PASS" if failures==0 else "FAIL")
	quit(failures)
