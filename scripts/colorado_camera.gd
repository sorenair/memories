extends "res://scripts/follow_camera.gd"

const WALKING_OFFSET := Vector3(0, 0.85, -0.30)
const VIEW_ENTER_RADIUS := 1.45
const VIEW_EXIT_RADIUS := 2.65
const VIEW_HEIGHT_TOLERANCE := 0.65

@export var field_zone: MemoryZone
@export var summit_zone: MemoryZone
@export var lake_zone: MemoryZone
@export var walking_size := 4.8
@export var flatirons_size := 29.0
@export var summit_size := 8.8
@export var lake_size := 16.5
@export var flatirons_focus := Vector3(1.35, 8.55, -9.8)
@export var summit_focus := Vector3(-1.0, 3.87, -1.42)
@export var lake_focus := Vector3(3.8, 1.1, -0.5)

@onready var _camera: Camera3D = $Camera3D
var _scenic_zone: MemoryZone

func _ready() -> void:
	framing_offset = WALKING_OFFSET
	_camera.size = walking_size
	super._ready()

func _process(delta: float) -> void:
	if is_instance_valid(target):
		var at := target.get_global_transform_interpolated().origin
		var size := walking_size
		var offset := WALKING_OFFSET
		var next_zone: MemoryZone = null
		if _at_viewpoint(field_zone, at):
			next_zone = field_zone
			size = flatirons_size
			offset = field_zone.to_global(flatirons_focus) - at
		elif _at_viewpoint(summit_zone, at):
			next_zone = summit_zone
			size = summit_size
			offset = summit_zone.to_global(summit_focus) - at
		elif _at_viewpoint(lake_zone, at):
			next_zone = lake_zone
			size = lake_size
			offset = lake_zone.to_global(lake_focus) - at
		_scenic_zone = next_zone
		var blend := 1.0 - exp(-3.5 * delta)
		framing_offset = framing_offset.lerp(offset, blend)
		_camera.size = lerpf(_camera.size, size, blend)
	super._process(delta)

func _at_viewpoint(zone: MemoryZone, at: Vector3) -> bool:
	if not is_instance_valid(zone):
		return false
	var fragment := zone.get_fragment()
	if not is_instance_valid(fragment):
		return false
	var difference := at - fragment.global_position
	# Hold the composition as players shift around the viewpoint. Re-entering
	# after leaving requires walking up to the fragment again.
	var radius := VIEW_EXIT_RADIUS if zone == _scenic_zone else VIEW_ENTER_RADIUS
	return absf(difference.y) <= VIEW_HEIGHT_TOLERANCE and Vector2(difference.x, difference.z).length_squared() <= radius * radius
