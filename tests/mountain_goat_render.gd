extends "res://tests/elk_render.gd"
## Reuse the study capture/image comparison helpers; exercise goat anatomy.
func run() -> void:
	root.content_scale_size = Vector2i(1600,1000)
	var stage: Node3D = load("res://tests/scenes/mountain_goat_test.tscn").instantiate()
	root.add_child(stage)
	current_scene = stage
	await process_frame
	await process_frame
	var study: Node3D = stage.subject
	var goat: PainterlyMountainGoat = study.get_node("Goat")
	var camera: Camera3D = stage.get_node("Camera3D")
	for id in ["Explorer","Partner"]:
		var explorer: MemoryExplorer = stage.get_node(id)
		explorer.set_physics_process(false)
		explorer.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
		explorer.animation_player.pause()
		explorer.reset_physics_interpolation()
	for animal in study.get_children(): animal.seek_time(1.5)
	stage.get_node("Controls").hide()
	await shot("res://docs/previews/mountain-goat-study.png")
	for animal in study.get_children(): animal.visible = animal == goat
	stage.get_node("Partner").hide()
	var actor: MemoryExplorer = stage.get_node("Explorer")
	actor.position = goat.position+Vector3(-1.3,0.03,1.3)
	actor.reset_physics_interpolation()
	camera.position = goat.position+Vector3(6.0,2.8,7.5)
	camera.size = 3.5
	camera.look_at(goat.position+Vector3(-0.1,0.86,0.15))
	var first := await shot("res://docs/previews/mountain-goat.png")
	goat.seek_time(7.4)
	var pixels := changes(first,await shot())
	check(pixels > 100,"Mountain goat head/ear/breathing idles must visibly animate")
	goat.idle_pose = 2
	var grazing := await shot("res://docs/previews/mountain-goat-grazing.png")
	check(changes(first,grazing)>1000,"Grazing must lower the head, horns and beard as one connected form")
	goat.idle_motion = 0
	var still := await shot()
	goat.seek_time(20.5)
	check(changes(still,await shot()) < 10,"Zero idle motion must freeze the chosen goat pose")
	goat.idle_pose = 1
	var alert := await shot()
	goat.seek_time(45)
	check(changes(alert,await shot()) < 10,"Alert pose must also freeze at zero motion")
	# Capture rear coat/hooves too, where the broad fur fringe is easiest to inspect.
	goat.idle_pose = 0
	camera.position = goat.position+Vector3(-6,2.6,-7)
	camera.look_at(goat.position+Vector3(0,0.9,0))
	actor.hide()
	camera.size = 2.6
	await shot("res://docs/previews/mountain-goat-rear.png")
	print("Mountain goat Mobile render: ","PASS" if failures == 0 else "FAIL"," | idle pixels: ",pixels)
	stage.free()
	await process_frame
	quit(failures)
