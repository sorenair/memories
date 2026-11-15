extends "res://scripts/follow_camera.gd"
## Intimate trail, a little space at the frozen pond, then the fireside clearing.
@export var clearing: Node3D
@export var lookout: Node3D
@export var fire: Node3D
@export var trail_size := 3.5
@export var pond_size := 4.1
@export var clearing_size := 5.2

func _ready() -> void:
	framing_offset = Vector3(0,0.85,-0.65)
	$Camera3D.size = trail_size
	super._ready()

func _process(delta: float) -> void:
	if is_instance_valid(target) and is_instance_valid(clearing) and is_instance_valid(lookout):
		var at := target.get_global_transform_interpolated().origin
		var to_clearing := clearing.global_position-at
		var to_pond := lookout.global_position-at
		var arrival := 1.0-smoothstep(7.0,12.0,Vector2(to_clearing.x,to_clearing.z).length())
		var pond := 1.0-smoothstep(1.5,5.0,Vector2(to_pond.x,to_pond.z).length())
		var size := lerpf(lerpf(trail_size,pond_size,pond),clearing_size,arrival)
		var offset := Vector3(0,0.85,-0.65).lerp(Vector3(-0.4,1.0,-0.9),pond)
		offset = offset.lerp(Vector3(0,1.3,-1.8),arrival)
		if is_instance_valid(fire):
			var to_fire := fire.global_position-at
			var fireside := 1.0-smoothstep(2.0,4.0,Vector2(to_fire.x,to_fire.z).length())
			offset = offset.lerp(Vector3(0.7,0.95,-0.2),fireside*arrival)
		var blend := 1.0-exp(-3.0*delta)
		framing_offset = framing_offset.lerp(offset,blend)
		$Camera3D.size = lerpf($Camera3D.size,size,blend)
	super._process(delta)
