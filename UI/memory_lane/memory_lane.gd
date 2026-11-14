extends Control
## Close-scale Memory Lane. Each entry recalls its own playable memory world.

signal memory_selected(index: int)

const PAPER := Color("faf9f6")
const INK := Color("363634")
const MUTED := Color("85827f")
const MemoryArrival := preload("res://UI/memory_arrival/memory_arrival.gd")
const IconButton := preload("res://UI/main_menu/menu_icon_button.gd")
const MemoryAction := preload("res://UI/main_menu/memory_action_button.gd")
const ThreadTransition := preload("res://UI/main_menu/timeline_transition.gd")
const ENTRANCE_DURATION := 1.8
static var _has_entered: bool = false
static var _last_selected_index: int = 0
const MEMORIES: Array[Dictionary] = [
	{"title": "First Meeting", "date": "NOV 12, 2025", "short": "NOV 12", "scene": "res://scenes/world/first_meeting_world.tscn"},
	{"title": "Football in the snow", "date": "COLLEGE FOOTBALL", "short": "SNOW", "scene": "res://scenes/world/snowy_stadium_world.tscn"},
	{"title": "Minneapolis Institute of Art", "date": "DEC 4, 2025", "short": "DEC 4", "scene": "res://scenes/world/art_museum_world.tscn"},
	{"title": "Christmas market", "date": "DEC 19, 2025", "short": "DEC 19", "scene": "res://scenes/world/christmas_market_world.tscn"},
	{"title": "New Year's Eve", "date": "DEC 31, 2025", "short": "DEC 31", "scene": "res://scenes/world/new_years_eve_world.tscn"},
	{"title": "Como Conservatory", "date": "JAN 14, 2026", "short": "JAN 14", "scene": "res://scenes/world/como_conservatory_world.tscn"},
	{"title": "Seasonal Demo", "date": "DEMO", "short": "DEMO", "scene": "res://scenes/world/memory_world.tscn"},
]

var selected_index: int = 0
var _position: float = 0.0
var _spacing: float = 320.0
var _line_y: float = 0.0
var _pointer: int = -2 # -2 idle, -1 mouse, >= 0 touch index
var _start := Vector2.ZERO
var _start_position: float = 0.0
var _dragged: bool = false
var _recall_touch: bool = false
var _travelling: bool = false
var _title: Label
var _recall: Button
var _back: Button
var _serif: SystemFont
var _sans: Font
var _title_tween: Tween
var _entrance_time: float = 0.0
var _title_y: float = 0.0
var _returning: bool = false
var _bridge_active := false
var _shared_point := false
var _entrance_delay := 0.0
var _entrance_speed := 1.0
var _date_font_size: int = 28
var _mark_scale: float = 1.0

func _ready() -> void:
	var returning_veil := get_tree().root.get_node_or_null(MemoryArrival.VEIL_LAYER_NAME)
	var from_main := get_tree().root.has_meta(&"timeline_from_main_menu")
	if from_main:
		get_tree().root.remove_meta(&"timeline_from_main_menu")
	_returning = not from_main and (_has_entered or returning_veil != null)
	_has_entered = true
	selected_index = clampi(_last_selected_index, 0, MEMORIES.size() - 1)
	_position = float(selected_index)
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
	_recall = MemoryAction.new()
	_recall.name = "Recall"
	_recall.action = MemoryAction.Action.RECALL
	_recall.tooltip_text = "Recall memory"
	_recall.pressed.connect(recall)
	add_child(_recall)
	_back = IconButton.new()
	_back.name = "MainMenu"
	_back.symbol = preload("res://UI/main_menu/icons/back.svg")
	_back.symbol_size = Vector2(40, 40)
	_back.tooltip_text = "Main menu"
	_back.pressed.connect(return_to_main_menu)
	add_child(_back)
	resized.connect(_layout)
	_title.text = MEMORIES[selected_index].title
	_layout()
	var bridge := get_tree().root.get_node_or_null("%s/Morph" % ThreadTransition.LAYER_NAME)
	if from_main and bridge != null:
		_bridge_active = true
		_shared_point = true
		_entrance_delay = ThreadTransition.TIMELINE_REVEAL_START - ThreadTransition.DEPART_DURATION
		_entrance_speed = 2.0
		_update_navigation()
		bridge.attach_timeline(self)
	if returning_veil != null:
		returning_veil.reparent(self)
		var tween := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(returning_veil.get_node("Paper"), "modulate:a", 0.0, 0.4)
		tween.tween_callback(returning_veil.queue_free)

func _layout() -> void:
	if not is_instance_valid(_title):
		return
	var portrait := size.y > size.x
	_spacing = clampf(size.x * 0.22, 170.0, 420.0)
	_line_y = size.y * 0.50
	_date_font_size = int(clampf(minf(size.x * 0.015, size.y * 0.034), 18.0, 30.0))
	var title_font_size := int(clampf(size.x * 0.112, 36.0, 56.0)) if portrait else int(clampf(minf(size.x * 0.05, size.y * 0.115), 36.0, 110.0))
	var title_width := minf(size.x - 64.0, 1440.0)
	var title_height := title_font_size * (2.8 if portrait or size.x < 760.0 else 1.5)
	_title_y = _line_y - title_height - clampf(size.y * 0.065, 32.0, 64.0)
	_title.add_theme_font_size_override("font_size", title_font_size)
	_title.position = Vector2((size.x - title_width) * 0.5, _title_y)
	_title.size = Vector2(title_width, title_height)
	_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var recall_y := _line_y + _date_font_size * 2.0 + clampf(size.y * 0.055, 28.0, 52.0)
	var recall_height := minf(clampf(size.y * 0.18, 112.0, 168.0), maxf(88.0, size.y - recall_y - 16.0))
	var recall_width := recall_height + 48.0
	_recall.symbol_size = Vector2(76, 76) if portrait else Vector2(96, 96)
	_recall.position = Vector2((size.x - recall_width) * 0.5, recall_y)
	_recall.size = Vector2(recall_width, recall_height)
	_back.position = Vector2(24, 24)
	_back.size = Vector2(96, 96)
	_mark_scale = clampf(minf(size.x / 1920.0, size.y / 886.0), 0.8, 1.2)
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
	_back.modulate.a = _reveal(0.85, 1.45)

