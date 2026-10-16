extends Control
## Close-scale Memory Lane. Dates are illustrative; spacing is deliberately uniform.
## All entries currently recall the playable demo world, which owns player/camera setup.

signal memory_selected(index: int)

const PAPER := Color("faf9f6")
const INK := Color("363634")
const MUTED := Color("85827f")
const DEMO_SCENE := "res://scenes/world/memory_world.tscn"
const MemoryArrival := preload("res://UI/memory_arrival/memory_arrival.gd")
const ENTRANCE_DURATION := 1.8
static var _has_entered: bool = false
const MEMORIES: Array[Dictionary] = [
	{"title": "A Sunday walk", "date": "MAY 26, 2024", "short": "MAY 26"},
	{"title": "Museum date", "date": "JUN 14, 2024", "short": "JUN 14"},
	{"title": "Under the stadium lights", "date": "JUL 09, 2024", "short": "JUL 09"},
	{"title": "Our days in Japan", "date": "APR 08, 2025", "short": "APR 08"},
	{"title": "The long way home", "date": "MAY 18, 2025", "short": "MAY 18"},
]

var selected_index: int = 1
var _position: float = 1.0
var _spacing: float = 320.0
var _line_y: float = 0.0
var _pointer: int = -2 # -2 idle, -1 mouse, >= 0 touch index
var _start := Vector2.ZERO
var _start_position: float = 1.0
var _dragged: bool = false
var _recall_touch: bool = false
var _travelling: bool = false
var _title: Label
var _recall: Button
var _serif: SystemFont
var _sans: Font
var _title_tween: Tween
var _entrance_time: float = 0.0
var _title_y: float = 0.0
var _returning: bool = false

func _ready() -> void:
	_returning = _has_entered
	_has_entered = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_sans = ThemeDB.fallback_font
	_serif = SystemFont.new()
	_serif.font_names = PackedStringArray(["Georgia", "Noto Serif", "DejaVu Serif"])
	_title = Label.new()
	_title.name = "MemoryTitle"
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_title.add_theme_font_override("font", _serif)
	_title.add_theme_color_override("font_color", INK)
	add_child(_title)
	_recall = Button.new()
	_recall.name = "Recall"
	_recall.text = "Recall  →"
	_recall.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_recall.add_theme_color_override("font_color", MUTED)
	_recall.add_theme_color_override("font_hover_color", INK)
	_recall.add_theme_color_override("font_pressed_color", INK)
	for style in ["normal", "hover", "pressed", "disabled"]:
		_recall.add_theme_stylebox_override(style, StyleBoxEmpty.new())
	var focus := StyleBoxFlat.new()
	focus.bg_color = Color.TRANSPARENT
	focus.border_color = Color("bdb7ac")
	focus.border_width_bottom = 1
	_recall.add_theme_stylebox_override("focus", focus)
	_recall.pressed.connect(recall)
	add_child(_recall)
	resized.connect(_layout)
	_title.text = MEMORIES[selected_index].title
	_layout()

func _layout() -> void:
	if not is_instance_valid(_title):
		return
	var portrait := size.y > size.x
	_spacing = clampf(size.x * 0.20, 170.0, 340.0)
	_line_y = size.y * (0.72 if portrait else 0.81)
	_title_y = size.y * (0.45 if portrait else 0.60)
	_title.add_theme_font_size_override("font_size", int(clampf(size.x * 0.037, 32.0, 66.0)))
	_title.position = Vector2(32, _title_y)
	_title.size = Vector2(size.x - 64, 90)
	_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_recall.add_theme_font_size_override("font_size", 24)
	_recall.position = Vector2(size.x * 0.5 - 110, _title_y - 76)
	_recall.size = Vector2(220, 64)
	_apply_entrance()
	queue_redraw()

func _reveal(start: float, end: float) -> float:
	if _returning:
		return smoothstep(0.0, 0.4, _entrance_time)
	return smoothstep(start, end, _entrance_time)

func _apply_entrance() -> void:
	var title_alpha := _reveal(0.95, 1.5)
	_title.modulate.a = title_alpha
	_title.position.y = _title_y + (1.0 - title_alpha) * 8.0
	_recall.modulate.a = _reveal(1.35, ENTRANCE_DURATION)

func _finish_entrance() -> void:
	if _entrance_time >= ENTRANCE_DURATION:
		return
	_entrance_time = ENTRANCE_DURATION
	_apply_entrance()
	queue_redraw()

