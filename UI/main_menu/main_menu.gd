extends Control
const PAPER := Color("faf9f6")
const INK := Color("363634")
const IconButton := preload("res://UI/main_menu/menu_icon_button.gd")
const Arrival := preload("res://UI/memory_arrival/memory_arrival.gd")
const FROM_MAIN_META := &"timeline_from_main_menu"
const TIMELINE := "res://UI/memory_lane/memory_lane.tscn"
var _title: Label
var _infinity: Button
var _avatar_picker: HBoxContainer
var _avatar_buttons: Array[Button] = []
var _travelling: bool = false

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var serif := SystemFont.new()
	serif.font_names = PackedStringArray(["Georgia", "Noto Serif", "DejaVu Serif"])
	_title = Label.new()
	_title.name = "EvermoreTitle"
	_title.text = "EVERMORE"
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_title.add_theme_font_override("font", serif)
	_title.add_theme_color_override("font_color", INK)
	add_child(_title)
	_infinity = IconButton.new()
	_infinity.name = "Infinity"
	_infinity.symbol = preload("res://UI/main_menu/icons/infinity.svg")
	_infinity.symbol_size = Vector2(104, 48)
	_infinity.tooltip_text = "Enter Memory Lane"
	_infinity.pressed.connect(enter_timeline)
	add_child(_infinity)
	_avatar_picker = HBoxContainer.new()
	_avatar_picker.name = "CharacterPicker"
	_avatar_picker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_avatar_picker.add_theme_constant_override("separation", 8)
	add_child(_avatar_picker)
	var group := ButtonGroup.new()
	for avatar in [MemoryExplorer.Avatar.SOREN, MemoryExplorer.Avatar.VIVIAN]:
		var button := IconButton.new()
		button.name = "Soren" if avatar == MemoryExplorer.Avatar.SOREN else "Vivian"
		button.tooltip_text = "Play as Soren" if avatar == MemoryExplorer.Avatar.SOREN else "Play as Vivian"
		button.symbol = preload("res://UI/main_menu/icons/male.svg") if avatar == MemoryExplorer.Avatar.SOREN else preload("res://UI/main_menu/icons/female.svg")
		button.selection_icon = true
		button.toggle_mode = true
		button.button_group = group
		button.button_pressed = avatar == MemoryExplorer.preferred_avatar
		button.pressed.connect(_select_avatar.bind(avatar))
		_avatar_picker.add_child(button)
		_avatar_buttons.append(button)
	resized.connect(_layout)
	_layout()
	var veil_layer := get_tree().root.get_node_or_null(Arrival.VEIL_LAYER_NAME)
	if veil_layer:
		veil_layer.reparent(self)
		var tween := create_tween()
		tween.tween_property(veil_layer.get_node("Paper"), "modulate:a", 0.0, 0.4)
		tween.tween_callback(veil_layer.queue_free)

func _select_avatar(avatar: MemoryExplorer.Avatar) -> void:
	if _travelling:
		return
	MemoryExplorer.preferred_avatar = avatar
	for index in _avatar_buttons.size():
		_avatar_buttons[index].set_pressed_no_signal(index == avatar)

func _layout() -> void:
	if _title == null:
		return
	var portrait := size.y > size.x
	var font_size := int(clampf(minf(size.x * 0.112, size.y * 0.16), 36.0, 144.0))
	_title.add_theme_font_size_override("font_size", font_size)
	_title.position = Vector2(24, size.y * 0.34)
	_title.size = Vector2(size.x - 48, font_size * 1.5)
	_infinity.size = Vector2(clampf(size.x * 0.15, 144.0, 240.0), 112.0)
	_infinity.position = Vector2((size.x - _infinity.size.x) * 0.5, size.y * 0.55)
	_infinity.pivot_offset = _infinity.size * 0.5
	_infinity.symbol_size = Vector2(80, 38) if portrait else Vector2(104, 48)
	var button_size := 80.0 if portrait else 112.0
	for button in _avatar_buttons:
		button.custom_minimum_size = Vector2(button_size, button_size)
		button.symbol_size = Vector2(42, 48) if portrait else Vector2(56, 64)
	_avatar_picker.size = _avatar_picker.get_combined_minimum_size()
	var margin := 24.0 if portrait else 40.0
	_avatar_picker.position = size - _avatar_picker.size - Vector2(margin, margin)
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), PAPER)

func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept") and not event.is_echo():
		enter_timeline()
		accept_event()

func enter_timeline() -> void:
	if _travelling:
		return
	_travelling = true
	_infinity.disabled = true
	for button in _avatar_buttons:
		button.disabled = true
	var veil := Arrival.get_transition_veil(get_tree())
	var tween := create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(_title, "modulate:a", 0.0, 0.5)
	tween.tween_property(_title, "position:y", _title.position.y - 16.0, 0.65)
	tween.tween_property(_infinity, "scale", Vector2.ONE * 0.7, 0.65)
	tween.tween_property(_infinity, "modulate:a", 0.0, 0.55)
	tween.tween_property(_avatar_picker, "modulate:a", 0.0, 0.4)
	tween.tween_property(veil, "modulate:a", 1.0, 0.65)
	await tween.finished
	get_tree().root.set_meta(FROM_MAIN_META, true)
	var error := get_tree().change_scene_to_file(TIMELINE)
	if error != OK:
		get_tree().root.remove_meta(FROM_MAIN_META)
		veil.get_parent().queue_free()
		_travelling = false
		_title.modulate.a = 1.0
		_infinity.modulate.a = 1.0
		_infinity.scale = Vector2.ONE
		_avatar_picker.modulate.a = 1.0
		_infinity.disabled = false
		for button in _avatar_buttons:
			button.disabled = false
		_layout()
		push_error("Unable to open timeline: %s" % error_string(error))
