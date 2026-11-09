class_name MemoryExplorer
extends CharacterBody3D
## Simulates the local explorer and presents either local or replicated poses.

enum Avatar { SOREN, VIVIAN }

const IDLE_ANIMATION: StringName = &"IDLE"
const WALK_ANIMATION: StringName = &"WALK"
const MOVEMENT_THRESHOLD := 0.05

static var preferred_avatar: Avatar = Avatar.SOREN

@export var walk_speed: float = 3.2
@export var acceleration: float = 12.0
@export var turn_speed: float = 10.0
@export var movement_camera: Camera3D
@export var movement_input: Node

@onready var visual: Node3D = $Visual
@onready var _soren: Node3D = $Visual/Soren
@onready var _vivian: Node3D = $Visual/Vivian
@onready var _soren_animation: AnimationPlayer = $Visual/Soren/AnimationPlayer
@onready var _vivian_animation: AnimationPlayer = $Visual/Vivian/AnimationPlayer
var animation_player: AnimationPlayer
var avatar: Avatar
var walking := false

func _ready() -> void:
	set_avatar(preferred_avatar)

func set_avatar(value: Avatar) -> void:
	avatar = value
	var is_vivian := avatar == Avatar.VIVIAN
	_soren.visible = not is_vivian
	_vivian.visible = is_vivian
	var next_player := _vivian_animation if is_vivian else _soren_animation
	if animation_player == next_player:
		return
	if animation_player:
		animation_player.stop()
	animation_player = next_player
	animation_player.play(WALK_ANIMATION if walking else IDLE_ANIMATION)
	animation_player.advance(0.0)

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
	var motion := get_real_velocity()
	var moving := Vector2(motion.x, motion.z).length_squared() > MOVEMENT_THRESHOLD * MOVEMENT_THRESHOLD
	if moving:
		# The imported model faces local +Z.
		visual.rotation.y = lerp_angle(visual.rotation.y, atan2(motion.x, motion.z), 1.0 - exp(-turn_speed * delta))
	set_walking(moving)

func set_walking(value: bool) -> void:
	walking = value
	var next_animation := WALK_ANIMATION if walking else IDLE_ANIMATION
	if animation_player.assigned_animation != next_animation:
		animation_player.play(next_animation)
