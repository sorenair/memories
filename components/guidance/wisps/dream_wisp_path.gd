@tool
class_name DreamWispPath
extends Path3D
## Sparse, camera-facing painted strokes carried along an editable route.
const WISP_SHADER = preload("res://components/guidance/wisps/dream_wisps.gdshader")
const SAMPLES: int = 256
@export_group("Wisps")
@export_range(0, 32, 1) var wisp_count: int = 8:
	set(value):
		wisp_count = clampi(value, 0, 32)
		_request_rebuild()
@export var wisp_seed: int = 83:
	set(value):
		wisp_seed = value
		_request_rebuild()
@export_range(0.15, 2.5, 0.05) var stroke_length: float = 0.95:
	set(value):
		stroke_length = value
		_update_material()
@export_range(0.02, 0.5, 0.01) var stroke_width: float = 0.11:
	set(value):
		stroke_width = value
		_update_material()
		_update_bounds()
@export_group("Drift")
## Meters per second; zero freezes drift, breathing, and flutter.
@export_range(0.0, 1.5, 0.01) var drift_speed: float = 0.34:
	set(value):
		drift_speed = value
		_update_material()
@export_range(0.0, 2.0, 0.01) var float_height: float = 0.48:
	set(value):
		float_height = value
		_update_material()
		_update_bounds()
@export_range(0.0, 0.6, 0.01) var wander: float = 0.16:
	set(value):
		wander = value
		_update_material()
		_update_bounds()
@export_group("Appearance")
@export var wisp_color := Color("d3e8df"):
	set(value):
		wisp_color = value
		_update_material()
@export var edge_color := Color("8fbcc5"):
	set(value):
		edge_color = value
		_update_material()
@export_range(0.0, 1.0, 0.01) var opacity: float = 0.5:
	set(value):
		opacity = value
		_update_material()
@export_range(10.0, 150.0, 1.0) var visibility_distance: float = 45.0:
	set(value):
		visibility_distance = value
		if is_instance_valid(_strokes):
			_strokes.visibility_range_end = value
var _queued: bool = false
var _strokes: MultiMeshInstance3D
var _material: ShaderMaterial
var _field: ImageTexture
var _length: float = 0.0
var _route_bounds := AABB()

func _ready() -> void:
	curve_changed.connect(_curve_changed)
	rebuild()

func _curve_changed() -> void:
	# Path3D's curve_changed includes assignment as well as handle edits.
	_request_rebuild()

func _request_rebuild() -> void:
	if is_inside_tree() and not _queued:
		_queued = true
		call_deferred("rebuild")

func _update_material() -> void:
	if not _material:
		return
	for key in [&"stroke_length", &"stroke_width", &"drift_speed", &"float_height", &"wander", &"wisp_color", &"edge_color", &"opacity"]:
		_material.set_shader_parameter(key, get(key))

func _update_bounds() -> void:
	if is_instance_valid(_strokes):
		var bounds := _route_bounds.grow(wander + stroke_width + 0.1)
		bounds.position.y += float_height
		_strokes.custom_aabb = bounds

func rebuild() -> void:
	_queued = false
	if not is_inside_tree():
		return
	if is_instance_valid(_strokes):
		remove_child(_strokes)
		_strokes.queue_free()
	_strokes = null
	_material = null
	if not curve or curve.point_count < 2 or wisp_count == 0:
		return
	_length = curve.get_baked_length()
	if _length < 0.05:
		return
	# The GPU reads arc-length samples; no particles or per-frame CPU uploads.
	var image := Image.create(SAMPLES, 1, false, Image.FORMAT_RGBAF)
	for index in range(SAMPLES):
		var point := curve.sample_baked(float(index) / float(SAMPLES - 1) * _length, true)
		image.set_pixel(index, 0, Color(point.x, point.y, point.z, 1.0))
		if index == 0:
			_route_bounds = AABB(point, Vector3.ZERO)
		else:
			_route_bounds = _route_bounds.expand(point)
	_field = ImageTexture.create_from_image(image)
	_material = ShaderMaterial.new()
	_material.shader = WISP_SHADER
	_material.set_shader_parameter("route", _field)
	_material.set_shader_parameter("route_length", _length)
	_update_material()
	var mesh := SurfaceTool.new()
	mesh.begin(Mesh.PRIMITIVE_TRIANGLES)
	for index in range(12):
		for corner in [Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 0), Vector2(1, 1), Vector2(0, 1)]:
			var uv := Vector2((index + corner.x) / 12.0, corner.y)
			mesh.set_uv(uv)
			mesh.set_normal(Vector3.UP)
			mesh.add_vertex(Vector3(uv.x, uv.y * 2.0 - 1.0, 0.0))
	var instances := MultiMesh.new()
	instances.transform_format = MultiMesh.TRANSFORM_3D
	instances.use_custom_data = true
	instances.mesh = mesh.commit()
	instances.instance_count = wisp_count
	var rng := RandomNumberGenerator.new()
	rng.seed = wisp_seed
	for index in range(wisp_count):
		instances.set_instance_transform(index, Transform3D.IDENTITY)
		# Jittered stratification retains gaps without a dotted-line rhythm.
		instances.set_instance_custom_data(index, Color((index + rng.randf_range(0.05, 0.95)) / wisp_count, rng.randf(), rng.randf(), rng.randf()))
	_strokes = MultiMeshInstance3D.new()
	_strokes.name = "WispStrokes"
	_strokes.multimesh = instances
	_strokes.material_override = _material
	_strokes.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_strokes.visibility_range_end = visibility_distance
	add_child(_strokes, false, Node.INTERNAL_MODE_BACK)
	_update_bounds()
