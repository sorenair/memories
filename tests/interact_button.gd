extends SceneTree
var failures := 0
func _initialize() -> void:
	call_deferred("run")
func check(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		failures += 1
func touch(button: Control, pressed: bool, cancelled: bool = false) -> void:
	var event := InputEventScreenTouch.new()
	event.index = 1
	event.position = button.get_global_transform_with_canvas() * button._origin
	event.pressed = pressed
	event.canceled = cancelled
	button._input(event)
func click(button: Control, pressed: bool) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.position = button.get_global_transform_with_canvas() * button._origin
	event.pressed = pressed
	button._input(event)
func run() -> void:
	var world = load("res://scenes/world/first_meeting_world.tscn").instantiate()
	root.add_child(world)
	current_scene = world
	await physics_frame
	await physics_frame
	var controller = world.get_node("InteractionController")
	var guidance = world.get_node("GuidanceController")
	var button = world.get_node("Controls/InteractButton")
	var fragment: MemoryFragment = world.get_node("Memory/Zones/House/Fragment")
	var player: Node3D = world.get_node("Explorer")
	var notes = world.get_node("Controls/FragmentInteraction")
	var calls := {"actions": 0, "guidance": 0, "components": 0}
	button.action_requested.connect(func(): calls.actions += 1)
	guidance.guidance_started.connect(func(_fragment: MemoryFragment): calls.guidance += 1)
	controller.interaction_performed.connect(func(_target: Node3D, _actor: Node3D): calls.components += 1)
	check(guidance.get_next_fragment() == fragment and not is_instance_valid(guidance.active_guide), "Entry must make the first unfinished fragment available without automatically starting a hint")
	player.global_position = fragment.global_position + Vector3.RIGHT
	player.reset_physics_interpolation()
	controller.refresh_target()
	button._process(1.0)
	check(controller.target == fragment and button.available and button._activity > 0.99, "An unfinished fragment must enable guidance independently of the nearby component target")
	touch(button, true)
	touch(button, false, true)
	check(calls.actions == 0 and calls.guidance == 0, "Cancelled HUD touches must not request guidance")
	touch(button, true)
	var drag := InputEventScreenDrag.new()
	drag.index = 1
	drag.position = button.get_global_transform_with_canvas() * (button._origin + Vector2(35, 0))
	button._input(drag)
	touch(button, false)
	check(calls.actions == 0 and calls.guidance == 0, "Dragging off the guidance circle and returning must cancel the request")
	touch(button, true)
	touch(button, false)
	check(calls.actions == 1 and calls.guidance == 1 and calls.components == 0 and not fragment.collected, "HUD touch must start guidance through its independent action signal without collecting the nearby fragment")
	check(guidance.active_destination == fragment and is_instance_valid(guidance.active_guide) and guidance.active_guide.is_playing(), "The auto-wired guidance controller must play a hint to the first unfinished fragment")
	var first = guidance.active_guide
	first.set_process(false)
	var key := InputEventKey.new()
	key.physical_keycode = KEY_E
	key.pressed = true
	click(button, true)
	click(button, false)
	button._unhandled_key_input(key)
	check(not button.available and calls.actions == 1 and calls.guidance == 1, "Mouse and E must be ignored while a brushstroke is active")
	check(not guidance.request_guidance() and is_zero_approx(first._clock), "Direct requests must not bypass the active-stroke lock")
	button._process(0.5)
	check(button._activity < 0.001, "The busy guidance circle must become faint")
	first._process(first.travel_duration+first.trail_duration+0.2)
	guidance._physics_process(0.0)
	check(button.available, "Finishing the brushstroke must restore the guidance button")
	click(button, true)
	click(button, false)
	check(calls.actions == 2 and calls.guidance == 2 and calls.components == 0 and not fragment.collected, "HUD mouse clicks must request guidance without activating components")
	var second = guidance.active_guide
	second.set_process(false)
	second._process(second.travel_duration+second.trail_duration+0.2)
	guidance._physics_process(0.0)
	button._unhandled_key_input(key)
	check(calls.actions == 3 and calls.guidance == 3 and calls.components == 0 and not fragment.collected, "E must request guidance without activating the nearby fragment")
	notes.enqueue_note("Modal", "Reading a note.")
	touch(button, true)
	touch(button, false)
	button._unhandled_key_input(key)
	check(calls.actions == 3 and calls.guidance == 3 and button._pointer == -1, "Open notes must block guidance touch and keyboard input")
	check(not guidance.request_guidance(), "The controller must also reject guidance requested directly while notes are open")
	notes.advance_note()
	player.set_physics_process(false)
	touch(button, true)
	touch(button, false)
	button._unhandled_key_input(key)
	button._process(0.5)
	check(calls.actions == 3 and calls.guidance == 3 and button._activity < 0.001, "Arrival and return movement locks must gate guidance and fade the circle")
	check(not guidance.request_guidance(), "The controller must also reject direct requests during movement locks")
	player.set_physics_process(true)
	button.set_anchors_preset(Control.PRESET_TOP_LEFT)
	button.size = Vector2(390, 844)
	button._layout()
	check(button._origin.x - button._radius > 0 and button._origin.y - button._radius > 0 and button._origin.x + button._radius < 390 and button._origin.y + button._radius < 844, "Guidance circle must fit portrait screens")
	check(not fragment.collected and calls.components == 0, "Every guidance input must leave component activation untouched")
	world.free()
	await create_timer(0.35).timeout
	print("Guidance interact button: ", "PASS" if failures == 0 else "FAIL")
	quit(failures)
