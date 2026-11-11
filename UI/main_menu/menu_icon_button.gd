extends Button
## Vector-only button with native touch support when mouse emulation is disabled.
@export var symbol: Texture2D
@export var symbol_size := Vector2(56, 64)
@export var selection_icon: bool = false
var _ink_alpha: float = 1.0
var _pointer: int = -1
var _start := Vector2.ZERO
var _cancelled: bool = false

func _ready() -> void:
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	for style in ["normal", "hover", "pressed", "hover_pressed", "disabled", "focus"]:
		add_theme_stylebox_override(style, StyleBoxEmpty.new())
	_ink_alpha = _target_alpha()

func _target_alpha() -> float:
	if selection_icon:
		return 1.0 if button_pressed else (0.4 if is_hovered() or has_focus() else 0.18)
	return 1.0 if is_hovered() or has_focus() or _pointer >= 0 else 0.72

func _process(delta: float) -> void:
	_ink_alpha = lerpf(_ink_alpha, _target_alpha(), 1.0 - exp(-delta * 16.0))
	queue_redraw()

func _draw() -> void:
	if symbol:
		draw_texture_rect(symbol, Rect2((size - symbol_size) * 0.5, symbol_size), false, Color(1, 1, 1, _ink_alpha))

func _input(event: InputEvent) -> void:
	if disabled:
		return
	if event is InputEventScreenTouch:
		if event.pressed and _pointer == -1 and get_global_rect().has_point(event.position):
			_pointer = event.index
			_start = event.position
			_cancelled = false
			get_viewport().set_input_as_handled()
		elif not event.pressed and event.index == _pointer:
			var activate: bool = not event.canceled and not _cancelled and get_global_rect().has_point(event.position)
			_pointer = -1
			get_viewport().set_input_as_handled()
			if activate:
				pressed.emit()
	elif event is InputEventScreenDrag and event.index == _pointer:
		_cancelled = _cancelled or event.position.distance_to(_start) > 18.0
		get_viewport().set_input_as_handled()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		_pointer = -1
