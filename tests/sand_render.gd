extends SceneTree
var failures := 0
func _initialize() -> void:
	call_deferred("run")
func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)
func shot(path: String = "") -> Image:
	await process_frame
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	if not path.is_empty():
		img.save_png(path)
	return img
func changes(a: Image, b: Image) -> int:
	var x := a.get_data()
	var y := b.get_data()
	var count := 0
	for i in range(0, x.size(), 4):
		if absi(int(x[i]) - int(y[i])) + absi(int(x[i+1]) - int(y[i+1])) + absi(int(x[i+2]) - int(y[i+2])) > 18:
			count += 1
	return count
func run() -> void:
	root.content_scale_size = Vector2i(1600, 1000)
	var study: Node3D = load("res://tests/scenes/sand_test.tscn").instantiate()
	root.add_child(study)
	current_scene = study
	await process_frame
	await process_frame
	var patch: PainterlySandPatch = study.subject.get_node("WindDunes")
	var actor: MemoryExplorer = study.get_node("Explorer")
	actor.set_physics_process(false)
	actor.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	actor.animation_player.pause()
	actor.position = Vector3(-2, patch.get_surface_height(Vector3(-2, 0, 0)) + 0.01, 0)
	actor.reset_physics_interpolation()
	study.get_node("Controls").hide()
	patch.track_footprints = false
	patch.set_physics_process(false)
	patch.footprint_linger = 16
	await shot("res://docs/previews/sand-forms.png")
	study.subject.get_node("RollingHills").hide()
	var camera: Camera3D = study.get_node("Camera3D")
	camera.size = 14.5
	camera.position = Vector3(15, 9, 17)
	camera.look_at(Vector3(0, 0.6, 0))
	var blank := await shot("res://docs/previews/sand-dunes.png")
	for i in range(18):
		var point := Vector3(-2.0, 0, 4.5 - i * 0.32)
		point.x += 0.105 if i % 2 == 0 else -0.105
		point.y = patch.get_surface_height(point)
		check(patch.stamp_footprint(point, Vector3.FORWARD), "Dune-height footprints must stamp")
	patch._flush_field()
	var marked := await shot("res://docs/previews/sand-footsteps.png")
	var visible := changes(blank, marked)
	check(visible > 150, "Sand footsteps must be visible on slopes")
	patch._clock = 8.0
	patch._update_material()
	check(changes(marked, await shot()) == 0, "Sand footprints must retain their full linger time")
	patch._clock = 23.0
	patch._update_material()
	check(changes(blank, await shot()) == 0, "Faded footprints must restore the original dune surface")
	patch._clock = 300
	var point := Vector3(-1.8, 0, 1.1)
	point.y = patch.get_surface_height(point)
	patch.stamp_footprint(point, Vector3.FORWARD)
	patch._flush_field()
	patch._update_material()
	check(changes(blank, await shot()) > 15, "Fresh sand footprints must work after long play sessions")
	print("Sand Mobile render: ", "PASS" if failures == 0 else "FAIL", " | footprint pixels: ", visible)
	study.free()
	await process_frame
	quit(failures)
