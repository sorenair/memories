extends SceneTree
## Walk the Flatirons meadow, Quandary summit and elk lake shore.
const WORLD := "res://scenes/world/colorado_world.tscn"
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
			check(player.is_on_floor(),"Colorado route joins must remain supported")
			return true
		driver.axis = offset.normalized()*minf(1.0,offset.length()*1.25)
		await physics_frame
	driver.axis = Vector2.ZERO
	push_error("Colorado walk stopped at %s on the way to %s" % [player.global_position,point])
	return false

func capture(name: String) -> void:
	if not "--capture" in OS.get_cmdline_user_args(): return
	await create_timer(1.3).timeout
	RenderingServer.force_draw(false)
	root.get_texture().get_image().save_png("res://docs/previews/colorado-memory-"+name+".png")

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

func check_passing_space(player: MemoryExplorer, trail: PainterlyCurvedPath, terrain: Node3D = null) -> void:
	var space := player.get_world_3d().direct_space_state
	var length := trail.get_path_length()
	for i in range(1, 48):
		var distance := length * i / 48.0
		var center := trail.to_global(trail.point_at(distance))
		var tangent := trail.to_global(trail.point_at(distance + 0.15)) - center
		var shoulder := tangent.cross(Vector3.UP).normalized() * 0.63
		for lane in [-1.0, 1.0]:
			var at := center + shoulder * float(lane)
			var ray := PhysicsRayQueryParameters3D.create(at + Vector3.UP * 0.35, at - Vector3.UP * 0.28)
			ray.exclude = [player.get_rid()]
			var ground := space.intersect_ray(ray)
			check(not ground.is_empty() and ground.normal.y > 0.68,
				"Both walking lanes need support on %s near %.1f m" % [trail.name, distance])
			if terrain and center.y > 0.45 and not ground.is_empty():
				check(terrain.is_ancestor_of(ground.collider), "The elevated climb and descent must stand on the rock surface itself")

func read_fragment(world: Node3D,fragment: MemoryFragment) -> void:
	var camera: Camera3D = world.get_node("CameraRig/Camera3D")
	check(world.get_node("InteractionController").pick_interactable(camera.unproject_position(fragment.get_interaction_tap_position()))==fragment,"Each note must be visible and tappable from its walking approach")
	check(fragment.try_activate(world.get_node("Explorer")),"Each Colorado memory fragment must be within reach")
	world.get_node("Controls/FragmentInteraction").advance_note()
	await create_timer(0.3).timeout