func _process(delta: float) -> void:
	if _entrance_time < ENTRANCE_DURATION:
		_entrance_time = minf(_entrance_time + delta, ENTRANCE_DURATION)
		_apply_entrance()
	if _pointer == -2:
		_position = lerpf(_position, float(selected_index), 1.0 - exp(-14.0 * delta))
		if absf(_position - selected_index) < 0.0005:
			_position = float(selected_index)
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), PAPER)
	if _sans == null:
		return
	var center := size.x * 0.5
	var thread_reveal := _reveal(0.22, 1.15)
	var reveal_radius := (center + 80.0) * thread_reveal
	var newest_x := center + (MEMORIES.size() - 1 - _position) * _spacing
	# The thread dissolves beyond the latest memory, without a cap or empty slots.
	for x in range(0, int(size.x), 4):
		var edge_alpha := clampf(minf(x, size.x - x) / 110.0, 0.0, 1.0)
		var future_alpha := 1.0 - smoothstep(newest_x + 20.0, newest_x + _spacing * 0.8, float(x))
		var entrance_alpha := (1.0 - smoothstep(reveal_radius - 80.0, reveal_radius, absf(x - center))) * thread_reveal
		draw_line(Vector2(x, _line_y), Vector2(minf(x + 4, size.x), _line_y), Color(0.64, 0.62, 0.60, edge_alpha * future_alpha * entrance_alpha * 0.58), 1.0, false)
	for i in MEMORIES.size():
		var offset := (i - _position) * _spacing
		var arrival := 0.34 + clampf(absf(offset) / maxf(center, 1.0), 0.0, 1.0) * 0.62
		var mark_reveal := _reveal(arrival, arrival + 0.40)
		var x := center + offset * lerpf(0.94, 1.0, mark_reveal)
		var alpha := clampf(minf(x, size.x - x) / 100.0, 0.0, 1.0)
		if alpha <= 0.0:
			continue
		var distance := absf(i - _position)
		var proximity := 1.0 - smoothstep(0.0, 0.85, distance)
		draw_circle(Vector2(x, _line_y), 5.0 + proximity * 4.0, Color(MUTED, alpha * (1.0 - proximity) * mark_reveal), true, -1, true)
		if distance < 1.7:
			var text: String = MEMORIES[i].date if i == selected_index else MEMORIES[i].short
			var font_size := 21 if i == selected_index else 19
			var width := _sans.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
			var date_reveal := _reveal(arrival + 0.16, arrival + 0.56)
			draw_string(_sans, Vector2(x - width * 0.5, _line_y + 56 + (1.0 - date_reveal) * 4.0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(INK if i == selected_index else MUTED, alpha * date_reveal))
	# The selection point stays stationary while the memory marks slide beneath it.
	var point_reveal := _reveal(0.05, 0.40)
	var halo_settle := _reveal(0.15, 0.9)
	draw_circle(Vector2(center, _line_y), lerpf(25.0, 19.0, halo_settle), Color(0.88, 0.85, 0.80, point_reveal * lerpf(0.24, 0.16, halo_settle)), true, -1, true)
	draw_circle(Vector2(center, _line_y), 15, Color(PAPER, point_reveal), true, -1, true)
	draw_circle(Vector2(center, _line_y), lerpf(10.0, 11.0, point_reveal), Color(INK, point_reveal), true, -1, true)

func select_memory(index: int) -> void:
	_finish_entrance()
	index = clampi(index, 0, MEMORIES.size() - 1)
	if selected_index == index:
		return
	selected_index = index
	_title.text = MEMORIES[index].title
	if _title_tween:
		_title_tween.kill()
	_title.modulate.a = 0.35
	_title_tween = create_tween()
	_title_tween.tween_property(_title, "modulate:a", 1.0, 0.22)
	memory_selected.emit(index)

func _begin(point: Vector2, pointer: int) -> void:
	if _pointer != -2 or _travelling:
		return
	_finish_entrance()
	_pointer = pointer
	_start = point
	_start_position = _position
	_dragged = false
	_recall_touch = pointer >= 0 and _recall.get_global_rect().has_point(point)

func _move(point: Vector2) -> void:
	if absf(point.x - _start.x) > 12.0:
		_dragged = true
	if _dragged and not _recall_touch:
		_position = clampf(_start_position - (point.x - _start.x) / _spacing, -0.22, MEMORIES.size() - 0.78)
		select_memory(roundi(_position))

func _end(point: Vector2, cancelled: bool = false) -> void:
	if _pointer == -2:
		return
	_pointer = -2
	if cancelled:
		return
	if _recall_touch:
		if not _dragged and _recall.get_global_rect().has_point(point):
			recall()
	elif _dragged:
		select_memory(roundi(_position))
	elif absf(point.y - _line_y) < 70.0:
		select_memory(roundi(_position + (point.x - size.x * 0.5) / _spacing))

func _input(event: InputEvent) -> void:
	# Finish before GUI hit testing, so even an early click can activate Recall.
	if event is InputEventMouseButton and event.pressed:
		_finish_entrance()
	elif event is InputEventKey and event.pressed and (event.is_action("ui_left") or event.is_action("ui_right") or event.is_action("ui_accept") or event.is_action("ui_focus_next")):
		_finish_entrance()
	if event is InputEventScreenTouch:
		if event.pressed:
			_begin(event.position, event.index)
		elif event.index == _pointer:
			_end(event.position, event.canceled)
	elif event is InputEventScreenDrag and event.index == _pointer:
		_move(event.position)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed and _pointer == -1:
		_end(event.position)
	elif event is InputEventMouseMotion and _pointer == -1:
		_move(event.position)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_begin(event.position, -1)

func _unhandled_key_input(event: InputEvent) -> void:
	if _travelling or not event.is_pressed() or event.is_echo():
		return
	if event.is_action("ui_left"):
		select_memory(selected_index - 1)
		accept_event()
	elif event.is_action("ui_right"):
		select_memory(selected_index + 1)
		accept_event()
	elif event.is_action("ui_accept"):
		recall()
		accept_event()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		_pointer = -2

func recall() -> void:
	if _travelling:
		return
	_finish_entrance()
	_travelling = true
	_recall.disabled = true
	var veil := MemoryArrival.get_transition_veil(get_tree())
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(veil, "modulate:a", 1.0, 0.45)
	await tween.finished
	get_tree().root.set_meta(MemoryArrival.REQUEST_META, true)
	var error := get_tree().change_scene_to_file(DEMO_SCENE)
	if error != OK:
		get_tree().root.remove_meta(MemoryArrival.REQUEST_META)
		push_error("Unable to recall demo: %s" % error_string(error))
		_travelling = false
		_recall.disabled = false
		veil.get_parent().queue_free()
