extends SceneTree
## Exercise the snowy hike, frozen water and safe fireside/cabin approaches.
const WORLD := "res://scenes/world/postcard_cabin_world.tscn"
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
			check(player.is_on_floor(),"Every snowy route join must remain supported")
			return true
		driver.axis = offset.normalized()*minf(1.0,offset.length()*1.25)
		await physics_frame
	driver.axis = Vector2.ZERO
	push_error("Winter cabin walk stopped at %s on the way to %s" % [player.global_position,point])
	return false

func capture(name: String) -> void:
	if not "--capture" in OS.get_cmdline_user_args(): return
	await create_timer(1.3).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/previews/winter-cabin-"+name+".png")

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
			await capture("forest-bend")
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
	var floor: MemoryPlatform = memory.get_node("Environment/WinterFloor")
	var snow: PainterlySnowPatch = memory.get_node("Environment/ContinuousSnow")
	var trail: PainterlyCurvedPath = memory.get_node("Zones/Hike/Scenery/Trail")
	var camera: Camera3D = world.get_node("CameraRig/Camera3D")
	check(memory.memory_id==&"postcard_cabin" and zones.size()==2,"Winter cabin must have exactly two exterior zones and a stable LAN ID")
	check(player.is_on_floor() and floor.contains_ground_point(player.global_position,0.5)
		and floor.contains_ground_point(player.global_position+Vector3.RIGHT*1.2,0.5),"Both explorers must arrive on supported snow")
	check(world._bounded_memory and not world.get_node("DreamSurface").visible,"The winter memory must use finite ground in the void")
	check(snow.custom_outline==floor.custom_outline,"One continuous snow field must follow the complete forest/clearing floor")
	check(memory.find_children("*","PainterlyTree",true,false).size()>=45,"The hike and clearing must have dense winter tree layers")
	check(memory.find_children("*","PainterlyAdirondackChair",true,false).size()==2,"The clearing must contain two distinct Adirondack chairs")
	check(camera.size<3.7 and zones[0].ambience.playing,"Arrival should be intimate, with the winter wind bed")
	for ice: PainterlyFrozenWater in memory.find_children("*","PainterlyFrozenWater",true,false):
		check(ice._water_material.shader==PainterlyFrozenWater.ICE,"Frozen ponds/streams must use still ice rather than animated water")
		var at := ice.global_position
		if ice.stream_path: at = ice.to_global(ice.stream_path.sample_baked(ice.stream_path.get_baked_length()*0.5,true))
		check(not snow.excludes_ground_point(at),"Snow must cut out the frozen water surface")
	for zone: MemoryZone in zones:
		check(zone.get_fragment()!=null and zone.ambience_stream!=null,"Both exterior zones must own a fragment and ambient bed")
	await capture("arrival")
	check(world.get_node("GuidanceController").request_guidance(),"Requested guidance must follow the snowy trail")
	await walk_trail(player,trail,0.0,memory.hike_fragment_ratio)
	await create_timer(1.0).timeout
	check(camera.size>3.9 and camera.size<4.3,"The frozen-water pause must give a little breathing room")
	check(snow._stamp_count>20,"The snowy hike must record a continuous footprint history")
	await capture("frozen-pond")
	check(zones[0].get_fragment().try_activate(player),"The forest fragment must be reachable from the trail")
	world.get_node("Controls/FragmentInteraction").advance_note()
	await create_timer(0.2).timeout
	check(world.get_node("GuidanceController").request_guidance(),"Guidance must continue along the trail to the fireside")
	await walk_trail(player,trail,memory.hike_fragment_ratio,1.0)
	await create_timer(1.0).timeout
	check(camera.size>5.0 and camera.size<5.4,"The clearing should widen modestly around the cabin and fire")
	check(zones[1].ambience.playing,"The clearing must blend its winter-air/fire bed")
	await capture("clearing")
	for point in [Vector3(4,0,-23.5),Vector3(4,0,-27.8),Vector3(4.8,0,-27.8)]:
		check(await walk_to(player,point),"The clearing must leave an open passage around the chairs and pit")
	var cabin: PainterlyPostcardCabin = zones[1].get_node("Scenery/Cabin")
	var pit: PainterlyFirePit = zones[1].get_node("Scenery/FirePit")
	check(cabin.get_recall_controller().progress>0.99 and pit.get_recall_controller().progress>0.99 and pit.get_node("Fire").get_recall_controller().progress>0.99,"Cabin, pit and nested fire must recall from reachable approaches")
	check(not snow.excludes_ground_point(cabin.global_position) and not snow.excludes_ground_point(pit.global_position),"Snow must exclude the cabin shell, steps and fire bowl")
	await capture("fireside")
	check(zones[1].get_fragment().try_activate(player),"The clearing fragment must be reachable beside the fire")
	world.get_node("Controls/FragmentInteraction").advance_note()
	await create_timer(0.2).timeout
	check(await walk_to(player,Vector3(5.2,0,-27.3)),"The fire bowl must have an open approach")
	driver.axis = Vector2(1,0)
	await create_timer(0.8).timeout
	driver.axis = Vector2.ZERO
	check(player.global_position.x<6.1,"Solid fire-pit collision must keep explorers outside the flames")
	for point in [Vector3(4.8,0,-27.8),Vector3(7,0,-29),Vector3(10.7,0,-29),Vector3(10.7,0,-34.424),cabin.get_anchor(&"Approach").global_position,cabin.get_anchor(&"FrontDoor").global_position]:
		check(await walk_to(player,point),"The cabin exterior and steps must be accessible with the real explorer")
	check(player.global_position.y>0.20,"The cabin's real ramp must lift the explorer onto its exterior steps")
	await capture("cabin")
	driver.axis = Vector2(-1,0)
	await create_timer(0.5).timeout
	driver.axis = Vector2.ZERO
	check(player.global_position.x>8.55,"The closed exterior must stay solid; there is no interior placeholder")
	for point in [cabin.get_anchor(&"Approach").global_position,Vector3(10.7,0,-34.424),Vector3(10.7,0,-29),Vector3(10,0,-24),Vector3(7,0,-23)]:
		check(await walk_to(player,point),"The doorstep and clearing route must work in reverse")
	await walk_trail(player,trail,1.0,0.0)
	await create_timer(1.0).timeout
	check(camera.size<3.7,"Returning through the pines must restore the intimate arrival camera")
	if "--capture" in args:
		var rig: Node3D = world.get_node("CameraRig")
		rig.set_process(false)
		rig.position = Vector3(3,1.5,-13)
		camera.size = 42.0
		for child in world.get_node("Controls").get_children():
			if child is CanvasItem: child.hide()
		await capture("overview")
	world.free()
	await process_frame
	change_scene_to_file("res://UI/memory_lane/memory_lane.tscn")
	await process_frame
	await process_frame
	check(current_scene.MEMORIES[6].date=="FEB 10, 2026" and current_scene.MEMORIES[6].scene==WORLD,"Postcard Cabin must be the dated seventh authored memory")
	MemoryExplorer.preferred_avatar = MemoryExplorer.Avatar.VIVIAN
	current_scene.select_memory(6)
	current_scene.recall()
	while current_scene==null or current_scene.scene_file_path!=WORLD: await process_frame
	if current_scene.has_node("MemoryArrival"): await current_scene.get_node("MemoryArrival").finished
	for frame in 8: await physics_frame
	check(current_scene.get_node("Explorer").avatar==MemoryExplorer.Avatar.VIVIAN and current_scene.get_node("Explorer").is_on_floor(),"Timeline recall must preserve character choice and a safe snowy arrival")
	current_scene.free()
	await create_timer(0.25).timeout
	print("Postcard Cabin memory: ","PASS" if failures==0 else "FAIL")
	quit(failures)

