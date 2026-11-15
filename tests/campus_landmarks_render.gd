extends SceneTree
var failures := 0
func _initialize() -> void:
	call_deferred("run")

func snapshot(path: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(path)

func run() -> void:
	root.content_scale_size=Vector2i(1600,1000)
	var study: Node3D=load("res://tests/scenes/campus_landmarks_test.tscn").instantiate()
	root.add_child(study)
	current_scene=study
	await process_frame
	await process_frame
	var setup: Node3D=study.subject
	var actor: MemoryExplorer=study.get_node("Explorer")
	actor.set_physics_process(false)
	actor.physics_interpolation_mode=Node.PHYSICS_INTERPOLATION_MODE_OFF
	actor.animation_player.pause()
	actor.reset_physics_interpolation()
	var tree: PainterlyTree=setup.get_node("CherryBlossomTree")
	tree.wind_strength=0
	tree.falling_leaf_rate=0
	tree.react_to_explorers=false
	study.get_node("Controls").hide()
	await create_timer(0.5).timeout
	await snapshot("res://docs/previews/campus-landmarks-overview.png")
	setup.get_node("ClassicalPortico").hide()
	var camera: Camera3D=study.get_node("Camera3D")
	camera.size=8.7
	camera.position=Vector3(-2,6.2,10)
	camera.look_at(Vector3(-8.1,2.1,-0.5))
	await snapshot("res://docs/previews/campus-arches-cherry.png")
	setup.get_node("ClassicalPortico").show()
	setup.get_node("CampusArches").hide()
	tree.hide()
	camera.size=10.6
	camera.position=Vector3(14,7.5,12)
	camera.look_at(Vector3(6.5,2.95,0.45))
	actor.position=Vector3(6.5,0.02,4.9)
	actor.reset_physics_interpolation()
	await snapshot("res://docs/previews/classical-portico.png")
	camera.size=3.8
	camera.position=Vector3(9,3.5,6)
	camera.look_at(Vector3(6.5,1.5,0.5))
	actor.position=Vector3(6.5,0.85,-0.1)
	actor.reset_physics_interpolation()
	await snapshot("res://docs/previews/classical-portico-detail.png")
	print("Campus landmark Mobile captures: PASS")
	study.free()
	await process_frame
	quit(failures)
