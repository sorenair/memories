extends SceneTree
const WORLD := "res://scenes/world/snowy_stadium_world.tscn"
var failures := 0

func _initialize() -> void: call_deferred("run")

func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)

func walk_to(player: MemoryExplorer, point: Vector3) -> bool:
	for frame in 900:
		var delta := Vector2(point.x - player.global_position.x, point.z - player.global_position.z)
		for action in [&"move_left", &"move_right", &"move_forward", &"move_back"]:
			Input.action_release(action)
		if delta.length() < 0.12:
			return true
		if absf(delta.x) > 0.07: Input.action_press("move_right" if delta.x > 0 else "move_left")
		if absf(delta.y) > 0.07: Input.action_press("move_back" if delta.y > 0 else "move_forward")
		await physics_frame
	for action in [&"move_left", &"move_right", &"move_forward", &"move_back"]:
		Input.action_release(action)
	return false

func capture(path: String) -> void:
	await process_frame
	await create_timer(0.1).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(path)

func run() -> void:
	var world := load(WORLD).instantiate() as Node3D
	root.add_child(world)
	current_scene = world
	await physics_frame
	await physics_frame
	await process_frame
	await create_timer(0.1).timeout
	var player: MemoryExplorer = world.get_node("Explorer")
	var memory: MemoryScene = world.get_node("Memory")
	var zone: MemoryZone = memory.get_node("Zones/Stadium")
	var deck: MemoryPlatform = zone.get_node("Scenery/WalkableDeck")
	var field: PainterlyFootballField = zone.get_node("Scenery/Field")
	var stands: PainterlyStadiumStands = zone.get_node("Scenery/Stands")
	var snow: PainterlySnowPatch = zone.get_node("Scenery/WalkableSnow")
	check(snow.custom_outline == deck.custom_outline and snow._custom_shape,
		"One continuous snow component must share the deck's connected outline")
	for point in [Vector3(-6,10.5,21), Vector3(-6,10.5,19), Vector3(-6,10.5,17),
		Vector3(-6,10.5,14.7), Vector3(-6,10.5,12), Vector3(0,10.5,12), Vector3(6,10.5,12)]:
		check(snow.excludes_ground_point(point), "Snow must continuously cover every walking section and its joins")
	check(not snow.excludes_ground_point(Vector3(0,10.5,18)),
		"Continuous snow must not bridge the empty space beside the narrow aisle")
	var camera: Camera3D = world.get_node("CameraRig/Camera3D")
	var first_meeting := load("res://scenes/world/first_meeting_world.tscn").instantiate() as Node3D
	check(is_equal_approx(camera.size, first_meeting.get_node("CameraRig/Camera3D").size),
		"Arrival must use First Meeting's intimate camera scale")
	first_meeting.free()
	check(player.global_position.z > 20.0 and zone.get_fragment().global_position.z >= 19.0,
		"Spawn and fragment must share the separate arrival landing")
	check(deck.contains_ground_point(Vector3(-6, 10.5, 17), 0.4)
		and not deck.contains_ground_point(Vector3(0, 10.5, 18)),
		"A narrow aisle, rather than one broad rectangle, must join the two sections")
	check(memory.memory_id == &"snowy_stadium" and memory.get_zones().size() == 1,
		"The stadium memory must use the shared zone framework")
	check(player.is_on_floor() and player.global_position.y > 10.4
		and player.global_position.distance_to(memory.get_entry_transform().origin) < 0.1,
		"Spawn must be safely grounded high in the stands")
	check(deck.contains_ground_point(player.global_position, 0.4)
		and deck.contains_ground_point(player.global_position + Vector3.RIGHT * 1.2, 0.4),
		"Both LAN spawns must fit on the upper deck")
	check(world._bounded_memory and not world.get_node("DreamSurface").visible
		and world.get_node("Ground/CollisionShape3D").disabled,
		"Only the raised deck should provide walkable ground, with no infinite floor")
	check(field.global_position.y == 0.0 and field.global_position.z < -20.0,
		"The football field must sit far below and beyond the player's overlook")
	for piece in [field, stands]:
		var mesh := piece.get_node("Visual").mesh as ArrayMesh
		check(mesh.get_faces().size() > 100 and mesh.get_faces().size() < 300000,
			"Stadium pieces must be nonempty, bounded, batched meshes")
		for vertex in mesh.get_faces():
			check(vertex.is_finite(), "Generated stadium geometry must be finite")
	check(zone.get_node("Scenery/StandSnowfall") is PainterlySnow and zone.get_node("Scenery/FieldSnowfall") is PainterlySnow,
		"The memory must reuse existing snowfall at both elevations")
	check(zone.ambience.playing and memory.get_guidance_fragments() == [zone.get_fragment()],
		"The zone must have ambient wind and a discoverable story fragment")
	check(world.get_node("GuidanceController").request_guidance(),
		"The shared guidance action must find a route across the elevated deck")
	player.movement_camera = null
	player.walk_speed = 2.5
	world.get_node("Controls/FPSLabel").hide()
	if "--capture" in OS.get_cmdline_user_args():
		root.content_scale_size = Vector2i(1600, 738)
		await create_timer(0.7).timeout
		await capture("res://docs/snowy-stadium-aisle.png")
	check(await walk_to(player, zone.get_fragment().global_position), "The arrival fragment must be reachable at close camera scale")
	check(zone.get_fragment().try_activate(player), "The arrival fragment must be readable")
	world.get_node("Controls/FragmentInteraction").advance_note()
	check(await walk_to(player, Vector3(-6, 10.5, 20)), "The landing must lead to the connecting aisle")
	check(camera.size < 3.6, "The whole arrival landing must keep its close camera")
	check(await walk_to(player, Vector3(-6, 10.5, 17)), "The narrow connecting aisle must be traversable")
	await create_timer(0.7).timeout
	check(camera.size > 10.0 and camera.size < 75.0, "The connecting aisle must smoothly stage the camera reveal")
	check(await walk_to(player, Vector3(-6, 10.5, 12)), "The aisle must open into the viewing platform without an internal rim")
	check(player.is_on_floor() and player.global_position.y > 10.4, "Walking must remain on the raised deck")
	check(snow._stamp_count >= 12,
		"Native snow must record real footsteps in both sections")
	check(await walk_to(player, Vector3(4, 10.5, 11.3)), "The viewing bay must be traversable past the benches")
	check(await walk_to(player, Vector3(4, 10.5, 9.95)), "The front guardrail overlook must be approachable")
	await create_timer(1.5).timeout
	check(camera.size > 63.0 and camera.size < 65.0, "The viewing platform must keep the tighter stadium view")
	check(not camera.is_position_behind(field.global_position), "The football field must be in front of the overlook camera")
	if "--capture" in OS.get_cmdline_user_args():
		await capture("res://docs/snowy-stadium-overlook.png")
	Input.action_press("move_forward")
	for frame in 160: await physics_frame
	Input.action_release("move_forward")
	check(player.global_position.z > 9.5 and player.is_on_floor() and player.global_position.y > 10.4,
		"The guardrail boundary must prevent falling into the lower stands or field")
	check(await walk_to(player, Vector3(7.5, 10.5, 11.5)), "The exit marker must remain reachable")
	check(await walk_to(player, Vector3(-6, 10.5, 11.5)), "The viewing bay must lead back to the aisle opening")
	check(await walk_to(player, Vector3(-6, 10.5, 17)), "The connector must remain traversable in reverse")
	check(await walk_to(player, Vector3(-6, 10.5, 21.6)), "The arrival landing must remain reachable")
	await create_timer(1.5).timeout
	check(camera.size < 3.7, "Returning to the landing must restore First Meeting's close scale")
	world.free()
	await create_timer(0.35).timeout

	# Exercise the actual timeline entry and recalled arrival, including its elevated spawn.
	change_scene_to_file("res://UI/memory_lane/memory_lane.tscn")
	await process_frame
	await process_frame
	var menu := current_scene
	menu.select_memory(1)
	menu.recall()
	await create_timer(0.65).timeout
	check(current_scene.scene_file_path == WORLD, "The next timeline entry must recall the stadium")
	if current_scene.has_node("MemoryArrival"):
		await current_scene.get_node("MemoryArrival").finished
	for frame in 30:
		await physics_frame
		if current_scene.get_node("Explorer").is_on_floor():
			break
	check(current_scene.get_node("Explorer").is_on_floor()
		and current_scene.get_node("Explorer").global_position.y > 10.4,
		"Recall must preserve the elevated, grounded spawn: %s / velocity %s" % [
			current_scene.get_node("Explorer").global_position, current_scene.get_node("Explorer").velocity])
	current_scene.free()
	await create_timer(0.35).timeout
	print("Snowy stadium memory: ", "PASS" if failures == 0 else "FAIL")
	quit(failures)
