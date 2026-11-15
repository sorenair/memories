extends "res://scripts/follow_camera.gd"
## Intimate entry, then a modest street reveal. Keep the camera yaw stable.
@export var entry_size := 3.5
@export var street_size := 6.0
@export var party_size := 8.2
@export var porch_size := 4.8
@export var bar_size := 4.4

func _ready() -> void:
	framing_offset = Vector3(0,0.8,-0.7)
	$Camera3D.size = entry_size
	super._ready()

func _process(delta: float) -> void:
	if is_instance_valid(target):
		var at := target.get_global_transform_interpolated().origin
		var entered := 1.0-smoothstep(10.0,17.0,at.z)
		var heart := 1.0-smoothstep(3.0,9.5,absf(at.z+2.0))
		var porch := smoothstep(3.2,6.2,absf(at.x))
		var size := lerpf(lerpf(entry_size,street_size,entered),party_size,heart)
		size = lerpf(size,porch_size,porch)
		var offset := Vector3(0,0.8,-0.7).lerp(Vector3(0,1.7,-1.4),heart)
		offset = offset.lerp(Vector3(signf(at.x)*0.6,1.2,-0.35),porch)
		var inside := 1.0-smoothstep(-28.5,-22.5,at.z)
		size = lerpf(size,bar_size,inside)
		offset = offset.lerp(Vector3(0,1.0,-0.45),inside)
		var blend := 1.0-exp(-3.0*delta)
		framing_offset = framing_offset.lerp(offset,blend)
		$Camera3D.size = lerpf($Camera3D.size,size,blend)
	super._process(delta)
