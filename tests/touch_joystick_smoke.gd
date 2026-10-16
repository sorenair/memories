extends SceneTree
## godot --headless --path . --script tests/touch_joystick_smoke.gd
var failures: int = 0

func check(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		failures += 1

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var stick = load("res://scripts/exploration_input.gd").new()
	stick.size = Vector2(1920, 886)
	root.add_child(stick)
	stick.set_process(false)
	check(stick._origin.x < stick.size.x * 0.2 and stick._origin.y > stick.size.y * 0.7, "Joystick must sit in the bottom-left corner")
	check(stick._activity == 0.0, "Joystick must begin in its transparent idle state")
	var touch := InputEventScreenTouch.new()
	touch.index = 0
	touch.position = stick.size * 0.5
	touch.pressed = true
	stick._input(touch)
	check(stick._touch_id == -1, "Touches outside the fixed joystick must not capture movement")
	touch.position = stick._origin
	stick._input(touch)
	var drag := InputEventScreenDrag.new()
	drag.index = 0
	drag.position = stick._origin + Vector2(2, 0)
	stick._input(drag)
	check(stick.get_movement() == Vector2.ZERO, "Thumb jitter inside the deadzone must not move the player")
	drag.position = stick._origin + Vector2((stick._radius - stick._thumb_radius) * 0.55, 0)
	stick._input(drag)
	check(is_equal_approx(stick.get_movement().length(), 0.5), "Joystick must preserve analog walking speed beyond the deadzone")
	drag.position = stick._origin + Vector2(stick._radius * 3.0, 0)
	stick._input(drag)
	check(stick.get_movement().is_equal_approx(Vector2.RIGHT), "Dragging outside the ring must clamp to full speed")
	touch.index = 1
	stick._input(touch)
	touch.pressed = false
	stick._input(touch)
	check(stick._touch_id == 0, "A second finger must not steal or release the joystick")
	stick._process(0.3)
	check(stick._activity > 0.99, "Joystick circles must become opaque while held")
	check(stick._thumb_offset.length() <= stick._radius - stick._thumb_radius, "Thumb circle must stay inside the outline")
	touch.index = 0
	touch.canceled = true
	stick._input(touch)
	check(stick.get_movement() == Vector2.ZERO, "Cancelled touches must stop movement immediately")
	stick._process(1.0)
	check(stick._activity < 0.001 and stick._thumb_offset.length() < 0.01, "Joystick must fade and recenter after release")
	touch.pressed = true
	touch.canceled = false
	stick._input(touch)
	stick._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	check(stick._touch_id == -1 and stick.get_movement() == Vector2.ZERO, "Focus loss must release the joystick")
	Input.action_press("move_forward")
	check(stick.get_movement().is_equal_approx(Vector2.UP), "Keyboard movement must remain available")
	Input.action_release("move_forward")
	stick.size = Vector2(390, 844)
	stick._layout()
	check(stick._origin.x - stick._radius >= 24.0 and stick._origin.y + stick._radius < stick.size.y - 24.0, "Portrait layout must preserve a comfortable edge margin")
	var mouse := InputEventMouseButton.new()
	mouse.button_index = MOUSE_BUTTON_LEFT
	mouse.pressed = true
	mouse.position = stick._origin
	stick._input(mouse)
	var motion := InputEventMouseMotion.new()
	motion.position = stick._origin - Vector2(0, stick._radius * 2.0)
	stick._input(motion)
	check(stick.get_movement().is_equal_approx(Vector2.UP), "Mouse dragging must support desktop preview")
	mouse.pressed = false
	mouse.position = motion.position
	stick._input(mouse)
	check(stick.get_movement() == Vector2.ZERO, "Mouse release outside the ring must stop movement")
	stick.process_mode = Node.PROCESS_MODE_DISABLED
	touch.position = stick._origin
	stick._input(touch)
	check(stick._touch_id == -1, "Disabled arrival controls must ignore new touches")
	print("Touch joystick smoke checks: ", "PASS" if failures == 0 else "FAIL")
	quit(failures)
