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
	var player := world.get_node("Explorer") as MemoryExplorer
	var input := world.get_node("Controls/ExplorationInput")
	check(player.is_on_floor(), "Explorer must settle on the ground")
	var soren := player.get_node("Visual/Soren") as Node3D
	check(soren.visible and not player.get_node("Visual/Vivian").visible,
		"Only Soren should be visible by default")
	check(player.animation_player.current_animation == &"IDLE", "Soren must start in IDLE")
	check(player.animation_player.get_animation(&"IDLE").loop_mode == Animation.LOOP_LINEAR
		and player.animation_player.get_animation(&"WALK").loop_mode == Animation.LOOP_LINEAR,
		"Soren's imported locomotion clips must both loop")
	check(world.get_node("Memory/Environment").has_node("SummerSpring/Meadow"), "Demo must contain the reusable meadow")
	check(physics_interpolation, "Physics interpolation must be enabled for uncapped rendering")
	check(world.get_node("CameraRig").physics_interpolation_mode == Node.PHYSICS_INTERPOLATION_MODE_OFF, "Render-frame camera must avoid double interpolation")
	var crowd: PainterlyCrowd = world.get_node("Memory/Environment/SummerSpring/CrowdGathering")
	check(crowd.generated_count == 12 and crowd._hitbox_shapes.size() == 12, "The demo gathering must contain twelve solid people")
	# The starting clearing now deliberately contains solid crowd members. Exercise
	# unblocked locomotion in the open autumn clearing instead of walking into them.
	player.global_position = Vector3(0, 0.04, -1.2)
	player.reset_physics_interpolation()
	await physics_frame
	await physics_frame
	var start := player.position
	Input.action_press("move_forward")
	for frame in range(60):
		await physics_frame
	check(player.animation_player.current_animation == &"WALK", "Soren must play WALK while moving")
	Input.action_release("move_forward")
	check(player.position.distance_to(start) > player.walk_speed * 0.8,
		"Forward input must move the explorer at its configured speed")
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
	check(player.animation_player.current_animation == &"IDLE", "Soren must return to IDLE after stopping")
	check(Vector2(player.velocity.x, player.velocity.z).length() < 0.01, "Explorer must stop after release")
	check(world.get_node("CameraRig").position.distance_to(player.position) < 0.05, "Camera must settle on explorer")
	var touch := InputEventScreenTouch.new()
	touch.index = 0
	touch.position = input._origin
	touch.pressed = true
	input._input(touch)
	var drag := InputEventScreenDrag.new()
	drag.index = 0
	drag.position = input._origin + Vector2(input._radius * 2.0, 0)
	input._input(drag)
	check(input.get_movement().is_equal_approx(Vector2.RIGHT), "Touch drag must clamp to unit movement")
	touch.pressed = false
	input._input(touch)
	check(input.get_movement() == Vector2.ZERO, "Touch release must stop movement")
	var platform: MemoryPlatform = world.get_node("Memory/Environment/MemoryPlatform")
	check(platform.contains_ground_point(player.global_position), "Explorer must remain on the finite memory platform")
	check(not world.get_node("DreamSurface").visible and world.get_node("Ground/CollisionShape3D").disabled, "Bounded memory must replace the infinite surface and collision")
	var ray := PhysicsRayQueryParameters3D.create(Vector3(3000, 3, 3000), Vector3(3000, -3, 3000))
	check(world.get_world_3d().direct_space_state.intersect_ray(ray).is_empty(), "Ground must not extend into the void")
	print("Scene smoke checks: ", "PASS" if failures == 0 else "FAIL")
	quit(failures)
