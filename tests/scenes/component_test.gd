@tool
extends Node3D
## Generic test stage: swap Subject Scene, preserving camera, ground and controls.
@export_group("Subject")
@export var subject_scene: PackedScene:
	set(value):
		subject_scene = value
		_queue_subject()
@export var subject_position := Vector3.ZERO:
	set(value):
		subject_position = value
		_place_subject()
@export var subject_rotation_degrees := Vector3.ZERO:
	set(value):
		subject_rotation_degrees = value
		_place_subject()
@export_enum("Scene Default", "Enabled", "Disabled") var recall_mode: int = 0:
	set(value):
		recall_mode = clampi(value, 0, 2)
		_queue_subject()
@export_group("Stage")
@export var floor_color := Color(0.28, 0.30, 0.33, 1.0):
	set(value):
		floor_color = value
		_apply_floor()
@export var show_wall: bool = false:
	set(value):
		show_wall = value
		if has_node("BackWall"):
			$BackWall.visible = value
@export_range(3.0, 30.0, 0.5) var camera_size: float = 10.0:
	set(value):
		camera_size = value
		if has_node("Camera3D"):
			$Camera3D.size = value

@export var camera_focus := Vector3(0, 0.8, 0):
	set(value):
		camera_focus = value
		if is_inside_tree() and has_node("Camera3D"):
			$Camera3D.look_at(value)

var subject: Node3D
var _queued: bool = false

func _ready() -> void:
	_apply_floor()
	$BackWall.visible = show_wall
	$Camera3D.size = camera_size
	$Camera3D.look_at(camera_focus)
	_queue_subject()
	if not Engine.is_editor_hint():
		$Controls/Panel/Rows/Reload.pressed.connect(reload_subject)
		$Controls/Panel/Rows/Toggle.pressed.connect(_toggle_subject)
		$Controls/Panel/Rows/Replay.pressed.connect(_replay)
		$Controls/Panel/Rows/Floor.item_selected.connect(_floor_selected)
		$Controls/Panel/Rows/RecallMode.item_selected.connect(_recall_mode_selected)
		$Controls/Panel/Rows/RecallMode.select(recall_mode)
		$Controls/Panel/Rows/Wall.toggled.connect(_wall_toggled)
		$Controls/Panel/Rows/Wall.set_pressed_no_signal(show_wall)
	set_process(not Engine.is_editor_hint())
	set_process_unhandled_key_input(not Engine.is_editor_hint())

func _queue_subject() -> void:
	if is_inside_tree() and not _queued:
		_queued = true
		call_deferred("reload_subject")

func reload_subject() -> void:
	_queued = false
	if not has_node("SubjectMount"):
		return
	if is_instance_valid(subject):
		$SubjectMount.remove_child(subject)
		subject.queue_free()
		subject = null
	if subject_scene:
		var instance := subject_scene.instantiate()
		if not instance is Node3D:
			instance.free()
			push_warning("The component test stage expects a 3D scene.")
			return
		subject = instance as Node3D
		if recall_mode != 0 and subject.has_method("get_recall_controller"):
			subject.set("recall_enabled", recall_mode == 1)
		# Place before _ready so exclusions/recall use the correct authoring transform.
		_place_subject()
		$SubjectMount.add_child(subject, false, Node.INTERNAL_MODE_BACK)
	_update_labels()

func _place_subject() -> void:
	if is_instance_valid(subject):
		subject.position = subject_position
		subject.rotation_degrees = subject_rotation_degrees

func _apply_floor() -> void:
	if not has_node("Floor"):
		return
	$Floor.mesh.material.albedo_color = floor_color
	$WorldEnvironment.environment.background_color = floor_color
	if has_node("Controls/Title"):
		var ink := Color(0.18, 0.20, 0.22) if floor_color.get_luminance() > 0.6 else Color(0.94, 0.935, 0.89)
		$Controls/Title.label_settings.font_color = ink
		$Controls/Hint.add_theme_color_override("font_color", ink)

func _update_labels() -> void:
	if not has_node("Controls"):
		return
	$Controls/Title.text = "Component test / " + (subject.name if is_instance_valid(subject) else "No subject")
	$Controls/Panel/Rows/Toggle.disabled = not is_instance_valid(subject)
	$Controls/Panel/Rows/Replay.disabled = _recall_controller() == null

func _recall_controller() -> Node:
	if is_instance_valid(subject) and subject.has_method("get_recall_controller"):
		return subject.get_recall_controller()
	return null

func _process(_delta: float) -> void:
	# Some components build after their dependencies become ready.
	$Controls/Panel/Rows/Replay.disabled = _recall_controller() == null

func _toggle_subject() -> void:
	if is_instance_valid(subject):
		subject.visible = not subject.visible

func _replay() -> void:
	var recall := _recall_controller()
	if recall:
		recall.replay()

func _floor_selected(index: int) -> void:
	floor_color = [Color(0.28, 0.30, 0.33), Color(0.94, 0.935, 0.89), Color(0.08, 0.095, 0.12)][index]

func _recall_mode_selected(index: int) -> void:
	recall_mode = index

func _wall_toggled(value: bool) -> void:
	show_wall = value

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_R:
			reload_subject()
		elif event.keycode == KEY_V:
			_toggle_subject()
