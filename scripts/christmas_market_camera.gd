extends "res://scripts/follow_camera.gd"
## One walking frame, with a separate view of the tree and performers.

@export var gathering_focus: Node3D
@export var gathering_viewpoint: Node3D
@export var walking_size := 4.5
@export var gathering_size := 8.8

const WALKING_OFFSET := Vector3(0, 0.85, -0.62)
const VIEW_ENTER_RADIUS := 1.55
const VIEW_EXIT_RADIUS := 2.75

var _at_gathering := false
@onready var _camera: Camera3D = $Camera3D

func _ready() -> void:
	framing_offset = WALKING_OFFSET
	_camera.size = walking_size
	super._ready()

func _process(delta: float) -> void:
	if is_instance_valid(target) and is_instance_valid(gathering_viewpoint) and is_instance_valid(gathering_focus):
		var at := target.get_global_transform_interpolated().origin
		var offset := gathering_viewpoint.global_position - at
		var radius := VIEW_EXIT_RADIUS if _at_gathering else VIEW_ENTER_RADIUS
		_at_gathering = Vector2(offset.x, offset.z).length_squared() <= radius * radius
		var focus_offset := gathering_focus.global_position - at if _at_gathering else WALKING_OFFSET
		var size := gathering_size if _at_gathering else walking_size
		var blend := 1.0 - exp(-3.3 * delta)
		framing_offset = framing_offset.lerp(focus_offset, blend)
		_camera.size = lerpf(_camera.size, size, blend)
	super._process(delta)
