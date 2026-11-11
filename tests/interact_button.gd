extends SceneTree
var failures := 0

class ExampleInteractable extends Node3D:
	var activations := 0
	func can_interact(actor: Node3D) -> bool:
		return global_position.distance_to(actor.global_position) <= 2.0
	func try_activate(actor: Node3D) -> bool:
		if not can_interact(actor):
			return false
		activations += 1
		return true

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		failures += 1

func touch(button: Control, pressed: bool, cancelled: bool = false) -> void:
	var event := InputEventScreenTouch.new()
	event.index = 1
	event.position = button._origin
	event.pressed = pressed
	event.canceled = cancelled
	button._input(event)

func run() -> void:
	var world = load("res://scenes/world/memory_world.tscn").instantiate()
	root.add_child(world)
	current_scene = world
	await process_frame
	var player: Node3D = world.get_node("Explorer")
	var controller = world.get_node("InteractionController")
	var button = world.get_node("Controls/InteractButton")
	var joystick = world.get_node("Controls/ExplorationInput")
	var notes = world.get_node("Controls/FragmentInteraction")
	var fragment: MemoryFragment = world.get_node("Memory/Environment/SummerSpring/SummerFragment")
	var counts := {"requested": 0, "performed": 0}
	controller.interaction_requested.connect(func(_target: Node3D, _actor: Node3D): counts.requested += 1)
	controller.interaction_performed.connect(func(_target: Node3D, _actor: Node3D): counts.performed += 1)
	player.global_position = Vector3(1000, 0, 1000)
	controller.refresh_target()
	button._process(1.0)
	check(controller.target == null and button._activity < 0.001, "Distant action button must be faint and unavailable")
	touch(button, true)
	touch(button, false)
	check(counts.requested == 0 and not fragment.collected, "Unavailable touches must not request an interaction")
	player.global_position = fragment.global_position + Vector3(0, 0, 1)
	controller.refresh_target()
	button._process(0.5)
	check(controller.target == fragment and button._activity > 0.99, "Entering demo fragment range must activate the button")
	check(button._origin.x > button.size.x * 0.8 and button._origin.y > button.size.y * 0.7, "Action circle must sit at the bottom right")
	touch(button, true)
	var drag := InputEventScreenDrag.new()
	drag.index = 1
	drag.position = button._origin + Vector2(30, 0)
	button._input(drag)
	touch(button, false)
	check(not fragment.collected, "A drag must cancel the action")
	touch(button, true)
	touch(button, false, true)
	check(not fragment.collected, "Cancelled touch must not activate a fragment")
	touch(button, true)
	player.global_position += Vector3(20, 0, 0)
	touch(button, false)
	check(not fragment.collected, "Leaving range before release must reject the action")
	player.global_position = fragment.global_position + Vector3(0, 0, 1)
	controller.refresh_target()
	var stick_touch := InputEventScreenTouch.new()
	stick_touch.index = 0
	stick_touch.pressed = true
	stick_touch.position = joystick._origin
	joystick._input(stick_touch)
	touch(button, true)
	touch(button, false)
	check(joystick._touch_id == 0, "Action finger must not steal the movement finger")
	stick_touch.pressed = false
	joystick._input(stick_touch)
	check(fragment.collected and not notes.current_note.is_empty(), "Action touch must collect the actual demo fragment and open its note")
	check(counts.requested == 1 and counts.performed == 1, "Accepted action must emit generic request and completion signals once")
	check(controller.target == null and not controller.request_interaction(), "Open notes must gate further HUD interactions")
	touch(button, true)
	check(button._pointer == -1, "Modal notes must retain touch priority even where they overlap the HUD")
	while not notes.current_note.is_empty():
		notes.advance_note()
	controller.refresh_target()
	check(controller.target != fragment and fragment.state == MemoryFragment.State.DECAYING, "Consumed fragment must become unavailable after its note closes")
	var generic := ExampleInteractable.new()
	world.add_child(generic)
	generic.add_to_group(&"memory_interactables")
	generic.global_position = Vector3(500, 0, 500)
	player.global_position = generic.global_position
	controller.refresh_target()
	check(controller.target == generic, "Future interactables must work without fragment inheritance")
	var key := InputEventKey.new()
	key.physical_keycode = KEY_E
	key.pressed = true
	button._unhandled_key_input(key)
	check(generic.activations == 1, "Keyboard interaction must use the same generic controller")
	player.set_physics_process(false)
	check(not controller.request_interaction(), "Arrival and return movement locks must block interaction")
	player.set_physics_process(true)
	generic.hide()
	controller.refresh_target()
	check(controller.target == null, "Hidden targets must not activate the button")
	button.size = Vector2(390, 844)
	button._layout()
	check(button._origin.x + button._radius < 390 and button._origin.y + button._radius < 844, "Portrait touch target must fit the available screen")
	print("Interact button: ", "PASS" if failures == 0 else "FAIL")
	quit(failures)
