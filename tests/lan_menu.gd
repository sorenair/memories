extends SceneTree
var failures := 0
func _initialize() -> void:
	call_deferred("run")
func check(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		failures += 1
func touch(controls: Control, target: Control, pressed: bool, cancelled: bool = false) -> void:
	var event := InputEventScreenTouch.new()
	event.index = 0
	event.position = target.get_global_rect().get_center()
	event.pressed = pressed
	event.canceled = cancelled
	controls._input(event)
func run() -> void:
	var session := root.get_node("LanSession")
	var menu = load("res://UI/main_menu/main_menu.tscn").instantiate()
	root.add_child(menu)
	current_scene = menu
	await process_frame
	var controls = menu.get_node("LAN")
	check(session.state == session.State.HOSTING and session.menu_mode == session.MenuMode.HOST, "Fresh launch must automatically activate hosting")
	check(controls._row.visible and not controls._address.editable and controls._address.text.is_valid_ip_address(), "Host must use the shared address row without an IP prefix")
	check(not controls._status.visible and not controls._connection.connected, "Waiting status must be conveyed by the disconnected rings only")
	var host_field: Rect2 = controls._address.get_global_rect()
	var host_arrow: Rect2 = controls._submit.get_global_rect()
	var host_indicator: Rect2 = controls._connection.get_global_rect()
	check(controls._buttons.position.x <= 40 and controls._buttons.position.y > menu.size.y * 0.75, "Host/Join must be in the bottom-left corner")
	touch(controls, controls._host, true)
	touch(controls, controls._host, false, true)
	check(session.state == session.State.HOSTING, "Cancelled hosting touch must leave default hosting active")
	touch(controls, controls._host, true)
	touch(controls, controls._host, false)
	check(session.state == session.State.OFFLINE, "Tapping active Host must stop hosting")
	controls._host.pressed.emit()
	check(session.state == session.State.HOSTING and controls._address.text.is_valid_ip_address(), "Hosting must restart without moving the IP row")
	check(not menu.get_node("Proceed").disabled, "Hosting must leave solo navigation available")
	check(controls._submit.disabled and controls._submit.modulate.a == 0.0, "Host must have no visible or interactive arrow")
	check(controls._host.get_theme_stylebox("focus") is StyleBoxEmpty and controls._join.get_theme_stylebox("focus") is StyleBoxEmpty, "Host/Join focus must not draw an underline")
	check(controls._join.get_theme_color("font_hover_color") == controls._join.get_theme_color("font_color"), "Inactive Join must not brighten on hover")
	controls._host.pressed.emit()
	check(session.state == session.State.OFFLINE and controls._row.visible, "Stopping hosting must keep the row in place")
	controls._join.pressed.emit()
	check(controls._row.visible and controls._address.editable, "Join must reuse the address field and arrow")
	await process_frame
	check(controls._address.get_global_rect() == host_field and controls._submit.get_global_rect() == host_arrow and controls._connection.get_global_rect() == host_indicator, "Switching roles must preserve address, arrow, and indicator geometry exactly")
	controls._address.text = "192.168.1.42"
	controls._host.pressed.emit()
	controls._join.pressed.emit()
	check(controls._address.text == "192.168.1.42", "Switching roles must preserve the join draft")
	await create_timer(0.22).timeout
	check(is_equal_approx(controls._submit.modulate.a, 1.0), "Join arrow must fade in")
	check(controls._host.get_theme_color("font_hover_color") == controls._host.get_theme_color("font_color"), "Inactive Host must not brighten on hover")
	touch(controls, controls._host, true)
	check(controls._host.get_theme_color("font_color") == controls.INK, "Touching inactive Host must darken it while held")
	touch(controls, controls._host, false, true)
	check(controls._host.get_theme_color("font_color") == controls.MUTED, "Cancelled touch must restore the inactive color")
	controls._host.pressed.emit()
	await create_timer(0.22).timeout
	check(controls._submit.disabled and is_zero_approx(controls._submit.modulate.a), "Returning to Host must fade the arrow out")
	check(controls._address.get_global_rect() == host_field and controls._submit.get_global_rect() == host_arrow, "Hiding the arrow must preserve field and slot dimensions")
	controls._join.pressed.emit()
	touch(controls, controls._address, true)
	touch(controls, controls._address, false)
	check(controls._address.has_focus(), "Native touch must focus the address field without mouse emulation")
	controls._address.text = "invalid"
	controls._submit.pressed.emit()
	check(session.state == session.State.OFFLINE and controls._status.visible, "Invalid IP must show feedback and preserve offline play")
	controls._address.text = "127.0.0.1"
	controls._submit.pressed.emit()
	check(session.state == session.State.JOINING and not menu.get_node("Proceed").disabled, "Connection attempts must leave timeline navigation available")
	menu.enter_timeline()
	await create_timer(1.2).timeout
	check(current_scene.scene_file_path == "res://UI/memory_lane/memory_lane.tscn" and not current_scene.has_node("LAN"), "Connection controls must move entirely off the timeline")
	check(session.state == session.State.JOINING, "Opening the timeline must not cancel a pending connection")
	session._join_deadline = Time.get_ticks_msec() - 1
	session._process(0.0)
	check(session.state == session.State.OFFLINE and not session.status.is_empty(), "Timed-out connections must fall back to offline without navigation")
	current_scene.return_to_main_menu()
	await create_timer(0.9).timeout
	menu = current_scene
	menu.set_anchors_preset(Control.PRESET_TOP_LEFT)
	menu.size = Vector2(390, 844)
	menu._layout()
	await process_frame
	controls = menu.get_node("LAN")
	check(session.state == session.State.OFFLINE and session.menu_mode == session.MenuMode.JOIN, "Returning to the menu must respect explicit disconnect and the selected role")
	var avatars: Control = menu.get_node("CharacterPicker")
	check(controls._buttons.get_rect().end.x < avatars.position.x, "Portrait Host/Join and avatar choices must not overlap")
	check(controls._row.get_rect().end.x <= 390 - 24 and controls._row.get_rect().end.y < controls._buttons.position.y, "Portrait join field must fit above the bottom controls")
	check(controls._row.get_rect().end.y < avatars.position.y, "Portrait IP entry must not overlap avatar touch targets")
	check(controls._row.position.y > menu.get_node("Proceed").get_rect().end.y, "Connection details must keep the Enter action clear")
	await process_frame
	check(menu.get_node("EvermoreTitle").get_rect().end.x <= 390, "Title must reflow fully after changing orientation")
	print("Main-menu LAN controls: ", "PASS" if failures == 0 else "FAIL")
	session.leave()
	current_scene.free()
	quit(failures)
