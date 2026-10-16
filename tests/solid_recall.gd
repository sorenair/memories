extends SceneTree
var failures: int = 0
func _initialize() -> void:
	call_deferred("run")
func check(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		failures += 1
func run() -> void:
	var scene := load("res://scenes/effects/boulder_recall_test.tscn").instantiate() as Node3D
	root.add_child(scene)
	await process_frame
	var recall: SolidRecall = scene.recall
	var stone: PainterlyBoulder = scene.get_node("Subjects/Boulder")
	check(recall.progress == 0.0, "Stone must wait for approach")
	check(stone.get_node("BoulderCollision").get_child(0).disabled, "Hidden stone must not block players")
	check(recall._shadow.get_shader_parameter("shadow_color").a == 0.0, "Hidden stone must not cast a contact shadow")
	var mesh := stone.get_recall_mesh().mesh
	recall.seek(0.5)
	check(stone.get_recall_mesh().mesh == mesh, "Scanning must not rebuild the stone")
	check(recall._material.get_shader_parameter("recall_solid_progress") == 0.5, "Scan must advance through stone height")
	stone.palette_preset = 4
	check(recall._material.get_shader_parameter("mid_color") == stone.palette.mid_color, "Recall must preserve live palette changes")
	recall.play()
	stone.rebuild()
	check(stone.get_recall_controller() == recall and recall.progress == 0.5 and recall.playing, "Rebuild must preserve recall playback")
	recall._process(recall.duration)
	await physics_frame
	await process_frame
	check(recall.progress == 1.0 and not recall.playing, "Stone must settle completely recalled")
	check(not stone.get_node("BoulderCollision").get_child(0).disabled, "Completed stone must restore collision")
	stone.recall_enabled = false
	check(stone.get_recall_controller() == null and stone.get_recall_mesh().material_override.shader == PainterlyBoulder.STONE_SHADER, "Toggle off must restore ordinary stone materials")
	stone.recall_enabled = true
	recall = stone.get_recall_controller()
	recall.auto_discover = true
	scene.recall = recall
	scene._waiting = false
	scene.get_node("Explorer").position = Vector3(100, 0, 100)
	recall._process(0.1)
	check(recall.progress == 0.0, "Distant boulder must remain hidden")
	scene.get_node("Explorer").position = stone.global_position
	recall._process(0.1)
	check(recall.playing, "Approach must discover the boulder")
	scene.get_node("Explorer").position = Vector3(100, 0, 100)
	recall._process(recall.duration)
	check(recall.progress == 1.0, "Stone must finish and remain recalled when players leave")
	var cluster := load("res://components/scenery/rock_clusters/painterly_rock_cluster.tscn").instantiate() as PainterlyRockCluster
	cluster.recall_enabled = true
	root.add_child(cluster)
	var effect: SolidRecall = cluster.get_recall_controller()
	effect.auto_discover = false
	effect.seek(0.5)
	cluster.rebuild()
	check(effect._material.shader == PainterlyBoulder.RECALL_SHADER and effect.progress == 0.5, "Inherited clusters must support solid recall")
	cluster.rock_count = 0
	cluster.rebuild()
	check(effect._material == null, "Empty clusters must release recall surfaces")
	cluster.rock_count = 3
	cluster.rebuild()
	check(effect._material.get_shader_parameter("recall_solid_progress") == 0.5, "Repopulated cluster must restore recall state")
	cluster.queue_free()
	if "--capture" in OS.get_cmdline_user_args():
		root.content_scale_size = Vector2i(1280, 720)
		scene.get_node("Explorer").position = Vector3(0, 0, 4.2)
		recall.auto_discover = false
		recall.playing = false
		for stage in [0.0, 0.35, 0.65, 1.0]:
			recall.seek(stage)
			await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("/tmp/boulder-recall-%d.png" % roundi(stage * 100.0))
	print("Solid recall checks: ", "PASS" if failures == 0 else "FAIL")
	quit(failures)
