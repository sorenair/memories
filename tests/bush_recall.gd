extends SceneTree
var failures: int = 0
func _initialize() -> void:
	call_deferred("run")
func check(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		failures += 1
func run() -> void:
	var scene := load("res://scenes/effects/bush_recall_test.tscn").instantiate() as Node3D
	root.add_child(scene)
	await process_frame
	var recall: BushRecall = scene.recall
	var bush: PainterlyBush = scene.get_node("Subjects/Bush")
	check(recall.progress == 0.0 and not recall.playing, "Bush must begin hidden and wait for approach")
	var batch: MultiMeshInstance3D = bush.get_node("Foliage")
	var mesh := batch.multimesh
	recall.seek(0.5)
	check(batch.multimesh == mesh, "Bush recall must preserve generated scatter")
	recall.play()
	bush.bush_seed += 1
	await process_frame
	await process_frame
	check(recall.progress >= 0.5 and recall.playing, "Rebuild must preserve bush playback")
	check(bush.get_node("Foliage").material_override.shader == BushRecall.LEAF_SHADER, "Rebuild must restore recall shader")
	check(recall._foliage.get_shader_parameter("disturbance_strength") == bush.disturbance_strength, "Recall must retain explorer disturbance")
	recall._process(recall.duration)
	check(recall.progress == 1.0 and not recall.playing, "Bush recall must settle complete")
	recall.apply_wave(Vector3(2, 0, 1), 3.5, true)
	bush.rebuild()
	recall._process(0.0)
	check(recall._wave_radius == 3.5 and recall._wave_complete, "External cluster state must survive rebuild")
	var regular := load("res://components/foliage/painterly_bush.tscn").instantiate() as PainterlyBush
	root.add_child(regular)
	check(regular.get_node("Foliage").material_override.shader == PainterlyBush.LEAF_SHADER, "Regular bushes must keep their original shader")
	regular.queue_free()
	scene._reset()
	scene.get_node("Explorer").position = scene.get_node("Subjects/RecallOrigin").position
	scene._process(0.0)
	check(recall.playing, "Approach must trigger bush recall")
	if "--capture" in OS.get_cmdline_user_args():
		root.content_scale_size = Vector2i(1280, 720)
		scene._waiting = false
		scene.get_node("Explorer").position = Vector3(0, 0, 4.2)
		recall.playing = false
		for stage in [0.0, 0.45, 1.0]:
			recall.seek(stage)
			await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("/tmp/bush-recall-%d.png" % roundi(stage * 100.0))
	print("Bush recall checks: ", "PASS" if failures == 0 else "FAIL")
	quit(failures)
