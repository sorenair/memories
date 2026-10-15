extends Control
## Keyboard, controller, and one floating touch stick, in screen coordinates.
@export var stick_radius: float = 68.0
var _touch_id: int = -1
var _origin := Vector2.ZERO
var _axis := Vector2.ZERO

func get_movement() -> Vector2:
	var keyboard := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	return _axis if _axis.length_squared() > keyboard.length_squared() else keyboard

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and _touch_id == -1:
			_touch_id = event.index
			_origin = event.position
			_axis = Vector2.ZERO
		elif not event.pressed and event.index == _touch_id:
			_release()
	elif event is InputEventScreenDrag and event.index == _touch_id:
		_axis = ((event.position - _origin) / stick_radius).limit_length()
	queue_redraw()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		_release()

func _release() -> void:
	_touch_id = -1
	_axis = Vector2.ZERO
	queue_redraw()

func _draw() -> void:
	if _touch_id != -1:
		draw_circle(_origin, stick_radius, Color(0.35, 0.43, 0.43, 0.07))
		draw_arc(_origin, stick_radius, 0.0, TAU, 64, Color(0.35, 0.43, 0.43, 0.16), 1.5, true)
		draw_circle(_origin + _axis * stick_radius, 18.0, Color(0.35, 0.43, 0.43, 0.25))
