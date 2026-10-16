extends Node3D
## Test controls live here; the reusable grass adapter has no UI dependencies.
@export_range(0.5, 5.0, 0.1) var discovery_distance: float = 1.4
@export var subject_name: String = "meadow"
@export var subject_path := NodePath("Subjects/Grass")
@onready var recall: Node = get_node(subject_path).get_recall_controller()
@onready var scrub: HSlider = $Controls/Panel/Rows/Scrub
@onready var status: Label = $Controls/Panel/Rows/Status
var _waiting: bool = true
var _base_duration: float = 3.2

func _ready() -> void:
	recall.auto_discover = false
	recall.origin = $Subjects/RecallOrigin
	recall.reset()
	_base_duration = recall.duration
	$Controls/Panel/Rows/Buttons/Replay.pressed.connect(_replay)
	$Controls/Panel/Rows/Buttons/Reset.pressed.connect(_reset)
	$Controls/Panel/Rows/Buttons/Pause.pressed.connect(_pause)
	$Controls/Panel/Rows/Speed.value_changed.connect(_speed_changed)
	scrub.value_changed.connect(_scrubbed)

func _process(_delta: float) -> void:
	if _waiting and $Explorer.global_position.distance_to($Subjects/RecallOrigin.global_position) < discovery_distance:
		_waiting = false
		recall.play()
	scrub.set_value_no_signal(recall.progress)
	status.text = ("Approach the " + subject_name if _waiting else ("Recalling" if recall.playing else ("Recalled" if recall.progress >= 1.0 else "Paused"))) + "  ·  %d%%" % roundi(recall.progress * 100.0)

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_R:
			_replay()
		elif event.keycode == KEY_SPACE:
			_pause()

func _replay() -> void:
	_waiting = false
	recall.replay()

func _reset() -> void:
	_waiting = true
	$Explorer.position = Vector3(0, 0, 4.2)
	$Explorer.velocity = Vector3.ZERO
	$Explorer.reset_physics_interpolation()
	recall.reset()

func _pause() -> void:
	_waiting = false
	if recall.progress >= 1.0:
		recall.replay()
	else:
		recall.playing = not recall.playing

func _scrubbed(value: float) -> void:
	_waiting = false
	recall.playing = false
	recall.seek(value)

func _speed_changed(value: float) -> void:
	recall.duration = _base_duration / value
