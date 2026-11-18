extends SceneTree
## Walk the actual three-zone route, including columns, raised path, aisle and stage.
const WORLD := "res://scenes/world/graduation_world.tscn"
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
			check(player.is_on_floor(),"Graduation route joins must remain supported")
			return true
		driver.axis = offset.normalized()*minf(1.0,offset.length()*1.25)
		await physics_frame
	driver.axis = Vector2.ZERO
	push_error("Graduation walk stopped at %s on the way to %s" % [player.global_position,point])
	return false

func capture(name: String) -> void:
	if not "--capture" in OS.get_cmdline_user_args(): return
	await create_timer(1.3).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/previews/graduation-memory-"+name+".png")

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
			check(player.is_on_floor(),"Both directions of the curved campus path must be supported")
			return
		var lookahead := clampf(distance+direction*0.55,minf(from,to)*length,maxf(from,to)*length)
		var target := trail.to_global(trail.point_at(lookahead))
		var offset := Vector2(target.x-player.global_position.x,target.z-player.global_position.z)
		driver.axis = offset.normalized()*minf(1.0,remaining.length()*1.25)
		await physics_frame
	driver.axis = Vector2.ZERO
	check(false,"Explorer must be able to follow the full curved campus route")

func read_fragment(world: Node3D,fragment: MemoryFragment) -> void:
	var camera: Camera3D = world.get_node("CameraRig/Camera3D")
	check(world.get_node("InteractionController").pick_interactable(camera.unproject_position(fragment.get_interaction_tap_position()))==fragment,"Each note must be visible and tappable from its walking approach")
	check(fragment.try_activate(world.get_node("Explorer")),"Each campus and ceremony fragment must be within reach")
	world.get_node("Controls/FragmentInteraction").advance_note()
	await create_timer(0.3).timeout

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
	var floor: MemoryPlatform = memory.get_node("Environment/CampusFloor")
	var walk: PainterlyCurvedPath = zones[0].get_node("Scenery/CampusWalk")
	var garden: PainterlyCurvedPath = zones[1].get_node("Scenery/GardenWalk")
	var aisle: PainterlyCurvedPath = zones[2].get_node("Scenery/Aisle")
	var camera: Camera3D = world.get_node("CameraRig/Camera3D")
	check(memory.memory_id==&"graduation" and zones.size()==3,"Graduation needs three ordered zones and a stable multiplayer identity")
	check(zones[0].zone_id==&"st_thomas_arches" and zones[1].zone_id==&"minnesota_portico" and zones[2].zone_id==&"commencement","Story order must follow the requested campuses and ceremony")
	check(player.is_on_floor() and floor.contains_ground_point(player.global_position+Vector3.RIGHT*1.2,0.5),"Paired arrivals must be supported in front of the arches")
	check(world._bounded_memory and not world.get_node("DreamSurface").visible,"Use finite memory ground in the white void")
	check(camera.size<3.8 and zones[0].ambience.playing,"Arrival must start intimate with a quiet spring bed")
	check(zones[0].get_node("Scenery/Cherry1").global_position.x < -10 and zones[0].get_node("Scenery/Cherry2").global_position.x > -2,"Cherry blossoms must flank the St. Thomas arches")
	var graduates: PainterlyGraduateCrowd = zones[2].get_node("Scenery/Setup/SeatedGraduates")
	var minnesota: PainterlyGraduateCrowd = zones[2].get_node("Scenery/Setup/MinnesotaGraduates")
	var chairs: PainterlyCeremonySeating = zones[2].get_node("Scenery/Setup/Chairs")
	check(graduates.seating==chairs and minnesota.seating==chairs and graduates.generated_count==12 and minnesota.generated_count==12,"The two school groups must fill the same 24 chairs without overlap")
	for group: PainterlyGraduateCrowd in [graduates,minnesota]:
		for pose in group._placements:
			var local := chairs.to_local(group.to_global(pose.origin))
			check(local.x<0 if group==graduates else local.x>0,"Each school's students must stay on its own side of the aisle")
	check(graduates._material.get_shader_parameter("cap_color")==Color(0.96,0.95,0.92,1) and minnesota._material.get_shader_parameter("cap_color")==Color(0.94,0.70,0.22,1),"St. Thomas needs white caps and Minnesota needs gold caps")
	await capture("arrival")
	check(world.get_node("GuidanceController").request_guidance(),"Requested guidance must cross the correct stone arch")
	check(await walk_to(player,Vector3(-7.71,0,10.5)),"The first arch approach must remain clear")
	await create_timer(2.0).timeout
	check(camera.size>6.7 and camera.size<7.2,"Walking toward the arch must gently reveal its silhouette")
	await capture("arches")
	var ratio := walk.curve.get_closest_offset(walk.curve.get_point_position(2))/walk.get_path_length()
	await walk_trail(player,walk,0,ratio)
	await create_timer(1.0).timeout
	await read_fragment(world,zones[0].get_fragment())
	check(world.get_node("GuidanceController").request_guidance(),"The next hint must climb the portico's actual shallow treads")
	await walk_trail(player,walk,ratio,1)
	check(walk.end_fade.y>=3.5 and walk.to_global(walk.point_at(walk.get_path_length())).z>-2.0,"The path must fade out before the grassy portico approach")
	check(await walk_to(player,Vector3(3,0,-2.2)),"The grass courtyard must be supported and open for walking")
	await capture("courtyard")
	check(await walk_to(player,Vector3(4,0,-3.5)),"The grass courtyard must join the portico stairs")
	await create_timer(2.0).timeout
	check(camera.size>12.8 and camera.size<13.7,"The portico approach should reveal the colonnade without losing the player")
	var portico_tree: PainterlyTree = zones[1].get_node("Scenery/WestPorticoTree")
	check(portico_tree.get_recall_controller().progress>0.4,"The courtyard must recall the portico's framing trees before the stair climb")
	await capture("portico")
	check(await walk_to(player,zones[1].get_fragment().global_position),"The real explorer must climb every portico step")
	check(player.global_position.y>0.80 and zones[1].ambience.playing,"The portico note must stand on the raised landing, with blended ambience")
	await create_timer(1.0).timeout
	check(camera.size<6.3,"Climbing to the landing must bring the camera back toward the intimate note")
	await read_fragment(world,zones[1].get_fragment())
	check(world.get_node("GuidanceController").request_guidance(),"Ceremony guidance must connect through the columns and down the garden path")
	check(await walk_to(player,garden.to_global(garden.point_at(0))),"The center gap between columns must lead onto the raised garden path")
	await walk_trail(player,garden,0,1)
	check(player.global_position.y<0.09,"The garden path must descend continuously to the ceremony")
	await capture("ceremony-arrival")
	await walk_trail(player,aisle,0,1)
	check(await walk_to(player,Vector3(-6,0,-27.0)),"The 2.2m occupied seating aisle must connect to the stage ramp")
	await create_timer(2.0).timeout
	check(camera.size>6.3 and camera.size<6.7,"The ceremony camera must stay comfortably close")
	var stage_tree: PainterlyTree = zones[2].get_node("Scenery/StageBackdropTree")
	check(stage_tree.get_recall_controller().progress>0.4,"The aisle must recall the stage backdrop before reaching the ramp")
	await capture("ceremony")
	check(await walk_to(player,zones[2].get_fragment().global_position),"The central ramp must lead onto the commencement stage")
	check(player.global_position.y>0.42,"The ceremony fragment must be supported by the deck")
	await create_timer(1.0).timeout
	await read_fragment(world,zones[2].get_fragment())
	check(not world.get_node("GuidanceController").request_guidance(),"Completed graduation fragments must leave no automatic or repeated hint")
	await capture("stage")
	# Reverse the full route to catch one-way stair/ramp seams and branch joins.
	check(await walk_to(player,Vector3(-6,0,-25.8)),"The explorer must descend the ceremony ramp")
	await walk_trail(player,aisle,1,0)
	await walk_trail(player,garden,1,0)
	check(player.global_position.y>0.80,"The returning garden path must join the rear landing without a step")
	check(await walk_to(player,Vector3(4,0,-3.5)),"The explorer must descend the portico treads")
	check(await walk_to(player,walk.to_global(walk.point_at(walk.get_path_length()))),"The returning courtyard must reconnect to the faded path")
	await walk_trail(player,walk,1,ratio)
	var other: PainterlyCurvedPath = zones[0].get_node("Scenery/OtherPassage")
	await walk_trail(player,other,1,0)
	check(await walk_to(player,Vector3(-7.71,0,15)),"Both stone passages and the arrival crossing must remain navigable")
	await create_timer(3.0).timeout
	check(camera.size<3.8,"Returning to arrival must restore the intimate camera")
	if "--capture" in args:
		for prop in memory.find_children("*","Node3D",true,false):
			if prop.has_method("get_recall_controller"):
				var effect: Node = prop.get_recall_controller()
				if effect: effect.seek(1.0)
		var rig: Node3D = world.get_node("CameraRig")
		rig.set_process(false)
		rig.position = Vector3(-2,1.5,-10)
		camera.size = 40.0
		for child in world.get_node("Controls").get_children():
			if child is CanvasItem: child.hide()
		await capture("overview")
	world.free()
	await process_frame
	change_scene_to_file("res://UI/memory_lane/memory_lane.tscn")
	await process_frame
	await process_frame
	check(current_scene.MEMORIES[8].date=="MAY 14, 2026" and current_scene.MEMORIES[8].scene==WORLD,"Graduation must appear between Mifflin and Vineyard on the correct date")
	MemoryExplorer.preferred_avatar = MemoryExplorer.Avatar.VIVIAN
	current_scene.select_memory(8)
	current_scene.recall()
	while current_scene==null or current_scene.scene_file_path!=WORLD: await process_frame
	if current_scene.has_node("MemoryArrival"): await current_scene.get_node("MemoryArrival").finished
	for frame in 8: await physics_frame
	check(current_scene.get_node("Explorer").avatar==MemoryExplorer.Avatar.VIVIAN and current_scene.get_node("Explorer").is_on_floor(),"Timeline recall must retain the chosen avatar and supported graduation arrival")
	current_scene.free()
	await create_timer(0.25).timeout
	print("Graduation memory: ","PASS" if failures==0 else "FAIL")
	quit(failures)

