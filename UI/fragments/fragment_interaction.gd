extends Control
## One picker / note queue per viewport. GUI and joystick get first refusal on input.
const PAPER := Color("faf9f6")
const INK := Color("363634")
const MUTED := Color("85827f")
const CONTINUE_ICON := preload("res://UI/fragments/icons/continue.svg")
const CLOSE_ICON := preload("res://UI/fragments/icons/close.svg")

var pending_notes: Array[Dictionary] = []
var current_note: Dictionary = {}
var _panel: PanelContainer
var _column: VBoxContainer
var _scroll: ScrollContainer
var _serif: SystemFont
var _style: StyleBoxFlat
var _presentation: Tween
var _page_fade: Tween
var _slide: float = 0.0
var _rest_position := Vector2.ZERO
var _note_scrolling: bool = false
var _note_last := Vector2.ZERO
var _reflow_queued: bool = false
var _title: Label
var _body: Label
var _next: Button
var _candidate: MemoryFragment
var _pointer: int = -1
var _start := Vector2.ZERO
var _note_pointer: int = -1
var _note_start := Vector2.ZERO
var _note_cancelled: bool = false

func _ready() -> void:
	add_to_group(&"fragment_note_queue")
	add_to_group(&"interaction_blockers")
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_serif = SystemFont.new()
	_serif.font_names = PackedStringArray(["Georgia", "Noto Serif", "DejaVu Serif"])
	_panel = PanelContainer.new()
	_panel.name = "NotePanel"
	add_child(_panel)
	_style = StyleBoxFlat.new()
	_style.bg_color = Color(PAPER, 0.98)
	_style.set_corner_radius_all(20)
	_style.corner_detail = 8
	_panel.add_theme_stylebox_override("panel", _style)
	_column = VBoxContainer.new()
	_panel.add_child(_column)
	_title = Label.new()
	_title.name = "NoteTitle"
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_title.add_theme_color_override("font_color", MUTED)
	_column.add_child(_title)
	_scroll = ScrollContainer.new()
	_scroll.name = "NoteScroll"
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_column.add_child(_scroll)
	var bar := _scroll.get_v_scroll_bar()
	bar.add_theme_stylebox_override("scroll", StyleBoxEmpty.new())
	var grabber := StyleBoxFlat.new()
	grabber.bg_color = Color(MUTED, 0.35)
	grabber.content_margin_left = 2
	grabber.content_margin_right = 2
	grabber.set_corner_radius_all(2)
	for state in ["grabber", "grabber_highlight", "grabber_pressed"]:
		bar.add_theme_stylebox_override(state, grabber)
	_body = Label.new()
	_body.name = "NoteBody"
	_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_body.add_theme_font_override("font", _serif)
	_body.add_theme_color_override("font_color", INK)
	_scroll.add_child(_body)
	_next = Button.new()
	_next.name = "AdvanceNote"
	_next.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_next.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_next.expand_icon = true
	_next.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_next.add_theme_color_override("icon_normal_color", MUTED)
	_next.add_theme_color_override("icon_hover_color", INK)
	_next.add_theme_color_override("icon_pressed_color", INK)
	for state in ["normal", "hover", "pressed"]:
		_next.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	var focus := StyleBoxFlat.new()
	focus.bg_color = Color.TRANSPARENT
	focus.border_color = Color(MUTED, 0.4)
	focus.border_width_bottom = 1
	_next.add_theme_stylebox_override("focus", focus)
	_next.pressed.connect(advance_note)
	_column.add_child(_next)
	_panel.hide()
	resized.connect(_request_layout)
	_request_layout()

func _request_layout() -> void:
	_layout()
	# Containers settle wrapping after width changes. Remeasure once they have sorted.
	if not _reflow_queued:
		_reflow_queued = true
		_finish_layout.call_deferred()

func _finish_layout() -> void:
	_reflow_queued = false
	_layout()

