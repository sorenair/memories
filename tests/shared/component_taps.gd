extends RefCounted
## Aim a real component from its front for deterministic screen-picking tests.
static func point(controller: Node, component: Node3D) -> Vector2:
	var camera: Camera3D = controller.get_viewport().get_camera_3d()
	var focus: Vector3
	if component.has_method("get_interaction_tap_position"):
		focus = component.get_interaction_tap_position()
	else:
		var visual := component.get_node("Visual") as MeshInstance3D
		focus = visual.global_transform * visual.get_aabb().get_center()
	var root: Node3D = component.band if component.get("band") != null else component
	camera.global_position = root.to_global(Vector3(0, 3.2, 5))
	camera.look_at(focus)
	return camera.unproject_position(focus)

static func press(controller: Node, component: Node3D) -> void:
	var event := InputEventScreenTouch.new()
	event.index = 1
	event.position = point(controller, component)
	event.pressed = true
	controller._unhandled_input(event)

static func release(controller: Node) -> void:
	var event := InputEventScreenTouch.new()
	event.index = 1
	event.position = controller._tap_start
	event.pressed = false
	controller._unhandled_input(event)

static func click(controller: Node, component: Node3D) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.position = point(controller, component)
	event.pressed = true
	controller._unhandled_input(event)
	event.pressed = false
	controller._unhandled_input(event)
