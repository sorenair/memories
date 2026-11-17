extends SceneTree
## Walk the autumn trail, rock lookout, striped lighthouse shore and quiet garden.
const WORLD := "res://scenes/world/duluth_autumn_world.tscn"
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
			check(player.is_on_floor(),"Duluth autumn route joins must remain supported")
			return true
		driver.axis = offset.normalized()*minf(1.0,offset.length()*1.25)
		await physics_frame
	driver.axis = Vector2.ZERO
	push_error("Duluth autumn walk stopped at %s on the way to %s" % [player.global_position,point])
	return false

func capture(name: String) -> void:
	if not "--capture" in OS.get_cmdline_user_args(): return
	await create_timer(1.3).timeout
	RenderingServer.force_draw(false)
	root.get_texture().get_image().save_png("res://docs/previews/duluth_autumn-memory-"+name+".png")

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
	for i in player.get_slide_collision_count():
		var hit := player.get_slide_collision(i)
		var body := hit.get_collider() as CollisionObject3D
		print("Blocked by ",body.get_path()," ",hit.get_collider_shape()," at ",hit.get_position()," normal ",hit.get_normal())
	check(false,"Explorer stopped on "+str(trail.get_path())+" at "+str(player.global_position)+" heading to "+str(end))
	quit(1)

func read_fragment(world: Node3D,fragment: MemoryFragment) -> void:
	var camera: Camera3D = world.get_node("CameraRig/Camera3D")
	check(world.get_node("InteractionController").pick_interactable(camera.unproject_position(fragment.get_interaction_tap_position()))==fragment,"Each note must be visible and tappable from its walking approach")
	check(fragment.try_activate(world.get_node("Explorer")),"Each autumn memory fragment must be within reach")
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
		print("Duluth autumn views: captured")
		quit()
		return
	var floor: MemoryPlatform = memory.get_node("Environment/AutumnFloor")
	var forest: PainterlyCurvedPath = zones[0].get_node("Scenery/ForestTrail")
	var climb: PainterlyCurvedPath = zones[0].get_node("Scenery/LookoutClimb")
	var to_lake: PainterlyCurvedPath = zones[0].get_node("Scenery/ToLighthouse")
	var shore: PainterlyCurvedPath = zones[1].get_node("Scenery/ShoreWalk")
	var around: PainterlyCurvedPath = zones[1].get_node("Scenery/AroundLighthouse")
	var to_garden: PainterlyCurvedPath = zones[1].get_node("Scenery/ToGarden")
	var garden: PainterlyCurvedPath = zones[2].get_node("Scenery/GardenWalk")
	var circuit: PainterlyCurvedPath = zones[2].get_node("Scenery/GardenCircuit")
	check(zones.size()==3 and memory.memory_id==&"duluth_autumn","Duluth needs three ordered zones and its own shared memory identity")
	check(zones[0].zone_id==&"duluth_fall_trail" and zones[1].zone_id==&"duluth_lighthouse" and zones[2].zone_id==&"duluth_zen_garden","Preserve fall hike, lighthouse and zen garden order")
	check(player.is_on_floor() and floor.contains_ground_point(player.global_position+Vector3.RIGHT*1.2,.5),"Both explorers need supported, clear arrival space")
	check(camera.size<4.0,"The autumn forest arrival should start close")
	for path in [forest,climb,to_lake,shore,around,to_garden,garden,circuit]:
		for i in 81:
			check(floor.contains_ground_point(path.to_global(path.point_at(path.get_path_length()*i/80.0)),.3),"Every authored path must fit the finite floor: "+path.name)
	check(world.get_node("GuidanceController").request_guidance(),"The first requested hint must wind through the fall trail and climb onto the rock")
	await capture("forest-arrival")
	await walk_trail(player,forest,0,1)
	await create_timer(1.5).timeout
	check(zones[0].ambience.playing and camera.size<4.0,"The short autumn hike should keep a close view and its wind bed")
	await capture("fall-trail")
	await walk_trail(player,climb,0,1)
	await create_timer(3.0).timeout
	check(player.global_position.y>2.35 and player.global_position.y<2.55,"The real explorer must reach the supported rock landing")
	check(camera.size>13.6 and camera.size<14.3,"The rock lookout should open a controlled autumn panorama")
	check(zones[0].get_node("Scenery/AutumnVista0").get_recall_controller().progress>.99,"The distant fall crowns must recall from the reachable lookout")
	await capture("rock-lookout")
	await read_fragment(world,zones[0].get_fragment())
	check(world.get_node("GuidanceController").request_guidance(),"The second hint must descend from the rock to the lighthouse shore")
	await walk_trail(player,to_lake,0,1)
	await walk_trail(player,shore,0,1)
	await create_timer(4.0).timeout
	var tower: PainterlyLighthouse = zones[1].get_node("Scenery/Lighthouse")
	var water: PainterlyWater = zones[1].get_node("Scenery/LakeSuperior")
	check(tower.stripes_enabled and tower.stripe_count==6,"The lakeshore lighthouse must carry alternating red-and-white bands")
	check(tower.get_recall_controller().progress>.99 and water.get_recall_controller().progress>.99,"The tower and open lake must recall from the reachable shore")
	check(camera.size>17.5 and camera.size<18.3 and zones[1].ambience.playing,"The lighthouse shore needs a wider tower view and quiet waves")
	for point: Vector3 in [tower.global_position,tower.get_anchor(&"Roof").global_position]:
		var screen := camera.unproject_position(point)
		check(camera.is_position_in_frustum(point) and screen.y>16 and screen.y<root.get_visible_rect().size.y-16,"The full lighthouse should fit the actual shore framing")
	await capture("striped-lighthouse")
	await read_fragment(world,zones[1].get_fragment())
	check(world.get_node("GuidanceController").request_guidance(),"The final hint must pass around the tower and enter the quiet garden")
	await walk_trail(player,around,0,1)
	await walk_trail(player,to_garden,0,1)
	await walk_trail(player,garden,0,1)
	await create_timer(3.0).timeout
	check(camera.size>9.6 and camera.size<10.3 and zones[2].ambience.playing,"The garden should have intimate fixed framing and its own ambient bed")
	for name in ["RakedGravel","StoneLantern","GardenStone0","GardenStone1","GardenStone2"]:
		check(zones[2].get_node("Scenery/"+name).get_recall_controller().progress>.99,"The whole garden arrangement must recall from the entrance: "+name)
	await capture("zen-garden")
	await read_fragment(world,zones[2].get_fragment())
	check(world.get_node("GuidanceController").get_next_fragment()==null,"All three notes should finish without automatic hints")
	# Split the closed curve at its midpoint so both halves actually get walked.
	await walk_trail(player,circuit,0,.5)
	await walk_trail(player,circuit,.5,1)
	await walk_trail(player,circuit,1,.5)
	await walk_trail(player,circuit,.5,0)
	await walk_trail(player,garden,1,0)
	await walk_trail(player,to_garden,1,0)
	await walk_trail(player,around,1,0)
	await walk_trail(player,shore,1,0)
	await walk_trail(player,to_lake,1,0)
	await walk_trail(player,climb,1,0)
	await walk_trail(player,forest,1,0)
	await create_timer(2.0).timeout
	check(camera.size<4.0 and player.is_on_floor(),"Returning to the trail arrival must restore close, grounded exploration")
	if "--capture" in args: await capture_views(world,memory,camera)
	world.free()
	await process_frame
	change_scene_to_file("res://UI/memory_lane/memory_lane.tscn")
	await process_frame
	await process_frame
	check(current_scene.MEMORIES[17].date=="OCT 12, 2026" and current_scene.MEMORIES[17].scene==WORLD,"Duluth must follow Colorado on October 12")
	MemoryExplorer.preferred_avatar = MemoryExplorer.Avatar.VIVIAN
	current_scene.select_memory(17)
	current_scene.recall()
	while current_scene==null or current_scene.scene_file_path!=WORLD: await process_frame
	if current_scene.has_node("MemoryArrival"): await current_scene.get_node("MemoryArrival").finished
	for frame in 12: await physics_frame
	check(current_scene.get_node("Explorer").avatar==MemoryExplorer.Avatar.VIVIAN and current_scene.get_node("Explorer").is_on_floor(),"Timeline recall must preserve avatar choice and grounded forest arrival")
	current_scene.free()
	await create_timer(.25).timeout
	print("Duluth autumn memory: ","PASS" if failures==0 else "FAIL")
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
	var names := ["trail-overview","lighthouse-overview","garden-overview","overview"]
	var views := [Vector4(1,2,9,31),Vector4(30,2,-12,32),Vector4(54,1,-36,24),Vector4(25,3,-10,78)]
	for i in views.size():
		var view: Vector4 = views[i]
		rig.position = Vector3(view.x,view.y,view.z)
		camera.size = view.w
		await capture(names[i])

