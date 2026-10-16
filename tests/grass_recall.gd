extends SceneTree
## Run headless for state checks; add -- --capture for actual rendered previews.
var failures: int = 0
func _initialize() -> void:
	call_deferred("run")
func check(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		failures += 1
func run() -> void:
	var scene := load("res://scenes/effects/recall_test.tscn").instantiate() as Node3D
	root.add_child(scene)
	await process_frame
	var recall: GrassRecall = scene.recall
	var patch: PainterlyGrassPatch = scene.get_node("Subjects/Grass")
	check(recall.progress == 0.0 and not recall.playing, "Scene should wait for discovery in an empty state")
	var regular := load("res://components/foliage/painterly_grass_patch.tscn").instantiate() as PainterlyGrassPatch
	root.add_child(regular)
	regular.position.x = 100.0
	check(regular.get_node("GrassTufts").material_override.shader == PainterlyGrassPatch.FOLIAGE_SHADER, "Ordinary patches must keep the original shader")
	var batch: MultiMeshInstance3D = patch.get_node("GrassTufts")
	var mesh := batch.multimesh
	var first := mesh.get_instance_transform(0)
	recall.seek(0.5)
	check(batch.multimesh == mesh and mesh.get_instance_transform(0) == first, "Scrubbing must not rebuild scatter or move instance roots")
	check(recall._tufts != recall._leaves, "Leaves and tufts need independent stage timing")
	recall.play()
	patch.patch_seed += 1
	await process_frame
	await process_frame
	check(recall.progress >= 0.5 and recall.playing, "Rebuilds must preserve recall progress and playback")
	check(patch.get_node("GrassTufts").material_override == recall._tufts, "Rebuild must rebind current materials")
	recall.seek(0.99)
	recall._process(recall.duration)
	check(recall.progress == 1.0 and not recall.playing, "Recall must finish and stop")
	check(recall._tufts.get_shader_parameter("recall_complete") == 1.0, "Completed recall must resolve to the full material")
	scene.get_node("Explorer").position = Vector3(20, 0, 20)
	await process_frame
	check(recall.progress == 1.0, "Walking away must not reverse recall")
	scene._reset()
	await process_frame
	check(recall.progress == 0.0 and not recall.playing, "Reset must clear recall and wait for approach")
	scene.get_node("Explorer").position = scene.get_node("Subjects/RecallOrigin").position
	scene._process(0.0)
	check(recall.playing, "Approach must trigger recall")
	if "--capture" in OS.get_cmdline_user_args():
		root.content_scale_size = Vector2i(1280, 720)
		scene._waiting = false
		scene.get_node("Explorer").position = Vector3(0, 0, 4.2)
		recall.playing = false
		for stage in [0.0, 0.45, 1.0]:
			recall.seek(stage)
			await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("/tmp/grass-recall-%d.png" % roundi(stage * 100.0))
	print("Grass recall checks: ", "PASS" if failures == 0 else "FAIL")
	quit(failures)
