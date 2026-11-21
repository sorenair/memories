extends Control
## Floating touch joystick with a resting position in the lower-left corner.
@export_range(48.0, 160.0, 1.0) var stick_radius: float = 104.0
@export_range(16.0, 48.0, 1.0) var thumb_radius: float = 26.0
@export_range(24.0, 100.0, 1.0) var edge_padding: float = 56.0
@export_range(0.0, 0.3, 0.01) var deadzone: float = 0.10
@export var interaction_controller: Node

const INK := Color(0.38, 0.40, 0.38)
const MOUSE_POINTER := -2
var _touch_id: int = -1
var _origin := Vector2.ZERO
var _home := Vector2.ZERO
var _draw_origin := Vector2.ZERO
var _tap_target: Node3D
var _axis := Vector2.ZERO
var _radius: float = 104.0
var _thumb_radius: float = 26.0
var _activity: float = 0.0
var _thumb_offset := Vector2.ZERO

func _ready() -> void:
	resized.connect(_layout)
	_layout()

func _layout() -> void:
	_release()
	# Keep a useful thumb target in both the project landscape viewport and portrait.
	_radius = minf(stick_radius, minf(size.x, size.y) * 0.14)
	_thumb_radius = thumb_radius * _radius / stick_radius
	var padding := minf(edge_padding, minf(size.x, size.y) * 0.07)
	_home = Vector2(padding + _radius, size.y - padding - _radius)
	_origin = _home
	_draw_origin = _home
	_thumb_offset = Vector2.ZERO
	queue_redraw()

func get_movement() -> Vector2:
	var keyboard := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	return _axis if _axis.length_squared() > keyboard.length_squared() else keyboard

func _sample(point: Vector2) -> void:
	if point.distance_to(_origin) > 20.0:
		_tap_target = null
	var offset := (point - _origin) / maxf(_radius - _thumb_radius, 1.0)
	var magnitude := offset.length()
	if magnitude <= deadzone:
		_axis = Vector2.ZERO
	else:
		_axis = offset.normalized() * clampf((magnitude - deadzone) / (1.0 - deadzone), 0.0, 1.0)

func _press(point: Vector2, pointer: int) -> bool:
	var movement_area := Rect2(Vector2(0.0, size.y * 0.5), size * 0.5)
	if _touch_id != -1 or not movement_area.has_point(point):
		return false
	if is_instance_valid(interaction_controller) and not interaction_controller.input_allowed():
		return false
	_touch_id = pointer
	_origin = point
	_draw_origin = point
	_thumb_offset = Vector2.ZERO
	if is_instance_valid(interaction_controller):
		_tap_target = interaction_controller.pick_interactable(get_global_transform_with_canvas() * point)
	return true

func _finish(point: Vector2, cancelled: bool = false) -> void:
	var target := _tap_target
	var start := get_global_transform_with_canvas() * _origin
	_release()
	if not cancelled and is_instance_valid(target) and is_instance_valid(interaction_controller) and point.distance_to(start) <= 20.0 \
			and interaction_controller.pick_interactable(point) == target:
		interaction_controller.request_interaction(target)

func _input(event: InputEvent) -> void:
	if not can_process():
		return
	var captured := false
	if event is InputEventScreenTouch:
		if event.pressed and not event.canceled:
			captured = _press(get_global_transform_with_canvas().affine_inverse() * event.position, event.index)
		elif not event.pressed and event.index == _touch_id:
			_finish(event.position, event.canceled)
			captured = true
	elif event is InputEventScreenDrag and event.index == _touch_id:
		_sample(get_global_transform_with_canvas().affine_inverse() * event.position)
		captured = true
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			captured = _press(get_global_transform_with_canvas().affine_inverse() * event.position, MOUSE_POINTER)
		elif _touch_id == MOUSE_POINTER:
			_finish(event.position)
			captured = true
	elif event is InputEventMouseMotion and _touch_id == MOUSE_POINTER:
		_sample(get_global_transform_with_canvas().affine_inverse() * event.position)
		captured = true
	if captured:
		get_viewport().set_input_as_handled()

func _process(delta: float) -> void:
	if _touch_id != -1 and is_instance_valid(interaction_controller) and not interaction_controller.input_allowed():
		_release()
	var active := _touch_id != -1
	_activity = lerpf(_activity, 1.0 if active else 0.0, 1.0 - exp(-delta * (22.0 if active else 12.0)))
	_draw_origin = _draw_origin.lerp(_origin, 1.0 - exp(-delta * 16.0))
	var target := _axis * (_radius - _thumb_radius)
	_thumb_offset = _thumb_offset.lerp(target, 1.0 - exp(-delta * 24.0))
	queue_redraw()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		_release()

func _release() -> void:
	_touch_id = -1
	_axis = Vector2.ZERO
	_tap_target = null
	_origin = _home
	queue_redraw()

func _draw() -> void:
	# No plate, labels, arrows, or extra buttons: just two quiet circles.
	var outline_alpha := lerpf(0.14, 1.0, _activity)
	var thumb_alpha := lerpf(0.12, 1.0, _activity)
	draw_arc(_draw_origin, _radius, 0.0, TAU, 128, Color(INK, outline_alpha), 2.0, true)
	draw_circle(_draw_origin + _thumb_offset, _thumb_radius, Color(INK, thumb_alpha), true, -1, true)