func run_lan(host: bool) -> void:
	var barrier := LanBarrier.new()
	barrier.name = "DuluthAutumnLanBarrier"
	root.add_child(barrier)
	var avatar := MemoryExplorer.Avatar.VIVIAN if host else MemoryExplorer.Avatar.SOREN
	MemoryExplorer.preferred_avatar = avatar
	var session := root.get_node("LanSession")
	var peer := ENetMultiplayerPeer.new()
	var error := peer.create_server(24785,1) if host else peer.create_client("127.0.0.1",24785)
	check(error==OK,"The isolated duluth_autumn test transport must open")
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
	check(session.partner_id!=0,"The test clients must pair before recalling the duluth_autumn")
	if not host:
		while session.partner_memory!="duluth_autumn" and Time.get_ticks_msec()<deadline: await process_frame
	var world := load(WORLD).instantiate() as Node3D
	root.add_child(world)
	current_scene = world
	for frame in 8: await physics_frame
	deadline = Time.get_ticks_msec()+30000
	while Time.get_ticks_msec()<deadline:
		await process_frame
		if session.shares_memory() and world.has_node("Partner") and world.get_node("Partner").visible: break
	check(session.shares_memory() and world.has_node("Partner"),"Matching duluth_autumn memories must show the partner")
	if world.has_node("Partner"):
		barrier.ready_mark.rpc()
		while not barrier.partner_ready and Time.get_ticks_msec()<deadline: await process_frame
		check(barrier.partner_ready,"Both duluth_autumn clients must be ready before walking")
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
			check(partner.visible and partner.avatar!=avatar and partner.position.distance_to(initial)>0.25,"Both avatar choices and walking must replicate through the duluth_autumn arrival")
			check(player.is_on_floor(),"Both LAN arrivals must remain grounded on the duluth_autumn path")
			barrier.done_mark.rpc()
			while not barrier.partner_done and Time.get_ticks_msec()<deadline: await process_frame
			check(barrier.partner_done,"Both duluth_autumn clients must finish their movement check")
			await create_timer(0.2).timeout
	session.leave()
	await process_frame
	world.free()
	await create_timer(0.3).timeout
	print("Duluth autumn LAN ","host" if host else "guest",": ","PASS" if failures==0 else "FAIL")
	quit(failures)
