extends SceneTree
## Actual Mobile render checks and component-study captures.
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

func changes(first: Image, second: Image) -> int:
	var a := first.get_data()
	var b := second.get_data()
	var changed := 0
	for index in range(0, a.size(), 4):
		if absi(int(a[index]) - int(b[index])) + absi(int(a[index + 1]) - int(b[index + 1])) + absi(int(a[index + 2]) - int(b[index + 2])) > 12:
			changed += 1
	return changed

func run() -> void:
	root.content_scale_size = Vector2i(1600, 1000)
	var stage: Node3D = load("res://tests/scenes/concert_test.tscn").instantiate()
	root.add_child(stage)
	await process_frame
	await process_frame
	var setup: Node3D = stage.subject
	check(setup != null, "The inherited test stage must load the concert composition")
	var rig: PainterlyRaveLights = setup.get_node("RaveLights")
	setup.get_node("VisualScreen").seek_time(0.7)
	rig.set_process(false)
	rig.seek_time(0.0)
	var crowd: PainterlyCrowd = setup.get_node("Audience")
	check(crowd.generated_count == 12, "Audience must fit with a clear central walking approach")
	crowd._material.set_shader_parameter("preview_time", 0.0)
	var actor: MemoryExplorer = stage.get_node("Explorer")
	actor.set_physics_process(false)
	actor.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	actor.reset_physics_interpolation()
	actor.animation_player.pause()
	for name in ["LeftSpeakers", "RightSpeakers"]:
		setup.get_node(name)._material.set_shader_parameter("animation_time", 0.0)
	# Hide authoring panel for the still, retain the normal three-quarter composition.
	stage.get_node("Controls").hide()
	# Allow initial skeleton buffers and shader compilation to settle before
	# comparing otherwise identical frames at a paused clock.
	await create_timer(0.25).timeout
	var first := await snapshot()
	rig.seek_time(3.5)
	var second := await snapshot("res://docs/previews/concert-components-overview.png")
	var movement := changes(first, second)
	check(movement > 1500, "Moving lenses, beams and painted pools must visibly change the actual render")
	rig.seek_time(3.5)
	var frozen := await snapshot()
	var paused_pixels := changes(second, frozen)
	check(paused_pixels < 15, "The same light time must produce a stable repeatable frame (%d changed pixels)" % paused_pixels)
	# Judge a speaker and nearby fixture at the normal exploration scale.
	var camera: Camera3D = stage.get_node("Camera3D")
	camera.size = 3.5
	camera.position = Vector3(10, 10, 12)
	camera.look_at(Vector3(2.65, 1.0, 0.4))
	actor.global_position = Vector3(2.4, 0.48, 1.3)
	actor.reset_physics_interpolation()
	var speaker: PainterlySpeakerStack = setup.get_node("RightSpeakers")
	speaker.cone_motion = 0.02
	speaker._material.set_shader_parameter("animation_time", 0.0)
	var cone_a := await snapshot()
	speaker._material.set_shader_parameter("animation_time", 15.0 / speaker.beat_bpm)
	var cone_b := await snapshot()
	var cone_pixels := changes(cone_a, cone_b)
	check(cone_pixels > 5, "Speaker cones must visibly move in the real renderer")
	speaker.beat_bpm = 0
	var quiet_a := await snapshot()
	speaker._material.set_shader_parameter("animation_time", 2.0)
	var quiet_b := await snapshot()
	check(changes(quiet_a, quiet_b) < 15, "Zero BPM must hold speaker cones still")
	speaker.beat_bpm = 112
	speaker.cone_motion = 0.008
	await snapshot("res://docs/previews/concert-components-close.png")
	print("Concert Mobile render: ", "PASS" if failures == 0 else "FAIL", " | moving pixels: ", movement, " | paused pixels: ", paused_pixels, " | cone pixels: ", cone_pixels)
	stage.free()
	await process_frame
	quit(failures)
