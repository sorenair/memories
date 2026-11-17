extends "res://scripts/follow_camera.gd"
## Intimate sand walks; reveal the cape lighthouse, dune relief and city canyon.
@export var beach_zone: Node3D
@export var dunes_zone: Node3D
@export var city_zone: Node3D
@export var walking_size := 3.5
@export var beach_size := 9.0
@export var lighthouse_size := 15.0
@export var dunes_size := 8.5
@export var city_size := 10.5
func _ready() -> void:
	framing_offset = Vector3(0,0.8,-0.6)
	$Camera3D.size = walking_size
	super._ready()
func _process(delta: float) -> void:
	if is_instance_valid(target):
		var at := target.get_global_transform_interpolated().origin
		var size := walking_size
		var offset := Vector3(0,0.8,-0.6)
		if is_instance_valid(beach_zone):
			var p := beach_zone.to_local(at)
			var cove := (1.0-smoothstep(6.0,11.0,absf(p.x)))*smoothstep(3.0,7.0,p.z)
			size = lerpf(size,beach_size,cove)
			offset = offset.lerp(Vector3(0,0.8,-2.0),cove)
			var cape := smoothstep(9.0,12.5,p.x)*(1.0-smoothstep(1.0,5.0,p.z))*(1.0-smoothstep(20.0,24.0,p.x))
			size = lerpf(size,lighthouse_size,cape)
			offset = offset.lerp(Vector3(13,7.2,-6.8)-p,cape)
		if is_instance_valid(dunes_zone):
			var p := dunes_zone.to_local(at)
			var dunes := 1.0-smoothstep(4.0,10.0,Vector2(p.x,p.z).length())
			size = lerpf(size,dunes_size,dunes)
			offset = offset.lerp(Vector3(0,0.9,-0.8),dunes)
		if is_instance_valid(city_zone):
			var p := city_zone.to_local(at)
			var city := (1.0-smoothstep(11.0,17.0,Vector2(p.x,p.z).length()))
			size = lerpf(size,city_size,city)
			offset = offset.lerp(Vector3(0,1.6,-1.8),city)
		var blend := 1.0-exp(-3.0*delta)
		framing_offset = framing_offset.lerp(offset,blend)
		$Camera3D.size = lerpf($Camera3D.size,size,blend)
	super._process(delta)
