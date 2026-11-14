extends SceneTree
## Real Mobile rendering: visible fountain motion, variants and deterministic captures.
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func snapshot(path: String = "") -> Image:
	await process_frame
	await RenderingServer.frame_post_draw
	var result := root.get_texture().get_image()
	if not path.is_empty():
		result.save_png(path)
	return result

func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)

func changes(a: Image, b: Image) -> int:
	var first := a.get_data()
	var second := b.get_data()
	var changed := 0
	for index in range(0, first.size(), 4):
		if absi(int(first[index]) - int(second[index])) + absi(int(first[index + 1]) - int(second[index + 1])) + absi(int(first[index + 2]) - int(second[index + 2])) > 24:
			changed += 1
	return changed

func run() -> void:
	root.content_scale_size = Vector2i(1440, 900)
	var stage: Node3D = load("res://tests/scenes/conservatory_test.tscn").instantiate()
	root.add_child(stage)
	await process_frame
	await process_frame
	var study: Node3D = stage.subject
	var fountain: PainterlyMarbleFountain = study.get_node("Fountain")
	fountain.seek_time(1.0)
	for child in study.get_children():
		if child is PainterlyBush or child is PainterlyTree:
			child.wind_strength = 0
			if child is PainterlyBush:
				child.react_to_explorers = false
			elif child is PainterlyBonsai:
				child.react_to_explorers = false
	var actor: MemoryExplorer = stage.get_node("Explorer")
	actor.set_physics_process(false)
	actor.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	actor.reset_physics_interpolation()
	actor.animation_player.pause()
	stage.get_node("Controls").hide()
	await create_timer(0.3).timeout
	await snapshot("res://docs/previews/conservatory-components-overview.png")
	var camera: Camera3D = stage.get_node("Camera3D")
	camera.size = 3.5
	camera.position = Vector3(7, 7, 10)
	camera.look_at(Vector3(0, 0.85, 0))
	actor.position = Vector3(1.8, 0.02, 1.0)
	actor.reset_physics_interpolation()
	var first := await snapshot("res://docs/previews/conservatory-fountain.png")
	fountain.seek_time(2.0)
	var moved := await snapshot()
	var motion := changes(first, moved)
	check(motion > 800, "Fountain paint, ripples and overflow must visibly animate in the real renderer")
	fountain.flow_speed = 0
	var paused := await snapshot()
	fountain.seek_time(9.0)
	check(changes(paused, await snapshot()) < 15, "Zero flow speed must freeze all fountain animation")
	camera.position = Vector3(6, 6, 10)
	camera.look_at(Vector3(-2.7, 0.48, 1.3))
	actor.position = Vector3(-1.4, 0.02, 2.4)
	actor.reset_physics_interpolation()
	await snapshot("res://docs/previews/conservatory-flower-bushes.png")
	camera.look_at(Vector3(2.5, 0.9, 1.0))
	actor.position = Vector3(1.3, 0.02, 2.6)
	actor.reset_physics_interpolation()
	await snapshot("res://docs/previews/conservatory-bonsai.png")
	camera.position = Vector3(6, 7, 10)
	camera.look_at(Vector3(0.1, 0.4, -2.5))
	await snapshot("res://docs/previews/conservatory-masonry.png")
	print("Conservatory Mobile render: ", "PASS" if failures == 0 else "FAIL", " | animated fountain pixels: ", motion)
	stage.free()
	await process_frame
	quit(failures)
