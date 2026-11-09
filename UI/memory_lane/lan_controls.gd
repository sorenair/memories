extends VBoxContainer
## The timeline handles touch directly because the project disables mouse emulation.

signal host_requested

var _host: Button
var _join: Button
var _address: LineEdit
var _status: Label
var _touch_id := -1
var _touch_target: Control
var _touch_start := Vector2.ZERO
var _touch_dragged := false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_constant_override("separation", 4)
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 8)
	add_child(row)
	_host = _make_button("Host", "Host LAN")
	row.add_child(_host)
	_host.pressed.connect(func() -> void: host_requested.emit())
	_address = LineEdit.new()
	_address.name = "HostIP"
	_address.placeholder_text = "Host IP"
	_address.text = LanSession.last_address
	_address.max_length = 45
	_address.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_address.add_theme_font_size_override("font_size", 22)
	_address.add_theme_color_override("font_color", Color("363634"))
	_address.add_theme_color_override("font_placeholder_color", Color("615b55"))
	_address.add_theme_color_override("caret_color", Color("363634"))
	_address.add_theme_stylebox_override("normal", _surface(Color("f4f1eb"), Color("d8d1c6")))
	_address.add_theme_stylebox_override("read_only", _surface(Color("eeeae2"), Color("d8d1c6")))
	_address.add_theme_stylebox_override("focus", _surface(Color.TRANSPARENT, Color("9d9589")))
	_address.text_submitted.connect(func(_text: String) -> void: _join_or_cancel())
	row.add_child(_address)
	_join = _make_button("Join", "Join LAN")
	row.add_child(_join)
	_join.pressed.connect(_join_or_cancel)
	_status = Label.new()
	_status.name = "Status"
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status.custom_minimum_size.y = 50.0
	_status.add_theme_font_size_override("font_size", 20)
	_status.add_theme_color_override("font_color", Color("615b55"))
	add_child(_status)

func layout_at_bottom(area: Vector2) -> void:
	var width := minf(640.0, area.x - 32.0)
	size = Vector2(width, get_combined_minimum_size().y)
	position = Vector2((area.x - size.x) * 0.5, area.y - size.y - 16.0)

func refresh(travelling: bool) -> void:
	var joining := LanSession.state == LanSession.State.JOINING
	_host.disabled = travelling or LanSession.state != LanSession.State.OFFLINE
	_join.disabled = travelling
	_join.text = "Cancel" if joining else "Join LAN"
	_address.editable = not (joining or travelling)
	_status.text = "" if travelling else LanSession.status

func _make_button(node_name: String, title: String) -> Button:
	var button := Button.new()
	button.name = node_name
	button.text = title
	button.custom_minimum_size = Vector2(104.0, 64.0)
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.add_theme_font_size_override("font_size", 22)
	for mode in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		button.add_theme_color_override(mode, Color("363634"))
	button.add_theme_color_override("font_disabled_color", Color("85827f"))
	button.add_theme_stylebox_override("normal", _surface(Color("eeeae2"), Color.TRANSPARENT))
	button.add_theme_stylebox_override("hover", _surface(Color("e7e1d7"), Color.TRANSPARENT))
	button.add_theme_stylebox_override("pressed", _surface(Color("ddd6ca"), Color.TRANSPARENT))
	button.add_theme_stylebox_override("disabled", _surface(Color("f4f1eb"), Color.TRANSPARENT))
	button.add_theme_stylebox_override("focus", _surface(Color.TRANSPARENT, Color("9d9589")))
	return button

func _surface(fill: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(12)
	style.content_margin_left = 12
	style.content_margin_right = 12
	return style

func _join_or_cancel() -> void:
	if _join.disabled:
		return
	_address.release_focus()
	if LanSession.state == LanSession.State.JOINING:
		LanSession.leave()
	else:
		LanSession.join(_address.text, MemoryExplorer.preferred_avatar)

func handle_touch(event: InputEvent) -> bool:
	if event is InputEventScreenTouch:
		if event.pressed and _touch_id == -1:
			for control: Control in [_host, _address, _join]:
				if control.get_global_rect().has_point(event.position):
					_touch_id = event.index
					_touch_target = control
					_touch_start = event.position
					_touch_dragged = false
					return true
		elif not event.pressed and event.index == _touch_id:
			var target := _touch_target
			_touch_id = -1
			_touch_target = null
			if not event.canceled and not _touch_dragged and target.get_global_rect().has_point(event.position):
				if target == _address and _address.editable:
					_address.grab_focus()
					_address.edit()
					_address.caret_column = _address.text.length()
				elif target is Button and not target.disabled:
					target.pressed.emit()
			return true
	elif event is InputEventScreenDrag and event.index == _touch_id:
		_touch_dragged = _touch_dragged or event.position.distance_to(_touch_start) > 20.0
		return true
	return false

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		_touch_id = -1
		_touch_target = null
