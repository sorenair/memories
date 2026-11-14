extends "res://scripts/follow_camera.gd"
## Close arrival, a garden reveal, then intimate walking between plants/displays.
@export var arrival_size := 3.5
@export var garden_size := 4.8
@export var jungle_size := 3.5
@export var bonsai_size := 4.2

func _ready() -> void:
	framing_offset = Vector3(0,0.75,-0.6)
	$Camera3D.size = arrival_size
	super._ready()

func _process(delta: float) -> void:
	if is_instance_valid(target):
		var at := target.get_global_transform_interpolated().origin
		var garden := 1.0-smoothstep(0.0,7.0,at.z)
		var jungle := 1.0-smoothstep(-14.0,-9.0,at.z)
		var bonsai := smoothstep(5.5,10.5,at.x)*(1.0-smoothstep(5.5,8.0,absf(at.z+24.5)))
		var desired_size := lerpf(lerpf(arrival_size,garden_size,garden),jungle_size,jungle)
		desired_size = lerpf(desired_size,bonsai_size,bonsai)
		var desired_offset := Vector3(0,0.75,-0.6).lerp(Vector3(0,1.0,-0.85),garden)
		desired_offset = desired_offset.lerp(Vector3(0,0.85,-0.65),jungle)
		desired_offset = desired_offset.lerp(Vector3(0,1.0,-0.9),bonsai)
		var blend := 1.0-exp(-3.0*delta)
		framing_offset = framing_offset.lerp(desired_offset,blend)
		$Camera3D.size = lerpf($Camera3D.size,desired_size,blend)
	super._process(delta)
