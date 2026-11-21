extends "res://scripts/follow_camera.gd"
## Keep walking scale steady between the fountain and bonsai viewpoints.
@export var fountain_viewpoint: Node3D
@export var bonsai_viewpoint: Node3D
@export var walking_size := 4.4
@export var fountain_size := 6.4
@export var bonsai_size := 6.6

const WALKING_OFFSET := Vector3(0, 0.87, -0.55)
var _viewpoint: Node3D

func _ready() -> void:
	framing_offset = WALKING_OFFSET
	$Camera3D.size = walking_size
	super._ready()

func _process(delta: float) -> void:
	if is_instance_valid(target):
		var at := target.get_global_transform_interpolated().origin
		var size := walking_size
		var offset := WALKING_OFFSET
		if _holds_view(fountain_viewpoint, at):
			_viewpoint = fountain_viewpoint
			size = fountain_size
			offset = fountain_viewpoint.global_position + Vector3(-1.55, 1.0, -0.25) - at
		elif _holds_view(bonsai_viewpoint, at):
			_viewpoint = bonsai_viewpoint
			size = bonsai_size
			offset = bonsai_viewpoint.global_position + Vector3(0, 1.12, -0.85) - at
		else:
			_viewpoint = null
		var blend := 1.0 - exp(-3.3 * delta)
		framing_offset = framing_offset.lerp(offset, blend)
		$Camera3D.size = lerpf($Camera3D.size, size, blend)
	super._process(delta)

func _holds_view(anchor: Node3D, at: Vector3) -> bool:
	if not is_instance_valid(anchor):
		return false
	var delta := anchor.global_position - at
	var radius := 3.1 if anchor == _viewpoint else 1.55
	return Vector2(delta.x, delta.z).length_squared() < radius * radius
