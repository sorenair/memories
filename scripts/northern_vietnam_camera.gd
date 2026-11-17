extends "res://scripts/follow_camera.gd"
## Intimate lanes and island notes; movement opens the lake and karst overlook.
@export var lake_zone: Node3D
@export var bay_zone: Node3D
@export var walking_size := 3.5
@export var street_size := 5.2
@export var lake_size := 12.5
@export var temple_size := 6.5
@export var bay_size := 22.0
func _ready() -> void:
	framing_offset = Vector3(0,0.8,-0.6)
	$Camera3D.size = walking_size
	super._ready()
func _process(delta: float) -> void:
	if is_instance_valid(target):
		var at := target.get_global_transform_interpolated().origin
		var size := walking_size
		var offset := Vector3(0,0.8,-0.6)
		var street := smoothstep(25.0,20.0,at.z)*(1.0-smoothstep(6.0,12.0,absf(at.x)))
		size = lerpf(size,street_size,street)
		if is_instance_valid(lake_zone):
			var p := lake_zone.to_local(at)
			var in_lake := 1.0-smoothstep(11.0,17.0,Vector2(p.x,p.z).length())
			var island := 1.0-smoothstep(-2.0,0.5,p.z)
			size = lerpf(size,lerpf(lake_size,temple_size,island),in_lake)
			offset = offset.lerp(Vector3(0,1.0,-2.0).lerp(Vector3(0,0.7,-0.5),island),in_lake)
		if is_instance_valid(bay_zone):
			var p := bay_zone.to_local(at)
			var bay := (1.0-smoothstep(3.5,7.0,absf(p.x)))*(1.0-smoothstep(5.5,12.0,p.z))
			size = lerpf(size,bay_size,bay)
			offset = offset.lerp(Vector3(0,3.2,-6.5),bay)
		var blend := 1.0-exp(-3.0*delta)
		framing_offset = framing_offset.lerp(offset,blend)
		$Camera3D.size = lerpf($Camera3D.size,size,blend)
	super._process(delta)
