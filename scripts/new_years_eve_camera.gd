extends "res://scripts/follow_camera.gd"
## Walk into the crowd before the stage opens up. Fixed yaw, reversible framing.
@export var arrival_size := 3.5
@export var crowd_size := 5.5
@export var stage_size := 10.5
@export var deck_size := 5.0

func _ready() -> void:
	framing_offset = Vector3(0,0.75,-0.6)
	$Camera3D.size = arrival_size
	super._ready()

func _process(delta: float) -> void:
	if is_instance_valid(target):
		var at := target.get_global_transform_interpolated().origin
		var among_crowd := 1.0-smoothstep(4.0,13.0,at.z)
		var near_stage := 1.0-smoothstep(-5.0,2.0,at.z)
		var on_deck := 1.0-smoothstep(-11.0,-9.4,at.z)
		var desired_size := lerpf(lerpf(arrival_size,crowd_size,among_crowd),stage_size,near_stage)
		desired_size = lerpf(desired_size,deck_size,on_deck)
		var desired_offset := Vector3(0,0.75,-0.6).lerp(Vector3(-0.4,2.5,-4.2),near_stage)
		# Look a little back toward the controls after climbing onto the deck.
		var deck_offset := Vector3(clampf(-at.x*0.25,-0.8,0.8),1.0,0.6)
		desired_offset = desired_offset.lerp(deck_offset,on_deck)
		var blend := 1.0-exp(-2.5*delta)
		framing_offset = framing_offset.lerp(desired_offset,blend)
		$Camera3D.size = lerpf($Camera3D.size,desired_size,blend)
	super._process(delta)
