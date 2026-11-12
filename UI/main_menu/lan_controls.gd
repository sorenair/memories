extends Control
## One fixed connection row shared by Host and Join; navigation never waits for LAN.
const INK := Color("363634")
const MUTED := Color("85827f")
const IconButton := preload("res://UI/main_menu/menu_icon_button.gd")
const Indicator := preload("res://UI/main_menu/connection_indicator.gd")
var _host: Button
var _join: Button
var _address: LineEdit
var _submit: Button
var _buttons: HBoxContainer
var _row: HBoxContainer
var _connection: Control
var _status: Label
var _locked := false
var _join_draft := ""
var _displayed_mode: int = -1
var _field_fade: Tween
var _arrow_fade: Tween
var _arrow_alpha_goal: float = -1.0
var _touch_id := -1
var _touch_target: Control
var _touch_start := Vector2.ZERO
var _touch_dragged := false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_join_draft = LanSession.last_address
	_buttons = HBoxContainer.new()
	_buttons.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_buttons.add_theme_constant_override("separation", 12)
	add_child(_buttons)
	_host = _make_button("Host")
	_join = _make_button("Join")
	_buttons.add_child(_host)
	_buttons.add_child(_join)
	_host.pressed.connect(_toggle_host)
	_join.pressed.connect(_toggle_join)
	_row = HBoxContainer.new()
	_row.name = "ConnectionRow"
	_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_row.add_theme_constant_override("separation", 8)
	add_child(_row)
	_connection = Indicator.new()
	_connection.name = "ConnectionIndicator"
	_row.add_child(_connection)
	_address = LineEdit.new()
	_address.name = "Address"
	_address.max_length = 45
	_address.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_address.add_theme_color_override("font_color", INK)
	_address.add_theme_color_override("font_uneditable_color", INK)
	_address.add_theme_color_override("font_selected_color", INK)
	_address.add_theme_color_override("selection_color", Color(MUTED, 0.15))
	_address.add_theme_color_override("font_placeholder_color", MUTED)
	_address.add_theme_color_override("caret_color", INK)
	for mode in ["normal", "read_only", "focus"]:
		var style := StyleBoxFlat.new()
		style.bg_color = Color.TRANSPARENT
		style.border_width_bottom = 1
		style.border_color = Color(MUTED, 0.6 if mode == "focus" else 0.25)
		style.content_margin_left = 4
		style.content_margin_right = 4
		_address.add_theme_stylebox_override(mode, style)
	_address.text_submitted.connect(func(_value: String): _perform_action())
	_row.add_child(_address)
	_submit = IconButton.new()
	_submit.name = "AddressAction"
	_submit.symbol = preload("res://UI/main_menu/icons/submit.svg")
	_submit.symbol_size = Vector2(32, 32)
	_submit.pressed.connect(_perform_action)
	_row.add_child(_submit)
	_status = Label.new()
	_status.name = "ConnectionError"
	_status.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status.add_theme_color_override("font_color", MUTED)
	add_child(_status)
	LanSession.status_changed.connect(refresh)
	LanSession.initialize_main_menu()
	refresh()

func _make_button(title: String) -> Button:
	var button := Button.new()
	button.name = title
	button.text = title
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	for mode in ["normal", "hover", "pressed", "hover_pressed", "disabled", "focus"]:
		button.add_theme_stylebox_override(mode, StyleBoxEmpty.new())
	button.add_theme_color_override("font_pressed_color", INK)
	return button

func _refresh_mode_colors() -> void:
	for button in [_host, _join]:
		var active: bool = LanSession.state == LanSession.State.HOSTING if button == _host else LanSession.menu_mode == LanSession.MenuMode.JOIN
		var touched: bool = _touch_id != -1 and _touch_target == button and not _touch_dragged
		var color := INK if active or touched else MUTED
		for mode in ["font_color", "font_hover_color", "font_focus_color", "font_hover_pressed_color", "font_disabled_color"]:
			button.add_theme_color_override(mode, color)

func layout_in(area: Vector2) -> void:
	var portrait := area.y > area.x
	var margin := 24.0 if portrait else 40.0
	var height := 56.0 if portrait else 64.0
	var width := minf(420.0, area.x - margin * 2.0)
	for button in [_host, _join]:
		button.custom_minimum_size = Vector2(68.0 if portrait else 96.0, height)
		button.add_theme_font_size_override("font_size", 22 if portrait else 26)
	_buttons.size = _buttons.get_combined_minimum_size()
	_buttons.position = Vector2(margin, area.y - margin - height)
	_row.position = _buttons.position - Vector2(0, (36.0 if portrait else 12.0) + height)
	_row.size = Vector2(width, height)
	_connection.custom_minimum_size = Vector2(48.0 if portrait else 64.0, height)
	_submit.custom_minimum_size = Vector2(height, height)
	_address.add_theme_font_size_override("font_size", 20 if portrait else 24)
	_status.position = _row.position - Vector2(0, 48)
	_status.size = Vector2(width, 44)
	_status.add_theme_font_size_override("font_size", 16 if portrait else 20)

