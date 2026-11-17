extends "res://scripts/follow_camera.gd"

const WALKING_OFFSET := Vector3(0, 0.77, -0.25)

@export var field_zone: Node3D
@export var summit_zone: Node3D
@export var lake_zone: Node3D
@export var walking_size := 3.25
@export var flatirons_size := 29.0
@export var summit_size := 8.8
@export var lake_size := 16.5
@export var flatirons_focus := Vector3(1.35, 8.55, -9.8)
@export var summit_focus := Vector3(-1.0, 3.87, -1.42)
@export var lake_focus := Vector3(3.8, 1.1, -0.5)

@onready var _camera: Camera3D = $Camera3D

func _ready() -> void:
	framing_offset = WALKING_OFFSET
	_camera.size = walking_size
	super._ready()

func _process(delta: float) -> void:
	if is_instance_valid(target):
		var at := target.get_global_transform_interpolated().origin
		var size := walking_size
		var offset := WALKING_OFFSET
		# Each reveal belongs to a small viewpoint. The approach, ridge and
		# valley floor keep the explorer at the same close walking scale.
		if is_instance_valid(field_zone):
			var point := field_zone.to_local(at)
			var reveal := _view_weight(point, Vector2(0.3, -1.3), 0.7, 3.0)
			size = lerpf(size, flatirons_size, reveal)
			offset = offset.lerp(flatirons_focus - point, reveal)
		if is_instance_valid(summit_zone):
			var point := summit_zone.to_local(at)
			var reveal := _view_weight(point, Vector2(0, -1), 0.6, 2.7)
			reveal *= smoothstep(3.15, 3.5, point.y)
			size = lerpf(size, summit_size, reveal)
			offset = offset.lerp(summit_focus - point, reveal)
		if is_instance_valid(lake_zone):
			var point := lake_zone.to_local(at)
			var reveal := _view_weight(point, Vector2(5.5, 4), 0.75, 2.75)
			size = lerpf(size, lake_size, reveal)
			offset = offset.lerp(lake_focus - point, reveal)
		var blend := 1.0 - exp(-3.5 * delta)
		framing_offset = framing_offset.lerp(offset, blend)
		_camera.size = lerpf(_camera.size, size, blend)
	super._process(delta)

func _view_weight(point: Vector3, center: Vector2, inner: float, outer: float) -> float:
	return 1.0 - smoothstep(inner, outer, Vector2(point.x, point.z).distance_to(center))
