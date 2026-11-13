extends "res://scripts/follow_camera.gd"
## Close arrival among the huts; a little space opens around the tree and music.
@export var gathering_focus: Node3D
@export var arrival_size := 3.5
@export var lane_size := 4.5
@export var gathering_size := 7.5
func _ready() -> void:
	framing_offset = Vector3(0,0.75,-0.6)
	$Camera3D.size = arrival_size
	super._ready()
func _process(delta: float) -> void:
	if is_instance_valid(target) and is_instance_valid(gathering_focus):
		var at := target.get_global_transform_interpolated().origin
		var gathering := 1.0-smoothstep(2.5,7.5,gathering_focus.to_local(at).z)
		var browsing := 1.0-smoothstep(1.0,5.0,at.z)
		var desired_size := lerpf(lerpf(arrival_size,lane_size,browsing),gathering_size,gathering)
		var close_offset := Vector3(0,0.75,-0.6).lerp(Vector3(0,1.0,-0.8),browsing)
		# Keep following the explorer inside the plaza rather than locking the view
		# to a scenic camera when they go around the tree or browse the last huts.
		var wide_offset := Vector3(-0.7,1.4,-1.5)
		var blend := 1.0-exp(-2.5*delta)
		framing_offset = framing_offset.lerp(close_offset.lerp(wide_offset,gathering),blend)
		$Camera3D.size = lerpf($Camera3D.size,desired_size,blend)
	super._process(delta)
