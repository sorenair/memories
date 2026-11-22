extends "res://scripts/follow_camera.gd"
## An intimate planted shore opens along the pier to both boats and the lake.
@export var lake_zone: Node3D
@export var shore_size := 3.5
@export var pier_size := 6.0
@export var sailing_size := 17.0
@export var sailing_focus := Vector3(0.2,2.45,-3.7)
func _ready() -> void:
	framing_offset = Vector3(0,0.8,-0.65)
	$Camera3D.size = shore_size
	super._ready()
func _process(delta: float) -> void:
	if is_instance_valid(target) and is_instance_valid(lake_zone):
		var at := target.get_global_transform_interpolated().origin
		var p := lake_zone.to_local(at)
		var pier := 1.0-smoothstep(4.5,9.3,p.z)
		var reveal := 1.0-smoothstep(-2.4,3.5,p.z)
		var size := lerpf(lerpf(shore_size,pier_size,pier),sailing_size,reveal)
		var offset := Vector3(0,0.8,-0.65).lerp(Vector3(0,1.1,-0.9),pier)
		offset = offset.lerp(lake_zone.to_global(sailing_focus)-at,reveal)
		var blend := 1.0-exp(-2.8*delta)
		framing_offset = framing_offset.lerp(offset,blend)
		$Camera3D.size = lerpf($Camera3D.size,size,blend)
	super._process(delta)
