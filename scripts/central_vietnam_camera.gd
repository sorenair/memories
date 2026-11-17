extends "res://scripts/follow_camera.gd"
## Close jungle arrival, a temple/limestone reveal, terraces and imperial court.
@export var mountain_zone: Node3D
@export var rice_zone: Node3D
@export var hue_zone: Node3D
@export var walking_size := 3.5
@export var mountain_size := 15.0
@export var fields_size := 15.0
@export var gate_size := 12.0
@export var palace_size := 9.0
func _ready() -> void:
	framing_offset = Vector3(0,0.8,-0.6)
	$Camera3D.size = walking_size
	super._ready()
func _process(delta: float) -> void:
	if is_instance_valid(target):
		var at := target.get_global_transform_interpolated().origin
		var size := walking_size
		var offset := Vector3(0,0.8,-0.6)
		if is_instance_valid(mountain_zone):
			var p := mountain_zone.to_local(at)
			var reveal := (1.0-smoothstep(5.0,9.5,absf(p.x)))*(1.0-smoothstep(6.0,9.0,p.z))
			size = lerpf(size,mountain_size,reveal)
			offset = offset.lerp(Vector3(0,3.2,-3.6),reveal)
		if is_instance_valid(rice_zone):
			var p := rice_zone.to_local(at)
			var fields := smoothstep(0.35,1.2,p.y)*(1.0-smoothstep(13.3,17.5,p.x))*(1.0-smoothstep(-1.5,2.0,p.z))
			size = lerpf(size,fields_size,fields)
			offset = offset.lerp(Vector3(-5.0,0.9,-0.5),fields)
		if is_instance_valid(hue_zone):
			var p := hue_zone.to_local(at)
			var gate := (1.0-smoothstep(10.0,14.0,p.z))*smoothstep(0.0,3.0,p.z)*(1.0-smoothstep(3.0,7.0,absf(p.x)))
			size = lerpf(size,gate_size,gate)
			offset = offset.lerp(Vector3(0,2.2,5)-p,gate)
			var palace := (1.0-smoothstep(-5.0,0.0,p.z))*(1.0-smoothstep(4.0,8.0,absf(p.x)))
			size = lerpf(size,palace_size,palace)
			offset = offset.lerp(Vector3(0,1.1,-1.7),palace)
		var blend := 1.0-exp(-3.0*delta)
		framing_offset = framing_offset.lerp(offset,blend)
		$Camera3D.size = lerpf($Camera3D.size,size,blend)
	super._process(delta)
