extends SceneTree
## Run with Godot --headless --path . --script tests/scene_smoke.gd
var failures: int = 0

func check(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		failures += 1

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var world := load("res://scenes/world/memory_world.tscn").instantiate() as Node3D
	root.add_child(world)
	await physics_frame
	await physics_frame
	var player := world.get_node("Explorer") as CharacterBody3D
	var input := world.get_node("Controls/ExplorationInput")
	check(player.is_on_floor(), "Explorer must settle on the ground")
	check(world.get_node("Memory/Environment").has_node("Meadow"), "Demo must contain the reusable meadow")
	check(physics_interpolation, "Physics interpolation must be enabled for uncapped rendering")
	check(world.get_node("CameraRig").physics_interpolation_mode == Node.PHYSICS_INTERPOLATION_MODE_OFF, "Render-frame camera must avoid double interpolation")
	var start := player.position
	Input.action_press("move_forward")
	for frame in range(60):
		await physics_frame
	Input.action_release("move_forward")
	check(player.position.distance_to(start) > 1.0, "Forward input must move the explorer")
	var camera := world.get_node("CameraRig/Camera3D") as Camera3D
	var screen_forward := -camera.global_basis.z
	screen_forward.y = 0.0
	check((player.position - start).normalized().dot(screen_forward.normalized()) > 0.99, "Movement must align with screen direction")
	Input.action_press("move_forward")
	Input.action_press("move_right")
	for frame in range(30):
		await physics_frame
	check(Vector2(player.velocity.x, player.velocity.z).length() <= player.walk_speed + 0.01, "Diagonal movement must not exceed walk speed")
	Input.action_release("move_forward")
	Input.action_release("move_right")
	for frame in range(90):
		await physics_frame
	check(Vector2(player.velocity.x, player.velocity.z).length() < 0.01, "Explorer must stop after release")
	check(world.get_node("CameraRig").position.distance_to(player.position) < 0.05, "Camera must settle on explorer")
	var touch := InputEventScreenTouch.new()
	touch.index = 0
	touch.position = Vector2(120, 240)
	touch.pressed = true
	input._input(touch)
	var drag := InputEventScreenDrag.new()
	drag.index = 0
	drag.position = Vector2(256, 240)
	input._input(drag)
	check(input.get_movement().is_equal_approx(Vector2.RIGHT), "Touch drag must clamp to unit movement")
	touch.pressed = false
	input._input(touch)
	check(input.get_movement() == Vector2.ZERO, "Touch release must stop movement")
	player.position = Vector3(3000, 0, 3000)
	player.reset_physics_interpolation()
	for frame in range(5):
		await physics_frame
	check(player.is_on_floor(), "Void ground must remain walkable beyond the original surface")
	check(world.get_node("DreamSurface").position.distance_to(player.position) < 0.05, "Visual surface must follow explorer")
	print("Scene smoke checks: ", "PASS" if failures == 0 else "FAIL")
	quit(failures)
