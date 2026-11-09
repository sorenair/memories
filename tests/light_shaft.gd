extends SceneTree
var failures: int = 0
func _initialize() -> void:
	call_deferred("run")
func check(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		failures += 1
func snapshot() -> Image:
	await process_frame
	await RenderingServer.frame_post_draw
	var frame := root.get_texture().get_image()
	frame.resize(320, 180)
	return frame
func changes(first: Image, second: Image) -> int:
	var a := first.get_data()
	var b := second.get_data()
	var count := 0
	for index in range(a.size()):
		if absi(int(a[index]) - int(b[index])) > 2:
			count += 1
	return count
func capture(name: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/tmp/light-shaft-%s.png" % name)
func run() -> void:
	var stage := load("res://tests/scenes/component_test.tscn").instantiate() as Node3D
	stage.subject_scene = load("res://components/lighting/light_shaft/painterly_light_shaft.tscn")
	root.add_child(stage)
	await process_frame
	await process_frame
	var shaft := stage.subject as PainterlyLightShaft
	check(shaft != null, "Generic stage must load the selected shaft")
	var layer_count := 1 + (1 if shaft.mote_count > 0 else 0) + (1 if shaft.ground_wash_enabled else 0)
	check(shaft.get_children().is_empty() and shaft.get_children(true).size() == layer_count, "Shaft should have only its enabled internal layers")
	check(not shaft.is_processing(), "Shaft and mote motion should have no CPU animation callback")
	var batch := shaft.get_node("Motes") as MultiMeshInstance3D
	check(batch.multimesh.instance_count == 72, "Default motes must remain sparse")
	check(shaft.get_node("Shaft").mesh.get_faces().size() / 3 == 2, "Beam must use one two-triangle ribbon")
	check(batch.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF, "Motes must avoid shadow passes")
	var can_read_instances := DisplayServer.get_name() != "headless"
	var data := batch.multimesh.get_instance_custom_data(0)
	var id := batch.get_instance_id()
	shaft.opacity = 0.2
	shaft.drift_speed = 0.12
	check(shaft.get_node("Motes").get_instance_id() == id, "Appearance/drift edits must preserve geometry")
	shaft.opacity = 0.18
	shaft.drift_speed = 0.08
	shaft.rebuild()
	if can_read_instances:
		check(shaft.get_node("Motes").multimesh.get_instance_custom_data(0).is_equal_approx(data), "Seed must reproduce mote distribution")
	shaft.shaft_seed += 1
	shaft.rebuild()
	if can_read_instances:
		check(not shaft.get_node("Motes").multimesh.get_instance_custom_data(0).is_equal_approx(data), "New seed must change motes")
	shaft.shaft_seed -= 1
	shaft.rebuild()
	var other := load("res://components/lighting/light_shaft/painterly_light_shaft.tscn").instantiate() as PainterlyLightShaft
	other.position.x = 100
	root.add_child(other)
	check(other._beam_material != shaft._beam_material and other._mote_material != shaft._mote_material, "Shaft materials must be independent")
	other.queue_free()
	shaft.recall_enabled = true
	var recall: Node = shaft.get_recall_controller()
	recall.set_process(false)
	stage.get_node("Explorer").position = Vector3(100, 0, 100)
	recall._process(0.1)
	check(recall.progress == 0.0, "Shaft recall should wait for nearby explorers")
	stage.get_node("Explorer").position = Vector3.ZERO
	recall._process(0.1)
	check(recall.playing, "A nearby explorer should recall the shaft")
	stage.get_node("Explorer").position = Vector3(0, 0, 4.5)
	recall.auto_discover = false
	recall.seek(0.5)
	for material in shaft.recall_materials():
		check(material.get_shader_parameter("recall_visibility") == 0.5, "Recall must fade beam, motes and ground wash together")
	shaft.rebuild()
	check(shaft.get_recall_controller() == recall and recall.progress == 0.5, "Rebuild must preserve recall")
	shaft.recall_enabled = false
	for material in shaft.recall_materials():
		check(material.get_shader_parameter("recall_visibility") == 1.0, "Disabling recall must restore all layers")
	if "--capture" in OS.get_cmdline_user_args():
		root.content_scale_size = Vector2i(1280, 720)
		await create_timer(0.2).timeout
		await capture("neutral")
		stage._floor_selected(1)
		await capture("white")
		stage._floor_selected(2)
		await capture("dark")
		stage._floor_selected(0)
		# Freeze all three layers, then confirm motion comes back when enabled.
		shaft.drift_speed = 0.0
		await create_timer(0.1).timeout
		var frozen_a := await snapshot()
		await create_timer(0.35).timeout
		var frozen_b := await snapshot()
		check(changes(frozen_a, frozen_b) == 0, "Zero drift must freeze motes, beam and grounding wash")
		shaft.drift_speed = 0.4
		await create_timer(0.1).timeout
		var moving_a := await snapshot()
		await create_timer(0.7).timeout
		var moving_b := await snapshot()
		var moved := changes(moving_a, moving_b)
		check(moved > 15, "GPU motes should visibly drift")
		print("Shaft motion changed channels: ", moved)
		shaft.drift_speed = 0.08
		# View the same component from the side to verify camera-facing ribbons.
		stage.get_node("Camera3D").position = Vector3(8, 7, 7)
		stage.get_node("Camera3D").look_at(Vector3(0, 1.2, 0))
		await capture("side")
	shaft.mote_count = 0
	shaft.ground_wash_enabled = false
	shaft.rebuild()
	check(not shaft.has_node("Motes") and not shaft.has_node("GroundingWash"), "Optional layers must remove their draw surfaces")
	check(shaft.get_children(true).size() == 1, "A beam-only component must stay one surface")
	print("Light shaft checks: ", "PASS" if failures == 0 else "FAIL")
	quit(failures)
