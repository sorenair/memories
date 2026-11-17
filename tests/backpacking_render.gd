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
	var result := root.get_texture().get_image()
	if not path.is_empty():
		result.save_png(path)
	return result
func changes(a: Image, b: Image) -> int:
	var x := a.get_data()
	var y := b.get_data()
	var count := 0
	for i in range(0,x.size(),4):
		if absi(int(x[i])-int(y[i]))+absi(int(x[i+1])-int(y[i+1]))+absi(int(x[i+2])-int(y[i+2])) > 15:
			count += 1
	return count
func run() -> void:
	root.content_scale_size = Vector2i(1600,1000)
	var stage: Node3D = load("res://tests/scenes/backpacking_test.tscn").instantiate()
	root.add_child(stage)
	current_scene = stage
	await process_frame
	await process_frame
	var setup: Node3D = stage.subject
	var actor: MemoryExplorer = stage.get_node("Explorer")
	actor.set_physics_process(false)
	actor.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	actor.animation_player.pause()
	actor.reset_physics_interpolation()
	stage.get_node("Controls").hide()
	var car: PainterlyFourRunner = setup.get_node("FourRunner")
	var tent: PainterlyStormbreakTent = setup.get_node("Tent")
	var stove: PainterlyBackpackingStove = setup.get_node("Stove")
	tent.seek_time(0.8)
	stove.seek_time(0.8)
	await shot("res://docs/previews/backpacking-overview.png")
	var camera: Camera3D = stage.get_node("Camera3D")
	tent.hide()
	stove.hide()
	camera.size = 6.3
	camera.position = car.position + Vector3(8,5,10)
	camera.look_at(car.position + Vector3(0,0.9,0))
	actor.position = car.position + Vector3(-1.8,0.03,2.5)
	actor.reset_physics_interpolation()
	await shot("res://docs/previews/backpacking-4runner.png")
	camera.position = car.position + Vector3(-8,4.5,-10)
	camera.look_at(car.position + Vector3(0,0.9,0))
	await shot("res://docs/previews/backpacking-4runner-rear.png")
	car.hide()
	tent.show()
	camera.size = 4.6
	camera.position = tent.position + Vector3(6,3.6,8)
	camera.look_at(tent.position + Vector3(0,0.6,0))
	actor.position = tent.position + Vector3(-1.9,0.03,0.8)
	actor.reset_physics_interpolation()
	var first := await shot("res://docs/previews/backpacking-stormbreak.png")
	tent.seek_time(3.5)
	var wind := changes(first,await shot())
	check(wind > 80,"Tent cloth must visibly respond to shader wind")
	tent.wind_strength = 0
	var frozen := await shot()
	tent.seek_time(7.5)
	check(changes(frozen,await shot()) < 10,"Zero wind must hold tent cloth still")
	tent.hide()
	stove.show()
	actor.hide()
	camera.size = 1.35
	camera.position = stove.position + Vector3(1.2,0.9,1.8)
	camera.look_at(stove.position + Vector3(0.1,0.32,0))
	stage.floor_color = Color("697574")
	var stove_first := await shot("res://docs/previews/backpacking-whisperlite.png")
	stove.seek_time(4.4)
	var steam := changes(stove_first,await shot())
	check(steam > 30,"Cooking flame and steam must animate")
	stove.burner_on = false
	var off := await shot()
	stove.seek_time(8.0)
	check(changes(off,await shot()) < 10,"A switched-off stove must stop flame and steam")
	print("Backpacking Mobile render: ","PASS" if failures == 0 else "FAIL"," | tent pixels: ",wind," | cooking pixels: ",steam)
	stage.free()
	await process_frame
	quit(failures)
