extends SceneTree
var failures := 0
func _initialize() -> void:
	call_deferred("run")
func check(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		failures += 1
func touch(button: Button, pressed: bool, cancelled: bool = false) -> void:
	var event := InputEventScreenTouch.new()
	event.index = 0
	event.position = button.get_global_rect().get_center()
	event.pressed = pressed
	event.canceled = cancelled
	button._input(event)
func run() -> void:
	check(ProjectSettings.get_setting("application/run/main_scene") == "res://UI/main_menu/main_menu.tscn", "Game must launch to the title screen")
	MemoryExplorer.preferred_avatar = MemoryExplorer.Avatar.SOREN
	var main = load("res://UI/main_menu/main_menu.tscn").instantiate()
	root.add_child(main)
	current_scene = main
	await process_frame
	var male = main.get_node("CharacterPicker/Soren")
	var female = main.get_node("CharacterPicker/Vivian")
	var infinity = main.get_node("Infinity")
	check(main.get_node("EvermoreTitle").text == "EVERMORE", "Main menu must show the game title")
	check(male.button_pressed and not female.button_pressed, "Main menu must reflect the preferred avatar")
	check(male._ink_alpha > 0.99 and female._ink_alpha < 0.2, "Unselected avatar symbol must be transparent")
	check(male.get_global_rect().position.x > main.size.x * 0.7 and male.get_global_rect().position.y > main.size.y * 0.7, "Avatar icons must sit at the bottom right")
	touch(female, true)
	touch(female, false, true)
	check(MemoryExplorer.preferred_avatar == MemoryExplorer.Avatar.SOREN, "Cancelled avatar touch must preserve selection")
	touch(female, true)
	touch(female, false)
	female._process(1.0)
	male._process(1.0)
	check(MemoryExplorer.preferred_avatar == MemoryExplorer.Avatar.VIVIAN and female.button_pressed and not male.button_pressed, "Female symbol must choose Vivian exclusively")
	check(female._ink_alpha > 0.99 and male._ink_alpha < 0.2, "Symbol opacity must follow selection")
	touch(infinity, true)
	var drag := InputEventScreenDrag.new()
	drag.index = 0
	drag.position = infinity.get_global_rect().get_center() + Vector2(30, 0)
	infinity._input(drag)
	touch(infinity, false)
	check(not main._travelling, "Dragging the infinity symbol must not navigate")
	touch(infinity, true)
	touch(infinity, false)
	check(main._travelling and male.disabled and female.disabled, "Transition must lock character selection")
	main.enter_timeline()
	await create_timer(1.1).timeout
	check(current_scene.scene_file_path == "res://UI/memory_lane/memory_lane.tscn", "Infinity must open the timeline")
	check(not current_scene.has_node("CharacterPicker"), "Timeline must no longer contain character selection")
	check(not current_scene._returning, "Main menu entry must play the full timeline unfolding")
	check(not root.has_meta(&"timeline_from_main_menu"), "Timeline must consume the transition request")
	check(MemoryExplorer.preferred_avatar == MemoryExplorer.Avatar.VIVIAN, "Avatar choice must survive entry")
	current_scene.return_to_main_menu()
	await create_timer(0.9).timeout
	check(current_scene.scene_file_path == "res://UI/main_menu/main_menu.tscn", "Timeline back control must return to the main menu")
	check(current_scene.get_node("CharacterPicker/Vivian").button_pressed, "Main menu must retain the selected avatar on return")
	var menu := current_scene
	menu.size = Vector2(390, 844)
	menu._layout()
	await process_frame
	var picker: Control = menu.get_node("CharacterPicker")
	check(picker.position.x >= 0 and picker.get_rect().end.x <= 390, "Avatar picker must fit portrait width")
	check(menu.get_node("Infinity").position.y > menu.get_node("EvermoreTitle").get_rect().end.y, "Infinity must remain below the title in portrait")
	print("Main menu: ", "PASS" if failures == 0 else "FAIL")
	quit(failures)
