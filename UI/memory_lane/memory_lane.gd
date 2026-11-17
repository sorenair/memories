extends Control
## One thread at memory and whole-story scales. Each entry recalls its own playable world.

signal memory_selected(index: int)

const PAPER := Color("faf9f6")
const INK := Color("363634")
const MUTED := Color("85827f")
const MemoryArrival := preload("res://UI/memory_arrival/memory_arrival.gd")
const IconButton := preload("res://UI/main_menu/menu_icon_button.gd")
const MemoryAction := preload("res://UI/main_menu/memory_action_button.gd")
const ThreadTransition := preload("res://UI/main_menu/timeline_transition.gd")
const StoryLayout := preload("res://UI/memory_lane/story_layout.gd")
const ENTRANCE_DURATION := 1.8
const SCALE_TRANSITION_DURATION := 1.1
const PINCH_IN_THRESHOLD := 0.88
const PINCH_OUT_THRESHOLD := 1.12
static var _has_entered: bool = false
static var _last_selected_index: int = 0
const MEMORIES: Array[Dictionary] = [
	{"title": "First Meeting", "period": "2025-11", "date": "NOV 12, 2025", "short": "NOV 12", "scene": "res://scenes/world/first_meeting_world.tscn"},
	{"title": "Axe Game", "period": "2025-11", "date": "NOV 25, 2025", "short": "NOV 25", "scene": "res://scenes/world/snowy_stadium_world.tscn"},
	{"title": "First Date At MIA", "period": "2025-12", "date": "DEC 4, 2025", "short": "DEC 4", "scene": "res://scenes/world/art_museum_world.tscn"},
	{"title": "Christmas Market", "period": "2025-12", "date": "DEC 19, 2025", "short": "DEC 19", "scene": "res://scenes/world/christmas_market_world.tscn"},
	{"title": "New Year's Eve", "period": "2025-12", "date": "DEC 31, 2025", "short": "DEC 31", "scene": "res://scenes/world/new_years_eve_world.tscn"},
	{"title": "Como Conservatory", "period": "2026-01", "date": "JAN 14, 2026", "short": "JAN 14", "scene": "res://scenes/world/como_conservatory_world.tscn"},
	{"title": "Postcard Cabin", "period": "2026-02", "date": "FEB 10, 2026", "short": "FEB 10", "scene": "res://scenes/world/postcard_cabin_world.tscn"},
	{"title": "Mifflin Block Party", "period": "2026-04", "date": "APR 25, 2026", "short": "APR 25", "scene": "res://scenes/world/mifflin_world.tscn"},
	{"title": "Graduation", "period": "2026-05", "date": "MAY 14, 2026", "short": "MAY 14", "scene": "res://scenes/world/graduation_world.tscn"},
	{"title": "Tokyo", "period": "2026-05", "date": "MAY 28, 2026", "short": "MAY 28", "scene": "res://scenes/world/tokyo_world.tscn"},
	{"title": "Northern Vietnam", "period": "2026-06", "date": "JUN 6, 2026", "short": "JUN 6", "scene": "res://scenes/world/northern_vietnam_world.tscn"},
	{"title": "Central Vietnam", "period": "2026-06", "date": "JUN 15, 2026", "short": "JUN 15", "scene": "res://scenes/world/central_vietnam_world.tscn"},
	{"title": "Southern Vietnam", "period": "2026-06", "date": "JUN 20, 2026", "short": "JUN 20", "scene": "res://scenes/world/southern_vietnam_world.tscn"},
	{"title": "Bean And Bear Lakes", "period": "2026-07", "date": "JUL 25, 2026", "short": "JUL 25", "scene": "res://scenes/world/bean_bear_world.tscn"},
	{"title": "Vineyard", "period": "2026-08", "date": "AUG 1, 2026", "short": "AUG 1", "scene": "res://scenes/world/vineyard_world.tscn"},
	{"title": "First Sail", "period": "2026-08", "date": "AUG 22, 2026", "short": "AUG 22", "scene": "res://scenes/world/first_sail_world.tscn"},
	{"title": "Labor Day In Colorado", "period": "2026-09", "date": "SEP 6, 2026", "short": "SEP 6", "scene": "res://scenes/world/colorado_world.tscn"},
	{"title": "Duluth In The Fall", "period": "2026-10", "date": "OCT 12, 2026", "short": "OCT 12", "scene": "res://scenes/world/duluth_autumn_world.tscn"},
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
var _date: Button
var _story_title: Label
var _story_title_y := 0.0
var _story: Dictionary = {}
var _zoom := 0.0
var _story_target := false
var _view_tween: Tween
var _view_offset := 0.0
var _view_offset_velocity := 0.0
var _position_velocity := 0.0
var _zoom_velocity := 0.0
var _motion_from := 0.0
var _motion_to := 0.0
var _motion_velocity := 0.0
var _motion_offset := 0.0
var _motion_offset_velocity := 0.0
var _motion_duration := SCALE_TRANSITION_DURATION
var _title_mix := 1.0
var _tap_target: StringName = &""
var _touches: Dictionary = {}
var _pinch_ids := PackedInt32Array()
var _pinching := false
var _gesture_consumed := false
var _pinch_distance := 1.0
var _pinch_requested := false
var _magnify_idle := 0.0
var _magnify_amount := 0.0
var _magnify_requested := false

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
	# Coordinate all fingers here so a pinch starting over a button cannot activate it.
	_recall.set_process_input(false)
	_back = IconButton.new()
	_back.name = "MainMenu"
	_back.symbol = preload("res://UI/main_menu/icons/back.svg")
	_back.symbol_size = Vector2(40, 40)
	_back.tooltip_text = "Main menu"
	_back.pressed.connect(_back_pressed)
	add_child(_back)
	_back.set_process_input(false)
	_date = Button.new()
	_date.name = "SelectedDate"
	_date.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_date.focus_mode = Control.FOCUS_ALL
	_date.add_theme_font_override("font", _sans)
	_date.pressed.connect(toggle_story)
	for style in ["normal", "hover", "pressed", "hover_pressed", "disabled", "focus"]:
		_date.add_theme_stylebox_override(style, StyleBoxEmpty.new())
	for color_name in ["font_color", "font_hover_color", "font_focus_color", "font_pressed_color", "font_hover_pressed_color"]:
		_date.add_theme_color_override(color_name, INK)
	add_child(_date)
	_story_title = Label.new()
	_story_title.name = "StoryTitle"
	_story_title.text = "Whole story"
	_story_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_story_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_story_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_story_title.add_theme_font_override("font", _serif)
	_story_title.add_theme_color_override("font_color", INK)
	#add_child(_story_title)
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
	_date.add_theme_font_size_override("font_size", _date_font_size)
	_date.size = Vector2(minf(size.x - 48.0, clampf(_date_font_size * 14.0, 220.0, 420.0)), 64.0)
	var story_font_size := int(clampf(title_font_size * 0.6, 32.0, 64.0))
	_story_title.add_theme_font_size_override("font_size", story_font_size)
	_story_title.size = Vector2(title_width, story_font_size * 1.5)
	_story_title_y = _line_y - _story_title.size.y - clampf(size.y * 0.1, 64.0, 100.0)
	_build_story()
	_apply_entrance()
	queue_redraw()

func _build_story() -> void:
	_story = StoryLayout.build(MEMORIES, size.x, _sans, _date_font_size, selected_index)

func _place_date() -> void:
	_date.text = str(MEMORIES[selected_index].date)
	var baseline := _line_y + _date_font_size * 2.0
	var close_y := baseline - _date.size.y * 0.5 - (_sans.get_ascent(_date_font_size) - _sans.get_descent(_date_font_size)) * 0.5
	_date.position = Vector2((size.x - _date.size.x) * 0.5, close_y)

func toggle_story() -> void:
	if _story_target:
		show_memory()
	else:
		show_story()

func show_story() -> void:
	if _travelling or _bridge_active or _pinching:
		return
	_change_scale(true)

func show_memory(index: int = -1) -> void:
	if _travelling or _bridge_active or _pinching:
		return
	_change_scale(false, index)

func _change_scale(story: bool, index: int = -1) -> void:
	_finish_entrance()
	_reset_pointer()
	if index < 0 and story == _story_target and _view_tween != null and _view_tween.is_running():
		return
	_magnify_idle = 0.0
	_magnify_amount = 0.0
	_magnify_requested = false
	if story:
		_story_title.text = "Whole story"
	else:
		var previous_origin := _mark_x(0)
		var previous_velocity := _origin_velocity()
		if index >= 0:
			select_memory(index)
		if _story_target or _zoom > 0.001:
			_position = float(selected_index)
			_position_velocity = 0.0
		# Re-anchor a newly tapped memory without shifting the thread on the tap frame.
		_view_offset += previous_origin - _mark_x(0)
		_view_offset_velocity += previous_velocity - _origin_velocity()
	_story_target = story
	_animate_zoom(1.0 if story else 0.0)

func _animate_zoom(target: float) -> void:
	if _view_tween:
		_view_tween.kill()
	_update_navigation()
	_motion_from = _zoom
	_motion_to = target
	_motion_velocity = clampf(_zoom_velocity, -3.0, 3.0)
	_motion_offset = _view_offset
	_motion_offset_velocity = _view_offset_velocity
	_motion_duration = SCALE_TRANSITION_DURATION
	var distance := target - _zoom
	if distance * _motion_velocity > 0.0:
		_motion_velocity = signf(distance) * minf(absf(_motion_velocity), absf(distance) * 2.0 / _motion_duration)
	if is_equal_approx(target, _zoom) and absf(_view_offset) < 0.01:
		_zoom_velocity = 0.0
		_view_offset = 0.0
		_view_offset_velocity = 0.0
		_set_zoom(target)
		return
	_view_tween = create_tween()
	_view_tween.tween_method(_advance_zoom, 0.0, 1.0, _motion_duration)

func _advance_zoom(time: float) -> void:
	# Minimum-jerk motion: zero endpoint acceleration, with velocity preserved on reversal.
	var blend := time * time * time * (10.0 + time * (-15.0 + time * 6.0))
	var carry := time - 6.0 * pow(time, 3.0) + 8.0 * pow(time, 4.0) - 3.0 * pow(time, 5.0)
	var derivative := 30.0 * time * time * pow(1.0 - time, 2.0)
	var carry_derivative := 1.0 - 18.0 * time * time + 32.0 * pow(time, 3.0) - 15.0 * pow(time, 4.0)
	_zoom_velocity = (_motion_to - _motion_from) * derivative / _motion_duration + _motion_velocity * carry_derivative
	_view_offset = _motion_offset * (1.0 - blend) + _motion_offset_velocity * _motion_duration * carry
	_view_offset_velocity = -_motion_offset * derivative / _motion_duration + _motion_offset_velocity * carry_derivative
	_set_zoom(lerpf(_motion_from, _motion_to, blend) + _motion_velocity * _motion_duration * carry)

func _set_zoom(value: float) -> void:
	_zoom = clampf(value, 0.0, 1.0)
	_apply_entrance()
	_update_navigation()
	queue_redraw()

func _back_pressed() -> void:
	return_to_main_menu()

func _mark_x(index: int, settle: float = 1.0) -> float:
	var step := _view_spacing()
	var camera_index := lerpf(_position, float(selected_index), _zoom)
	return _selection_x() + (index - camera_index) * step * lerpf(settle, 1.0, _zoom)

func _view_spacing() -> float:
	var story_step: float = _story.positions[1] - _story.positions[0] if MEMORIES.size() > 1 else _spacing
	return exp(lerpf(log(_spacing), log(story_step), _zoom))

func _origin_velocity() -> float:
	var step := _view_spacing()
	var story_step: float = _story.positions[1] - _story.positions[0] if MEMORIES.size() > 1 else _spacing
	var camera := lerpf(_position, float(selected_index), _zoom)
	var derivative: float = _story.positions[selected_index] - size.x * 0.5 - (selected_index - _position) * step - camera * step * log(story_step / _spacing)
	return _zoom_velocity * derivative + _view_offset_velocity - (1.0 - _zoom) * step * _position_velocity

func _selection_x() -> float:
	return lerpf(size.x * 0.5, _story.positions[selected_index], _zoom) + _view_offset

func _story_label_left(label: Dictionary, row: String) -> float:
	var current := _mark_x(label.first) if row == "years" else (_mark_x(label.first) + _mark_x(label.last)) * 0.5
	var fitted: float = _story.positions[label.first] if row == "years" else (_story.positions[label.first] + _story.positions[label.last]) * 0.5
	return current + label.left - fitted

func _story_index_at(x: float) -> int:
	if MEMORIES.size() < 2:
		return 0
	var first := _mark_x(0)
	var last := _mark_x(MEMORIES.size() - 1)
	return clampi(roundi((x - first) / (last - first) * (MEMORIES.size() - 1)), 0, MEMORIES.size() - 1)

func _story_label_at(point: Vector2) -> int:
	var closest := -1
	var distance := INF
	for row in ["years", "months"]:
		var label_y := _line_y - 46.0 if row == "years" else _line_y + 34.0
		for label in _story[row]:
			var left := _story_label_left(label, row)
			var right: float = left + label.right - label.left
			if absf(point.y - label_y) < 28.0 and point.x >= left - 12.0 and point.x <= right + 12.0:
				var candidate := point.distance_squared_to(Vector2((left + right) * 0.5, label_y))
				if candidate < distance:
					distance = candidate
					closest = label.index
	return closest

func _period_caption(index: int) -> String:
	for period in _story.periods:
		if index >= period.first and index <= period.last:
			return "%s %s" % [period.text, period.year] if not period.year.is_empty() else str(period.text)
	return "Whole story"

func _reveal(start: float, end: float) -> float:
	if _returning:
		return smoothstep(0.0, 0.4, _entrance_time)
	return smoothstep(start, end, _entrance_time)

func _apply_entrance() -> void:
	var title_alpha := _reveal(0.95, 1.5)
	var close_alpha := 1.0 - smoothstep(0.0, 0.48, _zoom)
	_title.modulate.a = title_alpha * _title_mix * close_alpha
	_title.position.y = _title_y + (1.0 - title_alpha) * 8.0 - _zoom * 10.0
	_recall.modulate.a = _reveal(1.35, ENTRANCE_DURATION) * close_alpha
	_recall.visible = _zoom < 0.99
	_recall.mouse_filter = Control.MOUSE_FILTER_IGNORE if _zoom > 0.02 or _story_target else Control.MOUSE_FILTER_STOP
	_back.modulate.a = _reveal(0.85, 1.45)
	_story_title.modulate.a = smoothstep(0.35, 0.9, _zoom)
	_story_title.position = Vector2(_title.position.x, _story_title_y + (1.0 - _zoom) * 8.0)
	_date.modulate.a = _reveal(0.5, 0.9) * close_alpha
	_date.visible = close_alpha > 0.001
	_place_date()

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
	if _magnify_idle > 0.0:
		_magnify_idle = maxf(0.0, _magnify_idle - delta)
		if _magnify_idle == 0.0:
			_magnify_amount = 0.0
			_magnify_requested = false
	var previous_position := _position
	if _pointer == -2:
		_position = lerpf(_position, float(selected_index), 1.0 - exp(-14.0 * delta))
		if absf(_position - selected_index) < 0.0005:
			_position = float(selected_index)
	_position_velocity = (_position - previous_position) / maxf(delta, 0.0001)
	_apply_entrance()
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), PAPER)
	if _sans == null:
		return
	var center := size.x * 0.5
	var thread_reveal := _reveal(0.22, 1.15)
	var reveal_radius := (center + 80.0) * thread_reveal
	var newest_x := _mark_x(MEMORIES.size() - 1)
	var story_margin: float = size.x - _story.positions[-1]
	# The thread dissolves beyond the latest memory, without a cap or empty slots.
	for x in range(0, int(size.x), 4):
		var edge_alpha := clampf(minf(x, size.x - x) / 110.0, 0.0, 1.0)
		var future_alpha := 1.0 - smoothstep(newest_x + lerpf(20.0, 4.0, _zoom), newest_x + lerpf(_spacing * 0.8, story_margin * 0.95, _zoom), float(x))
		var entrance_alpha := (1.0 - smoothstep(reveal_radius - 80.0, reveal_radius, absf(x - center))) * thread_reveal
		draw_line(Vector2(x, _line_y), Vector2(minf(x + 4, size.x), _line_y), Color(0.64, 0.62, 0.60, edge_alpha * future_alpha * entrance_alpha * 0.58), 1.0, false)
	var last_bucket := -999
	for i in MEMORIES.size():
		var offset := (i - _position) * _spacing
		var arrival := 0.34 + clampf(absf(offset) / maxf(center, 1.0), 0.0, 1.0) * 0.62
		var mark_reveal := _reveal(arrival, arrival + 0.40)
		var x := _mark_x(i, lerpf(0.94, 1.0, mark_reveal))
		var alpha := clampf(minf(x, size.x - x) / lerpf(100.0, 16.0, _zoom), 0.0, 1.0)
		if alpha <= 0.0:
			continue
		var distance := absf(i - _position)
		var proximity := 1.0 - smoothstep(0.0, 0.85, distance)
		draw_circle(Vector2(x, _line_y), (6.0 + proximity * 4.0) * _mark_scale, Color(MUTED, alpha * (1.0 - proximity) * mark_reveal * (1.0 - _zoom)), true, -1, true)
		var bucket := int(x / 3.0)
		if _zoom < 0.98 or bucket != last_bucket:
			var height := 6.0 * _mark_scale
			if i != selected_index:
				draw_line(Vector2(x, _line_y - height), Vector2(x, _line_y + height), Color(MUTED, alpha * _zoom * mark_reveal * 0.8), 1.0, true)
		last_bucket = bucket
		if distance < 1.7 and i != selected_index and _zoom < 0.99:
			var text: String = MEMORIES[i].short
			var font_size := int(_date_font_size * 0.88)
			var width := _sans.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
			var date_reveal := _reveal(arrival + 0.16, arrival + 0.56)
			draw_string(_sans, Vector2(x - width * 0.5, _line_y + _date_font_size * 2.0 + (1.0 - date_reveal) * 4.0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(MUTED, alpha * date_reveal * pow(1.0 - _zoom, 2.0)))
	_draw_story_labels()
	# The same selected mark travels between its story slot and the close-view center.
	if _bridge_active:
		return
	var point_reveal := 1.0 if _shared_point else _reveal(0.05, 0.40)
	var halo_settle := 1.0 if _shared_point else _reveal(0.15, 0.9)
	var selected_x := _selection_x()
	draw_circle(Vector2(selected_x, _line_y), lerpf(lerpf(29.0, 23.0, halo_settle), 11.0, _zoom) * _mark_scale, Color(0.88, 0.85, 0.80, point_reveal * lerpf(lerpf(0.24, 0.16, halo_settle), 0.1, _zoom)), true, -1, true)
	draw_circle(Vector2(selected_x, _line_y), lerpf(18.0, 8.0, _zoom) * _mark_scale, Color(PAPER, point_reveal), true, -1, true)
	draw_circle(Vector2(selected_x, _line_y), lerpf(lerpf(12.0, 14.0, point_reveal), 5.5, _zoom) * _mark_scale, Color(INK, point_reveal), true, -1, true)

func _draw_story_labels() -> void:
	var alpha := smoothstep(0.25, 0.92, _zoom)
	if alpha == 0.0:
		return
	for row in ["years", "months"]:
		var baseline := _line_y - 34.0 if row == "years" else _line_y + 43.0
		var font_size: int = _story.year_size if row == "years" else _story.month_size
		for label in _story[row]:
			var selected: bool = selected_index >= label.first and selected_index <= label.last
			draw_string(_sans, Vector2(_story_label_left(label, row), baseline), label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(INK if selected or row == "years" else MUTED, alpha * (0.85 if row == "years" else 1.0)))

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
	_title_mix = 0.35
	_title_tween = create_tween()
	_title_tween.tween_property(self, "_title_mix", 1.0, 0.22)
	_build_story()
	_apply_entrance()
	memory_selected.emit(index)

func _reset_pointer() -> void:
	_pointer = -2
	_tap_target = &""
	_recall_touch = false
	if is_instance_valid(_recall):
		_recall.set_touch_active(false)
	if is_instance_valid(_back):
		_back.set_touch_active(false)

func _begin(point: Vector2, pointer: int) -> void:
	if _pointer != -2 or _travelling or _bridge_active:
		return
	_finish_entrance()
	_pointer = pointer
	_start = point
	_start_position = _position
	_dragged = false
	_tap_target = &""
	if not _back.disabled and _back.get_global_rect().has_point(point):
		_tap_target = &"back"
	elif not _recall.disabled and _recall.visible and _recall.get_global_rect().has_point(point):
		_tap_target = &"recall"
	elif not _date.disabled and _date.modulate.a > 0.1 and _date.get_global_rect().has_point(point):
		_tap_target = &"date"
		_date.grab_focus()
	_recall_touch = _tap_target == &"recall"
	_recall.set_touch_active(pointer >= 0 and _recall_touch)
	_back.set_touch_active(pointer >= 0 and _tap_target == &"back")

func _move(point: Vector2) -> void:
	_dragged = _dragged or point.distance_to(_start) > 12.0
	if not _dragged or _tap_target == &"recall" or _tap_target == &"back":
		return
	if _story_target or _zoom > 0.5:
		if _tap_target != &"date":
			select_memory(_story_index_at(point.x))
			_story_title.text = _period_caption(selected_index)
	else:
		_position = clampf(_start_position - (point.x - _start.x) / _spacing, -0.22, MEMORIES.size() - 0.78)
		select_memory(roundi(_position))

func _end(point: Vector2, cancelled: bool = false) -> void:
	if _pointer == -2:
		return
	var target := _tap_target
	_reset_pointer()
	if cancelled:
		return
	if target == &"recall":
		if not _dragged and _recall.get_global_rect().has_point(point):
			recall()
	elif target == &"back":
		if not _dragged and _back.get_global_rect().has_point(point):
			_back_pressed()
	elif target == &"date":
		if not _dragged and _date.get_global_rect().has_point(point):
			toggle_story()
		elif _dragged and not _story_target:
			select_memory(roundi(_position))
	elif _story_target or _zoom > 0.5:
		var label_index := _story_label_at(point)
		if label_index >= 0 or absf(point.y - _line_y) < 90.0 or _dragged:
			show_memory(selected_index if _dragged else (label_index if label_index >= 0 else _story_index_at(point.x)))
	elif _dragged:
		select_memory(roundi(_position))
	elif absf(point.y - _line_y) < 70.0:
		select_memory(roundi(_position + (point.x - size.x * 0.5) / _spacing))

func _begin_pinch() -> void:
	_reset_pointer()
	_finish_entrance()
	_magnify_idle = 0.0
	_magnify_amount = 0.0
	_magnify_requested = false
	var keys := _touches.keys()
	_pinch_ids = PackedInt32Array([keys[0], keys[1]])
	var first: Vector2 = _touches[_pinch_ids[0]]
	var second: Vector2 = _touches[_pinch_ids[1]]
	_pinch_distance = maxf(first.distance_to(second), 20.0)
	_pinch_requested = false
	_pinching = true
	_gesture_consumed = true

func _move_pinch() -> void:
	if _pinch_requested:
		return
	var first: Vector2 = _touches[_pinch_ids[0]]
	var second: Vector2 = _touches[_pinch_ids[1]]
	var distance := maxf(first.distance_to(second), 20.0)
	var ratio := distance / _pinch_distance
	if ratio <= PINCH_IN_THRESHOLD and not _story_target:
		_pinch_requested = true
		_change_scale(true)
	elif ratio >= PINCH_OUT_THRESHOLD and _story_target:
		_pinch_requested = true
		_change_scale(false)

func _end_pinch(_cancelled: bool = false) -> void:
	_pinching = false
	_pinch_ids.clear()
	_update_navigation()

func _touch(event: InputEventScreenTouch) -> void:
	if event.pressed:
		_touches[event.index] = event.position
		if _touches.size() >= 2 and not _pinching:
			_begin_pinch()
		elif not _pinching and not _gesture_consumed:
			_begin(event.position, event.index)
	else:
		_touches.erase(event.index)
		if _pinching and _pinch_ids.has(event.index):
			_end_pinch(event.canceled)
		elif not _pinching and not _gesture_consumed and event.index == _pointer:
			_end(event.position, event.canceled)
		if _touches.is_empty():
			_gesture_consumed = false
	get_viewport().set_input_as_handled()

func _input(event: InputEvent) -> void:
	if _bridge_active or _travelling:
		return
	if event is InputEventScreenTouch:
		_touch(event)
	elif event is InputEventScreenDrag:
		if not _touches.has(event.index):
			return
		_touches[event.index] = event.position
		if _pinching:
			_move_pinch()
		elif not _gesture_consumed and event.index == _pointer:
			_move(event.position)
		get_viewport().set_input_as_handled()
	elif event is InputEventMagnifyGesture and event.factor > 0.0 and not _pinching:
		_finish_entrance()
		_reset_pointer()
		if _magnify_idle == 0.0:
			_magnify_amount = 0.0
			_magnify_requested = false
		_magnify_amount += log(event.factor)
		if not _magnify_requested:
			if _magnify_amount <= log(PINCH_IN_THRESHOLD) and not _story_target:
				_change_scale(true)
				_magnify_requested = true
			elif _magnify_amount >= log(PINCH_OUT_THRESHOLD) and _story_target:
				_change_scale(false)
				_magnify_requested = true
		_magnify_idle = 0.18
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton:
		if event.pressed:
			_finish_entrance()
		if event.pressed and (event.ctrl_pressed or event.meta_pressed):
			if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				show_story()
				get_viewport().set_input_as_handled()
			elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
				show_memory()
				get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_LEFT and not event.pressed and _pointer == -1:
			_end(event.position)
	elif event is InputEventMouseMotion:
		if _pointer == -1:
			_move(event.position)
		var date_hover := _date.modulate.a > 0.1 and _date.get_global_rect().has_point(event.position)
		var story_hover := _story_target and absf(event.position.y - _line_y) < 90.0
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if date_hover or story_hover else Control.CURSOR_ARROW
	elif event is InputEventKey and event.pressed and not _pinching:
		if event.is_action("ui_left") or event.is_action("ui_right") or event.is_action("ui_accept") or event.is_action("ui_focus_next"):
			_finish_entrance()
		if not event.is_echo() and (event.is_action("ui_up") or event.is_action("ui_down") or event.is_action("ui_left") or event.is_action("ui_right")):
			_unhandled_key_input(event)
			get_viewport().set_input_as_handled()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_begin(get_global_transform() * event.position, -1)

func _unhandled_key_input(event: InputEvent) -> void:
	if _travelling or _bridge_active or _pinching or not event.is_pressed() or event.is_echo():
		return
	if event.is_action("ui_cancel"):
		_back_pressed()
		accept_event()
	elif event.is_action("ui_up"):
		show_story()
		accept_event()
	elif event.is_action("ui_down"):
		show_memory()
		accept_event()
	elif event.is_action("ui_left"):
		select_memory(selected_index - 1)
		accept_event()
	elif event.is_action("ui_right"):
		select_memory(selected_index + 1)
		accept_event()
	elif event.is_action("ui_accept"):
		if _story_target or _zoom > 0.5:
			show_memory()
		else:
			recall()
		accept_event()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		if _pinching:
			_end_pinch()
		_touches.clear()
		_gesture_consumed = false
		_reset_pointer()

func _update_navigation() -> void:
	_recall.disabled = _travelling or _bridge_active or _story_target or _zoom > 0.02 or _pinching
	_back.disabled = _travelling or _bridge_active
	_back.tooltip_text = "Main menu"
	_date.disabled = _travelling or _bridge_active or _story_target or _zoom > 0.05

func complete_main_menu_transition() -> void:
	_bridge_active = false
	_update_navigation()
	queue_redraw()

func recall() -> void:
	if _travelling or _bridge_active or _story_target or _zoom > 0.02 or _pinching:
		return
	_recall.play_recall()
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