func run_lan(host: bool) -> void:
	var barrier := LanBarrier.new()
	barrier.name = "GraduationLanBarrier"
	root.add_child(barrier)
	var avatar := MemoryExplorer.Avatar.VIVIAN if host else MemoryExplorer.Avatar.SOREN
	MemoryExplorer.preferred_avatar = avatar
	var session := root.get_node("LanSession")
	var peer := ENetMultiplayerPeer.new()
	var error := peer.create_server(24715,1) if host else peer.create_client("127.0.0.1",24715)
	check(error==OK,"The isolated graduation test transport must open")
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
	check(session.partner_id!=0,"The test clients must pair before recalling the graduation")
	if not host:
		while session.partner_memory!="graduation" and Time.get_ticks_msec()<deadline: await process_frame
	var world := load(WORLD).instantiate() as Node3D
	root.add_child(world)
	current_scene = world
	for frame in 8: await physics_frame
	deadline = Time.get_ticks_msec()+30000
	while Time.get_ticks_msec()<deadline:
		await process_frame
		if session.shares_memory() and world.has_node("Partner") and world.get_node("Partner").visible: break
	check(session.shares_memory() and world.has_node("Partner"),"Matching graduation memories must show the partner")
	if world.has_node("Partner"):
		barrier.ready_mark.rpc()
		while not barrier.partner_ready and Time.get_ticks_msec()<deadline: await process_frame
		check(barrier.partner_ready,"Both graduation clients must be ready before walking")
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
			check(partner.visible and partner.avatar!=avatar and partner.position.distance_to(initial)>0.25,"Both avatar choices and walking must replicate through the graduation arrival")
			check(player.is_on_floor(),"Both LAN arrivals must remain grounded on the graduation path")
			barrier.done_mark.rpc()
			while not barrier.partner_done and Time.get_ticks_msec()<deadline: await process_frame
			check(barrier.partner_done,"Both graduation clients must finish their movement check")
			await create_timer(0.2).timeout
	session.leave()
	await process_frame
	world.free()
	await create_timer(0.3).timeout
	print("Graduation LAN ","host" if host else "guest",": ","PASS" if failures==0 else "FAIL")
	quit(failures)
