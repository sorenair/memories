extends "res://scripts/follow_camera.gd"
## Close woodland walking, a single lake reveal, then a quiet camp pocket.
@export var trailhead_zone: Node3D
@export var overlook_zone: Node3D
@export var camp_zone: Node3D
@export var arrival_size := 3.5
@export var walking_size := 4.6
@export var overlook_size := 20.0
@export var camp_size := 9.4
@export var overlook_focus := Vector3(-6.35,1.4,-6.95)

@onready var _camp_scenery := camp_zone.get_node_or_null("Scenery") as Node3D if camp_zone else null
@onready var _camp_fragment := camp_zone.get_node_or_null("Fragment") as MemoryFragment if camp_zone else null

func _ready() -> void:
	framing_offset = Vector3(0,0.8,-0.6)
	$Camera3D.size = arrival_size
	super._ready()
func _process(delta: float) -> void:
	if is_instance_valid(target):
		var at := target.get_global_transform_interpolated().origin
		var size := walking_size
		var offset := Vector3(0,0.8,-0.6)
		var looking_at_lake := false
		if is_instance_valid(trailhead_zone):
			var p := trailhead_zone.to_local(at)
			size = lerpf(arrival_size,walking_size,smoothstep(1.5,5.0,Vector2(p.x-0.4,p.z-10.5).length()))
		if is_instance_valid(overlook_zone):
			var p := overlook_zone.to_local(at)
			# Height and distance prevent a reveal while passing below the rock.
			var reveal := smoothstep(2.5,3.15,p.y)*(1.0-smoothstep(1.7,3.5,Vector2(p.x-1.4,p.z+1.0).length()))
			size = lerpf(size,overlook_size,reveal)
			offset = offset.lerp(overlook_focus-p,reveal)
			looking_at_lake = reveal > 0.12
		if is_instance_valid(camp_zone):
			# Keep the destination available to guidance while hiding its rendered props.
			if is_instance_valid(_camp_scenery): _camp_scenery.visible = not looking_at_lake
			if is_instance_valid(_camp_fragment): _camp_fragment.set_presentation_visible(not looking_at_lake)
			var p := camp_zone.to_local(at)
			var camp := (1.0-smoothstep(5.0,10.0,Vector2(p.x,p.z).length()))*(1.0-smoothstep(0.8,2.0,p.y))
			var shore := smoothstep(2.6, 3.35, p.z) * smoothstep(1.7, 2.6, -p.x)
			var camp_focus := Vector3(-0.6, 1.05, 0.45).lerp(Vector3(-2.3, 0.95, 1.65), shore)
			size = lerpf(size,camp_size,camp)
			offset = offset.lerp(camp_focus-p,camp)
		var blend := 1.0-exp(-3.0*delta)
		framing_offset = framing_offset.lerp(offset,blend)
		$Camera3D.size = lerpf($Camera3D.size,size,blend)
	super._process(delta)
