extends SceneTree
var failures := 0
class Target extends Node3D:
	var calls := 0
	func _ready() -> void:
		add_to_group(&"memory_interactables")
		var mesh := MeshInstance3D.new()
		var geometry := ArrayMesh.new()
		geometry.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, BoxMesh.new().surface_get_arrays(0))
		mesh.mesh = geometry
		mesh.position.y = 0.5
		add_child(mesh)
	func can_interact(actor: Node3D) -> bool:
		return global_position.distance_to(actor.global_position) <= 3.0
	func try_activate(actor: Node3D) -> bool:
		if not can_interact(actor): return false
		calls += 1
		return true
func _initialize() -> void:
	call_deferred("run")
func check(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		failures += 1
func touch(controller: Node, point: Vector2, pressed: bool, cancelled: bool = false) -> void:
	var event := InputEventScreenTouch.new()
	event.position = point
	event.index = 1
	event.pressed = pressed
	event.canceled = cancelled
	controller._unhandled_input(event)
func run() -> void:
	var world := Node3D.new()
	root.add_child(world)
	var actor := CharacterBody3D.new()
	world.add_child(actor)
	actor.add_to_group(&"explorers")
	actor.set_physics_process(true)
	actor.position = Vector3(-0.8, 0, 1)
	var camera := Camera3D.new()
	world.add_child(camera)
	camera.position = Vector3(0, 4, 7)
	camera.look_at(Vector3(0, 0.5, 0))
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 6
	camera.current = true
	var controller = load("res://scripts/interaction/interaction_controller.gd").new()
	controller.actor = actor
	world.add_child(controller)
	var left := Target.new()
	left.position.x = -1
	world.add_child(left)
	var right := Target.new()
	right.position.x = 1
	world.add_child(right)
	var layer := CanvasLayer.new()
	world.add_child(layer)
	var notes = load("res://UI/fragments/fragment_interaction.tscn").instantiate()
	layer.add_child(notes)
	await physics_frame
	await physics_frame
	controller.refresh_target()
	var point := camera.unproject_position(right.global_position + Vector3.UP * 0.5)
	check(controller.target == left and controller.pick_interactable(point) == right, "Tap picking must select the object under the finger rather than the nearest object")
	touch(controller, point, true)
	touch(controller, point, false)
	check(right.calls == 1 and left.calls == 0, "Only the tapped component must activate")
	touch(controller, point, true)
	var drag := InputEventScreenDrag.new()
	drag.index = 1
	drag.position = point + Vector2(35, 0)
	controller._unhandled_input(drag)
	touch(controller, point, false)
	check(right.calls == 1, "A drag must cancel the component action")
	touch(controller, point, true)
	touch(controller, point, false, true)
	check(right.calls == 1, "Cancelled touches must not interact")
	touch(controller, point, true)
	actor.position.x = 20
	touch(controller, point, false)
	check(right.calls == 1 and controller.pick_interactable(point) == null, "Leaving range must cancel a held tap")
	actor.position.x = -0.8
	touch(controller, point, true)
	controller._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	touch(controller, point, false)
	check(right.calls == 1, "Focus loss must clear pending taps")
	touch(controller, point, true)
	var release := InputEventScreenTouch.new()
	release.index = 1
	release.pressed = false
	controller._input(release)
	await process_frame
	check(controller._tap_pointer == -1, "A release consumed by GUI must still clear world picking")
	var blocker := StaticBody3D.new()
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(0.8, 1.2, 0.5)
	collision.shape = shape
	blocker.add_child(collision)
	world.add_child(blocker)
	blocker.global_position = camera.project_ray_origin(point).lerp(right.global_position + Vector3.UP * 0.5, 0.5)
	await physics_frame
	await physics_frame
	check(controller.pick_interactable(point) == null, "Opaque scenery must block component taps")
	blocker.free()
	var fragment: MemoryFragment = load("res://components/interactables/fragments/memory_fragment.tscn").instantiate()
	fragment.position = Vector3(0, 0, 2)
	fragment.notes = ["A direct tap opened this note."]
	world.add_child(fragment)
	actor.position = Vector3(0, 0, 3)
	var orb := camera.unproject_position(fragment.get_orb_position())
	check(controller.pick_interactable(orb) == fragment, "Transparent fragments must use their orb contour target")
	touch(controller, orb, true)
	touch(controller, orb, false)
	check(fragment.collected and not notes.current_note.is_empty(), "Shared component taps must open fragment notes exactly once")
	check(controller.pick_interactable(point) == null, "Notes must block all component picking")
	while not notes.current_note.is_empty(): notes.advance_note()
	actor.position = Vector3(-0.8, 0, 1)
	right.hide()
	check(controller.pick_interactable(point) == null, "Hidden components must not be tappable")
	right.show()
	actor.set_physics_process(false)
	check(controller.pick_interactable(point) == null, "Arrival and return locks must block tapping")
	actor.set_physics_process(true)
	var joystick = load("res://scripts/exploration_input.gd").new()
	joystick.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(joystick)
	joystick.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	await process_frame
	var under_stick := Target.new()
	world.add_child(under_stick)
	under_stick.global_position = camera.project_ray_origin(joystick._origin) + camera.project_ray_normal(joystick._origin) * 8.0 - Vector3.UP * 0.5
	actor.global_position = under_stick.global_position
	check(controller.pick_interactable(joystick._origin) == under_stick, "The joystick priority check must place a real component behind its touch target")
	var stick_event := InputEventScreenTouch.new()
	stick_event.index = 0
	stick_event.position = joystick._origin
	stick_event.pressed = true
	root.push_input(stick_event.duplicate(), true)
	check(joystick._touch_id == 0 and controller._tap_pointer == -1, "Joystick acquisition must have priority over a component beneath the HUD")
	actor.position = Vector3(-0.8, 0, 1)
	var other_finger := InputEventScreenTouch.new()
	other_finger.index = 1
	other_finger.position = point
	other_finger.pressed = true
	root.push_input(other_finger.duplicate(), true)
	other_finger.pressed = false
	root.push_input(other_finger.duplicate(), true)
	check(right.calls == 2 and joystick._touch_id == 0, "A second finger must tap a component without releasing the joystick")
	stick_event.pressed = false
	root.push_input(stick_event.duplicate(), true)
	check(under_stick.calls == 0 and joystick._touch_id == -1, "Releasing the joystick must never activate the component behind it")
	print("Direct component tapping: ", "PASS" if failures == 0 else "FAIL")
	quit(failures)
