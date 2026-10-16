extends Button
## A small timeline glyph with a generous invisible touch target.
const MemoryArrival := preload("res://UI/memory_arrival/memory_arrival.gd")
const Timeline := preload("res://UI/memory_lane/memory_lane.gd")
const TIMELINE_SCENE := "res://UI/memory_lane/memory_lane.tscn"
const CONTRAST_SHADER := preload("res://UI/in_game/glyph_contrast.gdshader")

var _returning: bool = false
var _touch_id: int = -1
var _touch_start := Vector2.ZERO
var _touch_cancelled: bool = false
@onready var _world: Node = get_parent().get_parent()

func _ready() -> void:
	var contrast_material := ShaderMaterial.new()
	contrast_material.shader = CONTRAST_SHADER
	material = contrast_material
	tooltip_text = "Return to timeline"
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	for style in ["normal", "hover", "pressed", "disabled", "focus"]:
		add_theme_stylebox_override(style, StyleBoxEmpty.new())
	pressed.connect(return_to_timeline)

func _process(_delta: float) -> void:
	disabled = _returning or _world.has_node("MemoryArrival")
	queue_redraw()

func _draw() -> void:
	var center := size * 0.5
	var active := is_hovered() or has_focus() or button_pressed or _touch_id >= 0
	var color := Color(1.0, 1.0, 1.0, 0.25 if disabled else 1.0)
	draw_line(center - Vector2(24, 0), center + Vector2(24, 0), color, 3.0 if active else 2.5, true)
	draw_circle(center, 6.0, color, true, -1, true)

func _input(event: InputEvent) -> void:
	if disabled or _returning or _world.has_node("MemoryArrival"):
		return
	if event is InputEventScreenTouch:
		if event.pressed and _touch_id == -1 and get_global_rect().has_point(event.position):
			_touch_id = event.index
			_touch_start = event.position
			_touch_cancelled = false
			get_viewport().set_input_as_handled()
		elif not event.pressed and event.index == _touch_id:
			var activate: bool = not event.canceled and not _touch_cancelled and get_global_rect().has_point(event.position)
			_touch_id = -1
			get_viewport().set_input_as_handled()
			if activate:
				pressed.emit()
	elif event is InputEventScreenDrag and event.index == _touch_id:
		_touch_cancelled = _touch_cancelled or event.position.distance_to(_touch_start) > 20.0
		get_viewport().set_input_as_handled()

func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not event.is_echo():
		return_to_timeline()
		accept_event()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		_touch_id = -1

func return_to_timeline() -> void:
	if _returning or _world.has_node("MemoryArrival"):
		return
	_returning = true
	disabled = true
	var controls: Control = _world.get_node("Controls/ExplorationInput")
	var player: CharacterBody3D = _world.get_node("Explorer")
	var controls_mode := controls.process_mode
	var player_processing := player.is_physics_processing()
	controls._release()
	controls.process_mode = Node.PROCESS_MODE_DISABLED
	player.velocity = Vector3.ZERO
	player.set_physics_process(false)
	var veil := MemoryArrival.get_transition_veil(get_tree())
	var tween := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(veil, "modulate:a", 1.0, 0.45)
	await tween.finished
	var error := get_tree().change_scene_to_file(TIMELINE_SCENE)
	if error != OK:
		push_error("Unable to return to timeline: %s" % error_string(error))
		veil.get_parent().queue_free()
		controls.process_mode = controls_mode
		player.set_physics_process(player_processing)
		_returning = false
		disabled = false