func run() -> void:
	var args := OS.get_cmdline_user_args()
	if "host" in args or "guest" in args:
		await run_lan("host" in args)
		return
	root.content_scale_size=Vector2i(1600,900)
	var world := load(WORLD).instantiate() as Node3D
	root.add_child(world)
	current_scene=world
	var player: MemoryExplorer=world.get_node("Explorer")
	driver=WalkingInput.new()
	world.add_child(driver)
	player.movement_camera=null
	player.movement_input=driver
	world.get_node("Controls/FPSLabel").hide()
	for frame in 12: await physics_frame
	var memory: MemoryScene=world.get_node("Memory")
	var zones:=memory.get_zones()
	var camera: Camera3D=world.get_node("CameraRig/Camera3D")
	if "--views-only" in args:
		await capture_views(world,memory,camera)
		world.free()
		print("Colorado views: captured")
		quit()
		return
	var floor: MemoryPlatform=memory.get_node("Environment/ColoradoFloor")
	var field: PainterlyCurvedPath=zones[0].get_node("Scenery/FieldWalk")
	var to_summit: PainterlyCurvedPath=zones[0].get_node("Scenery/ToSummit")
	var climb: PainterlyCurvedPath=zones[1].get_node("Scenery/SummitClimb")
	var descent: PainterlyCurvedPath=zones[1].get_node("Scenery/ToLake")
	var terrain: Node3D=zones[1].get_node("Scenery/QuandaryTerrain")
	var lake_walk: PainterlyCurvedPath=zones[2].get_node("Scenery/LakeshoreWalk")
	check(zones.size()==3 and memory.memory_id==&"colorado","Colorado needs three ordered zones and its own LAN identity")
	check(zones[0].zone_id==&"colorado_flatirons" and zones[1].zone_id==&"colorado_quandary" and zones[2].zone_id==&"colorado_rmnp","Preserve Flatirons, Quandary and national-park lake order")
	check(player.is_on_floor() and floor.contains_ground_point(player.global_position+Vector3.RIGHT*1.2,.5),"Both arrivals must fit the clear golden-field approach")
	check(camera.size<4.0,"The meadow arrival should start close")
	for path in [field,to_summit,climb,descent,lake_walk]:
		for i in 81:
			check(floor.contains_ground_point(path.to_global(path.point_at(path.get_path_length()*i/80.0)),.3),"Every route must fit the finite floor: "+path.name)
	await capture("field-arrival")
	check(world.get_node("GuidanceController").request_guidance(),"The first requested hint must lead across the golden field")
	await walk_trail(player,field,0,1)
	await create_timer(3.0).timeout
	check(absf(camera.size-29.0)<.4 and zones[0].ambience.playing,"The meadow viewpoint should reveal the Flatirons with quiet wind")
	for name in ["ClassicFlatiron","SplitFlatiron","BrokenFlatiron"]:
		var formation: PainterlyFlatiron=zones[0].get_node("Scenery/"+name)
		check(formation.get_recall_controller().progress>.99,"Each Flatiron must recall from the accessible field")
		var crest:=formation.get_anchor(&"Crest").global_position
		var screen:=camera.unproject_position(crest)
		check(camera.is_position_in_frustum(crest) and screen.y>16 and screen.y<root.get_visible_rect().size.y-16,"Flatiron crests must fit the field reveal: "+name)
	await capture("flatirons-field")
	await read_fragment(world,zones[0].get_fragment())
	check(world.get_node("GuidanceController").request_guidance(),"The second hint must follow the real summit ascent")
	check(not to_summit.visible and not to_summit.collision_enabled,"The meadow gap uses the finite floor and still participates in requested guidance")
	await walk_trail(player,to_summit,0,.56)
	await capture("foothill-gap")
	await walk_trail(player,to_summit,.56,1)
	await walk_trail(player,climb,0,.52)
	await create_timer(.8).timeout
	check(player.global_position.y > 1.0 and camera.size < 3.6, "The camera should stay close while climbing the granite ledge")
	await capture("quandary-climb")
	await walk_trail(player,climb,.52,1)
	await create_timer(3.0).timeout
	check(player.global_position.y>3.55 and player.global_position.y<3.75,"The real explorer must reach the supported rocky summit")
	check(absf(camera.size-8.8)<.4 and zones[1].ambience.playing,"The summit should open just enough to show the goats")
	for name in ["Goat1","Goat2","Goat3"]:
		var goat: PainterlyMountainGoat=zones[1].get_node("Scenery/"+name)
		check(goat.get_recall_controller().progress>.99 and goat.idle_motion>0 and not goat.is_processing(),"All three goats must recall and use their existing shader-driven idles")
		var hooves := goat.global_position
		var ray := PhysicsRayQueryParameters3D.create(hooves + Vector3.UP * 0.2, hooves - Vector3.UP * 0.2)
		var support := goat.get_world_3d().direct_space_state.intersect_ray(ray)
		check(not support.is_empty() and terrain.is_ancestor_of(support.collider)
			and absf(support.position.y - hooves.y) < 0.05, "The goats' feet must sit on the exposed saddle")
		check(camera.is_position_in_frustum(goat.global_position+Vector3.UP),"The summit reveal should include all three goats")
	await capture("quandary-goats")
	await read_fragment(world,zones[1].get_fragment())
	check(world.get_node("GuidanceController").request_guidance(),"The final hint must descend to the forested lake bank")
	await walk_trail(player,descent,0,.40)
	await create_timer(.8).timeout
	check(camera.size < 3.6,"Leaving the summit viewpoint should return to close ridge walking")
	await capture("ridge-descent")
	await walk_trail(player,descent,.40,1)
	await walk_trail(player,lake_walk,0,1)
	await create_timer(4.0).timeout
	var water: PainterlyWater=zones[2].get_node("Scenery/ForestLake")
	var herd: PainterlyElkHerd=zones[2].get_node("Scenery/ElkHerd")
	check(absf(camera.size-16.5)<.4 and zones[2].ambience.playing,"The forest lake should have its own animal/shore view and ambient bed")
	check(water.get_recall_controller().progress>.99 and herd.get_recall_controller().progress>.99,"The lake and whole herd must recall from the reachable bank")
	check(herd.generated_count==7 and not herd.is_processing() and herd.idle_motion>0,"The meadow must contain a spaced herd of seven using instanced idle motion")
	for placement in herd.placements:
		var at:=herd.to_global(placement.transform.origin)
		var p:=water.to_local(at)
		check(not Geometry2D.is_point_in_polygon(Vector2(p.x,p.z),water._shape_data.outline),"Elk must be placed on the dry meadow rather than in the lake")
		check(camera.is_position_in_frustum(at+Vector3.UP),"The herd should fit in the lake viewpoint")
	check(zones[2].get_node("Scenery/ShoreElk").get_recall_controller().progress>.99,"The nearby cow must share the shore reveal")
	await capture("forest-lake-elk")
	await read_fragment(world,zones[2].get_fragment())
	check(world.get_node("GuidanceController").get_next_fragment()==null,"Three completed notes must not start hints automatically")
	await walk_trail(player,lake_walk,1,0)
	await walk_trail(player,descent,1,0)
	await walk_trail(player,climb,1,0)
	await walk_trail(player,to_summit,1,0)
	await walk_trail(player,field,1,0)
	await create_timer(2.0).timeout
	check(camera.size<4.0 and player.is_on_floor(),"Returning to the field arrival should restore close, supported exploration")
	for trail in [field, to_summit, lake_walk]:
		check_passing_space(player, trail)
	for trail in [climb, descent]:
		check_passing_space(player, trail, terrain)
	if "--capture" in args: await capture_views(world,memory,camera)
	world.free()
	await process_frame
	change_scene_to_file("res://UI/memory_lane/memory_lane.tscn")
	await process_frame
	await process_frame
	check(current_scene.MEMORIES[16].date=="SEP 6, 2026" and current_scene.MEMORIES[16].scene==WORLD,"Colorado must be inserted on September 6")
	check(current_scene.MEMORIES[15].title=="First Sail" and current_scene.MEMORIES[17].title=="Duluth In The Fall","Colorado must sit between First Sail and Duluth")
	MemoryExplorer.preferred_avatar=MemoryExplorer.Avatar.VIVIAN
	current_scene.select_memory(16)
	current_scene.recall()
	while current_scene==null or current_scene.scene_file_path!=WORLD: await process_frame
	if current_scene.has_node("MemoryArrival"): await current_scene.get_node("MemoryArrival").finished
	for frame in 12: await physics_frame
	check(current_scene.get_node("Explorer").avatar==MemoryExplorer.Avatar.VIVIAN and current_scene.get_node("Explorer").is_on_floor(),"Timeline recall must retain avatar choice and grounded field arrival")
	current_scene.free()
	await create_timer(.25).timeout
	print("Colorado memory: ","PASS" if failures==0 else "FAIL")
	quit(failures)

