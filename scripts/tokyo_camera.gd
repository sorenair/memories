extends "res://scripts/follow_camera.gd"
## A steady walking view with held reveals at the landmark approaches.
@export var meiji_gate: Node3D
@export var meiji_hall: Node3D
@export var senso_gate: Node3D
@export var senso_hall: Node3D
@export var crossing: Node3D
@export var walking_size := 4.5
@export var torii_size := 8.4
@export var shrine_size := 9.6
@export var lantern_gate_size := 11.0
@export var temple_size := 12.3
@export var crossing_size := 10.7

const WALKING_OFFSET := Vector3(0, 0.85, -0.7)
const EXIT_MARGIN := 0.65

class View:
	var anchor: Node3D
	var bounds: Rect2
	var focus: Vector3
	var size: float
	var tilt: float

	func _init(node: Node3D, area: Rect2, center: Vector3, zoom: float, pitch_offset := 0.0) -> void:
		anchor = node
		bounds = area
		focus = center
		size = zoom
		tilt = pitch_offset

	func contains(world_point: Vector3, margin: float) -> bool:
		if not is_instance_valid(anchor):
			return false
		var local_point := anchor.to_local(world_point)
		return bounds.grow(margin).has_point(Vector2(local_point.x, local_point.z))

var _views: Array[View] = []
var _active_view: View
var _walking_camera_pose: Transform3D
var _view_tilt := 0.0

@onready var _camera: Camera3D = $Camera3D

func _ready() -> void:
	_views = [
		View.new(meiji_gate, Rect2(-2.4, -0.9, 4.8, 5.4), Vector3(0, 2.9, 0.25), torii_size),
		View.new(meiji_hall, Rect2(-2.3, 4.65, 4.6, 2.3), Vector3(0, 2.65, 1.7), shrine_size),
		View.new(senso_gate, Rect2(-2.6, -0.9, 5.2, 4.6), Vector3(0, 3.1, 0.65), lantern_gate_size, deg_to_rad(19.0)),
		View.new(senso_hall, Rect2(-2.4, 5.0, 4.8, 3.0), Vector3(1.8, 2.6, 2.45), temple_size),
		View.new(crossing, Rect2(-4.3, -4.0, 9.5, 8.0), Vector3(-0.8, 1.85, -0.7), crossing_size),
	]
	framing_offset = WALKING_OFFSET
	_camera.size = walking_size
	_walking_camera_pose = _camera.transform
	super._ready()

func _process(delta: float) -> void:
	if is_instance_valid(target):
		var at := target.get_global_transform_interpolated().origin
		if _active_view and not _active_view.contains(at, EXIT_MARGIN):
			_active_view = null
		if not _active_view:
			for view in _views:
				if view.contains(at, 0.0):
					_active_view = view
					break

		var size := walking_size
		var offset := WALKING_OFFSET
		var tilt := 0.0
		if _active_view:
			size = _active_view.size
			offset = _active_view.anchor.to_global(_active_view.focus) - at
			tilt = _active_view.tilt
		var blend := 1.0 - exp(-3.0 * delta)
		framing_offset = framing_offset.lerp(offset, blend)
		_camera.size = lerpf(_camera.size, size, blend)
		var previous_tilt := _view_tilt
		_view_tilt = lerpf(_view_tilt, tilt, blend)
		if absf(_view_tilt - tilt) < 0.0001:
			_view_tilt = tilt
		if _view_tilt != previous_tilt:
			# Orbit and pitch together to see Hōzōmon's lantern beneath the eaves.
			# The horizontal camera axes remain unchanged for movement input.
			_camera.transform = _walking_camera_pose.rotated(_walking_camera_pose.basis.x.normalized(), _view_tilt)
	super._process(delta)
