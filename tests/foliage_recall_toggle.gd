extends SceneTree
var failures: int = 0
func _initialize() -> void:
	call_deferred("run")
func check(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		failures += 1
func run() -> void:
	var explorer := Node3D.new()
	explorer.add_to_group(&"explorers")
	root.add_child(explorer)
	explorer.position = Vector3(100, 0, 100)
	for kind in ["grass_patch", "bush"]:
		var component: Node3D = load("res://components/foliage/painterly_%s.tscn" % kind).instantiate()
		root.add_child(component)
		check(component.get_recall_controller() == null, "Disabled foliage should have no recall controller")
		component.recall_enabled = true
		var effect: Node = component.get_recall_controller()
		check(is_instance_valid(effect) and effect.get_parent() == component, "Toggle must create an internal effect on the component")
		check(component.get_children().is_empty(), "Internal effects must not become authored scene children")
		check(effect.auto_discover and not effect.playing, "Enabled standalone foliage should wait for approach")
		explorer.position = Vector3.ZERO
		effect._process(0.1)
		check(effect.playing and effect.progress > 0.0, "Standalone foliage must recall on approach")
		effect._process(effect.duration)
		component.rebuild()
		check(component.get_recall_controller() == effect and effect._wave_complete, "Rebuild must preserve the owned completed effect")
		component.recall_enabled = false
		check(component.get_recall_controller() == null, "Turning recall off must remove its controller")
		var foliage: ShaderMaterial = component.get_node("GrassTufts" if kind == "grass_patch" else "Foliage").material_override
		var original: Shader = load("res://components/foliage/shaders/foliage.gdshader" if kind == "grass_patch" else "res://components/foliage/shaders/tree_canopy.gdshader")
		check(foliage.shader == original, "Turning recall off must immediately restore the original material")
		component.recall_enabled = true
		check(component.get_recall_controller() != effect, "Re-enabling should create a fresh recall")
		component.queue_free()
		explorer.position = Vector3(100, 0, 100)
		await process_frame
	# Individual component toggles remain authoritative in the demo.
	var memory: Node3D = load("res://scenes/memories/foliage_demo.tscn").instantiate()
	memory.get_node("Environment/MeadowBush").recall_enabled = false
	root.add_child(memory)
	check(memory.get_node("Environment/MeadowBush").get_recall_controller() == null, "Disabled demo bush must stay fully visible")
	check(memory.get_node("Environment/SmallBush").get_recall_controller().auto_discover, "Other demo bushes must retain their independent discovery")
	print("Foliage recall toggle checks: ", "PASS" if failures == 0 else "FAIL")
	quit(failures)
