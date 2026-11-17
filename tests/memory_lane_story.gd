extends SceneTree
## Adaptive layout, native input, scale continuity, and safe two-finger gestures.
const Layout := preload("res://UI/memory_lane/story_layout.gd")
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		failures += 1

func touch(point: Vector2, pressed: bool, index: int = 0, cancelled: bool = false) -> void:
	var event := InputEventScreenTouch.new()
	event.position = point
	event.pressed = pressed
	event.index = index
	event.canceled = cancelled
	root.push_input(event, true)

func drag(point: Vector2, index: int = 0) -> void:
	var event := InputEventScreenDrag.new()
	event.position = point
	event.index = index
	root.push_input(event, true)

func tap(point: Vector2) -> void:
	touch(point, true)
	touch(point, false)

func settle(menu: Control) -> void:
	var deadline := Time.get_ticks_msec() + 2000
	while menu._view_tween != null and menu._view_tween.is_running() and Time.get_ticks_msec() < deadline:
		await process_frame
	check(is_equal_approx(menu._zoom, 1.0 if menu._story_target else 0.0), "Scale motion must settle at its destination")

func model_checks() -> void:
	for count in [0, 1, 3, 13, 120, 600]:
		var memories: Array[Dictionary] = []
		for index in count:
			memories.append({"period": "%04d-%02d" % [2018 + int(index / 24.0), int(index / 2.0) % 12 + 1]})
		for width in [390.0, 844.0, 1920.0]:
			var layout := Layout.build(memories, width, ThemeDB.fallback_font, 28, int(count / 2.0))
			var marks: PackedFloat32Array = layout.positions
			check(marks.size() == count, "Overview must keep every memory addressable")
			if count > 1:
				check(marks[-1] - marks[0] >= width * 0.8, "Small and large catalogs must both fill the screen")
				for index in range(1, count):
					check(marks[index] > marks[index - 1], "Overview positions must remain ordered")
			elif count == 1:
				check(is_equal_approx(marks[0], width * 0.5), "A single memory must remain centered")
			for row in ["years", "months"]:
				var previous_right := -100.0
				for label in layout[row]:
					check(label.left >= 0 and label.right <= width, "Period labels must fit the viewport")
					check(label.left > previous_right, "Period labels must never overlap")
					previous_right = label.right
					if row == "years":
						check(is_equal_approx(label.x, marks[label.first]) and label.index == label.first, "Year labels and taps must anchor to the year's first memory")

