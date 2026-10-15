extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func snapshot() -> Image:
	await RenderingServer.frame_post_draw
	var frame := root.get_texture().get_image()
	frame.resize(256, 256)
	return frame
func changes(a: Image, b: Image) -> int:
	var first := a.get_data()
	var second := b.get_data()
	var changed := 0
	for index in range(first.size()):
		if absi(int(first[index]) - int(second[index])) > 3:
			changed += 1
	return changed
func run() -> void:
	root.content_scale_size = Vector2i(800, 800)
	var scene := Node3D.new()
	root.add_child(scene)
	var water: PainterlyWater = load("res://components/scenery/water/painterly_water.tscn").instantiate()
	water.flow_speed = 0.0
	scene.add_child(water)
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 5.8
	scene.add_child(camera)
	camera.position = Vector3(0, 7, 5)
	camera.look_at(Vector3.ZERO)
	await create_timer(0.3).timeout
	var still_a: Image = await snapshot()
	await create_timer(0.5).timeout
	var still_b: Image = await snapshot()
	# With directional advection disabled, visible motion must still come from
	# interference and deformation rather than a scrolling texture.
	water.flow_direction = Vector2.ZERO
	water.flow_speed = 0.4
	water.wave_activity = 0.0
	water.foam_amount = 0.0
	await create_timer(0.2).timeout
	var no_waves_a: Image = await snapshot()
	await create_timer(0.5).timeout
	var no_waves_b: Image = await snapshot()
	water.wave_activity = 0.72
	await create_timer(0.2).timeout
	var moving_a: Image = await snapshot()
	await create_timer(0.6).timeout
	var moving_b: Image = await snapshot()
	water.wave_activity = 0.0
	water.foam_amount = 0.9
	await create_timer(0.2).timeout
	var foam_a: Image = await snapshot()
	await create_timer(0.6).timeout
	var foam_b: Image = await snapshot()
	var foam_changes := changes(foam_a, foam_b)
	var still_changes := changes(still_a, still_b)
	var no_waves_changes := changes(no_waves_a, no_waves_b)
	var motion_changes := changes(moving_a, moving_b)
	print("Water motion | still changed channels: ", still_changes, " | no-flow/no-waves changed channels: ", no_waves_changes, " | interference changed channels: ", motion_changes, " | foam-only changed channels: ", foam_changes)
	quit(0 if still_changes == 0 and no_waves_changes == 0 and motion_changes > 500 and foam_changes > 100 else 1)
