extends SceneTree
var failures: int = 0
func _initialize() -> void:
	call_deferred("run")
func check(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		failures += 1
func run() -> void:
	var stage := load("res://tests/scenes/component_test.tscn").instantiate() as Node3D
	stage.subject_scene = load("res://components/lighting/light_wash/painterly_light_wash.tscn")
	root.add_child(stage)
	await process_frame
	await process_frame
	var wash := stage.subject as PainterlyLightWash
	check(wash != null, "Generic test stage should load the selected light wash")
	check(wash.get_children().is_empty() and wash.get_children(true).size() == 1, "Wash should use one internal geometry node")
	var mesh: MeshInstance3D = wash.get_node("Wash")
	check(mesh.mesh.get_faces().size() / 3 == 2 and mesh.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF, "Wash must use two triangles without shadow passes")
	check(not wash.is_processing(), "Steady/flickering wash should not require a CPU animation callback")
	var original := mesh.get_instance_id()
	wash.light_color = Color(1.0, 0.86, 0.6)
	wash.intensity = 0.75
	wash.wash_shape = 2
	wash.window_grid = Vector2i(3, 2)
	wash.motion = 1
	check(wash.get_node("Wash").get_instance_id() == original, "Appearance and motion changes must preserve geometry")
	check(wash._material.get_shader_parameter("window_grid") == Vector2(3, 2), "Window panes must update the shader")
	var other := load("res://components/lighting/light_wash/painterly_light_wash.tscn").instantiate() as PainterlyLightWash
	root.add_child(other)
	other.position.x = 100
	check(other._material != wash._material, "Wash materials must be independent")
	wash.surface = 1
	check(is_equal_approx(mesh.rotation.x, PI * 0.5) and is_equal_approx(mesh.position.y, wash.wall_center_height), "Wall mode must raise/rotate the quad while retaining a grounded root")
	wash.surface = 0
	wash.recall_enabled = true
	var effect: Node = wash.get_recall_controller()
	effect.set_process(false)
	stage.get_node("Explorer").position = Vector3(100, 0, 100)
	effect._process(0.1)
	check(effect.progress == 0.0, "Hidden light should wait for proximity")
	stage.get_node("Explorer").position = Vector3.ZERO
	effect._process(0.3)
	check(effect.playing and effect.progress > 0.0, "Shared proximity must fade in nearby light")
	wash.footprint = Vector2(4.8, 3.2)
	wash.rebuild()
	check(wash.get_recall_controller() == effect and effect.progress > 0.0, "Rebuilding should preserve recall")
	wash.recall_enabled = false
	check(wash.get_recall_controller() == null and wash._material.get_shader_parameter("recall_visibility") == 1.0, "Disabling recall must show full wash")
	wash.footprint = Vector2(4.5, 3.0)
	wash.rebuild()
	wash.intensity = 0.65
	wash.light_color = Color(1, 0.90, 0.65)
	wash.motion = 0
	stage.get_node("Explorer").position = Vector3(0, 0, 4.5)
	other.queue_free()
	if "--capture" in OS.get_cmdline_user_args():
		root.content_scale_size = Vector2i(1280, 720)
		for shape in range(3):
			wash.wash_shape = shape
			await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("/tmp/light-wash-shape-%d.png" % shape)
		stage.show_wall = true
		wash.surface = 1
		wash.position.z = -3.2
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("/tmp/light-wash-wall.png")
	# Replacing the test subject must keep the stage/player/camera intact.
	stage.recall_mode = 1
	await process_frame
	await process_frame
	check(stage.subject.get_recall_controller() != null, "Generic stage must be able to enable recall without editing the component scene")
	stage.recall_mode = 0
	await process_frame
	await process_frame
	var camera_id := stage.get_node("Camera3D").get_instance_id()
	stage.subject_scene = load("res://components/scenery/boulders/painterly_boulder.tscn")
	await process_frame
	await process_frame
	check(stage.subject is PainterlyBoulder, "Subject Scene should swap in another reusable component")
	check(stage.get_node("Camera3D").get_instance_id() == camera_id, "Swapping subjects must preserve the test stage")
	stage._floor_selected(2)
	check(stage.floor_color == Color(0.08, 0.095, 0.12), "Runtime controls should change floor tone")
	stage._toggle_subject()
	check(not stage.subject.visible, "Generic show/hide must work on any 3D subject")
	stage.subject_scene = null
	await process_frame
	await process_frame
	check(stage.subject == null, "An empty test stage must be valid")
	print("Light wash and generic component stage checks: ", "PASS" if failures == 0 else "FAIL")
	quit(failures)
