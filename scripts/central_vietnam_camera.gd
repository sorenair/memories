extends "res://scripts/follow_camera.gd"
## A steady walking view with held reveals at four authored viewpoints.
@export var mountain_zone: Node3D
@export var rice_zone: Node3D
@export var hue_zone: Node3D
@export var walking_size := 4.7
@export var mountain_size := 17.6
@export var fields_size := 14.0
@export var gate_size := 11.6
@export var palace_size := 8.8

const WALKING_OFFSET := Vector3(0, 0.80, -0.73)
const EXIT_MARGIN := 0.62

class View:
	var zone: Node3D
	var area: Rect2
	var focus: Vector3
	var size: float

	func _init(anchor: Node3D, bounds: Rect2, center: Vector3, zoom: float) -> void:
		zone = anchor
		area = bounds
		focus = center
		size = zoom

	func contains(position: Vector3, margin: float) -> bool:
		if not is_instance_valid(zone):
			return false
		var local := zone.to_local(position)
		return area.grow(margin).has_point(Vector2(local.x, local.z))

var _views: Array[View] = []
var _held: View

@onready var _camera: Camera3D = $Camera3D

func _ready() -> void:
	_views = [
		View.new(mountain_zone, Rect2(-3.5, 1.7, 7.4, 4.3), Vector3(-1.45, 5.2, -2.7), mountain_size),
		View.new(rice_zone, Rect2(10.75, -3.15, 3.05, 2.95), Vector3(7.0, 1.8, 0.32), fields_size),
		View.new(hue_zone, Rect2(-3.1, 3.0, 6.2, 8.2), Vector3(0, 2.3, 5.25), gate_size),
		View.new(hue_zone, Rect2(-3.5, -9.0, 7.0, 3.9), Vector3(0.0, 1.7, -8.7), palace_size),
	]
	framing_offset = WALKING_OFFSET
	_camera.size = walking_size
	super._ready()

func _process(delta: float) -> void:
	if is_instance_valid(target):
		var position := target.get_global_transform_interpolated().origin
		if _held and not _held.contains(position, EXIT_MARGIN):
			_held = null
		if not _held:
			for view in _views:
				if view.contains(position, 0.0):
					_held = view
					break
		var size := _held.size if _held else walking_size
		var offset := _held.zone.to_global(_held.focus) - position if _held else WALKING_OFFSET
		var blend := 1.0 - exp(-3.0 * delta)
		framing_offset = framing_offset.lerp(offset, blend)
		_camera.size = lerpf(_camera.size, size, blend)
	super._process(delta)
