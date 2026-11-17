extends "res://tests/elk_render.gd"
func run() -> void:
	root.content_scale_size = Vector2i(1600,1000)
	var stage: Node3D = load("res://tests/scenes/shuttle_bus_test.tscn").instantiate()
	root.add_child(stage)
	current_scene = stage
	await process_frame
	await process_frame
	var bus: PainterlyShuttleBus = stage.subject
	var camera: Camera3D = stage.get_node("Camera3D")
	for id in ["Explorer","Partner"]:
		var actor: MemoryExplorer = stage.get_node(id)
		actor.set_physics_process(false)
		actor.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
		actor.animation_player.pause()
		actor.reset_physics_interpolation()
	bus.seek_time(1.5)
	stage.get_node("Controls").hide()
	var first := await shot("res://docs/previews/shuttle-bus.png")
	bus.headlights_enabled = true
	check(changes(first,await shot())>30,"Shuttle headlight toggle must visibly brighten the lenses")
	bus.headlights_enabled = false
	bus.seek_time(12.0)
	check(changes(first,await shot())<10,"Parked shuttle must remain still without CPU animation")
	camera.position = Vector3(-14,7,-17)
	camera.look_at(Vector3(0,1.20,0))
	await shot("res://docs/previews/shuttle-bus-rear.png")
	stage.get_node("Explorer").hide()
	stage.get_node("Partner").hide()
	camera.position = Vector3(20,4.5,0.1)
	camera.look_at(Vector3(0,1.3,0))
	camera.size = 5.7
	await shot("res://docs/previews/shuttle-bus-side.png")
	# Check the shortest length and optional details visually, too.
	bus.passenger_bays = 4
	bus.roof_pod_enabled = false
	bus.mountain_graphic_enabled = false
	bus.destination_text = "PARK & RIDE"
	bus.body_color = Color("829783")
	bus.rebuild()
	camera.position = Vector3(14,8,17)
	camera.look_at(Vector3(0,1.1,0))
	camera.size = 6.3
	await shot("res://docs/previews/shuttle-bus-compact.png")
	print("Shuttle bus Mobile render: ","PASS" if failures==0 else "FAIL")
	stage.free()
	await process_frame
	quit(failures)
