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
	# Presentation checks run independently of the two-process LAN suite.
	root.get_node("LanSession")._main_menu_opened = true
	var main_menu = load("res://UI/main_menu/main_menu.tscn").instantiate()
	root.add_child(main_menu)
	main_menu.get_node("CharacterPicker/Vivian").pressed.emit()
	main_menu.free()
	var menu = load("res://UI/memory_lane/memory_lane.tscn").instantiate()
	root.add_child(menu)
	current_scene = menu
	await process_frame
	check(menu.selected_index == 0, "First Meeting should be selected initially")
	check(menu.get_node("Recall").text.is_empty() and menu.get_node("Recall").action == menu.get_node("Recall").Action.RECALL, "Recall must use the circular arrow without text")
	var recall_paths: Array = menu.get_node("Recall").recall_strokes()
	var head_is_clear := true
	for segment in range(recall_paths[0].size() - 2):
		for wing in range(2):
			if Geometry2D.segment_intersects_segment(recall_paths[0][segment], recall_paths[0][segment + 1], recall_paths[1][wing], recall_paths[1][wing + 1]) != null:
				head_is_clear = false
	check(head_is_clear, "The Recall curve must not cross either arrowhead wing")
	check(menu.MEMORIES.size() == 4, "Timeline must contain three authored memories and Seasonal Demo")
	check(menu.MEMORIES[0].title == "First Meeting" and menu.MEMORIES[0].date == "NOV 12, 2025", "First memory must have the requested title and date")
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
	check(is_equal_approx(menu._line_y, menu.size.y * 0.5), "Timeline must sit at the vertical center")
	check(menu.get_node("MemoryTitle").get_rect().end.y < menu._line_y, "Memory title must remain above the timeline")
	check(menu.get_node("Recall").position.y > menu._line_y + menu._date_font_size * 2.0, "Recall must sit below the date")
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
	check(menu.selected_index == 1, "A left swipe should select the next memory")
	check(menu.get_node("MemoryTitle").text == "Football in the snow", "Selection must update the title")
	for frame in range(80):
		menu._process(1.0 / 60.0)
	check(is_equal_approx(menu._position, 1.0), "Swipe release should settle the mark at the fixed selection point")
	var next := origin - Vector2(menu._spacing, 0)
	touch(menu, next, true)
	touch(menu, next, false)
	check(menu.selected_index == 0, "Tapping a neighboring mark should select it")
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
	check(menu.selected_index == 2, "Keyboard left should select the museum before Seasonal Demo")
	menu.select_memory(0)
	menu.size = Vector2(390, 844)
	menu._layout()
	check(is_equal_approx(menu._line_y, 422.0), "Portrait timeline must remain vertically centered")
	check(menu.get_node("MemoryTitle").get_rect().end.y < menu._line_y, "Portrait title must remain above the timeline")
	check(menu.get_node("Recall").position.y > menu._line_y + menu._date_font_size * 2.0, "Portrait Recall must remain below the date")
	check(menu.get_node("Recall").get_rect().end.y < menu.size.y, "Portrait Recall must fit on screen")
	check(menu.get_node("Recall").size.x >= 168 and menu.get_node("Recall").size.y >= 140, "Portrait Recall must have an enlarged touch area")
	for compact_size in [Vector2(844, 390), Vector2(568, 320)]:
		menu.size = compact_size
		menu._layout()
		check(menu.get_node("Recall").get_rect().end.y <= compact_size.y, "The enlarged Recall target must fit short landscape screens")
	menu.size = Vector2(390, 844)
	menu._layout()
	check(menu.get_node("MemoryTitle").size.x == 326, "Portrait title must fit the available width")
	check(not menu.has_node("CharacterPicker"), "Avatar selection must live on the main menu")
	var recall_point: Vector2 = menu.get_node("Recall").get_global_rect().get_center()
	# Dispatch through the viewport to exercise the icon's native touch handling.
	for pressed in [true, false]:
		var event := InputEventScreenTouch.new()
		event.position = recall_point
		event.index = 0
		event.pressed = pressed
		root.push_input(event, true)
	var transition_veil := root.get_node("MemoryTransitionVeil/Paper")
	await create_timer(0.6).timeout
	check(current_scene != menu, "Touch Recall must change scenes")
	check(current_scene.scene_file_path == "res://scenes/world/first_meeting_world.tscn", "Recall must enter First Meeting with its player and camera")
	check(current_scene.has_node("Explorer"), "Recalled world must include the playable explorer")
	var world := current_scene
	var player := world.get_node("Explorer") as MemoryExplorer
	var vivian := player.get_node("Visual/Vivian") as Node3D
	var soren := player.get_node("Visual/Soren") as Node3D
	var animator := vivian.get_node("AnimationPlayer") as AnimationPlayer
	check(vivian.visible and not soren.visible, "Recall must show only the selected avatar")
	check(animator.current_animation == &"IDLE", "Vivian must begin in IDLE")
	check(animator.get_animation(&"IDLE").loop_mode == Animation.LOOP_LINEAR
		and animator.get_animation(&"WALK").loop_mode == Animation.LOOP_LINEAR,
		"Vivian's imported locomotion clips must both loop")
	var arrival := world.get_node("MemoryArrival")
	check(arrival._veil == transition_veil, "The same paper veil must bridge both scenes")
	var landing := player.global_position
	check(is_equal_approx(landing.distance_to(world.get_node("Memory/Entry").global_position), 0.0), "First Meeting must land on its sidewalk entry")
	check(arrival._veil.modulate.a > 0.0, "Paper veil must bridge the scene swap while uncovering recall")
	check(root.get_node_or_null("MemoryTransitionVeil") == null, "Destination must take ownership of the transition veil")
	check(not player.is_physics_processing(), "Movement must pause during the arrival")
	check(player.get_node("Visual").position == Vector3.ZERO, "Player recall must remain grounded instead of dropping in")
	check(player.has_node("PresenceRecall"), "Local arrival must use the shared explorer recall")
	check(world.get_node("Controls/ExplorationInput").process_mode == Node.PROCESS_MODE_DISABLED, "Touch controls must pause during arrival")
	check(not root.has_meta(&"memory_recall_arrival"), "Arrival request must be consumed by the destination")
	Input.action_press("move_right")
	await create_timer(0.35).timeout
	check(player.global_position.is_equal_approx(landing), "Held movement must not displace the player during recall")
	check(arrival._veil.modulate.a >= 0.0 and arrival._veil.modulate.a < 0.9, "Background must uncover the local recall scan")
	Input.action_release("move_right")
	await arrival.finished
	await physics_frame
	await physics_frame
	check(player.is_physics_processing() and player.is_on_floor(), "Arrival must restore a grounded playable body")
	check(player.get_node("Visual").position.is_equal_approx(Vector3.ZERO), "Arrival must settle the visual at the body")
	var body := vivian.get_node("Armature/Skeleton3D/BODY") as MeshInstance3D
	check(body.get_active_material(0) == preload("res://characters/materials/toon_skin_soren.tres"),
		"Vivian must use the shared toon skin after arrival")
	check(world.get_node("Controls/ExplorationInput").process_mode == Node.PROCESS_MODE_INHERIT, "Arrival must restore touch controls")
	Input.action_press("move_right")
	for frame in range(20):
		await physics_frame
	check(animator.current_animation == &"WALK", "Vivian must play WALK while moving")
	Input.action_release("move_right")
	check(player.global_position.distance_to(landing) > 0.1, "Explorer must walk normally after landing")
	for frame in range(20):
		await physics_frame
	check(animator.current_animation == &"IDLE", "Vivian must return to IDLE after movement stops")
	print("Memory Lane smoke checks: ", "PASS" if failures == 0 else "FAIL")
	quit(failures)
