extends "res://scripts/follow_camera.gd"
@export var rows_size := 3.5
@export var deck_size := 5.2
@export var overlook_size := 13.0
func _ready() -> void:
	framing_offset = Vector3(0,0.8,-0.65)
	$Camera3D.size = rows_size
	super._ready()
func _process(delta: float) -> void:
	if is_instance_valid(target):
		var at := target.get_global_transform_interpolated().origin
		var deck := 1.0-smoothstep(-14.1,-10.1,at.z)
		var reveal := 1.0-smoothstep(-17.8,-16.0,at.z)
		var size := lerpf(lerpf(rows_size,deck_size,deck),overlook_size,reveal)
		var offset := Vector3(0,0.8,-0.65).lerp(Vector3(0,1.0,-1.1),deck)
		offset = offset.lerp(Vector3(-0.85,2.35,-5.35),reveal)
		var blend := 1.0-exp(-2.8*delta)
		framing_offset = framing_offset.lerp(offset,blend)
		$Camera3D.size = lerpf($Camera3D.size,size,blend)
	super._process(delta)
