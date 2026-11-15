extends SceneTree
## Exercise the populated block, cross-passages, porches, fragment and timeline.
const WORLD := "res://scenes/world/mifflin_world.tscn"
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
			check(player.is_on_floor(),"Every route join must remain supported")
			return true
		driver.axis = offset.normalized()*minf(1.0,offset.length()*1.25)
		await physics_frame
	driver.axis = Vector2.ZERO
	push_error("Mifflin walk stopped at %s on the way to %s" % [player.global_position,point])
	return false

func capture(name: String) -> void:
	if not "--capture" in OS.get_cmdline_user_args(): return
	await create_timer(1.3).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/previews/mifflin-"+name+".png")

func walk_path(player: MemoryExplorer,path: PainterlyCurvedPath,from: float,to: float) -> bool:
	var length := path.get_path_length()
	var end := path.to_global(path.point_at(length*to))
	var direction := signf(to-from)
	for frame in 2400:
		var local := path.to_local(player.global_position)
		var distance := path.curve.get_closest_offset(local)
		var remaining := Vector2(end.x-player.global_position.x,end.z-player.global_position.z)
		if remaining.length()<0.09:
			driver.axis = Vector2.ZERO
			for settle in 8: await physics_frame
			check(player.is_on_floor(),"The weave must remain on supported street ground")
			return true
		var next := clampf(distance+direction*0.55,minf(from,to)*length,maxf(from,to)*length)
		var target := path.to_global(path.point_at(next))
		var offset := Vector2(target.x-player.global_position.x,target.z-player.global_position.z)
		driver.axis = offset.normalized()*minf(1.0,remaining.length()*1.25)
		await physics_frame
	driver.axis = Vector2.ZERO
	push_error("Crowd weave stopped at %s" % player.global_position)
	return false

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
	var floor: MemoryPlatform = memory.get_node("Environment/BlockFloor")
	var scenery := zones[0].get_node("Scenery")
	var camera: Camera3D = world.get_node("CameraRig/Camera3D")
	var street: PainterlyStreet = memory.get_node("Environment/Street")
	var weave: PainterlyCurvedPath = memory.get_node("Environment/StreetWeave")
	var branch: PainterlyCurvedPath = memory.get_node("Environment/PorchWeave")
	var split: float = memory.porch_branch_ratio()
	check(memory.memory_id==&"mifflin" and zones.size()==2 and zones[1].zone_id==&"bar","Mifflin must contain the street and bar as two standard zones")
	check(world._bounded_memory and player.is_on_floor() and floor.contains_ground_point(player.global_position+Vector3.RIGHT*1.2,0.5),"Both explorers must arrive safely on finite ground")
	check(street.length==42 and street.width==9.4 and not street.has_node("PaintedSlabs"),"The road must use the continuous configurable street component")
	check(camera.size<3.7 and memory.get_audio().music.playing and zones[0].ambience.playing,"Arrival stays close with music and outdoor crowd ambience")
	var people := 0
	for crowd: PainterlyCrowd in memory.find_children("*","PainterlyCrowd",true,false):
		check(crowd.generated_count==crowd.count,"All authored people must fit: "+str(crowd.name)+" "+str(crowd.generated_count))
		people += crowd.generated_count
		for pose: Transform3D in crowd._placements:
			check(floor.contains_ground_point(crowd.to_global(pose.origin),0.12),"All guests must stand within memory ground")
	var crowd: PainterlyCrowd = scenery.get_node("StreetGathering")
	var middle := 0
	for pose: Transform3D in crowd._placements:
		var at := crowd.to_global(pose.origin)
		if absf(at.x)<1.5: middle += 1
		check(not weave.excludes_ground_point(at) and not branch.excludes_ground_point(at),"Narrow winding gaps must remain between crowd capsules")
	check(people>=260 and middle>=25 and crowd.collision_enabled,"The street center must be populated and solid, with people to wade around")
	var house: PainterlyNeighborhoodHouse = scenery.get_node("West2")
	for name in ["PorchSpeaker1","PorchSpeaker2"]:
		var speaker = scenery.get_node(name)
		var visual: MeshInstance3D = speaker._generated_root.get_node("PaintedProp")
		var bounds: AABB = house.global_transform.affine_inverse()*visual.global_transform*visual.mesh.get_aabb()
		check(bounds.position.z>house.footprint.y*0.5+0.12 and bounds.end.z<house.footprint.y*0.5+house.porch_depth-0.18,"Speaker cabinets must clear the house wall and front guardrail")
		check(absf(bounds.position.x)<house.footprint.x*0.45-0.1 and absf(bounds.end.x)<house.footprint.x*0.45-0.1,"Speaker cabinets must clear side railings")
	await capture("arrival")
	check(world.get_node("GuidanceController").request_guidance(),"Guidance must follow the winding gaps to the first fragment")
	check(await walk_path(player,weave,0,split),"The actual explorer must weave through the central crowd")
	await capture("street")
	check(await walk_path(player,branch,0,1),"The porch branch must wind past guests safely")
	await create_timer(1.0).timeout
	var fragment := zones[0].get_fragment()
	check(world.get_node("InteractionController").pick_interactable(camera.unproject_position(fragment.get_interaction_tap_position()))==fragment,"The porch note must remain directly tappable")
	check(fragment.try_activate(player),"The street fragment must activate")
	world.get_node("Controls/FragmentInteraction").advance_note()
	await create_timer(0.25).timeout
	for point in [house.get_node("Approach").global_position,house.get_node("FrontDoor").global_position]:
		check(await walk_to(player,point),"The porch stairs must remain reachable around the relocated speakers")
	check(player.global_position.y>0.32,"The explorer must climb the porch ramp")
	await capture("porch")
	check(await walk_to(player,house.get_node("Approach").global_position),"The porch must work in reverse")
	check(await walk_to(player,fragment.global_position),"The fragment approach must remain supported")
	check(world.get_node("GuidanceController").request_guidance(),"After the street note, guidance must continue into the bar")
	check(await walk_path(player,branch,1,0) and await walk_path(player,weave,split,1),"The rest of the street weave must lead toward the bar")
	for point in [Vector3(0,0,-24.5),Vector3(0,0,-27.2),Vector3(2.4,0,-28.8),Vector3(2.4,0,-30.1)]:
		check(await walk_to(player,point),"The same finite floor must connect into the bar without a rim or step snag")
	await create_timer(2.0).timeout
	check(camera.size>4.2 and camera.size<4.6,"The bar must keep an intimate camera")
	check(zones[1].ambience.playing and zones[0]._gain<0.05,"Street noise must blend into the bar room bed")
	var pool: PainterlyPoolTable = zones[1].get_node("Scenery/PoolTable")
	var jukebox: PainterlyJukebox = zones[1].get_node("Scenery/Jukebox")
	var counter: PainterlyBarCounter = zones[1].get_node("Scenery/BarCounter")
	check(zones[1].get_node("Scenery").get_child_count()==3,"The open bar should contain only pool, jukebox, and counter with stools")
	check(pool.recall_enabled and jukebox.recall_enabled and jukebox._screen_material!=null,"The bar must use the existing recallable pool table and animated jukebox")
	check(jukebox.get_recall_controller().progress>0.99,"The jukebox must be revealed beside the pool table on arrival")
	check(zones[1].get_fragment().try_activate(player),"The second fragment must be reachable inside the bar")
	world.get_node("Controls/FragmentInteraction").advance_note()
	await create_timer(0.25).timeout
	await capture("bar")
	for point in [Vector3(2.4,0,-28.8),Vector3(0.2,0,-28.8),pool.get_anchor(&"Play").global_position]:
		check(await walk_to(player,point),"The pool table must have a clear playable approach")
	var before: Vector2 = pool._shown_positions[0]
	check(pool.try_activate(player),"Pool must be playable through the shared interaction contract")
	await create_timer(0.9).timeout
	check(not pool._shown_positions[0].is_equal_approx(before),"The reused table must actually animate its break in this memory")
	await capture("pool")
	for point in [Vector3(-0.95,0,-29.1),Vector3(-1.25,0,-30.9),Vector3(-1.25,0,-33.0),Vector3(-1.25,0,-31.7)]:
		check(await walk_to(player,point),"Open ground between the pool table and stools must remain traversable")
	driver.axis = Vector2.LEFT
	await create_timer(0.6).timeout
	driver.axis = Vector2.ZERO
	check(player.global_position.x>-1.68,"The bar stools must retain solid collision")
	check(await walk_to(player,Vector3(-0.95,0,-29.1)),"The stool approach must remain open in reverse")
	for point in [Vector3(0.2,0,-28.8),Vector3(0,0,-27.2),Vector3(0,0,-24.5),Vector3(0,0,-22)]:
		check(await walk_to(player,point),"The bar exit must return smoothly to the street")
	check(await walk_path(player,weave,1,0),"The populated street must remain traversable back to arrival")
	await create_timer(1.0).timeout
	check(camera.size<3.7,"Returning to entry must restore the close camera")
	if "--capture" in args:
		for prop in memory.find_children("*","Node3D",true,false):
			if prop.has_method("get_recall_controller"):
				var effect: Node = prop.get_recall_controller()
				if effect: effect.seek(1.0)
		var rig: Node3D = world.get_node("CameraRig")
		rig.set_process(false)
		rig.position = Vector3(0,1.5,-6)
		camera.size = 46.0
		for child in world.get_node("Controls").get_children():
			if child is CanvasItem: child.hide()
		await capture("overview")
	world.free()
	await process_frame
	change_scene_to_file("res://UI/memory_lane/memory_lane.tscn")
	await process_frame
	await process_frame
	MemoryExplorer.preferred_avatar = MemoryExplorer.Avatar.VIVIAN
	current_scene.select_memory(7)
	current_scene.recall()
	while current_scene==null or current_scene.scene_file_path!=WORLD: await process_frame
	if current_scene.has_node("MemoryArrival"): await current_scene.get_node("MemoryArrival").finished
	for frame in 8: await physics_frame
	check(current_scene.get_node("Explorer").avatar==MemoryExplorer.Avatar.VIVIAN and current_scene.get_node("Explorer").is_on_floor(),"Timeline recall must preserve avatar selection and safe arrival")
	current_scene.free()
	await create_timer(0.25).timeout
	print("Mifflin memory: ","PASS" if failures==0 else "FAIL")
	quit(failures)

