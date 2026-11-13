extends SceneTree
## Mobile-render previews, warm/cool glazing and optional recall visibility.
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)

func snapshot(path: String = "") -> Image:
	await process_frame
	await RenderingServer.frame_post_draw
	var result := root.get_texture().get_image()
	if not path.is_empty():
		check(result.save_png(path) == OK, "Cabin capture must save successfully")
	return result

func changes(first: Image, second: Image) -> int:
	var a := first.get_data()
	var b := second.get_data()
	var changed := 0
	for index in range(0, a.size(), 4):
		if absi(int(a[index]) - int(b[index])) + absi(int(a[index + 1]) - int(b[index + 1])) + absi(int(a[index + 2]) - int(b[index + 2])) > 24:
			changed += 1
	return changed

func run() -> void:
	root.content_scale_size = Vector2i(1440, 900)
	var stage: Node3D = load("res://tests/scenes/postcard_cabin_test.tscn").instantiate()
	root.add_child(stage)
	await process_frame
	await process_frame
	var cabin: PainterlyPostcardCabin = stage.subject
	var actor: MemoryExplorer = stage.get_node("Explorer")
	actor.set_physics_process(false)
	actor.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	actor.reset_physics_interpolation()
	actor.animation_player.pause()
	stage.get_node("Controls").hide()
	await create_timer(0.3).timeout
	var warm := await snapshot("res://docs/previews/postcard-cabin-overview.png")
	cabin.window_warmth = 0.0
	var cool := await snapshot("res://docs/previews/postcard-cabin-reflections.png")
	check(changes(warm, cool) > 4000, "Window pigment must visibly change between amber light and forest reflections")
	cabin.window_warmth = 0.72
	var camera: Camera3D = stage.get_node("Camera3D")
	camera.size = 3.5
	camera.position = Vector3(-10, 5.6, 9)
	camera.look_at(Vector3(-2.0, 1.05, 0.75))
	actor.position = Vector3(-3.3, 0.02, 1.5)
	actor.reset_physics_interpolation()
	await snapshot("res://docs/previews/postcard-cabin-close.png")
	cabin.recall_enabled = true
	var recall: Node = cabin.get_recall_controller()
	recall.set_process(false)
	recall.seek(0.0)
	var hidden := await snapshot()
	recall.seek(1.0)
	check(changes(hidden, await snapshot()) > 10000, "Cabin recall must reveal a visible rendered exterior")
	print("Postcard cabin Mobile render: ", "PASS" if failures == 0 else "FAIL")
	stage.free()
	await process_frame
	quit(failures)