func capture_views(world: Node3D,memory: MemoryScene,camera: Camera3D) -> void:
	for prop in memory.find_children("*","Node3D",true,false):
		if prop.has_method("get_recall_controller"):
			var effect: Node=prop.get_recall_controller()
			if effect: effect.seek(1.0)
	var rig: Node3D=world.get_node("CameraRig")
	rig.set_process(false)
	for child in world.get_node("Controls").get_children():
		if child is CanvasItem: child.hide()
	var names:=["flatirons-overview","summit-overview","lake-overview","overview"]
	var views:=[Vector4(0,7,11,40),Vector4(29,3,-12,34),Vector4(54,2,-46,37),Vector4(24,5,-16,98)]
	for i in views.size():
		var view: Vector4=views[i]
		rig.position=Vector3(view.x,view.y,view.z)
		camera.size=view.w
		await capture(names[i])

func run_lan(host: bool) -> void:
	var barrier := LanBarrier.new()
	barrier.name = "ColoradoLanBarrier"
	root.add_child(barrier)
	var avatar := MemoryExplorer.Avatar.VIVIAN if host else MemoryExplorer.Avatar.SOREN
	MemoryExplorer.preferred_avatar = avatar
	var session := root.get_node("LanSession")
	var peer := ENetMultiplayerPeer.new()
	var error := peer.create_server(24795,1) if host else peer.create_client("127.0.0.1",24795)
	check(error==OK,"The isolated colorado test transport must open")
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
	check(session.partner_id!=0,"The test clients must pair before recalling the colorado")
	if not host:
		while session.partner_memory!="colorado" and Time.get_ticks_msec()<deadline: await process_frame
	var world := load(WORLD).instantiate() as Node3D
	root.add_child(world)
	current_scene = world
	for frame in 8: await physics_frame
	deadline = Time.get_ticks_msec()+30000
	while Time.get_ticks_msec()<deadline:
		await process_frame
		if session.shares_memory() and world.has_node("Partner") and world.get_node("Partner").visible: break
	check(session.shares_memory() and world.has_node("Partner"),"Matching colorado memories must show the partner")
	if world.has_node("Partner"):
		barrier.ready_mark.rpc()
		while not barrier.partner_ready and Time.get_ticks_msec()<deadline: await process_frame
		check(barrier.partner_ready,"Both colorado clients must be ready before walking")
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
			check(partner.visible and partner.avatar!=avatar and partner.position.distance_to(initial)>0.25,"Both avatar choices and walking must replicate through the colorado arrival")
			check(player.is_on_floor(),"Both LAN arrivals must remain grounded on the colorado path")
			barrier.done_mark.rpc()
			while not barrier.partner_done and Time.get_ticks_msec()<deadline: await process_frame
			check(barrier.partner_done,"Both colorado clients must finish their movement check")
			await create_timer(0.2).timeout
	session.leave()
	await process_frame
	world.free()
	await create_timer(0.3).timeout
	print("Colorado LAN ","host" if host else "guest",": ","PASS" if failures==0 else "FAIL")
	quit(failures)
