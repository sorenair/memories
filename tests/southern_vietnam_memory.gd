extends SceneTree
## Walk the cove, lighthouse cliff, real dunes and crowded city promenade.
const WORLD := "res://scenes/world/southern_vietnam_world.tscn"
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
			check(player.is_on_floor(),"Southern Vietnam route joins must remain supported")
			return true
		driver.axis = offset.normalized()*minf(1.0,offset.length()*1.25)
		await physics_frame
	driver.axis = Vector2.ZERO
	push_error("Southern Vietnam walk stopped at %s on the way to %s" % [player.global_position,point])
	return false

func capture(name: String) -> void:
	if not "--capture" in OS.get_cmdline_user_args(): return
	await create_timer(1.3).timeout
	RenderingServer.force_draw(false)
	root.get_texture().get_image().save_png("res://docs/previews/southern_vietnam-memory-"+name+".png")

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
	check(fragment.try_activate(world.get_node("Explorer")),"Each lighthouse, dune and city fragment must be within reach")
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
		print("Southern Vietnam views: captured")
		quit()
		return
	var floor: MemoryPlatform = memory.get_node("Environment/VietnamFloor")
	var beach_sand: PainterlySandPatch = zones[0].get_node("Scenery/CrescentSand")
	var shore: PainterlyCurvedPath = zones[0].get_node("Scenery/BeachRoute")
	var climb: PainterlyCurvedPath = zones[0].get_node("Scenery/HeadlandWalk")
	var to_dunes: PainterlyCurvedPath = zones[0].get_node("Scenery/ToDunes")
	var dune_sand: PainterlySandPatch = zones[1].get_node("Scenery/DuneSand")
	var dunes: PainterlyCurvedPath = zones[1].get_node("Scenery/DuneRoute")
	var to_city: PainterlyCurvedPath = zones[1].get_node("Scenery/ToSaigon")
	var city: PainterlyCurvedPath = zones[2].get_node("Scenery/CityRoute")
	var boat: Node3D = zones[0].get_node("Scenery/CoveFishingBoat")
	check(zones.size()==3 and memory.memory_id==&"southern_vietnam","Three ordered zones need a separate shared memory ID")
	check(zones[0].zone_id==&"bai_mon" and zones[1].zone_id==&"sand_dunes" and zones[2].zone_id==&"saigon","The final Vietnam memory must preserve cove, dunes and city order")
	check(player.is_on_floor() and floor.contains_ground_point(player.global_position+Vector3.RIGHT*1.2,0.5),"Both arrivals must fit the supported crescent beach")
	check(absf(camera.size - 4.7) < 0.15,"The beach arrival should begin at the walking zoom")
	for trail in [shore,climb,to_dunes,dunes,to_city,city]:
		for index in 81:
			check(floor.contains_ground_point(trail.to_global(trail.point_at(trail.get_path_length()*index/80.0)),0.3),"Every authored path must fit inside the finite floor: "+trail.name)
	check(world.get_node("GuidanceController").request_guidance(),"The first requested hint must follow the beach and climb to the lighthouse")
	await capture("cove-arrival")
	await walk_trail(player,shore,0,0.5)
	await create_timer(2.0).timeout
	check(absf(camera.size - 10.0) < 0.15,"The cove's middle should open a controlled sea view")
	check(beach_sand._stamp_count>0 and zones[0].ambience.playing,"The beach needs real footsteps and quiet surf")
	check(boat.bob_amount > 0.0 and camera.is_position_in_frustum(boat.global_position),"The bobbing fishing boat should be visible from the beach")
	check(boat.get_recall_controller().progress > 0.99,"The boat should recall from the beach route")
	await capture("cove-shore")
	await walk_trail(player,shore,0.5,1)
	var headland: PainterlyCoastalHeadland = zones[0].get_node("Scenery/Headland")
	check(headland.ridge_routes.size() == 2 and not headland._ridge_faces.is_empty(),"Both coastal paths must sit on faceted rock shoulders")
	await walk_trail(player,climb,0,0.55)
	await capture("headland-ascent")
	await walk_trail(player,climb,0.55,1)
	await create_timer(2.5).timeout
	check(player.global_position.y>3.15 and player.global_position.y<3.4,"The actual explorer must climb onto the supported cliff")
	check(absf(camera.size - 17.2) < 0.15,"The cliff landing must reveal the existing lighthouse")
	check(zones[0].get_node("Scenery/Lighthouse").get_recall_controller().progress>0.99,"The lighthouse must recall from the reachable low beach approach")
	check(camera.is_position_in_frustum(boat.global_position),"The fishing boat should also be visible from the lighthouse")
	var ground_bird: PainterlyBird = zones[0].get_node("Scenery/LighthouseGroundBird1")
	var orbiting_bird: PainterlyBird = zones[0].get_node("Scenery/LighthouseCirclingBird1")
	check(ground_bird.palette_preset == 5 and ground_bird.state != PainterlyBird.State.IDLE,"A white ground bird should take flight when approached")
	check(orbiting_bird.palette_preset == 5 and orbiting_bird.state == PainterlyBird.State.CIRCLING,"White birds should circle above the lighthouse")
	await capture("lighthouse-overlook")
	await read_fragment(world,zones[0].get_fragment())
	check(world.get_node("GuidanceController").request_guidance(),"The second hint must descend from the headland and enter the dunes")
	await walk_trail(player,to_dunes,0,0.72)
	await capture("headland-descent")
	await walk_trail(player,to_dunes,0.72,1)
	var distance := dunes.curve.get_closest_offset(dunes.to_local(zones[1].get_fragment().global_position))
	var ratio := distance/dunes.get_path_length()
	var heights := PackedFloat32Array()
	for fraction in [0.21, 0.35, 0.49, 0.63, 0.82]:
		var at := dunes.to_global(dunes.point_at(dunes.get_path_length() * fraction))
		heights.append(dune_sand.get_surface_height(at))
	check(heights[0] - heights[1] > 1.1 and heights[2] - heights[1] > 1.6,"The actual terrain should rise out of the first swale on both sides")
	check(heights[2] - heights[3] > 1.6 and heights[4] - heights[3] > 1.1,"The second swale should lie between two distinct crests")
	await walk_trail(player,dunes,0,0.35)
	await capture("dune-swale")
	await walk_trail(player,dunes,0.35,ratio)
	await create_timer(2.5).timeout
	check(absf(player.global_position.y-dune_sand.get_surface_height(player.global_position))<0.10,"The dune path must follow the actual sculpted terrain")
	check(player.global_position.y>0.2 and dune_sand._stamp_count>0,"The dunes must have real relief and new footprints")
	check(absf(camera.size - 12.4) < 0.15 and zones[1].ambience.playing,"The dune fragment should have its own reveal and ambient bed")
	await capture("dunes-walk")
	await read_fragment(world,zones[1].get_fragment())
	check(world.get_node("GuidanceController").request_guidance(),"The final requested hint must lead from the dunes into the city crowd")
	await walk_trail(player,dunes,ratio,1)
	await walk_trail(player,to_city,0,1)
	await create_timer(2.5).timeout
	check(absf(camera.size - 4.7) < 0.15 and zones[2].ambience.playing,"City arrival should keep the walking zoom while its crowd bed blends in")
	await capture("saigon-arrival")
	var city_center := city.curve.get_closest_offset(Vector3(2.4, 0, 2)) / city.get_path_length()
	await walk_trail(player,city,0,city_center)
	await create_timer(2.4).timeout
	check(absf(camera.size - 13.9) < 0.15,"The boulevard should open up from within the crowd")
	var monument: PainterlyConcertComponent = zones[2].get_node("Scenery/HoChiMinhMonument")
	var flagpole: PainterlyConcertComponent = zones[2].get_node("Scenery/VietnamFlagpole")
	for landmark in [monument, flagpole]:
		check(landmark.get_recall_controller().progress > 0.99,"Both monuments should recall along the promenade approach")
		check(not landmark.excludes_ground_point(player.global_position),"The promenade bypass must stay clear of the pedestal and pole")
	check(camera.is_position_in_frustum(monument.get_anchor(&"Crown").global_position),"The street reveal must include the statue")
	check(camera.is_position_in_frustum(flagpole.get_anchor(&"Flag").global_position),"The street reveal must include the flag between the towers")
	for name in ["AvenueCrowd", "NorthGathering"]:
		var crowd: PainterlyCrowd = zones[2].get_node("Scenery/" + name)
		for pose in crowd._placements:
			var at := crowd.to_global(pose.origin)
			check(not monument.excludes_ground_point(at) and not flagpole.excludes_ground_point(at),
				"Crowd placement must leave the monuments' bases clear")
	await capture("saigon-center")
	await walk_trail(player,city,city_center,1)
	await create_timer(2.0).timeout
	for name in ["LotusTower","SpireTower"]:
		check(zones[2].get_node("Scenery/"+name).get_recall_controller().progress>0.99,"The skyline should recall from the accessible promenade")
	await capture("saigon-promenade")
	await read_fragment(world,zones[2].get_fragment())
	check(world.get_node("GuidanceController").get_next_fragment()==null,"All three notes should finish without automatic hints")
	await walk_trail(player,city,1,0)
	await walk_trail(player,to_city,1,0)
	await walk_trail(player,dunes,1,0)
	await walk_trail(player,to_dunes,1,0)
	await walk_trail(player,climb,1,0)
	await walk_trail(player,shore,1,0)
	await create_timer(2.0).timeout
	check(absf(camera.size - 4.7) < 0.15,"Returning to the cove arrival must restore close framing")
	if "--capture" in args: await capture_views(world,memory,camera)
	world.free()
	await process_frame
	change_scene_to_file("res://UI/memory_lane/memory_lane.tscn")
	await process_frame
	await process_frame
	check(current_scene.MEMORIES[12].date=="JUN 20, 2026" and current_scene.MEMORIES[12].scene==WORLD,"Southern Vietnam must follow Central Vietnam on June 20")
	MemoryExplorer.preferred_avatar = MemoryExplorer.Avatar.VIVIAN
	current_scene.select_memory(12)
	current_scene.recall()
	while current_scene==null or current_scene.scene_file_path!=WORLD: await process_frame
	if current_scene.has_node("MemoryArrival"): await current_scene.get_node("MemoryArrival").finished
	for frame in 12: await physics_frame
	check(current_scene.get_node("Explorer").avatar==MemoryExplorer.Avatar.VIVIAN and current_scene.get_node("Explorer").is_on_floor(),"Timeline recall must retain avatar choice and grounded sand arrival")
	current_scene.free()
	await create_timer(0.25).timeout
	print("Southern Vietnam memory: ","PASS" if failures==0 else "FAIL")
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
	var names := ["bai-mon-overview","dunes-overview","saigon-overview","overview"]
	var views := [Vector4(2,3,10,35),Vector4(40,2,-23,29),Vector4(67,10,-61,42),Vector4(34,4,-20,90)]
	for index in views.size():
		var view: Vector4 = views[index]
		rig.position = Vector3(view.x,view.y,view.z)
		camera.size = view.w
		await capture(names[index])

