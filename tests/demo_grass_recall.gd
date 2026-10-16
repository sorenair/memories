extends SceneTree
## Demo discovery is per component, never propagated from one component to another.
var failures: int = 0
func _initialize() -> void:
	call_deferred("run")
func check(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		failures += 1
func run() -> void:
	var memory := load("res://scenes/memories/foliage_demo.tscn").instantiate() as Node3D
	root.add_child(memory)
	var effects: Array[Node] = []
	for component in memory.get_node("Environment").get_children():
		if component is PainterlyGrassPatch or component is PainterlyBush or component is PainterlyTree or component is PainterlyBoulder:
			var effect: Node = component.get_recall_controller()
			check(effect != null and effect.auto_discover, "Each demo recallable component must discover independently")
			effect.set_process(false)
			effects.append(effect)
	check(effects.size() == 31, "Demo should recall foliage, four boulders and a rock cluster independently")
	check(not memory.get_node("RevealClusters").has_node("GrassRecall"), "Demo must not contain a shared recall wave")
	var explorer := Node3D.new()
	explorer.add_to_group(&"explorers")
	root.add_child(explorer)
	explorer.position = Vector3(100, 0, 100)
	for effect in effects:
		effect._process(0.1)
		check(effect.progress == 0.0, "Distant foliage must stay hidden")
	var near_bush: BushRecall = memory.get_node("Environment/MeadowBush").get_recall_controller()
	var far_tree: TreeRecall = memory.get_node("Environment/WestGrove").get_recall_controller()
	var far_bush: BushRecall = memory.get_node("Environment/PondSouthLowBush").get_recall_controller()
	explorer.position = near_bush.patch.global_position + Vector3(0, 5, 0)
	near_bush._process(0.1)
	check(near_bush.progress == 0.0, "Airborne arrivals must not trigger discovery")
	explorer.position = near_bush.patch.global_position
	for effect in effects:
		effect._process(0.2)
	check(near_bush.playing and near_bush.progress > 0.0, "Nearby bush must start recalling")
	check(far_bush.progress == 0.0 and not far_bush.playing, "Nearby bush recall must not reveal distant bushes")
	check(far_tree.progress == 0.0, "Nearby foliage must not reveal distant trees")
	# A player near a patch edge should trigger that patch without entering its center.
	var grass: GrassRecall = memory.get_node("Environment/Meadow").get_recall_controller()
	grass.reset()
	explorer.position = grass.patch.to_global(Vector3(-grass.patch.patch_size.x * 0.5 - 0.8, 0, 0))
	grass._process(0.2)
	check(grass.playing, "Grass must discover near its footprint, not just its center")
	check(far_bush.progress == 0.0, "Recalled grass must not reveal distant bushes")
	explorer.position = Vector3(100, 0, 100)
	for effect in effects:
		effect._process(effect.duration * 2.0)
	check(near_bush.progress == 1.0 and grass.progress == 1.0, "Started components must finish when the explorer walks away")
	check(far_bush.progress == 0.0, "Distant foliage must remain hidden after other animations finish")
	near_bush.patch.rebuild()
	check(near_bush._wave_complete, "Completed local recall must survive geometry rebuilds")
	# Either explorer can independently discover another component.
	var second := Node3D.new()
	second.add_to_group(&"explorers")
	root.add_child(second)
	second.position = far_bush.patch.global_position
	far_bush._process(0.2)
	check(far_bush.playing, "Either explorer must be able to discover an individual bush")
	second.position = far_tree.patch.global_position
	far_tree._process(0.2)
	check(far_tree.playing, "Trees must independently discover the second explorer")
	print("Demo proximity recall checks: ", "PASS" if failures == 0 else "FAIL")
	quit(failures)
