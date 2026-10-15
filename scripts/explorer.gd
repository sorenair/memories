class_name MemoryExplorer
extends CharacterBody3D
## Reusable local explorer. Input is separate so networking can supply it later.

@export var walk_speed: float = 3.2
@export var acceleration: float = 12.0
@export var turn_speed: float = 10.0
@export var movement_camera: Camera3D
@export var movement_input: Node

@onready var visual: Node3D = $Visual
@onready var left_foot: MeshInstance3D = $Visual/LeftFoot
@onready var right_foot: MeshInstance3D = $Visual/RightFoot
var _stride: float = 0.0

func _physics_process(delta: float) -> void:
	var axis: Vector2 = movement_input.get_movement() if movement_input else Vector2.ZERO
	var direction := Vector3(axis.x, 0.0, axis.y)
	if movement_camera:
		var right := movement_camera.global_basis.x
		var forward := movement_camera.global_basis.z
		right.y = 0.0
		forward.y = 0.0
		direction = right.normalized() * axis.x + forward.normalized() * axis.y
	velocity.x = move_toward(velocity.x, direction.x * walk_speed, acceleration * delta)
	velocity.z = move_toward(velocity.z, direction.z * walk_speed, acceleration * delta)
	if not is_on_floor():
		velocity.y -= 18.0 * delta
	else:
		velocity.y = 0.0
	move_and_slide()
	var speed := Vector2(velocity.x, velocity.z).length()
	if speed > 0.05:
		visual.rotation.y = lerp_angle(visual.rotation.y, atan2(-velocity.x, -velocity.z), 1.0 - exp(-turn_speed * delta))
	_stride += speed * delta * 3.8
	var amount := clampf(speed / walk_speed, 0.0, 1.0)
	visual.position.y = abs(sin(_stride)) * 0.035 * amount
	left_foot.position.z = sin(_stride) * 0.10 * amount
	right_foot.position.z = -sin(_stride) * 0.10 * amount
