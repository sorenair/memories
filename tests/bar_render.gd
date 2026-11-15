extends SceneTree
## Actual Mobile render and mesh picking, including an animated break capture.
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
		result.save_png(path)
	return result

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
	var stage: Node3D = load("res://tests/scenes/bar_test.tscn").instantiate()
	root.add_child(stage)
	current_scene = stage
	await process_frame
	await process_frame
	var pool: PainterlyPoolTable = stage.subject.get_node("PoolTable")
	var juke: PainterlyJukebox = stage.subject.get_node("Jukebox")
	var actor: MemoryExplorer = stage.get_node("Explorer")
	var controller: Node = stage.get_node("InteractionController")
	var camera: Camera3D = stage.get_node("Camera3D")
	juke.seek_time(1.0)
	stage.get_node("Controls").hide()
	actor.global_position = pool.to_global(Vector3(0.95, 0.03, 0.5))
	actor.reset_physics_interpolation()
	# Exercise the real triangle picker and press/release controller path.
	await physics_frame
	var tap := camera.unproject_position(pool.to_global(Vector3(0, pool.LAYOUT.CLOTH_Y, 0.3)))
	check(controller.pick_interactable(tap) == pool, "The visible table cloth must pick the pool component")
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.position = tap
	event.pressed = true
	controller._unhandled_input(event)
	event.pressed = false
	controller._unhandled_input(event)
	check(pool.is_playing(), "Clicking the table geometry must start its real interaction")
	pool.rebuild()
	actor.set_physics_process(false)
	actor.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	actor.reset_physics_interpolation()
	actor.animation_player.pause()
	var no_targets: Array[Node3D] = []
	controller._outlines.refresh(no_targets, null)
	await create_timer(0.5).timeout
	await snapshot("res://docs/previews/bar-components-overview.png")
	camera.size = 3.5
	camera.position = Vector3(5, 7, 9)
	camera.look_at(pool.global_position + Vector3(0, 0.55, 0.1))
	var before := await snapshot("res://docs/previews/pool-table-racked.png")
	pool.start_interaction(42)
	pool.set_process(false)
	for frame in range(70):
		pool._process(1.0 / 60.0)
	var after := await snapshot("res://docs/previews/pool-table-break.png")
	var moved := changes(before, after)
	check(moved > 100, "The break must visibly move the cue and racked billiard balls")
	if OS.get_cmdline_user_args().has("--capture"):
		pool.rebuild()
		pool.start_interaction(42)
		pool.set_process(false)
		DirAccess.make_dir_recursive_absolute("/tmp/memories-pool-frames")
		for frame in range(80):
			pool._process(1.0 / 20.0)
			await snapshot("/tmp/memories-pool-frames/frame-%03d.png" % frame)
	camera.size = 2.4
	camera.position = juke.global_position + Vector3(2.5, 2.5, 5)
	camera.look_at(juke.global_position + Vector3(0, 0.95, 0))
	var display_a := await snapshot("res://docs/previews/electronic-jukebox.png")
	juke.seek_time(4)
	check(changes(display_a, await snapshot()) > 150, "The electronic display must visibly animate")
	juke.animation_speed = 0
	var held := await snapshot()
	juke.seek_time(10)
	check(changes(held, await snapshot()) < 15, "Zero display speed must freeze its animation")
	print("Bar Mobile render: ", "PASS" if failures == 0 else "FAIL", " | moving ball pixels: ", moved)
	stage.free()
	await create_timer(0.15).timeout
	quit(failures)
