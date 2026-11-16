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
		if absi(int(x[i]) - int(y[i])) + absi(int(x[i+1]) - int(y[i+1])) + absi(int(x[i+2]) - int(y[i+2])) > 12:
			count += 1
	return count
func run() -> void:
	root.content_scale_size = Vector2i(1200, 1400)
	var stage: Node3D = load("res://tests/scenes/lighthouse_test.tscn").instantiate()
	root.add_child(stage)
	current_scene = stage
	await process_frame
	await process_frame
	var tower: PainterlyLighthouse = stage.subject
	var actor: MemoryExplorer = stage.get_node("Explorer")
	actor.set_physics_process(false)
	actor.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	actor.animation_player.pause()
	actor.position = Vector3(-1.5, 0.03, 2.4)
	actor.reset_physics_interpolation()
	stage.get_node("Controls").hide()
	tower.seek_time(1.5)
	await shot("res://docs/previews/lighthouse-overview.png")
	var camera: Camera3D = stage.get_node("Camera3D")
	camera.size = 5.7
	camera.position = Vector3(7, 12, 10)
	camera.look_at(Vector3(0, tower.tower_height + 0.75, 0))
	await shot("res://docs/previews/lighthouse-lantern.png")
	stage.floor_color = Color("29383d")
	root.content_scale_size = Vector2i(1600, 1000)
	camera.size = 18
	camera.position = Vector3(17, 12, 23)
	camera.look_at(Vector3(0, 6.3, 0))
	tower.beam_heading = 95
	tower.seek_time(0)
	var before := await shot("res://docs/previews/lighthouse-beacon.png")
	tower.seek_time(5.0)
	var moved := changes(before, await shot())
	check(moved > 200, "The lighthouse beacon must visibly rotate in the Mobile renderer")
	tower.rotation_speed = 0
	var frozen := await shot()
	tower.seek_time(9.0)
	check(changes(frozen, await shot()) < 10, "Zero rotation speed must freeze the beacon and lens")
	tower.beacon_enabled = false
	tower.rebuild()
	check(not tower._generated_root.has_node("BeaconBeam") and not tower._generated_root.has_node("LanternGlow"), "Disabling the beacon must remove its transparent effect layers")
	print("Lighthouse Mobile render: ", "PASS" if failures == 0 else "FAIL", " | rotating pixels: ", moved)
	stage.free()
	await process_frame
	quit(failures)
