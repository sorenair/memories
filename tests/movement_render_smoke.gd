extends SceneTree
## Requires graphics: godot --path . --script tests/movement_render_smoke.gd
## Checks that uncapped rendering supplies player poses between physics ticks.
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var world: Node3D = load("res://scenes/world/memory_world.tscn").instantiate()
	root.add_child(world)
	var player: Node3D = world.get_node("Explorer")
	await create_timer(1.0).timeout
	Input.action_press("move_right")
	await create_timer(0.6).timeout
	var previous_physics := player.global_position
	var previous_render := player.get_global_transform_interpolated().origin
	var physics_updates := 0
	var render_updates := 0
	var frames := 0
	var maximum_render_step := 0.0
	var end_time := Time.get_ticks_msec() + 1500
	while Time.get_ticks_msec() < end_time:
		await process_frame
		var current_physics := player.global_position
		var current_render := player.get_global_transform_interpolated().origin
		if not current_physics.is_equal_approx(previous_physics):
			physics_updates += 1
		if not current_render.is_equal_approx(previous_render):
			render_updates += 1
		maximum_render_step = maxf(maximum_render_step, current_render.distance_to(previous_render))
		previous_physics = current_physics
		previous_render = current_render
		frames += 1
	Input.action_release("move_right")
	print("Interpolation enabled: ", physics_interpolation, " | FPS: ", Engine.get_frames_per_second(), " | physics moves: ", physics_updates, " | rendered moves: ", render_updates, " / frames: ", frames, " | max rendered step: ", maximum_render_step)
	print("Camera interpolation disabled: ", world.get_node("CameraRig").physics_interpolation_mode == Node.PHYSICS_INTERPOLATION_MODE_OFF)
	var passed := physics_interpolation and (render_updates > physics_updates if frames > physics_updates * 1.5 else render_updates > 0)
	quit(0 if passed else 1)
