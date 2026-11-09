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
	root.get_texture().get_image().save_png("/tmp/painterly-smoke-%s.png" % name)
func run() -> void:
	var stage := load("res://tests/scenes/component_test.tscn").instantiate() as Node3D
	root.add_child(stage)
	await process_frame
	await process_frame
	var smoke := stage.subject as PainterlySmoke
	check(smoke != null, "Generic stage must now load the smoke/steam emitter")
	check(smoke.get_children().is_empty() and smoke.get_children(true).size() == 2, "Emitter must use two internal geometry batches")
	check(not smoke.is_processing(), "Normal plume animation must not require CPU processing")
	var triangles := 0
	for batch in smoke.get_children(true):
		triangles += batch.multimesh.mesh.get_faces().size() / 3 * batch.multimesh.instance_count
		check(batch.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF, "Plume batches must avoid shadow passes")
	check(triangles < 400, "Steam must have a small geometry budget")
	var original := smoke.get_node("Wisps").get_instance_id()
	smoke.wind = Vector2(0.5, -0.3)
	smoke.curl_radius = 0.45
	check(smoke.get_node("Wisps").get_instance_id() == original, "Curl/wind edits must preserve geometry")
	check(smoke.preset == 0, "Tuning a preset must switch it to Custom")
	var custom: Color = smoke.get_node("Puffs").multimesh.get_instance_custom_data(0)
	smoke.rebuild()
	if DisplayServer.get_name() != "headless":
		check(smoke.get_node("Puffs").multimesh.get_instance_custom_data(0).is_equal_approx(custom), "Seed must reproduce emission phases")
	var other := load("res://components/vfx/smoke/painterly_smoke.tscn").instantiate() as PainterlySmoke
	other.position.x = 100
	root.add_child(other)
	check(other._materials[0] != smoke._materials[0], "Emitters need independent materials")
	other.queue_free()
	smoke.recall_enabled = true
	var recall: Node = smoke.get_recall_controller()
	recall.set_process(false)
	stage.get_node("Explorer").position = Vector3(100, 0, 100)
	recall._process(0.1)
	check(recall.progress == 0.0, "Emitter must wait for approach when recall is enabled")
	stage.get_node("Explorer").position = Vector3.ZERO
	recall._process(0.1)
	check(recall.playing, "Nearby explorers must recall the emitter")
	recall.auto_discover = false
	recall.seek(0.5)
	smoke.rebuild()
	for material in smoke.recall_materials():
		check(material.get_shader_parameter("recall_visibility") == 0.5, "Rebuild must preserve fade on both layers")
	smoke.recall_enabled = false
	stage.get_node("Explorer").position = Vector3(0, 0, 4.5)
	for material in smoke.recall_materials():
		check(material.get_shader_parameter("recall_visibility") == 1.0, "Disabling recall must restore emission")
	for preset in range(1, 5):
		smoke.preset = preset
		await process_frame
		await process_frame
		check(smoke.preset == preset, "Applying a preset should preserve its selection")
		check(smoke.get_node("Puffs").multimesh.instance_count == smoke.puff_count, "Preset must rebuild puff density")
		check(smoke.get_node("Wisps").multimesh.instance_count == smoke.wisp_count, "Preset must rebuild stroke count")
	if "--capture" in OS.get_cmdline_user_args():
		root.content_scale_size = Vector2i(1280, 720)
		for preset in range(1, 5):
			smoke.preset = preset
			await process_frame
			await process_frame
			await capture(["", "steam", "smoke", "candle", "mist"][preset])
		smoke.preset = 1
		stage._floor_selected(1)
		await create_timer(0.1).timeout
		await capture("steam-white")
		stage._floor_selected(0)
		smoke.animation_speed = 0.0
		await create_timer(0.1).timeout
		var still_a := await snapshot()
		await create_timer(0.35).timeout
		var still_b := await snapshot()
		check(changes(still_a, still_b) == 0, "Zero animation speed must freeze the entire plume")
		smoke.animation_speed = 0.8
		await create_timer(0.1).timeout
		var moving_a := await snapshot()
		await create_timer(0.6).timeout
		var moving_b := await snapshot()
		var moved := changes(moving_a, moving_b)
		check(moved > 40, "Painterly puffs and wisps must visibly rise/curl")
		print("Smoke motion changed channels: ", moved)
	smoke.density = 0.0
	check(not smoke.get_node("Puffs").visible and not smoke.get_node("Wisps").visible, "Zero density should disable both layers")
	smoke.puff_count = 0
	smoke.wisp_count = 0
	smoke.rebuild()
	check(smoke.get_children(true).is_empty(), "Zero counts must remove all geometry")
	print("Painterly smoke/steam checks: ", "PASS" if failures == 0 else "FAIL", " | default triangles: ", triangles)
	quit(failures)
