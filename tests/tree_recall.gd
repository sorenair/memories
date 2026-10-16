extends SceneTree
var failures: int = 0
func _initialize() -> void:
	call_deferred("run")
func check(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		failures += 1
func run() -> void:
	var scene := load("res://scenes/effects/tree_recall_test.tscn").instantiate() as Node3D
	root.add_child(scene)
	await process_frame
	var recall: TreeRecall = scene.recall
	var tree: PainterlyTree = scene.get_node("Subjects/Tree")
	var canopy: MultiMeshInstance3D = tree.get_node("Canopy")
	var mesh := canopy.multimesh
	check(recall.progress == 0.0 and not recall.playing, "Tree study must wait for approach")
	check(not tree.get_node("FallingLeaves").visible, "Hidden tree must not shed leaves")
	check(tree.get_node("TrunkCollision").get_child(0).disabled, "Hidden tree must not block the explorer")
	recall.seek(0.20)
	check(recall._bark.get_shader_parameter("recall_solid_progress") > 0.0, "Trunk must manifest in the first stage")
	check(recall._canopy.get_shader_parameter("recall_local_progress") == 0.0, "Trunk must begin before the canopy")
	recall.seek(0.42)
	check(recall._bark.get_shader_parameter("recall_solid_progress") == 1.0, "Branches must finish at the wood stage boundary")
	check(recall._canopy.get_shader_parameter("recall_local_progress") > 0.2, "Canopy must already be unfurling when wood finishes")
	await process_frame
	check(not tree.get_node("TrunkCollision").get_child(0).disabled, "Visible wood must restore collision")
	recall.seek(0.75)
	check(recall._canopy.get_shader_parameter("recall_local_progress") > 0.0, "Canopy must unfurl in the second stage")
	check(canopy.multimesh == mesh, "Recall must not regenerate leaf scatter")
	tree.falling_leaf_rate = 1.2
	tree.falling_leaf_count = 8
	check(not tree.get_node("FallingLeaves").visible, "Changing falling-leaf settings must not bypass recall")
	recall.play()
	tree.rebuild()
	check(tree.get_recall_controller() == recall and recall.progress == 0.75 and recall.playing, "Tree rebuild must preserve playback")
	recall._process(recall.duration)
	check(recall.progress == 1.0 and tree.get_node("FallingLeaves").visible, "Completed tree can shed leaves")
	var original_bark: Shader = PainterlyTree.BARK_SHADER
	tree.recall_enabled = false
	check(tree.get_recall_controller() == null, "Tree toggle must remove recall")
	check(tree.get_node("TrunkAndBranches").material_override.shader == original_bark, "Disabling must restore bark")
	check(tree.get_node("Canopy").material_override.shader == PainterlyTree.CANOPY_SHADER, "Disabling must restore canopy shader")
	# All six procedural shapes must preserve recall, palette and wind after rebuilds.
	var variant := load("res://components/foliage/painterly_tree.tscn").instantiate() as PainterlyTree
	variant.recall_enabled = true
	root.add_child(variant)
	var effect: TreeRecall = variant.get_recall_controller()
	effect.auto_discover = false
	for kind in range(6):
		variant.tree_type = kind
		variant.rebuild()
		effect.seek(0.75)
		variant.wind_strength = 0.07
		variant.palette_preset = 6
		check(effect._canopy.get_shader_parameter("wind_strength") == 0.07, "Recalled variants must retain live wind")
		check(effect._canopy.get_shader_parameter("leaf_color") == variant.palette.leaf_color, "Recalled variants must retain live palette")
		effect.seek(1.0)
		check(effect._canopy.get_shader_parameter("recall_local_progress") == 1.0, "Every variant must resolve its full canopy")
	variant.leaf_sprays_per_cluster = 0
	variant.trunk_collision = false
	variant.rebuild()
	check(variant.get_node("Canopy").multimesh.instance_count == 0 and not variant.has_node("TrunkCollision"), "Recall must support bare decorative trees")
	variant.queue_free()
	# Standalone proximity, including a second explorer and leaving during animation.
	tree.recall_enabled = true
	recall = tree.get_recall_controller()
	recall.auto_discover = true
	var explorer := Node3D.new()
	explorer.add_to_group(&"explorers")
	root.add_child(explorer)
	explorer.position = Vector3(100, 0, 100)
	scene.get_node("Explorer").position = Vector3(100, 0, 100)
	recall._process(0.1)
	check(recall.progress == 0.0, "Distant tree must wait for approach")
	explorer.position = tree.global_position + Vector3(0, 5, 0)
	recall._process(0.1)
	check(recall.progress == 0.0, "Airborne explorer must not trigger tree")
	explorer.position = tree.global_position
	recall._process(0.1)
	check(recall.playing, "Second nearby explorer must trigger tree")
	explorer.position = Vector3(100, 0, 100)
	recall._process(recall.duration)
	check(recall.progress == 1.0, "Tree must finish after player leaves")
	if "--capture" in OS.get_cmdline_user_args():
		root.content_scale_size = Vector2i(1280, 720)
		scene.recall = recall
		scene._waiting = false
		scene.get_node("Explorer").position = Vector3(0, 0, 4.2)
		recall.auto_discover = false
		recall.playing = false
		for stage in [0.0, 0.20, 0.35, 0.42, 0.75, 1.0]:
			recall.seek(stage)
			await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("/tmp/tree-recall-%d.png" % roundi(stage * 100.0))
	print("Tree recall checks: ", "PASS" if failures == 0 else "FAIL")
	quit(failures)
