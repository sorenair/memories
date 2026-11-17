extends SceneTree
## Walk from the planted bank to the Ensign landing, then back to shore.
const WORLD := "res://scenes/world/first_sail_world.tscn"
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
			check(player.is_on_floor(),"First Sail route joins must remain supported")
			return true
		driver.axis = offset.normalized()*minf(1.0,offset.length()*1.25)
		await physics_frame
	driver.axis = Vector2.ZERO
	push_error("First Sail walk stopped at %s on the way to %s" % [player.global_position,point])
	return false

func capture(name: String) -> void:
	if not "--capture" in OS.get_cmdline_user_args(): return
	await create_timer(1.3).timeout
	RenderingServer.force_draw(false)
	root.get_texture().get_image().save_png("res://docs/previews/first_sail-memory-"+name+".png")

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
			check(player.is_on_floor(),"Both directions of the shore path must be supported")
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
	check(fragment.try_activate(world.get_node("Explorer")),"The landing fragment must be within reach")
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
	var zone: MemoryZone = zones[0]
	var camera: Camera3D = world.get_node("CameraRig/Camera3D")
	if "--views-only" in args:
		await capture_views(world,memory,camera)
		world.free()
		print("First Sail views: captured")
		quit()
		return
	var floor: MemoryPlatform = memory.get_node("Environment/ShoreAndDockFloor")
	var path: PainterlyCurvedPath = zone.get_node("Scenery/ShorePath")
	var dock: PainterlyWoodenDock = zone.get_node("Scenery/Dock")
	var boat: PainterlyEnsign = zone.get_node("Scenery/Ensign")
	var water: PainterlyWater = zone.get_node("Scenery/Lake")
	check(zones.size()==1 and zone.zone_id==&"first_sail_lake" and memory.memory_id==&"first_sail","First Sail should have one lake-centric zone and a unique LAN memory identity")
	check(player.is_on_floor() and floor.contains_ground_point(player.global_position+Vector3.RIGHT*1.2,0.5),"Both arrivals must fit on the planted shore approach")
	check(camera.size<4.0,"The shore arrival should start with intimate framing")
	for index in 81:
		check(floor.contains_ground_point(path.to_global(path.point_at(path.get_path_length()*index/80.0)),0.3),"The shore path must stay on finite supported ground")
	check(not water.block_water_entry,"Water shore barriers must leave the dock ramp open")
	check(boat.position.x-boat.beam*.5>dock.head_width*.5+.2,"The Ensign hull and fenders must clear the dock landing")
	check(absf(boat.global_position.y-water.global_position.y)<.01,"The Ensign root must match the actual waterline")
	check(boat.sails_enabled and boat.fenders_enabled and boat.bob_amount>0 and boat.wind_strength>0 and not boat.is_processing(),"The moored Ensign should reuse gentle shader-driven boat and sail motion")
	check(world.get_node("GuidanceController").request_guidance(),"Requested guidance must cross the real shore ramp and pier")
	await create_timer(4.0).timeout
	check(water.get_recall_controller().progress>.99 and dock.get_recall_controller().progress>.99,"The lake and supported dock must recall from the accessible bank")
	check(boat.get_recall_controller().progress==0,"The Ensign should wait for the pier approach")
	check(zone.ambience.playing,"The zone needs its quiet water ambient bed")
	await capture("shore-arrival")
	await walk_trail(player,path,0,1)
	await create_timer(1.0).timeout
	check(camera.size>4.2 and camera.size<5.5,"Walking toward the ramp should gradually open the shore view")
	await capture("dock-approach")
	for p: Vector3 in [Vector3(0,0,6.6),Vector3(0,.55,4.4),Vector3(0,.55,1.5)]:
		check(await walk_to(player,zone.to_global(p)),"The actual explorer must climb the access ramp and reach the main pier")
	await create_timer(4.0).timeout
	check(player.global_position.y>.52 and player.global_position.y<.65,"The dock's real deck must support the explorer above the water")
	check(boat.get_recall_controller().progress>.99,"The entire boat must recall from the reachable pier")
	check(camera.size>7.0 and camera.size<16.0,"Mid-pier framing should transition smoothly toward the sailboat")
	check(await walk_to(player,zone.to_global(Vector3(0,.55,-3.2))),"The main pier must connect to the T landing")
	check(await walk_to(player,zone.get_fragment().global_position),"The landing fragment must be reachable")
	await create_timer(2.5).timeout
	check(camera.size>16.6 and camera.size<17.3,"The landing must reveal the full Ensign silhouette")
	for point: Vector3 in [boat.get_anchor(&"Bow").global_position,boat.get_anchor(&"Stern").global_position,boat.to_global(Vector3(0,boat.mast_height,0))]:
		var screen := camera.unproject_position(point)
		var extent := root.get_visible_rect().size
		check(camera.is_position_in_frustum(point) and screen.x>16 and screen.x<extent.x-16 and screen.y>16 and screen.y<extent.y-16,"Bow, stern and masthead must fit in the landing reveal")
	await capture("first-sail-landing")
	await read_fragment(world,zone.get_fragment())
	check(world.get_node("GuidanceController").get_next_fragment()==null,"The one-zone memory must finish its note without automatic hints")
	for p: Vector3 in [Vector3(-2,.55,-3.2),Vector3(2,.55,-3.2)]:
		check(await walk_to(player,zone.to_global(p)),"Both sides of the T landing must be open for two explorers")
	driver.axis = Vector2.RIGHT
	await create_timer(0.8).timeout
	driver.axis = Vector2.ZERO
	for frame in 8: await physics_frame
	check(player.is_on_floor() and player.global_position.x<dock.head_width*.5,"Finite dock boundaries must stop the explorer before walking off the open landing")
	for p: Vector3 in [Vector3(0,.55,-3.2),Vector3(0,.55,1.5),Vector3(0,.55,4.4),Vector3(0,0,7.1)]:
		check(await walk_to(player,zone.to_global(p)),"The real explorer must return along the pier and descend the ramp")
	await walk_trail(player,path,1,0)
	await create_timer(2.5).timeout
	check(player.is_on_floor() and player.global_position.y<.12 and camera.size<4.0,"Returning to shore must restore grounded, intimate walking")
	if "--capture" in args: await capture_views(world,memory,camera)
	world.free()
	await process_frame
	change_scene_to_file("res://UI/memory_lane/memory_lane.tscn")
	await process_frame
	await process_frame
	check(current_scene.MEMORIES[15].date=="AUG 22, 2026" and current_scene.MEMORIES[15].scene==WORLD,"First Sail must follow Vineyard on August 22")
	MemoryExplorer.preferred_avatar = MemoryExplorer.Avatar.VIVIAN
	current_scene.select_memory(15)
	current_scene.recall()
	while current_scene==null or current_scene.scene_file_path!=WORLD: await process_frame
	if current_scene.has_node("MemoryArrival"): await current_scene.get_node("MemoryArrival").finished
	for frame in 12: await physics_frame
	check(current_scene.get_node("Explorer").avatar==MemoryExplorer.Avatar.VIVIAN and current_scene.get_node("Explorer").is_on_floor(),"Timeline recall must retain avatar choice and a grounded shore arrival")
	current_scene.free()
	await create_timer(0.25).timeout
	print("First Sail memory: ","PASS" if failures==0 else "FAIL")
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
	rig.position = Vector3(0,1,-1.8)
	camera.size = 33
	await capture("overview")

