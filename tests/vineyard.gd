extends SceneTree
## Exercise the snowy hike, frozen water and safe fireside/cabin approaches.
const WORLD := "res://scenes/world/vineyard_world.tscn"
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
			check(player.is_on_floor(),"Every vineyard route join must remain supported")
			return true
		driver.axis = offset.normalized()*minf(1.0,offset.length()*1.25)
		await physics_frame
	driver.axis = Vector2.ZERO
	push_error("Vineyard walk stopped at %s on the way to %s" % [player.global_position,point])
	return false

func capture(name: String) -> void:
	if not "--capture" in OS.get_cmdline_user_args(): return
	await create_timer(1.3).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/previews/vineyard-"+name+".png")

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
			await capture("grape-rows")
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
	var floor: MemoryPlatform = memory.get_node("Environment/VineyardFloor")
	var trail: PainterlyCurvedPath = memory.get_node("Zones/Rows/Scenery/Trail")
	var camera: Camera3D = world.get_node("CameraRig/Camera3D")
	check(memory.memory_id==&"vineyard" and zones.size()==2,"Vineyard must have two standard zones and its own LAN identity")
	check(player.is_on_floor() and floor.contains_ground_point(player.global_position+Vector3.RIGHT*1.2,0.5),"Both avatars must have supported arrivals between the grape rows")
	check(world._bounded_memory and not world.get_node("DreamSurface").visible,"The memory must use finite ground in the void")
	check(memory.find_children("GrapeBush*","PainterlyGrapevine",true,false).size()==36,"Six rows must contain rooted grapevines")
	check(camera.size<3.7 and zones[0].ambience.playing,"Arrival must remain intimate with a summer ambience bed")
	var field: PainterlyGrassPatch = zones[1].get_node("Scenery/FieldGrass1")
	check(field.get_recall_anchor()!=null and field.get_recall_controller().progress==0,"Scenic meadow must wait for the reachable overlook")
	await capture("arrival")
	check(world.get_node("GuidanceController").request_guidance(),"Guidance should follow the vine aisle to the first note")
	await walk_trail(player,trail,0,memory.rows_fragment_ratio)
	check(zones[0].get_fragment().try_activate(player),"The first note must be reachable between grape rows")
	world.get_node("Controls/FragmentInteraction").advance_note()
	await create_timer(0.25).timeout
	await capture("vines")
	check(world.get_node("GuidanceController").request_guidance(),"Guidance must continue up the deck's real ramp")
	await walk_trail(player,trail,memory.rows_fragment_ratio,1)
	var deck: PainterlyStage = zones[1].get_node("Scenery/TimberDeck")
	check(deck.edge_finish==1 and deck._collision_data.size()>=2,"The reused stage must supply a timber finish and supported ramp/deck")
	for point in [Vector3(0,0,-12.3),Vector3(0,0,-13.7),Vector3(0,0,-15.35),Vector3(-1.5,0,-15.35)]:
		check(await walk_to(player,point),"The vine path, ramp, deck and note must join without a blocking seam")
	check(player.global_position.y>0.5,"The explorer must stand on the raised wooden deck")
	await create_timer(1.0).timeout
	check(camera.size>5.0 and camera.size<5.4,"The deck's first pause should remain intimate")
	check(zones[1].get_fragment().try_activate(player),"The deck note must be accessible before the wide overlook")
	world.get_node("Controls/FragmentInteraction").advance_note()
	await capture("deck")
	for point in [Vector3(0,0,-15.35),Vector3(0,0,-17.8)]:
		check(await walk_to(player,point),"There must be a clear viewing route between both chairs")
	await create_timer(5.0).timeout
	check(camera.size>12.7 and camera.size<13.2,"Walking to the rail must reveal the field with a controlled wider camera")
	check(field.get_recall_controller().progress>0.99,"Distant grass must recall from the accessible deck anchor")
	for tree: PainterlyTree in memory.find_children("FieldTree*","PainterlyTree",true,false):
		check(tree.get_recall_controller().progress>0.99,"Distant field trees must also recall from the overlook")
	check(zones[1].ambience.playing and not floor.contains_ground_point(field.global_position),"The field is scenic beyond the supported overlook, with its own ambience")
	await capture("overlook")
	driver.axis = Vector2(0,-1)
	await create_timer(0.8).timeout
	driver.axis = Vector2.ZERO
	check(player.global_position.z>-18.25 and player.is_on_floor(),"The viewing rail must safely stop the explorer before the scenic field")
	for point in [Vector3(0,0,-15.35),Vector3(0,0,-13.7),Vector3(0,0,-12.3),Vector3(0,0,-10.7),Vector3(3.9,0,-9),Vector3(3.9,0,13.5),Vector3(0,0,14)]:
		check(await walk_to(player,point),"Deck exit, row-end crossing and another vine aisle must work in reverse")
	await create_timer(1.0).timeout
	check(camera.size<3.7,"Returning among the vines must restore the close camera")
	if "--capture" in args:
		for prop in memory.find_children("*","Node3D",true,false):
			if prop.has_method("get_recall_controller"):
				var effect: Node = prop.get_recall_controller()
				if effect: effect.seek(1.0)
		var rig: Node3D = world.get_node("CameraRig")
		rig.set_process(false)
		rig.position = Vector3(0,1.5,-14)
		camera.size = 48.0
		for child in world.get_node("Controls").get_children():
			if child is CanvasItem: child.hide()
		await capture("overview")
	world.free()
	await process_frame
	change_scene_to_file("res://UI/memory_lane/memory_lane.tscn")
	await process_frame
	await process_frame
	check(current_scene.MEMORIES[14].date=="AUG 1, 2026" and current_scene.MEMORIES[14].scene==WORLD,"Vineyard must follow Bean and Bear Lakes in the dated timeline")
	MemoryExplorer.preferred_avatar = MemoryExplorer.Avatar.VIVIAN
	current_scene.select_memory(14)
	current_scene.recall()
	while current_scene==null or current_scene.scene_file_path!=WORLD: await process_frame
	if current_scene.has_node("MemoryArrival"): await current_scene.get_node("MemoryArrival").finished
	for frame in 8: await physics_frame
	check(current_scene.get_node("Explorer").avatar==MemoryExplorer.Avatar.VIVIAN and current_scene.get_node("Explorer").is_on_floor(),"Timeline recall must preserve avatar selection and grounded arrival")
	current_scene.free()
	await create_timer(0.25).timeout
	print("Vineyard memory: ","PASS" if failures==0 else "FAIL")
	quit(failures)

