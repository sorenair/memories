extends Node3D
## Fixed elevated composition with frame-rate independent follow smoothing.
@export var target: Node3D
@export var follow_speed: float = 5.0

func _ready() -> void:
	# This rig moves every rendered frame; do not interpolate it a second time.
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	if target:
		# Prime Godot's transform interpolator before the first follow update.
		target.get_global_transform_interpolated()
		global_position = target.global_position

func _process(delta: float) -> void:
	if target:
		var rendered_position := target.get_global_transform_interpolated().origin
		global_position = global_position.lerp(rendered_position, 1.0 - exp(-follow_speed * delta))