func _layout() -> void:
	if not is_instance_valid(_panel):
		return
	var portrait := size.y > size.x
	# Stay between the thumb controls in landscape and above them in portrait.
	var control_scale := minf(1.0, minf(size.x, size.y) * 0.14 / 104.0)
	var clearance := minf(56.0, minf(size.x, size.y) * 0.07) + 208.0 * control_scale + 24.0
	var width := minf(720.0, size.x - 2.0 * clearance) if not portrait else size.x - 32.0
	width = maxf(width, minf(280.0, size.x - 32.0))
	var padding := 40.0 if width >= 700.0 else 24.0
	var vertical_padding := 24.0 if not portrait else 20.0
	var separation := 18 if not portrait else 16
	var body_size := 26 if portrait else int(clampf(minf(size.x * 0.025, size.y * 0.045), 22.0, 36.0))
	var title_size := 18 if portrait else int(clampf(size.y * 0.026, 16.0, 23.0))
	var icon_size := 28 if portrait else int(clampf(size.y * 0.045, 28.0, 40.0))
	var action_height := 56.0 if portrait else clampf(size.y * 0.117, 56.0, 104.0)
	var bottom := clampf(size.y * 0.22, 140.0, 190.0) if portrait else clampf(size.y * 0.054, 24.0, 48.0)
	_style.content_margin_left = padding
	_style.content_margin_right = padding
	_style.content_margin_top = vertical_padding
	_style.content_margin_bottom = 8.0
	_column.add_theme_constant_override("separation", separation)
	_title.add_theme_font_size_override("font_size", title_size)
	_body.add_theme_font_size_override("font_size", body_size)
	_body.add_theme_constant_override("line_spacing", 6)
	_next.add_theme_constant_override("icon_max_width", icon_size)
	_next.custom_minimum_size = Vector2(minf(220.0, width - padding * 2.0), action_height)
	var text_width := width - padding * 2.0 - 16.0
	var heading_height := _title.get_theme_font("font").get_multiline_string_size(_title.text, HORIZONTAL_ALIGNMENT_CENTER, text_width, title_size).y
	var text_height := _serif.get_multiline_string_size(_body.text, HORIZONTAL_ALIGNMENT_CENTER, text_width, body_size).y
	var lines := maxf(1.0, ceilf(text_height / _serif.get_height(body_size)))
	text_height += (lines - 1.0) * 6.0 + 4.0
	var chrome := vertical_padding + 8.0 + heading_height + separation * 2.0 + action_height
	var max_height := minf(size.y * 0.52, size.y - bottom - 24.0)
	var body_height := clampf(text_height, body_size * 1.4, maxf(body_size * 1.4, max_height - chrome))
	_scroll.custom_minimum_size.y = body_height
	_panel.size = Vector2(width, chrome + body_height)
	_rest_position = Vector2((size.x - width) * 0.5, size.y - bottom - _panel.size.y)
	_panel.position = _rest_position + Vector2(0, _slide)

func _set_slide(value: float) -> void:
	_slide = value
	_panel.position = _rest_position + Vector2(0, _slide)

func _show_note(opening: bool) -> void:
	if _presentation:
		_presentation.kill()
	if _page_fade:
		_page_fade.kill()
	_panel.show()
	_scroll.scroll_vertical = 0
	_request_layout()
	if opening:
		_panel.modulate.a = 0.0
		_set_slide(8.0)
		_presentation = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		_presentation.tween_property(_panel, "modulate:a", 1.0, 0.26)
		_presentation.tween_method(_set_slide, 8.0, 0.0, 0.26)
	else:
		_panel.modulate.a = 1.0
		_set_slide(0.0)
	_column.modulate.a = 0.35 if not opening else 1.0
	_page_fade = create_tween()
	_page_fade.tween_property(_column, "modulate:a", 1.0, 0.20)

func _hide_note() -> void:
	if _presentation:
		_presentation.kill()
	if _page_fade:
		_page_fade.kill()
	_next.release_focus()
	_presentation = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	_presentation.tween_property(_panel, "modulate:a", 0.0, 0.18)
	_presentation.tween_method(_set_slide, _slide, 4.0, 0.18)
	_presentation.chain().tween_callback(_panel.hide)

func blocks_interaction() -> bool:
	return not current_note.is_empty()

func enqueue_note(title: String, text: String, finished: Callable = Callable()) -> void:
	pending_notes.append({"title": title, "text": text, "finished": finished})
	if current_note.is_empty():
		advance_note()
	else:
		_update_action()

func _update_action() -> void:
	_next.icon = CLOSE_ICON if pending_notes.is_empty() else CONTINUE_ICON
	_next.tooltip_text = "Close" if pending_notes.is_empty() else "Continue"

func advance_note() -> void:
	var opening := current_note.is_empty() or not _panel.visible
	_note_pointer = -1
	var completed: Callable = current_note.get("finished", Callable())
	current_note = {}
	if completed.is_valid():
		completed.call()
	if pending_notes.is_empty():
		current_note = {}
		_hide_note()
		return
	current_note = pending_notes.pop_front()
	_title.text = str(current_note.title).to_upper()
	_body.text = current_note.text
	_update_action()
	_show_note(opening)

