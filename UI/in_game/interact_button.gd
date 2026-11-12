extends Control
## On-demand guidance circle opposite the joystick. Components use direct scene taps.
const INK := Color(0.38, 0.40, 0.38)
signal action_requested
## Enabled by the memory's GuidanceController when an unfinished fragment remains.
@export var available: bool = false
@export var input_gate: Node
var _origin := Vector2.ZERO
var _radius: float = 64.0
var _activity: float = 0.0
var _pointer: int = -1
var _start := Vector2.ZERO
var _cancelled: bool = false
var _pressed_available: bool = false

func _ready() -> void:
	resized.connect(_layout)
	_layout()
	tooltip_text = "Find next fragment (E)"

func _layout() -> void:
	_release()
	var scale_factor := minf(1.0, minf(size.x, size.y) * 0.14 / 104.0)
	_radius = 64.0 * scale_factor
	var padding := minf(56.0, minf(size.x, size.y) * 0.07)
	_origin = Vector2(size.x - padding - 104.0 * scale_factor, size.y - padding - 104.0 * scale_factor)

func _process(delta: float) -> void:
	_activity = lerpf(_activity, 1.0 if available and _input_allowed() else 0.0, 1.0 - exp(-delta * 14.0))
	queue_redraw()

func _draw() -> void:
	var color := Color(INK, lerpf(0.14, 1.0, _activity))
	var radius := _radius * (0.96 if _pointer != -1 and not _cancelled else 1.0)
	draw_arc(_origin, radius, 0, TAU, 128, color, 2.0, true)
	var diamond := PackedVector2Array([Vector2(0, -12), Vector2(12, 0), Vector2(0, 12), Vector2(-12, 0), Vector2(0, -12)])
	for i in diamond.size():
		diamond[i] = _origin + diamond[i] * (_radius / 64.0)
	draw_polyline(diamond, color, 2.0, true)

func _release() -> void:
	_pointer = -1
	_pressed_available = false
	_cancelled = false
	queue_redraw()

func _press(point: Vector2, pointer: int) -> bool:
	if _pointer != -1 or not _input_allowed() or point.distance_to(_origin) > _radius * 1.2:
		return false
	_pointer = pointer
	_start = point
	_cancelled = false
	_pressed_available = available
	return true

func _end(point: Vector2, cancelled: bool) -> void:
	var was_available := _pressed_available
	var activate := not cancelled and not _cancelled and point.distance_to(_origin) <= _radius * 1.2
	_release()
	if activate and was_available and available and _input_allowed():
		action_requested.emit()

func _input_allowed() -> bool:
	return not is_instance_valid(input_gate) or input_gate.input_allowed()

func _input(event: InputEvent) -> void:
	if not can_process():
		return
	var captured := false
	var inverse := get_global_transform_with_canvas().affine_inverse()
	if event is InputEventScreenTouch:
		if event.pressed:
			captured = _press(inverse * event.position, event.index)
		elif event.index == _pointer:
			_end(inverse * event.position, event.canceled)
			captured = true
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			captured = _press(inverse * event.position, -2)
		elif _pointer == -2:
			_end(inverse * event.position, false)
			captured = true
	elif (event is InputEventScreenDrag and event.index == _pointer) or (event is InputEventMouseMotion and _pointer == -2):
		_cancelled = _cancelled or (inverse * event.position).distance_to(_start) > 20.0
		captured = true
	if captured:
		get_viewport().set_input_as_handled()

func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and not event.is_echo() and available and _input_allowed():
		action_requested.emit()
		accept_event()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		_release()