func run_lan(host: bool) -> void:
	var barrier := LanBarrier.new()
	barrier.name = "VineyardLanBarrier"
	root.add_child(barrier)
	var avatar := MemoryExplorer.Avatar.VIVIAN if host else MemoryExplorer.Avatar.SOREN
	MemoryExplorer.preferred_avatar = avatar
	var session := root.get_node("LanSession")
	var peer := ENetMultiplayerPeer.new()
	var error := peer.create_server(24705,1) if host else peer.create_client("127.0.0.1",24705)
	check(error==OK,"The isolated vineyard test transport must open")
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
	check(session.partner_id!=0,"The test clients must pair before recalling the vineyard")
	if not host:
		while session.partner_memory!="vineyard" and Time.get_ticks_msec()<deadline: await process_frame
	var world := load(WORLD).instantiate() as Node3D
	root.add_child(world)
	current_scene = world
	for frame in 8: await physics_frame
	deadline = Time.get_ticks_msec()+30000
	while Time.get_ticks_msec()<deadline:
		await process_frame
		if session.shares_memory() and world.has_node("Partner") and world.get_node("Partner").visible: break
	check(session.shares_memory() and world.has_node("Partner"),"Matching vineyard memories must show the partner")
	if world.has_node("Partner"):
		barrier.ready_mark.rpc()
		while not barrier.partner_ready and Time.get_ticks_msec()<deadline: await process_frame
		check(barrier.partner_ready,"Both vineyard clients must be ready before walking")
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
			check(partner.visible and partner.avatar!=avatar and partner.position.distance_to(initial)>0.25,"Both avatar choices and walking must replicate through the vineyard arrival")
			check(player.is_on_floor(),"Both LAN arrivals must remain grounded on the vineyard path")
			barrier.done_mark.rpc()
			while not barrier.partner_done and Time.get_ticks_msec()<deadline: await process_frame
			check(barrier.partner_done,"Both vineyard clients must finish their movement check")
			await create_timer(0.2).timeout
	session.leave()
	await process_frame
	world.free()
	await create_timer(0.3).timeout
	print("Vineyard LAN ","host" if host else "guest",": ","PASS" if failures==0 else "FAIL")
	quit(failures)
