extends SceneTree
var failures := 0
func _initialize() -> void:
	call_deferred("run")
func check(value: bool, message: String) -> void:
	if not value:
		push_error(message)
		failures += 1
func walk_to(player: MemoryExplorer, start: Vector3, target_z: float) -> bool:
	player.global_position = start
	player.velocity = Vector3.ZERO
	player.reset_physics_interpolation()
	await physics_frame
	Input.action_press("move_forward")
	for frame in range(200):
		await physics_frame
		if player.global_position.z <= target_z:
			break
	Input.action_release("move_forward")
	return player.global_position.z <= target_z
func run() -> void:
	var world: Node3D = load("res://scenes/world/first_meeting_world.tscn").instantiate()
	root.add_child(world)
	var player: MemoryExplorer = world.get_node("Explorer")
	player.movement_camera = null
	player.walk_speed = 2.5
	var env := world.get_node("Memory/Environment")
	await physics_frame
	await physics_frame
	var left: PainterlyYardFence = env.get_node("FrontFenceLeft")
	var right: PainterlyYardFence = env.get_node("FrontFenceRight")
	var opening_left := left.position.x + left.length * 0.5
	var opening_right := right.position.x - right.length * 0.5
	check(opening_right - opening_left > 2.0, "Gate opening must comfortably fit both explorers")
	check(await walk_to(player, Vector3(0.1,0.05,6.4),4.15), "Host spawn must have a walkable route through the gate")
	check(await walk_to(player, Vector3(1.3,0.05,6.4),4.15), "Guest spawn must have a walkable route through the gate")
	player.global_position = Vector3(-2.8, 0.05, 6.4)
	player.velocity = Vector3.ZERO
	player.reset_physics_interpolation()
	await physics_frame
	Input.action_press("move_forward")
	for frame in range(80):
		await physics_frame
	Input.action_release("move_forward")
	check(player.global_position.z > left.position.z + 0.20, "Fence spans must block walking through the mesh")
	check(await walk_to(player,Vector3(0.6,0.05,4.2),2.2), "Front walk and stair ramp must remain accessible")
	await physics_frame
	check(player.global_position.y > 0.30, "Player must climb the front steps")
	check(env.find_children("*", "PainterlyBird", true, false).is_empty(), "First Meeting must not contain birds")
	var tree: PainterlyTree = env.get_node("AutumnTree")
	check(tree.position.z > 2.0 and tree.position.z < left.position.z and tree.position.x < -1.0, "Autumn tree must sit inside the front yard left of the walkway")
	for component in env.get_children():
		if component is PainterlyTree or component is PainterlyBush or component is PainterlyGrassPatch or component is PainterlyWallVine:
			check(component.palette_preset in [3,4], "Every foliage component must use an autumn orange/red palette")
	check(env.get_node("Meadow").leaves_per_square_meter >= 35.0 and tree.leaf_sprays_per_cluster >= 120, "Autumn foliage should have fuller density")
	check(env.get_node("SidewalkLeaves").leaf_count > 0 and env.get_node("RoofEdgeLeaves").leaf_count > 0, "Autumn accents must connect ground and architecture")
	check(env.get_node("Meadow").ground_leaf_scale < 1.0, "First Meeting should use smaller groundcover dabs")
	world.queue_free()
	await process_frame
	print("First Meeting layout: ", "PASS" if failures == 0 else "FAIL")
	quit(failures)
