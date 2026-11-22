extends "res://scripts/follow_camera.gd"
@export var trail_zone: Node3D
@export var lighthouse_zone: Node3D
@export var garden_zone: Node3D
@export var walking_size := 4.35
@export var lookout_size := 14.0
@export var lighthouse_size := 18.0
@export var garden_size := 12.0
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
			var reveal := smoothstep(1.85,2.36,p.y)*(1.0-smoothstep(1.35,3.65,Vector2(p.x-.8,p.z+7).length()))
			size = lerpf(size,lookout_size,reveal)
			offset = offset.lerp(Vector3(-1.3,3,-8.0)-p,reveal)
		if is_instance_valid(lighthouse_zone):
			var p := lighthouse_zone.to_local(at)
			var shore := (1.0-smoothstep(-10.65,0.55,p.z)) * (1.0-smoothstep(2.5,4.5,absf(p.x)))
			size = lerpf(size,lighthouse_size,shore)
			offset = offset.lerp(Vector3(-1.4,2.45,-8.7)-p,shore)
		if is_instance_valid(garden_zone):
			var p := garden_zone.to_local(at)
			var garden := 1.0-smoothstep(1.25,4.65,Vector2(p.x+.5,p.z-2.94).length())
			size = lerpf(size,garden_size,garden)
			offset = offset.lerp(Vector3(.1,1.35,-1.05)-p,garden)
			var pavilion := 1.0 - smoothstep(1.0, 2.7, Vector2(p.x - 2.82, p.z + 3.0).length())
			size = lerpf(size, 6.8, pavilion)
			offset = offset.lerp(Vector3(1.27, 1.48, -4.17) - p, pavilion)
			var hill := 1.0 - smoothstep(0.95, 2.55, Vector2(p.x + 5.68, p.z + 5.11).length())
			size = lerpf(size, 12.4, hill)
			offset = offset.lerp(Vector3(-6.55, 3.87, -6.42) - p, hill)
		var blend := 1.0-exp(-2.8*delta)
		framing_offset = framing_offset.lerp(offset,blend)
		$Camera3D.size = lerpf($Camera3D.size,size,blend)
	super._process(delta)