func _explorer() -> Node3D:
	for explorer in get_tree().get_nodes_in_group(&"explorers"):
		if explorer.get_viewport() == get_viewport() and explorer.can_process():
			return explorer
	return null

func pick_fragment(point: Vector2) -> MemoryFragment:
	var camera := get_viewport().get_camera_3d()
	var explorer := _explorer()
	if not camera or not explorer:
		return null
	var winner: MemoryFragment
	var nearest := INF
	for node in get_tree().get_nodes_in_group(&"memory_fragments"):
		var fragment := node as MemoryFragment
		if fragment.get_viewport() != get_viewport() or not fragment.can_interact(explorer):
			continue
		var position := fragment.get_orb_position()
		if camera.is_position_behind(position):
			continue
		var screen := camera.unproject_position(position)
		var edge := camera.unproject_position(position + camera.global_basis.x * fragment.orb_radius)
		var radius := maxf(fragment.tap_radius_pixels, screen.distance_to(edge) * 1.4)
		if screen.distance_to(point) > radius:
			continue
		# Physics occluders (boulders, trunks, platform) block a tap through scenery.
		var ray := PhysicsRayQueryParameters3D.create(camera.project_ray_origin(point), position)
		ray.exclude = [explorer.get_rid()]
		if not fragment.get_world_3d().direct_space_state.intersect_ray(ray).is_empty():
			continue
		var depth := camera.global_position.distance_squared_to(position)
		if depth < nearest:
			nearest = depth
			winner = fragment
	return winner

func _unhandled_input(event: InputEvent) -> void:
	# Shared worlds pick every component through one gated path. Standalone fragment
	# hosts can still use the original orb picker without a controller.
	for controller in get_tree().get_nodes_in_group(&"interaction_controllers"):
		if controller.get_viewport() == get_viewport() and controller.get_parent().is_ancestor_of(self):
			return
	var press := false
	var release := false
	var point := Vector2.ZERO
	var pointer := -1
	if event is InputEventScreenTouch:
		point = event.position
		pointer = event.index
		press = event.pressed
		release = not event.pressed
		if event.canceled:
			if event.index == _pointer:
				_reset_pointer()
			return
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		point = event.position
		pointer = -2
		press = event.pressed
		release = not event.pressed
	elif event is InputEventScreenDrag and event.index == _pointer:
		if event.position.distance_to(_start) > 20:
			_candidate = null
		get_viewport().set_input_as_handled()
		return
	elif event is InputEventMouseMotion and _pointer == -2:
		if event.position.distance_to(_start) > 20:
			_candidate = null
		get_viewport().set_input_as_handled()
		return
	else:
		return
	if press and _pointer == -1:
		_candidate = pick_fragment(point)
		if _candidate:
			_pointer = pointer
			_start = point
			get_viewport().set_input_as_handled()
	elif release and _pointer == pointer:
		if is_instance_valid(_candidate) and pick_fragment(point) == _candidate and point.distance_to(_start) <= 20:
			_candidate.try_activate(_explorer())
		_reset_pointer()
		get_viewport().set_input_as_handled()

# Native touch handling is explicit because this project disables mouse emulation.
func _input(event: InputEvent) -> void:
	if current_note.is_empty():
		return
	if event is InputEventScreenTouch:
		if event.pressed and _note_pointer == -1 and _panel.get_global_rect().has_point(event.position):
			_note_pointer = event.index
			_note_start = event.position
			_note_last = event.position
			_note_scrolling = _scroll.get_global_rect().has_point(event.position)
			_note_cancelled = not _next.get_global_rect().has_point(event.position)
			get_viewport().set_input_as_handled()
		elif not event.pressed and event.index == _note_pointer:
			var activate: bool = not event.canceled and not _note_cancelled and _next.get_global_rect().has_point(event.position)
			_note_pointer = -1
			get_viewport().set_input_as_handled()
			if activate:
				advance_note()
	elif event is InputEventScreenDrag and event.index == _note_pointer:
		_note_cancelled = _note_cancelled or event.position.distance_to(_note_start) > 20
		if _note_scrolling:
			_scroll.scroll_vertical -= roundi(event.position.y - _note_last.y)
		_note_last = event.position
		get_viewport().set_input_as_handled()

func _unhandled_key_input(event: InputEvent) -> void:
	if not current_note.is_empty() and event.is_action_pressed("ui_accept") and not event.is_echo():
		advance_note()
		accept_event()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		_note_pointer = -1
		_reset_pointer()

func _reset_pointer() -> void:
	_pointer = -1
	_candidate = null
