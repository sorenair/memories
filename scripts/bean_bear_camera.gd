extends "res://scripts/follow_camera.gd"
## Close woodland walking, a two-lake reveal on the cliff, then a quiet camp pocket.
@export var trailhead_zone: Node3D
@export var overlook_zone: Node3D
@export var camp_zone: Node3D
@export var arrival_size := 3.5
@export var walking_size := 4.6
@export var overlook_size := 29.0
@export var camp_size := 8.0
@export var overlook_focus := Vector3(-10.0,1.0,-11.0)
func _ready() -> void:
	framing_offset = Vector3(0,0.8,-0.6)
	$Camera3D.size = arrival_size
	super._ready()
func _process(delta: float) -> void:
	if is_instance_valid(target):
		var at := target.get_global_transform_interpolated().origin
		var size := walking_size
		var offset := Vector3(0,0.8,-0.6)
		if is_instance_valid(trailhead_zone):
			var p := trailhead_zone.to_local(at)
			size = lerpf(arrival_size,walking_size,smoothstep(1.5,5.0,Vector2(p.x-0.4,p.z-10.5).length()))
		if is_instance_valid(overlook_zone):
			var p := overlook_zone.to_local(at)
			# Height and distance prevent a reveal while passing below the rock.
			var reveal := smoothstep(1.8,3.15,p.y)*(1.0-smoothstep(4.3,10.5,Vector2(p.x-1.4,p.z+1.0).length()))
			size = lerpf(size,overlook_size,reveal)
			offset = offset.lerp(overlook_focus-p,reveal)
		if is_instance_valid(camp_zone):
			var p := camp_zone.to_local(at)
			var camp := (1.0-smoothstep(5.0,10.0,Vector2(p.x,p.z).length()))*(1.0-smoothstep(0.8,2.0,p.y))
			size = lerpf(size,camp_size,camp)
			offset = offset.lerp(Vector3(0,0.9,-0.7)-p,camp)
		var blend := 1.0-exp(-3.0*delta)
		framing_offset = framing_offset.lerp(offset,blend)
		$Camera3D.size = lerpf($Camera3D.size,size,blend)
	super._process(delta)
