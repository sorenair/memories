extends SceneTree
var failures: int = 0

func check(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		failures += 1

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var menu = load("res://UI/memory_lane/memory_lane.tscn").instantiate()
	root.add_child(menu)
	current_scene = menu
	menu.select_memory(3)
	menu.free()
	var world = load("res://scenes/world/memory_world.tscn").instantiate()
	root.add_child(world)
	current_scene = world
	await process_frame
	var button = world.get_node("Controls/ReturnToTimeline")
	check(button.size.x >= 100.0 and button.size.y >= 100.0, "Timeline glyph must have a generous touch target")
	check(button.position.x > root.size.x * 0.8 and button.position.y < 100.0, "Timeline control must sit at the top right")
	var touch := InputEventScreenTouch.new()
	touch.index = 4
	touch.position = button.get_global_rect().get_center()
	touch.pressed = true
	button._input(touch)
	var drag := InputEventScreenDrag.new()
	drag.index = 4
	drag.position = touch.position - Vector2(40, 0)
	button._input(drag)
	touch.pressed = false
	button._input(touch)
	check(not button._returning, "A drag across the glyph must not accidentally return")
	touch.pressed = true
	button._input(touch)
	touch.canceled = true
	touch.pressed = false
	button._input(touch)
	check(not button._returning, "Cancelled touch must not navigate")
	touch.canceled = false
	touch.pressed = true
	button._input(touch)
	touch.pressed = false
	button._input(touch)
	check(button._returning, "Touching the timeline glyph must start the return fade")
	check(not world.get_node("Explorer").is_physics_processing(), "Return must stop player movement during the fade")
	check(root.has_node("MemoryTransitionVeil"), "Return fade must survive the scene swap")
	button.return_to_timeline()
	await create_timer(1.0).timeout
	check(current_scene.scene_file_path == "res://UI/memory_lane/memory_lane.tscn", "Return button must open the timeline")
	check(current_scene.selected_index == 3, "Timeline must remember the selected memory")
	check(current_scene._returning, "Timeline return must use the shorter entrance")
	check(not current_scene.has_node("MemoryTransitionVeil"), "Return veil must clean up after fading out")
	print("Timeline return smoke checks: ", "PASS" if failures == 0 else "FAIL")
	quit(failures)