func run_lan(host: bool) -> void:
	var barrier := LanBarrier.new()
	barrier.name = "Southern VietnamLanBarrier"
	root.add_child(barrier)
	var avatar := MemoryExplorer.Avatar.VIVIAN if host else MemoryExplorer.Avatar.SOREN
	MemoryExplorer.preferred_avatar = avatar
	var session := root.get_node("LanSession")
	var peer := ENetMultiplayerPeer.new()
	var error := peer.create_server(24755,1) if host else peer.create_client("127.0.0.1",24755)
	check(error==OK,"The isolated southern_vietnam test transport must open")
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
	check(session.partner_id!=0,"The test clients must pair before recalling the southern_vietnam")
	if not host:
		while session.partner_memory!="southern_vietnam" and Time.get_ticks_msec()<deadline: await process_frame
	var world := load(WORLD).instantiate() as Node3D
	root.add_child(world)
	current_scene = world
	for frame in 8: await physics_frame
	deadline = Time.get_ticks_msec()+30000
	while Time.get_ticks_msec()<deadline:
		await process_frame
		if session.shares_memory() and world.has_node("Partner") and world.get_node("Partner").visible: break
	check(session.shares_memory() and world.has_node("Partner"),"Matching southern_vietnam memories must show the partner")
	if world.has_node("Partner"):
		barrier.ready_mark.rpc()
		while not barrier.partner_ready and Time.get_ticks_msec()<deadline: await process_frame
		check(barrier.partner_ready,"Both southern_vietnam clients must be ready before walking")
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
			check(partner.visible and partner.avatar!=avatar and partner.position.distance_to(initial)>0.25,"Both avatar choices and walking must replicate through the southern_vietnam arrival")
			check(player.is_on_floor(),"Both LAN arrivals must remain grounded on the southern_vietnam path")
			barrier.done_mark.rpc()
			while not barrier.partner_done and Time.get_ticks_msec()<deadline: await process_frame
			check(barrier.partner_done,"Both southern_vietnam clients must finish their movement check")
			await create_timer(0.2).timeout
	session.leave()
	await process_frame
	world.free()
	await create_timer(0.3).timeout
	print("Southern Vietnam LAN ","host" if host else "guest",": ","PASS" if failures==0 else "FAIL")
	quit(failures)
