extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func snapshot() -> Image:
	await RenderingServer.frame_post_draw
	var frame := root.get_texture().get_image()
	frame.resize(400,300)
	return frame
func changes(a: Image,b: Image) -> int:
	var first := a.get_data()
	var second := b.get_data()
	var total := 0
	for index in range(first.size()):
		if absi(int(first[index])-int(second[index])) > 3:
			total += 1
	return total
func run() -> void:
	root.content_scale_size = Vector2i(800,600)
	var scene := Node3D.new()
	root.add_child(scene)
	var environment := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("50685e")
	environment.environment = env
	scene.add_child(environment)
	var path: DreamWispPath = load("res://components/guidance/wisps/dream_wisp_path.tscn").instantiate()
	path.drift_speed = 0.0
	scene.add_child(path)
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 7.5
	scene.add_child(camera)
	camera.position = Vector3(5,8,5)
	camera.look_at(Vector3(0,0,-1))
	await create_timer(0.3).timeout
	var still_a: Image = await snapshot()
	await create_timer(0.4).timeout
	var still_b: Image = await snapshot()
	path.drift_speed = 0.34
	await create_timer(0.1).timeout
	var move_a: Image = await snapshot()
	await create_timer(0.7).timeout
	var move_b: Image = await snapshot()
	path.visible = false
	await process_frame
	var hidden: Image = await snapshot()
	var still := changes(still_a, still_b)
	var motion := changes(move_a, move_b)
	var visible_pixels := changes(move_b, hidden)
	print("Wisp render | frozen: ", still, " | animated: ", motion, " | visible: ", visible_pixels)
	quit(0 if still == 0 and motion > 100 and visible_pixels > 100 else 1)
