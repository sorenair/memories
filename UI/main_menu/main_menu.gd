extends Control
const PAPER := Color("faf9f6")
const INK := Color("363634")
const IconButton := preload("res://UI/main_menu/menu_icon_button.gd")
const MemoryAction := preload("res://UI/main_menu/memory_action_button.gd")
const ThreadTransition := preload("res://UI/main_menu/timeline_transition.gd")
const Arrival := preload("res://UI/memory_arrival/memory_arrival.gd")
const FROM_MAIN_META := &"timeline_from_main_menu"
const TIMELINE := "res://UI/memory_lane/memory_lane.tscn"
var _title: Label
var _proceed: Button
var _proceed_intro: Tween
var _proceed_reveal := 0.0
var _avatar_picker: HBoxContainer
var _avatar_buttons: Array[Button] = []
var _travelling: bool = false
var _lan_controls: Control
var _layout_queued := false

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
	_proceed = MemoryAction.new()
	_proceed.name = "Proceed"
	_proceed.tooltip_text = "Enter Memory Lane"
	_proceed.modulate.a = 0.0
	_proceed.pressed.connect(enter_timeline)
	add_child(_proceed)
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
	LanSession.set_avatar(MemoryExplorer.preferred_avatar)
	_lan_controls = preload("res://UI/main_menu/lan_controls.gd").new()
	_lan_controls.name = "LAN"
	add_child(_lan_controls)
	resized.connect(_request_layout)
	_layout()
	_proceed_intro = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_proceed_intro.tween_method(_reveal_proceed, 0.0, 1.0, 0.65).set_delay(0.15)
	var veil_layer := get_tree().root.get_node_or_null(Arrival.VEIL_LAYER_NAME)
	if veil_layer:
		veil_layer.reparent(self)
		var tween := create_tween()
		tween.tween_property(veil_layer.get_node("Paper"), "modulate:a", 0.0, 0.4)
		tween.tween_callback(veil_layer.queue_free)

func _select_avatar(avatar: MemoryExplorer.Avatar) -> void:
	if _travelling:
		return
	LanSession.set_avatar(avatar)
	for index in _avatar_buttons.size():
		_avatar_buttons[index].set_pressed_no_signal(index == avatar)

func _request_layout() -> void:
	_layout()
	# Font and container minimum sizes settle after orientation changes.
	if not _layout_queued:
		_layout_queued = true
		_finish_layout.call_deferred()

func _finish_layout() -> void:
	_layout_queued = false
	_layout()

func _reveal_proceed(progress: float) -> void:
	_proceed_reveal = progress
	_proceed.modulate.a = progress
	_proceed.position.y = size.y * 0.55 + (1.0 - progress) * 10.0

func _layout() -> void:
	if _title == null:
		return
	var portrait := size.y > size.x
	var font_size := int(clampf(minf(size.x * 0.112, size.y * 0.16), 36.0, 144.0))
	_title.add_theme_font_size_override("font_size", font_size)
	_title.position = Vector2(24, size.y * 0.34)
	_title.size = Vector2(size.x - 48, font_size * 1.5)
	_proceed.size = Vector2(112, 96) if portrait else Vector2(144, 112)
	_proceed.symbol_size = Vector2(88, 56) if portrait else Vector2(104, 64)
	_proceed.position = Vector2((size.x - _proceed.size.x) * 0.5, size.y * 0.55 + (1.0 - _proceed_reveal) * 10.0)
	var button_size := 80.0 if portrait else 112.0
	for button in _avatar_buttons:
		button.custom_minimum_size = Vector2(button_size, button_size)
		button.symbol_size = Vector2(42, 48) if portrait else Vector2(56, 64)
	_avatar_picker.size = _avatar_picker.get_combined_minimum_size()
	var margin := 24.0 if portrait else 40.0
	_avatar_picker.position = size - _avatar_picker.size - Vector2(margin, margin)
	if _lan_controls != null:
		_lan_controls.layout_in(size)
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), PAPER)

func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept") and not event.is_echo() and not _lan_controls.is_editing():
		enter_timeline()
		accept_event()

func enter_timeline() -> void:
	if _travelling:
		return
	_travelling = true
	_proceed_intro.kill()
	_lan_controls.set_locked(true)
	_proceed.disabled = true
	for button in _avatar_buttons:
		button.disabled = true
	var layer := CanvasLayer.new()
	layer.name = ThreadTransition.LAYER_NAME
	layer.layer = 110
	get_tree().root.add_child(layer)
	var bridge := ThreadTransition.new()
	bridge.name = "Morph"
	layer.add_child(bridge)
	bridge.begin(_proceed.get_entry_pose())
	_proceed.hide()
	var tween := create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(_title, "modulate:a", 0.0, 0.3)
	tween.tween_property(_title, "position:y", _title.position.y - 16.0, 0.35)
	tween.tween_property(_avatar_picker, "modulate:a", 0.0, 0.3)
	tween.tween_property(_lan_controls, "modulate:a", 0.0, 0.3)
	tween.tween_property(bridge, "cover_alpha", 1.0, ThreadTransition.DEPART_DURATION)
	tween.tween_property(bridge, "progress", ThreadTransition.DEPART_DURATION, ThreadTransition.DEPART_DURATION).set_trans(Tween.TRANS_LINEAR)
	await tween.finished
	get_tree().root.set_meta(FROM_MAIN_META, true)
	var error := get_tree().change_scene_to_file(TIMELINE)
	if error != OK:
		get_tree().root.remove_meta(FROM_MAIN_META)
		bridge.cancel()
		_travelling = false
		_lan_controls.set_locked(false)
		_lan_controls.modulate.a = 1.0
		_title.modulate.a = 1.0
		_proceed_reveal = 1.0
		_proceed.modulate.a = 1.0
		_proceed.show()
		_avatar_picker.modulate.a = 1.0
		_proceed.disabled = false
		for button in _avatar_buttons:
			button.disabled = false
		_layout()
		push_error("Unable to open timeline: %s" % error_string(error))
