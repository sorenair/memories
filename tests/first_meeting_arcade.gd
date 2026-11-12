extends SceneTree

var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)

func walk_to(player: MemoryExplorer, target: Vector3) -> bool:
	for frame in range(650):
		var delta := Vector2(target.x-player.global_position.x,target.z-player.global_position.z)
		if delta.length() < 0.12:
			stop_walking()
			return true
		stop_walking()
		if absf(delta.x) > 0.06:
			Input.action_press("move_right" if delta.x > 0 else "move_left")
		if absf(delta.y) > 0.06:
			Input.action_press("move_back" if delta.y > 0 else "move_forward")
		await physics_frame
	stop_walking()
	print("Arcade route stalled at ",player.global_position," while approaching ",target)
	return false

func stop_walking() -> void:
	for action in ["move_right","move_left","move_forward","move_back"]:
		Input.action_release(action)

func has_physical_blocker(node: Node) -> bool:
	if node is PhysicsBody3D:
		return true
	for child in node.get_children(true):
		if has_physical_blocker(child):
			return true
	return false

func run() -> void:
	var world: Node3D = load("res://scenes/world/first_meeting_world.tscn").instantiate()
	root.add_child(world)
	var env := world.get_node("Memory/Zones/Arcade/Scenery")
	var arcade: Node3D = env.get_node("Machines")
	var house: Node3D = world.get_node("Memory/Zones/House/Scenery/House")
	var player: MemoryExplorer = world.get_node("Explorer")
	player.movement_camera = null
	await physics_frame
	await physics_frame
	var platform: MemoryPlatform = world.get_node("Memory/Environment/Platform")
	check(arcade.global_position.x > 10 and house.global_position.x < 2,
		"The arcade glade must remain a distinct area beyond the original house")
	check(not arcade.has_node("Room"), "The arcade must no longer contain the cutaway room")
	check(arcade.has_node("Echoes"), "The arcade must contain its decorative memory echoes")
	if arcade.has_node("Echoes"):
		check(not has_physical_blocker(arcade.get_node("Echoes")),
			"Memory echoes must not add room walls, a full room floor collider, or other physical blockers")
	check(arcade.get_node("Pinball") is PainterlyPinball and arcade.get_node("PunchingBag") is PainterlyPunchingBag
		and arcade.get_node("MechanicalBand") is PainterlyMechanicalBand,
		"The approved activity components must remain intact")
	for name in ["Pinball","PunchingBag","MechanicalBand"]:
		var component: PainterlyArcadeComponent = arcade.get_node(name)
		var mesh: MeshInstance3D = component.get_node("Visual")
		var bounds := mesh.mesh.get_aabb()
		for x in [bounds.position.x,bounds.end.x]:
			for z in [bounds.position.z,bounds.end.z]:
				check(platform.contains_ground_point(mesh.to_global(Vector3(x,0,z)),0.4),
					name + ": all corners must remain safely on the memory platform")
	check(player.global_position.distance_to(Vector3(0.1,0.041,6.4)) < 0.1,
		"The original sidewalk arrival must remain unchanged")
	# Reach the glade across the continuous white platform, without teleporting.
	for target in [Vector3(9,0,6.4),Vector3(12.5,0,4.8),Vector3(15,0,3.8)]:
		check(await walk_to(player,target),"A player must be able to follow the memory approach at " + str(target))
	# Approach each real activity hook from the open foreground. Return through
	# that corridor so the route does not cut through another activity's cabinet.
	for pair in [["Pinball",&"Play"],["PunchingBag",&"Punch"],["MechanicalBand",&"Play"]]:
		var component: PainterlyArcadeComponent = arcade.get_node(pair[0])
		var anchor := component.get_anchor(pair[1])
		check(anchor != null, str(pair[0]) + " must retain its activity hook")
		if anchor == null:
			continue
		var foreground := Vector3(anchor.global_position.x,0,3.8)
		check(await walk_to(player,foreground),str(pair[0]) + ": the open foreground must be reachable")
		check(await walk_to(player,anchor.global_position),str(pair[0]) + ": its activity hook must be reachable")
		check(player.is_on_floor() and platform.contains_ground_point(player.global_position,0.3),
			str(pair[0]) + ": the white memory surface must safely support the explorer")
		check(await walk_to(player,foreground),str(pair[0]) + ": players must be able to leave the activity")
	var band: PainterlyMechanicalBand = arcade.get_node("MechanicalBand")
	for id in [&"GuitarButton",&"KickButton",&"SnareButton",&"PianoButton"]:
		check(band.get_anchor(id) != null, "The single band component must retain the " + str(id) + " control")
	var exit: Node3D = world.get_node("Memory/Exit")
	check(await walk_to(player,exit.global_position), "The memory Exit must remain reachable after visiting every activity")
	check(player.is_on_floor() and platform.contains_ground_point(exit.global_position,0.5),
		"The Exit must sit on an open, safely supported part of the memory")
	world.free()
	print("First Meeting arcade glade route: ","PASS" if failures == 0 else "FAIL")
	quit(failures)
