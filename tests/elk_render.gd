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
	if not path.is_empty(): result.save_png(path)
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
	var stage: Node3D = load("res://tests/scenes/elk_test.tscn").instantiate()
	root.add_child(stage)
	current_scene = stage
	await process_frame
	await process_frame
	var study: Node3D = stage.subject
	var bull: PainterlyElk = study.get_node("Bull")
	var camera: Camera3D = stage.get_node("Camera3D")
	for id in ["Explorer","Partner"]:
		var actor: MemoryExplorer = stage.get_node(id)
		actor.set_physics_process(false)
		actor.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
		actor.animation_player.pause()
		actor.reset_physics_interpolation()
	for elk in study.get_children(): elk.seek_time(1.5)
	stage.get_node("Controls").hide()
	await shot("res://docs/previews/elk-herd.png")
	for elk in study.get_children(): elk.visible = elk == bull
	stage.get_node("Partner").hide()
	var actor: MemoryExplorer = stage.get_node("Explorer")
	actor.position = bull.position+Vector3(-1.3,0.03,1.5)
	actor.reset_physics_interpolation()
	camera.position = bull.position+Vector3(7,3.4,8)
	camera.size = 4.8
	camera.look_at(bull.position+Vector3(0,1.45,0.20))
	var first := await shot("res://docs/previews/elk-bull.png")
	bull.seek_time(7.5)
	var pixels := changes(first,await shot())
	check(pixels > 100,"Elk idle should visibly move head/ears/breathing")
	bull.idle_pose = 2
	var grazing := await shot("res://docs/previews/elk-grazing.png")
	check(changes(first,grazing) > 1000,"Grazing must visibly lower the connected head and neck")
	bull.idle_motion = 0.0
	var still := await shot()
	bull.seek_time(20.0)
	check(changes(still,await shot()) < 10,"Zero idle motion must freeze the elk in its selected pose")
	# Also verify custom instance animation, with independent per-elk phases/poses.
	bull.hide()
	actor.hide()
	var herd: PainterlyElkHerd = study.get_node("Herd")
	herd.show()
	camera.size = 10.0
	camera.position = herd.position+Vector3(12,8,14)
	camera.look_at(herd.position+Vector3(0,1,0))
	var herd_first := await shot()
	herd.seek_time(9.1)
	var herd_pixels := changes(herd_first,await shot())
	check(herd_pixels > 100,"Instanced herd must animate without CPU callbacks")
	herd.idle_motion = 0
	var herd_still := await shot()
	herd.seek_time(21.0)
	check(changes(herd_still,await shot()) < 10,"Zero motion must freeze all instanced elk")
	print("Elk Mobile render: ","PASS" if failures == 0 else "FAIL"," | single idle pixels: ",pixels," | herd idle pixels: ",herd_pixels)
	stage.free()
	await process_frame
	quit(failures)