func _finish_entrance() -> void:
	if _entrance_time >= ENTRANCE_DURATION:
		return
	_entrance_time = ENTRANCE_DURATION
	_apply_entrance()
	queue_redraw()

func _process(delta: float) -> void:
	var entrance_delta := delta
	if _entrance_delay > 0.0:
		var consumed := minf(entrance_delta, _entrance_delay)
		_entrance_delay -= consumed
		entrance_delta -= consumed
	if _entrance_time < ENTRANCE_DURATION:
		_entrance_time = minf(_entrance_time + entrance_delta * _entrance_speed, ENTRANCE_DURATION)
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
		draw_circle(Vector2(x, _line_y), (6.0 + proximity * 4.0) * _mark_scale, Color(MUTED, alpha * (1.0 - proximity) * mark_reveal), true, -1, true)
		if distance < 1.7:
			var text: String = MEMORIES[i].date if i == selected_index else MEMORIES[i].short
			var font_size := _date_font_size if i == selected_index else int(_date_font_size * 0.88)
			var width := _sans.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
			var date_reveal := _reveal(arrival + 0.16, arrival + 0.56)
			draw_string(_sans, Vector2(x - width * 0.5, _line_y + _date_font_size * 2.0 + (1.0 - date_reveal) * 4.0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(INK if i == selected_index else MUTED, alpha * date_reveal))
	# The selection point stays stationary while the memory marks slide beneath it.
	if _bridge_active:
		return
	var point_reveal := 1.0 if _shared_point else _reveal(0.05, 0.40)
	var halo_settle := 1.0 if _shared_point else _reveal(0.15, 0.9)
	draw_circle(Vector2(center, _line_y), lerpf(29.0, 23.0, halo_settle) * _mark_scale, Color(0.88, 0.85, 0.80, point_reveal * lerpf(0.24, 0.16, halo_settle)), true, -1, true)
	draw_circle(Vector2(center, _line_y), 18 * _mark_scale, Color(PAPER, point_reveal), true, -1, true)
	draw_circle(Vector2(center, _line_y), lerpf(12.0, 14.0, point_reveal) * _mark_scale, Color(INK, point_reveal), true, -1, true)

func select_memory(index: int) -> void:
	_finish_entrance()
	index = clampi(index, 0, MEMORIES.size() - 1)
	if selected_index == index:
		return
	selected_index = index
	_last_selected_index = index
	_title.text = MEMORIES[index].title
	if _title_tween:
		_title_tween.kill()
	_title.modulate.a = 0.35
	_title_tween = create_tween()
	_title_tween.tween_property(_title, "modulate:a", 1.0, 0.22)
	memory_selected.emit(index)

func _begin(point: Vector2, pointer: int) -> void:
	if _pointer != -2 or _travelling or _bridge_active:
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
	if _bridge_active:
		return
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
	if _travelling or _bridge_active or not event.is_pressed() or event.is_echo():
		return
	if event.is_action("ui_cancel"):
		return_to_main_menu()
		accept_event()
	elif event.is_action("ui_left"):
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

func _update_navigation() -> void:
	_recall.disabled = _travelling or _bridge_active
	_back.disabled = _travelling or _bridge_active

func complete_main_menu_transition() -> void:
	_bridge_active = false
	_update_navigation()
	queue_redraw()

func recall() -> void:
	if _travelling or _bridge_active:
		return
	_enter_memory()

func _enter_memory() -> void:
	_finish_entrance()
	_travelling = true
	_update_navigation()
	var veil := MemoryArrival.get_transition_veil(get_tree())
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(veil, "modulate:a", 1.0, 0.45)
	await tween.finished
	get_tree().root.set_meta(MemoryArrival.REQUEST_META, true)
	var scene_path: String = MEMORIES[selected_index].scene
	var error := get_tree().change_scene_to_file(scene_path)
	if error != OK:
		get_tree().root.remove_meta(MemoryArrival.REQUEST_META)
		push_error("Unable to recall memory: %s" % error_string(error))
		_travelling = false
		_update_navigation()
		veil.get_parent().queue_free()

func return_to_main_menu() -> void:
	if _travelling or _bridge_active:
		return
	_travelling = true
	_update_navigation()
	var veil := MemoryArrival.get_transition_veil(get_tree())
	var tween := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(veil, "modulate:a", 1.0, 0.4)
	await tween.finished
	var error := get_tree().change_scene_to_file("res://UI/main_menu/main_menu.tscn")
	if error != OK:
		veil.get_parent().queue_free()
		_travelling = false
		_update_navigation()
		push_error("Unable to open main menu: %s" % error_string(error))
