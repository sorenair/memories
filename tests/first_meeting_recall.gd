extends SceneTree
## Regression: the actual authored memory opts into per-component proximity recall.
var failures := 0
func _initialize() -> void:
	call_deferred("run")
func check(value: bool, message: String) -> void:
	if not value:
		push_error(message)
		failures += 1
func components(node: Node) -> Array[Node3D]:
	var result: Array[Node3D] = []
	for child in node.get_children():
		if child.has_method("get_recall_controller"):
			result.append(child)
		else:
			result.append_array(components(child))
	return result
func run() -> void:
	var explorer := Node3D.new()
	explorer.add_to_group(&"explorers")
	explorer.position = Vector3(100, 0, 100)
	root.add_child(explorer)
	var memory := load("res://scenes/memories/first_meeting.tscn").instantiate() as Node3D
	root.add_child(memory)
	await process_frame
	await process_frame
	var subjects := components(memory.get_node("Zones"))
	if "--capture" in OS.get_cmdline_user_args():
		var camera := Camera3D.new()
		camera.projection = Camera3D.PROJECTION_ORTHOGONAL
		camera.size = 31.0
		camera.position = Vector3(16, 17, 26)
		root.add_child(camera)
		camera.look_at(Vector3(7, 0, 0))
		camera.current = true
		var environment := WorldEnvironment.new()
		environment.environment = Environment.new()
		environment.environment.background_mode = Environment.BG_COLOR
		environment.environment.background_color = Color("efeadd")
		root.add_child(environment)
		for subject in subjects:
			subject.get_recall_controller().set_process(false)
		var images: Array[Image] = []
		for progress in [0.0, 0.5, 1.0]:
			for subject in subjects:
				subject.get_recall_controller().seek(progress)
			await process_frame
			await RenderingServer.frame_post_draw
			var image := root.get_texture().get_image()
			image.save_png("/tmp/first-meeting-recall-%s.png" % str(progress))
			images.append(image)
		check(images[0].get_data() != images[1].get_data() and images[1].get_data() != images[2].get_data(), "Recall must visibly change rendered geometry")
		for subject in subjects:
			subject.get_recall_controller().reset()
	check(subjects.size() >= 35, "Recall must include foliage, house, fences, arcade props and accent foliage")
	for subject in subjects:
		check(subject.recall_enabled, "Recall must be authored on: " + str(subject.name))
		var effect: Node = subject.get_recall_controller()
		check(is_instance_valid(effect), "Recall controller missing: " + str(subject.name))
		if not is_instance_valid(effect): continue
		effect.set_process(false)
		check(effect.progress == 0.0 and not effect.playing, "Distant components must wait: " + str(subject.name))
		explorer.global_position = subject.global_position
		effect._process(0.1)
		check(effect.playing and effect.progress > 0.0, "Approach must start recall: " + str(subject.name))
		if effect.get_script() == preload("res://components/effects/recall/assembled_recall.gd"):
			check(not effect._materials.is_empty(), "Scan needs painted surfaces: " + str(subject.name))
			effect.seek(0.5)
			subject.rebuild()
			check(subject.get_recall_controller() == effect and effect.progress == 0.5, "Rebuild must preserve recall: " + str(subject.name))
			for material in effect._materials:
				check(material.get_shader_parameter("assembly_progress") == 0.5, "Rebuilt surfaces must preserve scan")
		explorer.position = Vector3(100, 0, 100)
		effect._process(effect.duration * 2.0)
		check(effect.progress == 1.0 and not effect.playing, "Recall must finish after explorer leaves")
		subject.recall_enabled = false
		check(subject.get_recall_controller() == null, "Disabling recall must remove controller")
	# A changed global distance must reach the new solid component adapters too.
	var house: Node3D = memory.get_node("Zones/House/Scenery/House")
	house.recall_enabled = true
	var effect: Node = house.get_recall_controller()
	effect.set_process(false)
	var settings: Resource = preload("res://components/effects/recall/component_recall.gd").settings
	var saved: float = settings.proximity_distance
	explorer.global_position = house.global_position + Vector3(0, 0, 8)
	settings.proximity_distance = 0.0
	effect._process(0.1)
	check(effect.progress == 0.0, "Solid recall must respect small shared reach")
	settings.proximity_distance = 10.0
	effect._process(0.1)
	check(effect.playing, "Solid recall must respond to global reach changes")
	settings.proximity_distance = saved
	memory.free()
	explorer.free()
	var world := load("res://scenes/world/first_meeting_world.tscn").instantiate() as Node3D
	root.add_child(world)
	await physics_frame
	await process_frame
	var meadow: Node = world.get_node("Memory/Zones/House/Scenery/Meadow").get_recall_controller()
	var band: Node = world.get_node("Memory/Zones/Arcade/Scenery/Machines/MechanicalBand").get_recall_controller()
	check(meadow.progress > 0.0, "Actual world entry must start nearby recall")
	check(band.progress == 0.0, "Arcade must remain unrecalled while player is at the house")
	world.get_node("Explorer").global_position = world.get_node("Memory/Zones/Arcade/Scenery/Machines/MechanicalBand").global_position + Vector3(0, 0, 2)
	await physics_frame
	await process_frame
	check(band.progress > 0.0, "Actual world explorer must discover the arcade on approach")
	world.free()
	await create_timer(0.35).timeout
	print("First Meeting recall: ", "PASS" if failures == 0 else "FAIL", " | components: ", subjects.size())
	quit(failures)
