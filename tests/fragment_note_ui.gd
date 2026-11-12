extends SceneTree
var failures := 0
func _initialize() -> void:
	call_deferred("run")
func check(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		failures += 1
func touch(ui: Control, point: Vector2, pressed: bool, cancelled: bool = false) -> void:
	var event := InputEventScreenTouch.new()
	event.index = 0
	event.position = point
	event.pressed = pressed
	event.canceled = cancelled
	ui._input(event)
func settle() -> void:
	for frame in range(3):
		await process_frame
func run() -> void:
	var ui = load("res://UI/fragments/fragment_interaction.tscn").instantiate()
	root.add_child(ui)
	ui.set_anchors_preset(Control.PRESET_TOP_LEFT)
	ui.size = Vector2(1920, 886)
	ui.enqueue_note("The warm days", "We stayed until the rain softened, listening to the leaves.")
	await settle()
	await create_timer(0.3).timeout
	check(ui._panel.visible and is_equal_approx(ui._panel.modulate.a, 1.0), "Opening must settle to an opaque readable note")
	check(ui._next.text.is_empty() and ui._next.icon == ui.CLOSE_ICON, "Final page must display only the close X icon")
	check(ui._style.corner_radius_top_left == 20 and ui._style.corner_radius_bottom_right == 20, "Note panel corners must be rounded")
	check(is_zero_approx(ui._slide), "Entrance must finish without residual displacement")
	check(ui._panel.position.y > 450 and ui._panel.get_rect().end.y < 886, "Short note must remain in the lower landscape area")
	check(ui._panel.size.y < 350, "Short note must fit its content without excess height")
	check(ui._panel.position.x > 280, "Landscape note must keep clear of the movement joystick")
	check(ui._next.size.y >= 100 and ui._next.get_global_rect().end.y <= ui._panel.get_rect().end.y, "Action must have a generous touch target inside the panel")
	var point: Vector2 = ui._next.get_global_rect().get_center()
	touch(ui, point, true)
	touch(ui, point, false, true)
	check(not ui.current_note.is_empty(), "Cancelled action touch must retain the note")
	touch(ui, point, true)
	var drag := InputEventScreenDrag.new()
	drag.index = 0
	drag.position = point + Vector2(40, 0)
	ui._input(drag)
	touch(ui, point, false)
	check(not ui.current_note.is_empty(), "Dragging over the action must not dismiss the note")
	ui.advance_note()
	check(ui.current_note.is_empty(), "Closing must release the queue immediately")
	ui.enqueue_note("A new trace", "A new page arrived during the closing fade.")
	await create_timer(0.3).timeout
	check(ui._panel.visible and ui.current_note.title == "A new trace", "A new note must interrupt closing without being hidden by a stale tween")
	ui.advance_note()
	await create_timer(0.22).timeout
	ui.size = Vector2(390, 844)
	ui.enqueue_note("A long recollection", "We followed the river until the light disappeared, and found our way home together. ".repeat(35))
	await settle()
	await create_timer(0.3).timeout
	var bounds: Rect2 = ui._panel.get_rect()
	check(bounds.position.x >= 16 and bounds.end.x <= 374 and bounds.position.y >= 24 and bounds.end.y < 700, "Portrait notes must fit the screen above the touch controls")
	check(ui._body.size.y > ui._scroll.size.y, "Long notes must overflow inside the scroll area")
	check(ui._next.get_global_rect().end.y <= bounds.end.y, "Long notes must keep the action visible")
	var before: int = ui._scroll.scroll_vertical
	var scroll_point: Vector2 = ui._scroll.get_global_rect().get_center()
	touch(ui, scroll_point, true)
	drag.position = scroll_point - Vector2(0, 80)
	ui._input(drag)
	touch(ui, drag.position, false)
	check(ui._scroll.scroll_vertical > before and not ui.current_note.is_empty(), "Native touch must scroll prose without advancing it")
	ui.enqueue_note("Next", "A shorter page.")
	check(ui._next.text.is_empty() and ui._next.icon == ui.CONTINUE_ICON, "Queued pages must display only the forward arrow")
	var key := InputEventAction.new()
	key.action = &"ui_accept"
	key.pressed = true
	ui._unhandled_key_input(key)
	await settle()
	check(ui.current_note.title == "Next" and ui._scroll.scroll_vertical == 0, "Keyboard advance must reset scrolling on the next page")
	check(ui._next.icon == ui.CLOSE_ICON, "The final queued page must switch the arrow to X")
	check(ui._panel.size.y < bounds.size.y, "The panel must shrink again for a short page")
	ui.advance_note()
	await create_timer(0.22).timeout
	check(not ui._panel.visible and not ui.blocks_interaction(), "Final dissolve must remove the panel and release the interaction gate")
	print("Fragment note UI: ", "PASS" if failures == 0 else "FAIL")
	quit(failures)