func run_lan(host: bool) -> void:
	var barrier := LanBarrier.new()
	barrier.name = "MifflinLanBarrier"
	root.add_child(barrier)
	var avatar := MemoryExplorer.Avatar.VIVIAN if host else MemoryExplorer.Avatar.SOREN
	MemoryExplorer.preferred_avatar = avatar
	var session := root.get_node("LanSession")
	# Isolate this world/replication check from a concurrently open game on 24680.
	# Production host/join controls are covered by tests/lan_multiplayer.gd.
	var peer := ENetMultiplayerPeer.new()
	var error := peer.create_server(24695,1) if host else peer.create_client("127.0.0.1",24695)
	check(error==OK,"The isolated Mifflin test transport must open")
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
	check(session.partner_id!=0,"The test clients must pair before recalling the Mifflin")
	if not host:
		while session.partner_memory!="mifflin" and Time.get_ticks_msec()<deadline: await process_frame
	var world := load(WORLD).instantiate() as Node3D
	root.add_child(world)
	current_scene = world
	for frame in 8: await physics_frame
	deadline = Time.get_ticks_msec()+30000
	while Time.get_ticks_msec()<deadline:
		await process_frame
		if session.shares_memory() and world.has_node("Partner") and world.get_node("Partner").visible: break
	check(session.shares_memory() and world.has_node("Partner"),"Matching Mifflin memories must show the partner")
	if world.has_node("Partner"):
		barrier.ready_mark.rpc()
		while not barrier.partner_ready and Time.get_ticks_msec()<deadline: await process_frame
		check(barrier.partner_ready,"Both Mifflin clients must be ready before walking")
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
			check(partner.visible and partner.avatar!=avatar and partner.position.distance_to(initial)>0.25,"Both avatar choices and walking must replicate through the street arrival")
			check(player.is_on_floor(),"Both LAN arrivals must remain grounded on the street")
			barrier.done_mark.rpc()
			while not barrier.partner_done and Time.get_ticks_msec()<deadline: await process_frame
			check(barrier.partner_done,"Both Mifflin clients must finish their movement check")
			await create_timer(0.2).timeout
	session.leave()
	await process_frame
	world.free()
	await create_timer(0.3).timeout
	print("Mifflin LAN ","host" if host else "guest",": ","PASS" if failures==0 else "FAIL")
	quit(failures)