func run() -> void:
	model_checks()
	root.get_node("LanSession")._main_menu_opened = true
	root.content_scale_size = Vector2i(1920, 886)
	root.size = Vector2i(1920, 886)
	var menu = load("res://UI/memory_lane/memory_lane.tscn").instantiate()
	root.add_child(menu)
	current_scene = menu
	await process_frame
	menu._finish_entrance()
	menu.select_memory(9)
	menu._position = 9.0
	check(menu._story.periods[0].year == "2025" and menu._story.periods[0].text == "Nov" and menu._story.periods[0].last == 1, "Axe Game must join the November 2025 period")
	check(menu._story.periods[-1].text == "Oct" and menu._story.periods[-1].year == "2026", "The overview must end at the latest authored memory")
	var date: Button = menu.get_node("SelectedDate")
	tap(date.get_global_rect().get_center())
	check(menu._story_target, "Tapping the selected date must open the story")
	await create_timer(0.18).timeout
	check(menu._zoom > 0.0 and menu._zoom < 1.0, "Scale changes must interpolate smoothly")
	check(menu._mark_x(9) > menu.size.x * 0.5 and menu._mark_x(9) < menu._story.positions[9], "The selected mark must travel continuously into its story slot")
	await create_timer(0.62).timeout
	check(menu._zoom < 1.0 and menu._view_tween.is_running(), "A full scale transfer must remain gradual beyond the previous fast duration")
	await settle(menu)
	check(is_equal_approx(menu._zoom, 1.0), "Overview must settle fully")
	check(not menu.get_node("Recall").visible and menu.get_node("Recall").disabled, "Recall must recede in the story view")
	check(menu.get_node("MemoryTitle").modulate.a == 0.0, "The memory title must recede in the story view")
	check(not date.visible and date.disabled, "Overview must have no return-to-memory text button or hidden hit target")
	tap(menu.get_node("Recall").get_global_rect().get_center())
	check(menu._story_target, "Tapping the former return-button area must not change scale")
	var museum_x: float = menu._story.positions[2]
	tap(Vector2(museum_x, menu._line_y))
	check(menu.selected_index == 2 and not menu._story_target, "Tapping an overview mark must expand that memory")
	check(is_equal_approx(menu._mark_x(2), museum_x), "The chosen mark must start expanding from its overview position")
	await settle(menu)
	check(is_equal_approx(menu._mark_x(2), menu.size.x * 0.5), "The expanded memory must settle at the central selection point")
	check(menu.get_node("MemoryTitle").text == "First Date At MIA", "Zooming in must preserve the updated museum title")
	check(not menu.get_node("Recall").disabled, "Recall must become available in the memory view")
	# Exercise real mouse GUI routing over the date, whose hit area also permits swipes.
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = date.get_global_rect().get_center()
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		root.push_input(event, true)
	await settle(menu)
	check(is_equal_approx(menu._zoom, 1.0), "Mouse date clicks must also open the story")
	for label in menu._story.months:
		if label.text == "Dec":
			tap(Vector2(label.x, menu._line_y + 34.0))
			break
	await settle(menu)
	check(menu.selected_index == 3 and menu._zoom == 0.0, "Tapping a month must expand around that section")
	menu.show_story()
	await settle(menu)
	for label in menu._story.years:
		if label.text == "2026":
			check(is_equal_approx(label.x, menu._story.positions[5]), "The 2026 label must sit on its first memory")
			tap(Vector2(label.x, menu._line_y - 46.0))
			break
	await settle(menu)
	check(menu.selected_index == 5, "Tapping a year must expand its first memory")
	menu.show_story()
	await create_timer(0.3).timeout
	var before_first: float = menu._mark_x(0)
	var before_chosen: float = menu._mark_x(7)
	var before_last: float = menu._mark_x(menu.MEMORIES.size() - 1)
	var before_velocity: float = menu._origin_velocity()
	tap(Vector2(before_chosen, menu._line_y))
	check(menu.selected_index == 7, "A tap during the zoom must select the mark where it is currently drawn")
	check(is_equal_approx(menu._mark_x(0), before_first) and is_equal_approx(menu._mark_x(7), before_chosen) and is_equal_approx(menu._mark_x(menu.MEMORIES.size() - 1), before_last), "Reversing the zoom around a new memory must not jump the thread")
	check(is_equal_approx(menu._origin_velocity(), before_velocity), "Re-anchoring must preserve the thread's current motion")
	await settle(menu)
	check(menu._zoom == 0.0 and is_equal_approx(menu._mark_x(7), menu.size.x * 0.5), "An interrupted zoom must glide into the new selection")
	root.content_scale_size = Vector2i(390, 844)
	root.size = Vector2i(390, 844)
	await process_frame
	var line_y: float = menu._line_y
	touch(Vector2(60, line_y - 20), true, 0)
	touch(Vector2(330, line_y + 20), true, 1)
	drag(Vector2(65, line_y - 20), 0)
	touch(Vector2(65, line_y - 20), false, 0)
	touch(Vector2(330, line_y + 20), false, 1)
	check(menu._zoom == 0.0 and not menu._story_target, "A small two-finger movement must leave the settled scale unchanged")
	touch(Vector2(60, line_y - 20), true, 0)
	touch(Vector2(330, line_y + 20), true, 1)
	drag(Vector2(140, line_y - 20), 0)
	drag(Vector2(250, line_y + 20), 1)
	check(menu._pinching and menu._story_target and menu._zoom == 0.0, "A native pinch must request the next scale without jumping directly into it")
	await create_timer(0.2).timeout
	check(menu._zoom > 0.0 and menu._zoom < 1.0, "The pinch-triggered transfer must animate at its own gentle pace")
	var pinch_progress: float = menu._zoom
	drag(Vector2(200, line_y + 20), 1)
	check(is_equal_approx(menu._zoom, pinch_progress), "Continuing a pinch must not fast-forward the transition")
	touch(Vector2(140, line_y - 20), false, 0)
	touch(Vector2(250, line_y + 20), false, 1)
	await settle(menu)
	check(menu._zoom == 1.0 and not menu._travelling, "Releasing a pinch must settle the story without a stray tap")
	check(menu._story.positions[-1] - menu._story.positions[0] >= 312, "Portrait overview must fill the available width")
	touch(Vector2(140, line_y - 20), true, 2)
	touch(Vector2(250, line_y + 20), true, 3)
	drag(Vector2(60, line_y - 20), 2)
	drag(Vector2(330, line_y + 20), 3)
	touch(Vector2(60, line_y - 20), false, 2)
	touch(Vector2(330, line_y + 20), false, 3)
	await settle(menu)
	check(menu._zoom == 0.0, "A native outward pinch must return to adjacent memories")
	menu.show_story()
	await settle(menu)
	touch(Vector2(menu._story.positions[2], line_y), true)
	drag(Vector2(menu._story.positions[10], line_y))
	check(menu.selected_index == 10 and menu._period_caption(menu.selected_index) == "Jun 2026", "Overview dragging must scrub to the matching memory and calendar period")
	touch(Vector2(menu._story.positions[10], line_y), false)
	await settle(menu)
	check(menu._zoom == 0.0 and menu.selected_index == 10, "Releasing an overview scrub must expand the highlighted memory")
	var recall_point: Vector2 = menu.get_node("Recall").get_global_rect().get_center()
	touch(recall_point, true, 4)
	touch(recall_point + Vector2(130, -160), true, 5)
	drag(recall_point + Vector2(35, -25), 5)
	touch(recall_point, false, 4)
	touch(recall_point + Vector2(35, -25), false, 5)
	await settle(menu)
	check(current_scene == menu and not menu._travelling and menu._zoom == 1.0, "A pinch beginning over Recall must cancel the button tap")
	var magnify := InputEventMagnifyGesture.new()
	magnify.factor = 1.02
	root.push_input(magnify, true)
	await create_timer(0.2).timeout
	check(menu._zoom == 1.0 and menu._story_target, "Small trackpad movements must not change the settled scale")
	magnify.factor = 2.0
	root.push_input(magnify, true)
	check(menu._zoom == 1.0 and not menu._story_target, "A large trackpad gesture must select a destination without an immediate zoom jump")
	await settle(menu)
	check(menu._zoom == 0.0, "Trackpad magnification must also return to the memory view")
	touch(recall_point, true, 6)
	menu._notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
	touch(recall_point, false, 6)
	check(not menu._travelling and menu._touches.is_empty() and menu._pointer == -2, "Focus loss must clear pending button and gesture input")
	menu.show_story()
	await settle(menu)
	for viewport_size in [Vector2i(844, 390), Vector2i(568, 320), Vector2i(390, 844)]:
		root.content_scale_size = viewport_size
		root.size = viewport_size
		await process_frame
		for label in menu._story.years:
			check(is_equal_approx(label.x, menu._story.positions[label.first]), "Year labels must stay anchored to their first memory after rotation")
			check(label.left >= 0 and label.right <= menu.size.x, "Year labels must stay inside the rotated viewport")
	menu.free()
	print("Memory Lane story view: ", "PASS" if failures == 0 else "FAIL")
	quit(failures)
