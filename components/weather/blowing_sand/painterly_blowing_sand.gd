@tool
class_name PainterlyBlowingSand
extends Node3D
## A single GPU batch of near-ground grains. Assign a sand patch to follow its relief and recall.
const SHADER := preload("res://components/weather/blowing_sand/sand_grains.gdshader")
const FIELD_RESOLUTION := 96

@export_group("Coverage")
@export var sand_surface: PainterlySandPatch:
	set(value):
		if is_instance_valid(sand_surface) and sand_surface.ground_exclusion_changed.is_connected(_queue_rebuild):
			sand_surface.ground_exclusion_changed.disconnect(_queue_rebuild)
		sand_surface = value
		if is_inside_tree():
			_watch_surface()
		_queue_rebuild()
@export var footprint := Vector2(16.0, 12.0):
	set(value):
		footprint = value.max(Vector2.ONE)
		_queue_rebuild()
@export_range(0, 3000, 50) var grain_count := 650:
	set(value):
		grain_count = clampi(value, 0, 3000)
		_queue_rebuild()
@export var grain_seed := 275:
	set(value):
		grain_seed = value
		_queue_rebuild()

@export_group("Wind")
## Horizontal direction in the emitter's local X/Z plane.
@export var wind_direction := Vector2(1.0, 0.3):
	set(value):
		wind_direction = value
		_update_material()
@export_range(0.0, 12.0, 0.1, "suffix:m/s") var wind_speed := 3.5:
	set(value):
		wind_speed = value
		_update_material()
@export_range(0.0, 1.0, 0.01) var gust_strength := 0.76:
	set(value):
		gust_strength = value
		_update_material()
## Maximum clearance of the higher grains, in meters.
@export_range(0.04, 1.2, 0.01, "suffix:m") var lift_height := 0.39:
	set(value):
		lift_height = value
		_update_material()
		_update_bounds()

@export_group("Appearance")
## Smallest and largest grain widths, in meters.
@export var grain_size := Vector2(0.014, 0.048):
	set(value):
		grain_size = Vector2(minf(value.x, value.y), maxf(value.x, value.y)).max(Vector2.ONE * 0.005)
		_update_material()
		_update_bounds()
@export var sand_color := Color("ba895c"):
	set(value):
		sand_color = value
		_update_material()
@export var sparkle_color := Color("fff1cb"):
	set(value):
		sparkle_color = value
		_update_material()
@export_range(0.0, 1.0, 0.01) var glitter_strength := 0.82:
	set(value):
		glitter_strength = value
		_update_material()
@export_range(0.0, 1.0, 0.01) var opacity := 0.85:
	set(value):
		opacity = value
		_update_material()

var _grains: MultiMeshInstance3D
var _material: ShaderMaterial
var _ground_range := Vector2.ZERO
var _rebuild_queued := false
var _surface_fade := -1.0

func _enter_tree() -> void:
	set_notify_transform(true)
	_watch_surface()
	_queue_rebuild()

func _exit_tree() -> void:
	if is_instance_valid(sand_surface) and sand_surface.ground_exclusion_changed.is_connected(_queue_rebuild):
		sand_surface.ground_exclusion_changed.disconnect(_queue_rebuild)

func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSFORM_CHANGED and is_instance_valid(sand_surface):
		_queue_rebuild()

func _watch_surface() -> void:
	if is_instance_valid(sand_surface) and not sand_surface.ground_exclusion_changed.is_connected(_queue_rebuild):
		sand_surface.ground_exclusion_changed.connect(_queue_rebuild)

func _queue_rebuild() -> void:
	if is_inside_tree() and not _rebuild_queued:
		_rebuild_queued = true
		_rebuild.call_deferred()

func _rebuild() -> void:
	_rebuild_queued = false
	if not is_inside_tree():
		return
	if not is_instance_valid(_grains):
		_grains = MultiMeshInstance3D.new()
		_grains.name = "Grains"
		_grains.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_grains.visibility_range_end = 70.0
		_material = ShaderMaterial.new()
		_material.shader = SHADER
		_grains.material_override = _material
		add_child(_grains, false, Node.INTERNAL_MODE_BACK)

	var instances := MultiMesh.new()
	instances.transform_format = MultiMesh.TRANSFORM_3D
	instances.use_custom_data = true
	instances.mesh = QuadMesh.new()
	instances.instance_count = grain_count
	var rng := RandomNumberGenerator.new()
	rng.seed = grain_seed
	for index in range(instances.instance_count):
		instances.set_instance_transform(index, Transform3D.IDENTITY)
		instances.set_instance_custom_data(index, Color(rng.randf(), rng.randf(), rng.randf(), rng.randf()))
	_grains.multimesh = instances

	var use_surface := is_instance_valid(sand_surface) and sand_surface.is_inside_tree()
	_material.set_shader_parameter("use_surface", use_surface)
	_ground_range = Vector2.ZERO
	if use_surface:
		_material.set_shader_parameter("surface_field", _bake_surface())
	_update_material()
	_update_bounds()
	_surface_fade = -1.0
	_sync_recall()
	set_process(use_surface and not Engine.is_editor_hint())

func _bake_surface() -> ImageTexture:
	var image := Image.create(FIELD_RESOLUTION, FIELD_RESOLUTION, false, Image.FORMAT_RGF)
	for y in FIELD_RESOLUTION:
		for x in FIELD_RESOLUTION:
			var uv := (Vector2(x, y) + Vector2.ONE * 0.5) / FIELD_RESOLUTION
			var point := (uv - Vector2.ONE * 0.5) * footprint
			var world := to_global(Vector3(point.x, 0.0, point.y))
			world.y = sand_surface.get_surface_height(world)
			var height := to_local(world).y
			_ground_range.x = minf(_ground_range.x, height)
			_ground_range.y = maxf(_ground_range.y, height)
			var coverage := 1.0 if sand_surface.excludes_ground_point(world) else 0.0
			image.set_pixel(x, y, Color(height, coverage, 0.0, 1.0))
	return ImageTexture.create_from_image(image)

func _process(_delta: float) -> void:
	_sync_recall()

func _sync_recall() -> void:
	var fade := 1.0
	if not Engine.is_editor_hint() and is_instance_valid(sand_surface):
		var controller := sand_surface.get_recall_controller()
		if is_instance_valid(controller):
			fade = smoothstep(0.36, 0.96, float(controller.progress))
	if not is_equal_approx(fade, _surface_fade):
		_surface_fade = fade
		_material.set_shader_parameter("surface_fade", fade)

func _update_material() -> void:
	if not _material:
		return
	for key in [&"footprint", &"wind_speed", &"gust_strength", &"lift_height", &"grain_size", &"sand_color", &"sparkle_color", &"glitter_strength", &"opacity"]:
		_material.set_shader_parameter(key, get(key))
	var direction := wind_direction.normalized() if not wind_direction.is_zero_approx() else Vector2.RIGHT
	_material.set_shader_parameter("wind_direction", direction)
	_grains.visible = opacity > 0.0 and grain_count > 0

func _update_bounds() -> void:
	if is_instance_valid(_grains):
		var origin := Vector3(-footprint.x * 0.5, _ground_range.x, -footprint.y * 0.5)
		var size := Vector3(footprint.x, _ground_range.y - _ground_range.x + lift_height + 0.08, footprint.y)
		_grains.custom_aabb = AABB(origin, size).grow(grain_size.y * 2.5 + 0.08)
