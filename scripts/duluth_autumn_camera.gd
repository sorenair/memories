extends "res://scripts/follow_camera.gd"
@export var trail_zone: Node3D
@export var lighthouse_zone: Node3D
@export var garden_zone: Node3D
@export var walking_size := 3.5
@export var lookout_size := 14.0
@export var lighthouse_size := 18.0
@export var garden_size := 10.0
func _ready() -> void:
	framing_offset = Vector3(0,.8,-.65)
	$Camera3D.size = walking_size
	super._ready()
func _process(delta: float) -> void:
	if is_instance_valid(target):
		var at := target.get_global_transform_interpolated().origin
		var size := walking_size
		var offset := Vector3(0,.8,-.65)
		if is_instance_valid(trail_zone):
			var p := trail_zone.to_local(at)
			var reveal := smoothstep(1.5,2.35,p.y)*(1.0-smoothstep(4.0,8.5,Vector2(p.x-.8,p.z+7).length()))
			size = lerpf(size,lookout_size,reveal)
			offset = offset.lerp(Vector3(-1.3,3,-8.0)-p,reveal)
		if is_instance_valid(lighthouse_zone):
			var p := lighthouse_zone.to_local(at)
			var shore := 1.0-smoothstep(7.0,13.0,Vector2(p.x,p.z+1.8).length())
			size = lerpf(size,lighthouse_size,shore)
			offset = offset.lerp(Vector3(.3,3.3,-3.5)-p,shore)
		if is_instance_valid(garden_zone):
			var p := garden_zone.to_local(at)
			var garden := 1.0-smoothstep(6.0,11.0,Vector2(p.x,p.z).length())
			size = lerpf(size,garden_size,garden)
			offset = offset.lerp(Vector3(0,1.3,-.5)-p,garden)
		var blend := 1.0-exp(-2.8*delta)
		framing_offset = framing_offset.lerp(offset,blend)
		$Camera3D.size = lerpf($Camera3D.size,size,blend)
	super._process(delta)
