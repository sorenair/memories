extends "res://scripts/follow_camera.gd"
## Walk close through the three zones, with held views at the street, lake and dock.
@export var street_zone: Node3D
@export var lake_zone: Node3D
@export var bay_zone: Node3D
@export var walking_size := 4.7
@export var street_size := 6.1
@export var lake_size := 13.4
@export var bay_size := 22.8

const WALKING_OFFSET := Vector3(0, 0.85, -0.8)
const STREET_VIEW := Rect2(-2.2, -0.35, 4.4, 4.6)
const LAKE_VIEW := Rect2(-2.45, 5.1, 5.35, 7.5)
const ISLAND_COURTYARD := Rect2(-1.55, -5.9, 3.1, 2.55)
const BAY_VIEW := Rect2(-2.8, 1.35, 5.6, 5.55)
const EXIT_MARGIN := 0.65

var _held_view: Node3D
var _walking_camera_pose: Transform3D
var _tilt := 0.0

@onready var _camera: Camera3D = $Camera3D

func _ready() -> void:
	framing_offset = WALKING_OFFSET
	_camera.size = walking_size
	_walking_camera_pose = _camera.transform
	super._ready()

func _in_view(zone: Node3D, bounds: Rect2, at: Vector3) -> bool:
	if not is_instance_valid(zone):
		return false
	var point := zone.to_local(at)
	var margin := EXIT_MARGIN if zone == _held_view else 0.0
	return bounds.grow(margin).has_point(Vector2(point.x, point.z))

func _process(delta: float) -> void:
	if is_instance_valid(target):
		var at := target.get_global_transform_interpolated().origin
		var size := walking_size
		var offset := WALKING_OFFSET
		var tilt := 0.0
		if _in_view(street_zone, STREET_VIEW, at):
			_held_view = street_zone
			size = street_size
			offset = street_zone.to_global(Vector3(-0.8, 1.32, 1.1)) - at
		elif _in_view(lake_zone, LAKE_VIEW, at):
			_held_view = lake_zone
			size = lake_size
			offset = lake_zone.to_global(Vector3(1.7, 2.05, 3.85)) - at
		elif _in_view(bay_zone, BAY_VIEW, at):
			_held_view = bay_zone
			size = bay_size
			offset = bay_zone.to_global(Vector3(-1.6, 6.85, -6.8)) - at
		else:
			_held_view = null
			if is_instance_valid(lake_zone):
				var at_island := lake_zone.to_local(at)
				if ISLAND_COURTYARD.has_point(Vector2(at_island.x, at_island.z)):
					tilt = deg_to_rad(-27.0)
		var blend := 1.0 - exp(-3.0 * delta)
		framing_offset = framing_offset.lerp(offset, blend)
		_camera.size = lerpf(_camera.size, size, blend)
		if absf(tilt - _tilt) > 0.0001:
			_tilt = lerpf(_tilt, tilt, blend)
			_camera.transform = _walking_camera_pose.rotated(_walking_camera_pose.basis.x.normalized(), _tilt)
	super._process(delta)
