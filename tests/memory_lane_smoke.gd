extends SceneTree
## Headless integration checks for menu input and travel into the playable world.
var failures: int = 0

func check(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		failures += 1

func _initialize() -> void:
	call_deferred("run")

func touch(menu: Control, point: Vector2, pressed: bool, index: int = 0, cancelled: bool = false) -> void:
	var event := InputEventScreenTouch.new()
	event.position = point
	event.index = index
	event.pressed = pressed
	event.canceled = cancelled
	menu._input(event)

func run() -> void:
	var menu = load("res://UI/memory_lane/memory_lane.tscn").instantiate()
	root.add_child(menu)
	current_scene = menu
	await process_frame
	check(menu.selected_index == 1, "Museum date should be selected initially")
	menu.set_process(false)
	menu._entrance_time = 0.0
	menu._apply_entrance()
	check(menu.get_node("MemoryTitle").modulate.a == 0.0, "Title must begin invisible")
	check(menu.get_node("Recall").modulate.a == 0.0, "Recall must begin invisible")
	menu._process(0.5)
	check(menu._reveal(0.05, 0.40) == 1.0, "Center point must emerge before the text")
	check(menu._reveal(0.22, 1.15) > 0.0 and menu._reveal(0.22, 1.15) < 1.0, "Thread must progressively unfold")
	check(menu.get_node("MemoryTitle").modulate.a == 0.0, "Title must wait for the thread")
	menu._process(0.75)
	check(menu.get_node("MemoryTitle").modulate.a > 0.0, "Title must emerge after the thread")
	check(menu.get_node("Recall").modulate.a == 0.0, "Recall must appear last")
	menu._process(0.55)
	check(menu.get_node("Recall").modulate.a == 1.0, "Entrance must finish by 1.8 seconds")
	check(is_equal_approx(menu.get_node("MemoryTitle").position.y, menu._title_y), "Title must settle without residual offset")
	menu._entrance_time = 0.2
	menu._apply_entrance()
	var origin := Vector2(menu.size.x * 0.5, menu._line_y)
	touch(menu, origin, true)
	check(menu._entrance_time == menu.ENTRANCE_DURATION, "Touch must finish entrance immediately")
	check(menu.get_node("Recall").modulate.a == 1.0, "Early interaction must expose Recall")
	var drag := InputEventScreenDrag.new()
	drag.index = 0
	drag.position = origin - Vector2(menu._spacing, 0)
	menu._input(drag)
	touch(menu, origin, false, 1)
	check(menu._pointer == 0, "A second finger must not release the active swipe")
	touch(menu, drag.position, false)
	check(menu.selected_index == 2, "A left swipe should select the next memory")
	check(menu.get_node("MemoryTitle").text == "Under the stadium lights", "Selection must update the title")
	for frame in range(80):
		menu._process(1.0 / 60.0)
	check(is_equal_approx(menu._position, 2.0), "Swipe release should settle the mark at the fixed selection point")
	var next := origin + Vector2(menu._spacing, 0)
	touch(menu, next, true)
	touch(menu, next, false)
	check(menu.selected_index == 3, "Tapping a neighboring mark should select it")
	menu.select_memory(-100)
	check(menu.selected_index == 0, "Selection must clamp at the earliest memory")
	menu.select_memory(100)
	check(menu.selected_index == menu.MEMORIES.size() - 1, "Selection must clamp at the newest memory")
	touch(menu, origin, true)
	touch(menu, origin, false, 0, true)
	check(menu._pointer == -2, "Cancelled touch must release the gesture")
	var key := InputEventKey.new()
	key.keycode = KEY_LEFT
	key.pressed = true
	menu._unhandled_key_input(key)
	check(menu.selected_index == 3, "Keyboard left should select the preceding memory")
	menu.size = Vector2(390, 844)
	menu._layout()
	check(menu.get_node("Recall").get_rect().end.y < menu._line_y, "Portrait layout must keep Recall clear of the timeline")
	check(menu.get_node("MemoryTitle").size.x == 326, "Portrait title must fit the available width")
	var recall_point: Vector2 = menu.get_node("Recall").get_global_rect().get_center()
	touch(menu, recall_point, true)
	touch(menu, recall_point, false)
	var transition_veil := root.get_node("MemoryTransitionVeil/Paper")
	await create_timer(0.6).timeout
	check(current_scene != menu, "Touch Recall must change scenes")
	check(current_scene.scene_file_path == "res://scenes/world/memory_world.tscn", "Recall must enter the demo world with its player and camera")
	check(current_scene.has_node("Explorer"), "Recalled world must include the playable explorer")
	var world := current_scene
	var player := world.get_node("Explorer") as CharacterBody3D
	var arrival := world.get_node("MemoryArrival")
	check(arrival._veil == transition_veil, "The same paper veil must bridge both scenes")
	var landing := player.global_position
	check(is_equal_approx(landing.distance_to(world.get_node("Memory/Entry").global_position), 10.0), "Recall must land within a short walk of the clearing")
	check(arrival._veil.modulate.a > 0.9, "Paper veil must survive the scene swap without a background flash")
	check(root.get_node_or_null("MemoryTransitionVeil") == null, "Destination must take ownership of the transition veil")
	check(not player.is_physics_processing(), "Movement must pause during the arrival")
	check(player.get_node("Visual").position.y > 0.0, "Player visual must begin above its landing point")
	check(world.get_node("Controls/ExplorationInput").process_mode == Node.PROCESS_MODE_DISABLED, "Touch controls must pause during arrival")
	check(not root.has_meta(&"memory_recall_arrival"), "Arrival request must be consumed by the destination")
	Input.action_press("move_right")
	await create_timer(0.35).timeout
	check(player.global_position.is_equal_approx(landing), "Held movement must not displace the player during descent")
	check(arrival._veil.modulate.a > 0.5 and arrival._veil.modulate.a < 1.0, "Background must blend gradually during the descent")
	Input.action_release("move_right")
	await arrival.finished
	await physics_frame
	await physics_frame
	check(player.is_physics_processing() and player.is_on_floor(), "Arrival must restore a grounded playable body")
	check(player.get_node("Visual").position.is_equal_approx(Vector3.ZERO), "Arrival must settle the visual at the body")
	check(player.get_node("Visual/Body").material_override == null, "Arrival must restore the original opaque player material")
	check(world.get_node("Controls/ExplorationInput").process_mode == Node.PROCESS_MODE_INHERIT, "Arrival must restore touch controls")
	Input.action_press("move_right")
	for frame in range(20):
		await physics_frame
	Input.action_release("move_right")
	check(player.global_position.distance_to(landing) > 0.1, "Explorer must walk normally after landing")
	print("Memory Lane smoke checks: ", "PASS" if failures == 0 else "FAIL")
	quit(failures)
