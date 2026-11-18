extends "res://scripts/follow_camera.gd"
## Close spring paths, with brief, reversible views of the campus landmarks.
@export var arches_focus: Node3D
@export var portico_focus: Node3D
@export var ceremony_focus: Node3D
@export var walking_size := 3.5
@export var arches_size := 7.0
@export var portico_size := 13.5
@export var landing_size := 5.5
@export var ceremony_size := 6.5

func _ready() -> void:
	framing_offset = Vector3(0,0.8,-0.6)
	$Camera3D.size = walking_size
	super._ready()

func _process(delta: float) -> void:
	if is_instance_valid(target):
		var at := target.get_global_transform_interpolated().origin
		var desired_size := walking_size
		var desired_offset := Vector3(0,0.8,-0.6)
		if is_instance_valid(arches_focus):
			var p := arches_focus.to_local(at)
			var weight := (1.0-smoothstep(3.5,6.0,p.z)) * smoothstep(-4.0,-1.0,p.z)
			weight *= 1.0-smoothstep(4.0,6.0,absf(p.x))
			desired_size = lerpf(desired_size,arches_size,weight)
			desired_offset = desired_offset.lerp(arches_focus.global_position-at+Vector3(0,1.9,0.3),weight)
		if is_instance_valid(portico_focus):
			var p := portico_focus.to_local(at)
			var weight := (1.0-smoothstep(5.2,8.0,p.z)) * smoothstep(-4.0,-1.8,p.z)
			weight *= 1.0-smoothstep(3.5,7.0,absf(p.x))
			var overview := smoothstep(0.5,4.5,p.z)
			desired_size = lerpf(desired_size,lerpf(landing_size,portico_size,overview),weight)
			var focus := Vector3(0,0.9,-0.7).lerp(portico_focus.global_position-at+Vector3(-0.05,2.8,0.6),overview)
			desired_offset = desired_offset.lerp(focus,weight)
		if is_instance_valid(ceremony_focus):
			var p := ceremony_focus.to_local(at)
			var weight := (1.0-smoothstep(5.5,9.0,p.z)) * (1.0-smoothstep(4.0,8.0,absf(p.x)))
			desired_size = lerpf(desired_size,ceremony_size,weight)
			var stage := 1.0-smoothstep(1.0,4.2,p.z)
			var focus := Vector3(0,1.1,-1.2).lerp(Vector3(0,1.85,-1.45),stage)
			desired_offset = desired_offset.lerp(focus,weight)
		var blend := 1.0-exp(-3.0*delta)
		framing_offset = framing_offset.lerp(desired_offset,blend)
		$Camera3D.size = lerpf($Camera3D.size,desired_size,blend)
	super._process(delta)
