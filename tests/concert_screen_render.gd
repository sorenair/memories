extends SceneTree
## Real Mobile-render validation and deterministic animation capture.
var failures := 0
var capture_frames: bool = false

func _initialize() -> void:
	capture_frames = OS.get_cmdline_user_args().has("--capture")
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
		check(result.save_png(path) == OK, "Capture must save successfully: " + path)
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
	root.content_scale_size = Vector2i(960, 600)
	var stage: Node3D = load("res://tests/scenes/concert_test.tscn").instantiate()
	root.add_child(stage)
	await process_frame
	await process_frame
	var setup: Node3D = stage.subject
	var screen: PainterlyConcertScreen = setup.get_node("VisualScreen")
	var rig: PainterlyRaveLights = setup.get_node("RaveLights")
	rig.set_process(false)
	rig.seek_time(1.4)
	setup.get_node("Audience")._material.set_shader_parameter("preview_time", 0.0)
	for name in ["LeftSpeakers", "RightSpeakers"]:
		setup.get_node(name)._material.set_shader_parameter("animation_time", 0.0)
	var actor: MemoryExplorer = stage.get_node("Explorer")
	actor.set_physics_process(false)
	actor.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	actor.reset_physics_interpolation()
	actor.animation_player.pause()
	stage.get_node("Controls").hide()
	var camera: Camera3D = stage.get_node("Camera3D")
	camera.size = 6.6
	camera.position = Vector3(3, 5.0, 12)
	camera.look_at(Vector3(0, 1.9, -0.4))
	actor.position = Vector3(1.65, 0.48, 0.25)
	actor.reset_physics_interpolation()
	screen.seek_time(0.8)
	await create_timer(0.3).timeout
	var families: Array[Image] = []
	var sheet := Image.create(960, 400, false, Image.FORMAT_RGBA8)
	for family in range(1, 7):
		screen.pattern_mode = family
		var frame := await snapshot()
		for previous in families:
			check(changes(previous, frame) > 3000, "Every graphic family must render a distinct image, including a valid compiled shader")
		families.append(frame)
		var thumb := frame.duplicate() as Image
		thumb.convert(Image.FORMAT_RGBA8)
		thumb.resize(320, 200, Image.INTERPOLATE_LANCZOS)
		sheet.blit_rect(thumb, Rect2i(0, 0, 320, 200), Vector2i(((family - 1) % 3) * 320, ((family - 1) / 3) * 200))
	sheet.save_png("res://docs/previews/concert-screen-patterns.png")
	screen.pattern_mode = 1
	screen.seek_time(0.2)
	var moving_a := await snapshot()
	screen.seek_time(0.4)
	var moving_b := await snapshot()
	var motion := changes(moving_a, moving_b)
	check(motion > 1000, "A held graphic family must animate internally instead of only switching images")
	screen.pattern_mode = 0
	screen.beat_bpm = 120
	screen.beats_per_pattern = 1
	screen.seek_time(0.2)
	var first := await snapshot()
	screen.seek_time(0.7)
	var next := await snapshot()
	check(changes(first, next) > 3000, "Auto Mix must change graphics after one beat")
	screen.seek_time(0.7)
	check(changes(next, await snapshot()) < 15, "Repeated authored times must reproduce the same image")
	screen.playback_speed = 0
	var paused := await snapshot()
	screen.seek_time(50.7)
	check(changes(paused, await snapshot()) < 15, "Playback Speed zero must freeze the full automatic sequence")
	screen.playback_speed = 1
	screen.beat_bpm = 0
	screen.seek_time(0.2)
	var held := await snapshot()
	screen.pattern_mode = 6 # Seed 71 begins on the sunburst family.
	check(changes(held, await snapshot()) < 15, "Zero BPM must hold the first family while allowing its internal motion")
	screen.pattern_mode = 0
	screen.beat_bpm = 120
	screen.seek_time(0.7)
	await snapshot("res://docs/previews/concert-screen-close.png")
	if capture_frames:
		DirAccess.make_dir_recursive_absolute("/tmp/memories-concert-screen-frames")
		for frame in range(72):
			screen.seek_time(0.2 + float(frame) / 18.0)
			await snapshot("/tmp/memories-concert-screen-frames/frame-%03d.png" % frame)
	print("Concert screen Mobile render: ", "PASS" if failures == 0 else "FAIL", " | animated pixels: ", motion)
	stage.free()
	await process_frame
	quit(failures)
