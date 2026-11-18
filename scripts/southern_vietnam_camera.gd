extends "res://scripts/follow_camera.gd"
## Stay close on foot and hold the wider compositions at four reachable views.
@export var beach_zone: Node3D
@export var dunes_zone: Node3D
@export var city_zone: Node3D
@export var walking_size := 4.7
@export var beach_size := 10.0
@export var lighthouse_size := 17.2
@export var dunes_size := 9.7
@export var city_size := 11.4

const WALKING_OFFSET := Vector3(0, 0.86, -0.79)
const EXIT_MARGIN := 0.68

class View:
	var zone: Node3D
	var bounds: Rect2
	var focus: Vector3
	var size: float

	func _init(anchor: Node3D, area: Rect2, center: Vector3, zoom: float) -> void:
		zone = anchor
		bounds = area
		focus = center
		size = zoom

	func contains(at: Vector3, margin: float) -> bool:
		if not is_instance_valid(zone):
			return false
		var local := zone.to_local(at)
		return bounds.grow(margin).has_point(Vector2(local.x, local.z))

var _views: Array[View] = []
var _held_view: View

@onready var _camera: Camera3D = $Camera3D

func _ready() -> void:
	_views = [
		View.new(beach_zone, Rect2(-3.2, 6.75, 6.4, 3.65), Vector3(-0.6, 1.35, 5.75), beach_size),
		View.new(beach_zone, Rect2(10.9, -7.8, 6.9, 4.7), Vector3(11.35, 5.65, -5.8), lighthouse_size),
		View.new(dunes_zone, Rect2(-1.1, -0.7, 4.5, 4.45), Vector3(0.4, 1.1, 0.15), dunes_size),
		View.new(city_zone, Rect2(-4.8, -3.3, 9.6, 8.0), Vector3(-0.15, 2.5, -0.9), city_size),
	]
	framing_offset = WALKING_OFFSET
	_camera.size = walking_size
	super._ready()

func _process(delta: float) -> void:
	if is_instance_valid(target):
		var at := target.get_global_transform_interpolated().origin
		if _held_view and not _held_view.contains(at, EXIT_MARGIN):
			_held_view = null
		if not _held_view:
			for view in _views:
				if view.contains(at, 0.0):
					_held_view = view
					break
		var size := _held_view.size if _held_view else walking_size
		var offset := _held_view.zone.to_global(_held_view.focus) - at if _held_view else WALKING_OFFSET
		var blend := 1.0 - exp(-3.0 * delta)
		framing_offset = framing_offset.lerp(offset, blend)
		_camera.size = lerpf(_camera.size, size, blend)
	super._process(delta)