func run_lan(host: bool) -> void:
	var barrier := LanBarrier.new()
	barrier.name = "WinterCabinLanBarrier"
	root.add_child(barrier)
	var avatar := MemoryExplorer.Avatar.VIVIAN if host else MemoryExplorer.Avatar.SOREN
	MemoryExplorer.preferred_avatar = avatar
	var session := root.get_node("LanSession")
	if host: check(session.host(avatar),"The local winter cabin server must listen: %s" % session.status)
	else: session.join("127.0.0.1",avatar)
	var deadline := Time.get_ticks_msec()+30000
	while session.partner_id==0 and Time.get_ticks_msec()<deadline: await process_frame
	check(session.partner_id!=0,"The test clients must pair before recalling the winter cabin")
	if not host:
		while session.partner_memory!="postcard_cabin" and Time.get_ticks_msec()<deadline: await process_frame
	var world := load(WORLD).instantiate() as Node3D
	root.add_child(world)
	current_scene = world
	for frame in 8: await physics_frame
	deadline = Time.get_ticks_msec()+30000
	while Time.get_ticks_msec()<deadline:
		await process_frame
		if session.shares_memory() and world.has_node("Partner") and world.get_node("Partner").visible: break
	check(session.shares_memory() and world.has_node("Partner"),"Matching winter cabin memories must show the partner")
	if world.has_node("Partner"):
		barrier.ready_mark.rpc()
		while not barrier.partner_ready and Time.get_ticks_msec()<deadline: await process_frame
		check(barrier.partner_ready,"Both winter cabin clients must be ready before walking")
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
			check(partner.visible and partner.avatar!=avatar and partner.position.distance_to(initial)>0.25,"Both avatar choices and walking must replicate through the snowy arrival")
			check(player.is_on_floor(),"Both LAN arrivals must remain grounded on the snowy trail")
			barrier.done_mark.rpc()
			while not barrier.partner_done and Time.get_ticks_msec()<deadline: await process_frame
			check(barrier.partner_done,"Both winter cabin clients must finish their movement check")
			await create_timer(0.2).timeout
	session.leave()
	await process_frame
	world.free()
	await create_timer(0.3).timeout
	print("Postcard Cabin LAN ","host" if host else "guest",": ","PASS" if failures==0 else "FAIL")
	quit(failures)