func set_locked(value: bool) -> void:
	_locked = value
	refresh()

func refresh() -> void:
	var hosting := LanSession.state == LanSession.State.HOSTING
	var joining := LanSession.state == LanSession.State.JOINING
	var joined := LanSession.state == LanSession.State.GUEST
	var host_mode := LanSession.menu_mode == LanSession.MenuMode.HOST
	var initial := _displayed_mode == -1
	_host.disabled = _locked
	_join.disabled = _locked
	_refresh_mode_colors()
	_host.tooltip_text = "Stop hosting" if hosting else "Start hosting"
	_join.tooltip_text = "Disconnect" if joining or joined else "Join your partner"
	if _displayed_mode != LanSession.menu_mode:
		if _displayed_mode == LanSession.MenuMode.JOIN:
			_join_draft = _address.text
		_address.release_focus()
		_address.text = LanSession.host_addresses().split(", ")[0] if host_mode else _join_draft
		_address.caret_column = 0
		if _displayed_mode != -1:
			if _field_fade:
				_field_fade.kill()
			_address.self_modulate.a = 0.35
			_field_fade = create_tween()
			_field_fade.tween_property(_address, "self_modulate:a", 1.0, 0.18)
		_displayed_mode = LanSession.menu_mode
	_address.placeholder_text = "Host address" if host_mode else "Host IP address"
	_address.editable = not (host_mode or _locked or joining or joined)
	for mode in ["normal", "read_only", "focus"]:
		var style := _address.get_theme_stylebox(mode) as StyleBoxFlat
		style.border_color = Color.TRANSPARENT if host_mode else Color(MUTED, 0.6 if mode == "focus" else 0.25)
	_submit.disabled = _locked or host_mode or joining or joined
	_submit.focus_mode = Control.FOCUS_NONE if host_mode else Control.FOCUS_ALL
	_submit.mouse_filter = Control.MOUSE_FILTER_IGNORE if host_mode else Control.MOUSE_FILTER_STOP
	_submit.tooltip_text = "" if host_mode else "Connect"
	# Keep the HBox slot while fading the glyph, so the address never changes width.
	var arrow_alpha := 0.0 if host_mode else (0.35 if _submit.disabled else 1.0)
	if not is_equal_approx(arrow_alpha, _arrow_alpha_goal):
		_arrow_alpha_goal = arrow_alpha
		if _arrow_fade:
			_arrow_fade.kill()
		if initial:
			_submit.modulate.a = arrow_alpha
		else:
			_arrow_fade = create_tween()
			_arrow_fade.tween_property(_submit, "modulate:a", arrow_alpha, 0.18)
	_connection.set_connection(LanSession.partner_id != 0, joining)
	# Routine states are expressed by the rings; reserve text for actionable errors.
	_status.text = LanSession.status if LanSession.state == LanSession.State.OFFLINE else ""
	_status.visible = not _status.text.is_empty()

func _toggle_host() -> void:
	if _locked:
		return
	_address.release_focus()
	if LanSession.menu_mode == LanSession.MenuMode.JOIN:
		_join_draft = _address.text
	LanSession.menu_mode = LanSession.MenuMode.HOST
	if LanSession.state == LanSession.State.HOSTING:
		LanSession.leave()
	else:
		LanSession.leave()
		LanSession.host(MemoryExplorer.preferred_avatar)
	refresh()

func _toggle_join() -> void:
	if _locked:
		return
	_address.release_focus()
	LanSession.menu_mode = LanSession.MenuMode.JOIN
	LanSession.leave()
	refresh()

func _perform_action() -> void:
	if _locked or _submit.disabled or LanSession.menu_mode == LanSession.MenuMode.HOST:
		return
	_address.release_focus()
	_join_draft = _address.text
	LanSession.join(_address.text, MemoryExplorer.preferred_avatar)

func is_editing() -> bool:
	return _address.editable and _address.has_focus()

func _input(event: InputEvent) -> void:
	if _locked:
		return
	var captured := false
	if event is InputEventScreenTouch:
		if event.pressed and _touch_id == -1:
			for control: Control in [_host, _join, _address]:
				if control.is_visible_in_tree() and control.get_global_rect().has_point(event.position):
					_touch_id = event.index
					_touch_target = control
					_touch_start = event.position
					_touch_dragged = false
					captured = true
					break
		elif not event.pressed and event.index == _touch_id:
			var target := _touch_target
			_touch_id = -1
			_touch_target = null
			captured = true
			if not event.canceled and not _touch_dragged and target.get_global_rect().has_point(event.position):
				if target == _address and _address.editable:
					_address.grab_focus()
					_address.edit()
					_address.caret_column = _address.text.length()
				elif target is Button and not target.disabled:
					target.pressed.emit()
	elif event is InputEventScreenDrag and event.index == _touch_id:
		_touch_dragged = _touch_dragged or event.position.distance_to(_touch_start) > 20.0
		captured = true
	if captured:
		_refresh_mode_colors()
		get_viewport().set_input_as_handled()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		_touch_id = -1
		_touch_target = null
		if is_instance_valid(_host):
			_refresh_mode_colors()
