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
func changed(a: Image, b: Image) -> int:
	var x := a.get_data()
	var y := b.get_data()
	var count := 0
	for i in range(0, x.size(), 4):
		if absi(int(x[i]) - int(y[i])) + absi(int(x[i+1]) - int(y[i+1])) + absi(int(x[i+2]) - int(y[i+2])) > 18:
			count += 1
	return count
func run() -> void:
	root.content_scale_size = Vector2i(1600, 1000)
	var study: Node3D = load("res://tests/scenes/sailing_test.tscn").instantiate()
	root.add_child(study)
	current_scene = study
	await process_frame
	await process_frame
	var setup: Node3D = study.subject
	var actor: MemoryExplorer = study.get_node("Explorer")
	actor.set_physics_process(false)
	actor.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	actor.animation_player.pause()
	actor.position = Vector3(0, 0.555, -2.8)
	actor.reset_physics_interpolation()
	study.get_node("Controls").hide()
	var boat: PainterlyEnsign = setup.get_node("Ensign")
	boat.seek_time(1.2)
	await create_timer(0.4).timeout
	await shot("res://docs/previews/sailing-overview.png")
	var camera: Camera3D = study.get_node("Camera3D")
	camera.size = 11.5
	camera.position = Vector3(15, 9, 12)
	camera.look_at(boat.position + Vector3(0, 3.6, 0))
	await shot("res://docs/previews/sailing-ensign.png")
	for child in setup.get_children():
		if child != boat:
			child.hide()
	actor.hide()
	var before := await shot()
	boat.seek_time(3.9)
	var movement := changed(before, await shot())
	check(movement > 250, "The Ensign must show gentle shader motion in the real renderer")
	boat.wind_strength = 0
	boat.bob_amount = 0
	var frozen := await shot()
	boat.seek_time(8.5)
	check(changed(frozen, await shot()) < 10, "Zero wind and bob must freeze the boat without replacing meshes")
	boat.sails_enabled = false
	boat.rebuild()
	actor.show()
	actor.position = boat.position + Vector3(1.6, 0.03, -1.9)
	actor.reset_physics_interpolation()
	camera.size = 6.8
	camera.position = boat.position + Vector3(9, 7, -9)
	camera.look_at(boat.position + Vector3(0, 0.4, -0.1))
	await shot("res://docs/previews/sailing-ensign-cockpit.png")
	boat.hide()
	var dock: PainterlyWoodenDock = setup.get_node("Dock")
	dock.show()
	actor.position = Vector3(0, 0.555, -2.8)
	actor.reset_physics_interpolation()
	camera.size = 10.5
	camera.position = Vector3(12, 12, 15)
	camera.look_at(Vector3(0, 0.5, 0.7))
	await shot("res://docs/previews/sailing-dock.png")
	print("Sailing Mobile render: ", "PASS" if failures == 0 else "FAIL", " | moving boat pixels: ", movement)
	study.free()
	await process_frame
	quit(failures)
