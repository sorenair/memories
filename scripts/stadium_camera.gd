extends "res://scripts/follow_camera.gd"
## The arrival stays intimate; crossing the connecting aisle reveals the bowl.
@export var transition_start: Node3D
@export var transition_end: Node3D
@export var view_focus: Node3D
@export var arrival_size := 3.5
@export var overlook_size := 64.0
@export var transition_speed := 2.5

func _ready() -> void:
	framing_offset = Vector3.ZERO
	$Camera3D.size = arrival_size
	super._ready()

func reveal_weight(at: Vector3) -> float:
	if not is_instance_valid(transition_start) or not is_instance_valid(transition_end):
		return 0.0
	var start := transition_start.global_position
	var direction := transition_end.global_position - start
	direction.y = 0.0
	if direction.length_squared() < 0.001:
		return 0.0
	return smoothstep(0.0, 1.0, (at - start).dot(direction) / direction.length_squared())

func _process(delta: float) -> void:
	if is_instance_valid(target) and is_instance_valid(view_focus):
		var at := target.get_global_transform_interpolated().origin
		var weight := reveal_weight(at)
		var blend := 1.0 - exp(-transition_speed * delta)
		# Wide framing is anchored on the stadium, so strolling across the viewing
		# bay doesn't push an end zone out of shot. Movement orientation stays fixed.
		var offset := (view_focus.global_position - at) * weight
		framing_offset = framing_offset.lerp(offset, blend)
		$Camera3D.size = lerpf($Camera3D.size, lerpf(arrival_size, overlook_size, weight), blend)
	super._process(delta)