func run_lan(host: bool) -> void:
	var barrier := LanBarrier.new()
	barrier.name = "FirstSailLanBarrier"
	root.add_child(barrier)
	var avatar := MemoryExplorer.Avatar.VIVIAN if host else MemoryExplorer.Avatar.SOREN
	MemoryExplorer.preferred_avatar = avatar
	var session := root.get_node("LanSession")
	var peer := ENetMultiplayerPeer.new()
	var error := peer.create_server(24775,1) if host else peer.create_client("127.0.0.1",24775)
	check(error==OK,"The isolated first_sail test transport must open")
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
	check(session.partner_id!=0,"The test clients must pair before recalling the first_sail")
	if not host:
		while session.partner_memory!="first_sail" and Time.get_ticks_msec()<deadline: await process_frame
	var world := load(WORLD).instantiate() as Node3D
	root.add_child(world)
	current_scene = world
	for frame in 8: await physics_frame
	deadline = Time.get_ticks_msec()+30000
	while Time.get_ticks_msec()<deadline:
		await process_frame
		if session.shares_memory() and world.has_node("Partner") and world.get_node("Partner").visible: break
	check(session.shares_memory() and world.has_node("Partner"),"Matching first_sail memories must show the partner")
	if world.has_node("Partner"):
		barrier.ready_mark.rpc()
		while not barrier.partner_ready and Time.get_ticks_msec()<deadline: await process_frame
		check(barrier.partner_ready,"Both first_sail clients must be ready before walking")
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
			check(partner.visible and partner.avatar!=avatar and partner.position.distance_to(initial)>0.25,"Both avatar choices and walking must replicate through the first_sail arrival")
			check(player.is_on_floor(),"Both LAN arrivals must remain grounded on the first_sail path")
			barrier.done_mark.rpc()
			while not barrier.partner_done and Time.get_ticks_msec()<deadline: await process_frame
			check(barrier.partner_done,"Both first_sail clients must finish their movement check")
			await create_timer(0.2).timeout
	session.leave()
	await process_frame
	world.free()
	await create_timer(0.3).timeout
	print("First Sail LAN ","host" if host else "guest",": ","PASS" if failures==0 else "FAIL")
	quit(failures)
