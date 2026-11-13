extends "res://scripts/follow_camera.gd"
## First Meeting's intimate scale, opening up briefly around the portico.
@export var entrance_focus: Node3D
@export var entrance_size := 9.5
@export var gallery_size := 3.5
@export var exhibit_size := 4.8
@export var gallery_offset := Vector3(0,1.65,-1.25)
## Local Z in front of EntranceFocus: keep arrival close until the explorer
## has walked 1.5 m, then open the view over the approach to the columns.
@export var portico_reveal_start := 4.5
@export var portico_reveal_end := 1.5
var _exhibit_focuses: Array[Node] = []
func _ready() -> void:
	_exhibit_focuses = get_tree().get_nodes_in_group(&"museum_camera_focus")
	framing_offset = gallery_offset*0.48
	$Camera3D.size = gallery_size
	super._ready()
func _process(delta: float) -> void:
	if is_instance_valid(target) and is_instance_valid(entrance_focus):
		var at := target.get_global_transform_interpolated().origin
		var local := entrance_focus.to_local(at)
		var approach := 1.0-smoothstep(portico_reveal_end,portico_reveal_start,local.z)
		var weight := approach * (1.0-smoothstep(2.0,7.0,-local.z)) * (1.0-smoothstep(5.0,9.0,absf(local.x)))
		var exhibit_weight := 0.0
		for focus: Node3D in _exhibit_focuses:
			var offset := focus.global_position-at
			var distance := Vector2(offset.x,offset.z).length()
			exhibit_weight = maxf(exhibit_weight,1.0-smoothstep(3.7,6.0,distance))
		# Travel keeps the original intimate view; looking at a full sculpture
		# or canvas gives it a little breathing room, without framing a whole room.
		var near_size := lerpf(gallery_size,exhibit_size,exhibit_weight)
		var near_offset := gallery_offset*lerpf(0.48,1.0,exhibit_weight)
		var desired := near_offset.lerp(entrance_focus.global_position-at,weight)
		var blend := 1.0-exp(-3.0*delta)
		framing_offset = framing_offset.lerp(desired,blend)
		$Camera3D.size = lerpf($Camera3D.size,lerpf(near_size,entrance_size,weight),blend)
	super._process(delta)
