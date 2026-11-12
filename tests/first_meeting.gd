extends SceneTree
const MENU := "res://UI/memory_lane/memory_lane.tscn"
const FIRST := "res://scenes/world/first_meeting_world.tscn"
var failures := 0
func _initialize() -> void:
	call_deferred("run")
func check(value: bool, message: String) -> void:
	if not value:
		push_error(message)
		failures += 1
func run() -> void:
	var world: Node3D = load(FIRST).instantiate()
	root.add_child(world)
	current_scene = world
	await physics_frame
	await physics_frame
	var memory: MemoryScene = world.get_node("Memory")
	check(memory.memory_id == &"first_meeting" and memory.display_name == "First Meeting", "Memory must use the shared MemoryScene framework")
	check(memory.has_node("Zones/House/Scenery/House") and not memory.has_node("Camera3D") and not memory.has_node("WorldEnvironment"), "Scenery must belong to the memory, presentation to the shared world")
	for node in ["Explorer", "CameraRig/Camera3D", "Controls/ExplorationInput", "Controls/ReturnToTimeline", "Controls/FragmentInteraction"]:
		check(world.has_node(node), "Playable memory must include " + node)
	var player: MemoryExplorer = world.get_node("Explorer")
	var platform: MemoryPlatform = memory.get_node("Environment/Platform")
	check(world._bounded_memory and world.get_node("Ground/CollisionShape3D").disabled, "House must use the finite memory platform")
	check(player.is_on_floor() and player.global_position.distance_to(memory.get_entry_transform().origin) < 0.1, "Local explorer must spawn grounded on the sidewalk")
	check(platform.contains_ground_point(player.global_position, 0.8) and platform.contains_ground_point(player.global_position + Vector3.RIGHT * 1.2, 0.8), "Local and guest spawn positions must be safely on the platform")
	var house: PainterlyHouse = memory.get_node("Zones/House/Scenery/House")
	check(not house.excludes_ground_point(player.global_position) and not house.excludes_ground_point(player.global_position + Vector3.RIGHT * 1.2), "Both LAN spawns must be outside the house and steps")
	var rig := world.get_node("CameraRig")
	check(rig.target == player and rig.framing_offset == Vector3.ZERO, "First Meeting must use the same centered follow camera as the demo")
	var demo: Node3D = load("res://scenes/world/memory_world.tscn").instantiate()
	var camera: Camera3D = world.get_node("CameraRig/Camera3D")
	var demo_camera: Camera3D = demo.get_node("CameraRig/Camera3D")
	check(is_equal_approx(camera.size, demo_camera.size) and camera.transform.is_equal_approx(demo_camera.transform), "Zoom and camera angle must match Seasonal Demo exactly")
	demo.free()
	var start := player.global_position
	Input.action_press("move_right")
	for frame in range(25):
		await physics_frame
	Input.action_release("move_right")
	check(player.global_position.distance_to(start) > 0.2, "First Meeting must accept normal walking input")
	for frame in range(45):
		await physics_frame
	check(rig.global_position.distance_to(player.global_position + rig.framing_offset) < 0.08, "Camera framing must follow movement without drifting away")
	world.get_node("Controls/ReturnToTimeline").return_to_timeline()
	await create_timer(1.7).timeout
	check(current_scene.scene_file_path == MENU and current_scene.selected_index == 0, "Return must reopen First Meeting in the timeline")
	for index in range(current_scene.MEMORIES.size()):
		if current_scene.MEMORIES[index].scene == "res://scenes/world/memory_world.tscn":
			current_scene.select_memory(index)
			break
	current_scene.recall()
	await create_timer(0.6).timeout
	check(current_scene.scene_file_path == "res://scenes/world/memory_world.tscn", "Demo entry must recall the retained demo world")
	check(current_scene.get_node("Memory").memory_id == &"foliage_demo", "Demo entry must load the seasonal content, not First Meeting")
	if current_scene.has_node("MemoryArrival"):
		await current_scene.get_node("MemoryArrival").finished
	await physics_frame
	await physics_frame
	check(current_scene.get_node("Explorer").is_on_floor(), "Retained demo must still complete arrival with a grounded player")
	print("First Meeting integration: ", "PASS" if failures == 0 else "FAIL")
	quit(failures)
