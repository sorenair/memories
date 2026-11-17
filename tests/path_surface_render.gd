extends "res://tests/elk_render.gd"
func run() -> void:
	root.content_scale_size = Vector2i(1600,1000)
	var stage: Node3D = load("res://tests/scenes/path_surface_test.tscn").instantiate()
	root.add_child(stage)
	current_scene = stage
	await process_frame
	await process_frame
	for id in ["Explorer","Partner"]:
		var actor: MemoryExplorer = stage.get_node(id)
		actor.set_physics_process(false)
		actor.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
		actor.animation_player.pause()
		actor.reset_physics_interpolation()
	stage.get_node("Controls").hide()
	await shot("res://docs/previews/path-surfaces.png")
	var camera: Camera3D = stage.get_node("Camera3D")
	var study: Node3D = stage.subject
	var names := ["EarthTrail","GravelWalk","FieldTrack","FlagstonePath","UrbanPaverPath"]
	for i in range(names.size()):
		var path: PainterlySurfacePath = study.get_node(names[i])
		for child in study.get_children(): child.visible = child==path
		var actor: MemoryExplorer = stage.get_node("Explorer")
		actor.position = path.to_global(path.point_at(path.get_path_length()*0.30))+Vector3.UP*0.05
		actor.reset_physics_interpolation()
		stage.get_node("Partner").hide()
		camera.position = path.position+Vector3(6,7,9)
		camera.look_at(path.position+Vector3(0,0,0.4))
		camera.size = 11.0
		await shot("res://docs/previews/path-"+names[i].to_snake_case()+".png")
	print("Path surface Mobile render: PASS")
	stage.free()
	await process_frame
	quit(failures)
