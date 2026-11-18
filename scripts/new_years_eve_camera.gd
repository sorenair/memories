extends "res://scripts/follow_camera.gd"
## Stable exploration zoom, with a wide shot from the front of the crowd.
@export var walking_size := 4.7
@export var stage_size := 10.9

const WALKING_OFFSET := Vector3(0, 0.9, -0.65)
const SCENIC_FOCUS := Vector3(0, 2.95, -5.75)
var _stage_view := false

func _ready() -> void:
	framing_offset = WALKING_OFFSET
	$Camera3D.size = walking_size
	super._ready()

func _process(delta: float) -> void:
	if is_instance_valid(target):
		var at := target.get_global_transform_interpolated().origin
		if _stage_view:
			_stage_view = at.z < 0.4 and at.z > -6.4 and absf(at.x) < 4.4
		else:
			_stage_view = at.z < -1.1 and at.z > -5.8 and absf(at.x) < 3.8
		var offset := SCENIC_FOCUS - at if _stage_view else WALKING_OFFSET
		if at.z < -7.4:
			offset.z = 0.5
		var size := stage_size if _stage_view else walking_size
		var blend := 1.0 - exp(-3.3 * delta)
		framing_offset = framing_offset.lerp(offset, blend)
		$Camera3D.size = lerpf($Camera3D.size, size, blend)
	super._process(delta)
