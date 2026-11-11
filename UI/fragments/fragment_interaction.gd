extends Control
## One picker / note queue per viewport. GUI and joystick get first refusal on input.
var pending_notes: Array[Dictionary] = []
var current_note: Dictionary = {}
var _panel: PanelContainer
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
	_panel = PanelContainer.new()
	_panel.name = "NotePanel"
	add_child(_panel)
	_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_panel.offset_left = -300
	_panel.offset_right = 300
	_panel.offset_top = -230
	_panel.offset_bottom = -35
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.97, 0.96, 0.91, 0.96)
	style.set_corner_radius_all(18)
	style.content_margin_left = 28
	style.content_margin_right = 28
	style.content_margin_top = 20
	style.content_margin_bottom = 16
	_panel.add_theme_stylebox_override("panel", style)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	_panel.add_child(column)
	_title = Label.new()
	_title.add_theme_color_override("font_color", Color(0.28, 0.33, 0.34))
	_title.add_theme_font_size_override("font_size", 19)
	column.add_child(_title)
	_body = Label.new()
	_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body.add_theme_color_override("font_color", Color(0.20, 0.25, 0.26))
	_body.add_theme_font_size_override("font_size", 24)
	_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(_body)
	_next = Button.new()
	_next.text = "Continue"
	_next.alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_next.add_theme_color_override("font_color", Color(0.28, 0.33, 0.34))
	_next.add_theme_color_override("font_hover_color", Color(0.12, 0.24, 0.28))
	for state in ["normal", "hover", "pressed", "focus"]:
		_next.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	_next.custom_minimum_size.y = 44
	_next.pressed.connect(advance_note)
	column.add_child(_next)
	_panel.hide()
	resized.connect(_layout)
	_layout()

func _layout() -> void:
	if not is_instance_valid(_panel):
		return
	var width := minf(600.0, size.x - 40.0)
	_panel.offset_left = -width * 0.5
	_panel.offset_right = width * 0.5

func blocks_interaction() -> bool:
	return not current_note.is_empty()

func enqueue_note(title: String, text: String, finished: Callable = Callable()) -> void:
	pending_notes.append({"title": title, "text": text, "finished": finished})
	if current_note.is_empty():
		advance_note()
	else:
		_next.text = "Continue"

func advance_note() -> void:
	var completed: Callable = current_note.get("finished", Callable())
	current_note = {}
	if completed.is_valid():
		completed.call()
	if pending_notes.is_empty():
		current_note = {}
		_panel.hide()
		return
	current_note = pending_notes.pop_front()
	_title.text = current_note.title
	_body.text = current_note.text
	_next.text = "Close" if pending_notes.is_empty() else "Continue"
	_panel.show()

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
	if not _panel.visible:
		return
	if event is InputEventScreenTouch:
		if event.pressed and _note_pointer == -1 and _panel.get_global_rect().has_point(event.position):
			_note_pointer = event.index
			_note_start = event.position
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
		get_viewport().set_input_as_handled()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		_note_pointer = -1
		_reset_pointer()

func _reset_pointer() -> void:
	_pointer = -1
	_candidate = null
