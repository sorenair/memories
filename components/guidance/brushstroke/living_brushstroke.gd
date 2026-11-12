@tool
class_name LivingBrushstroke
extends Node3D
## A broad gesture of pigment travelling between two local-space endpoints.
## Geometry stays fixed; the GPU draws, frays, and releases each stroke.
const PAINT := preload("res://components/guidance/brushstroke/living_brushstroke.gdshader")
@export_group("Endpoints")
@export var start_point := Vector3(-2.0, 0.65, 0.0):
	set(value):
		start_point = value
		_update_path()
@export var end_point := Vector3(2.0, 1.0, -1.0):
	set(value):
		end_point = value
		_update_path()
## Optional curved route. Null retains the original two-point gesture.
@export var route_curve: Curve3D:
	set(value):
		if route_curve and route_curve.changed.is_connected(_curve_changed): route_curve.changed.disconnect(_curve_changed)
		route_curve = value
		if route_curve and not route_curve.changed.is_connected(_curve_changed): route_curve.changed.connect(_curve_changed)
		_curve_changed()
@export_range(0.0, 2.0, 0.01) var arc_height: float = 0.38:
	set(value):
		arc_height = value
		_update_path()
@export_range(-1.0, 1.0, 0.01) var curve_bend: float = 0.24:
	set(value):
		curve_bend = value
		_update_path()
@export_group("Brush")
@export_range(0.08, 0.9, 0.01) var stroke_width: float = 0.42:
	set(value):
		stroke_width = value
		_update_materials()
		_update_bounds()
@export var pigment_color := Color.WHITE:
	set(value):
		pigment_color = value
		_update_materials()
@export var edge_color := Color("ededed"):
	set(value):
		edge_color = value
		_update_materials()
@export var highlight_color := Color.WHITE:
	set(value):
		highlight_color = value
		_update_materials()
@export_range(0.0, 1.0, 0.01) var opacity: float = 0.86:
	set(value):
		opacity = value
		_update_materials()
## Local soft glow, including on the Mobile renderer without screen bloom.
@export_range(0.0, 2.0, 0.05) var glow_strength: float = 1.0:
	set(value):
		glow_strength = clampf(value, 0.0, 2.0)
		_update_materials()
## Gather, bloom, and feather apart as the head approaches the destination.
@export_range(0.0, 1.0, 0.05) var evolution_strength: float = 1.0:
	set(value):
		evolution_strength = clampf(value, 0.0, 1.0)
		_update_materials()
@export var stroke_seed: int = 31:
	set(value):
		stroke_seed = value
		_update_materials()
@export_group("Motion")
@export_range(1.0, 14.0, 0.1) var travel_duration: float = 5.5:
	set(value):
		travel_duration = maxf(value, 0.1)
		_update_materials()
@export_range(0.5, 5.0, 0.1) var trail_duration: float = 2.8:
	set(value):
		trail_duration = maxf(value, 0.1)
		_update_materials()
@export_range(0.0, 8.0, 0.1) var rest_duration: float = 1.6:
	set(value):
		rest_duration = maxf(value, 0.0)
		_update_materials()
## Zero holds a seeded still pose; no per-frame CPU animation is required.
@export_range(0.0, 3.0, 0.05) var playback_speed: float = 1.0:
	set(value):
		playback_speed = value
		_update_materials()
@export_range(0.0, 0.2, 0.005) var motion_amount: float = 0.06:
	set(value):
		motion_amount = value
		_update_materials()
		_update_bounds()
@export_group("Surface Pigment")
## Optional planar wash under the floating ribbon. It does not project onto scenery.
@export var surface_wash_enabled: bool = true:
	set(value):
		surface_wash_enabled = value
		_update_path()
@export var wash_height: float = 0.018:
	set(value):
		wash_height = value
		_update_materials()
		_update_bounds()
@export_range(0.0, 0.4, 0.01) var wash_opacity: float = 0.14:
	set(value):
		wash_opacity = value
		_update_materials()
@export_group("Rendering")
@export_range(32, 160, 8) var detail: int = 96:
	set(value):
		detail = clampi(value, 32, 160)
		_request_rebuild()
@export_range(10.0, 150.0, 1.0) var visibility_distance: float = 45.0:
	set(value):
		visibility_distance = value
		_update_materials()
@export_tool_button("Regenerate brushstroke") var regenerate = rebuild
var _ribbon: MeshInstance3D
var _wash: MeshInstance3D
var _materials: Array[ShaderMaterial] = []
var _queued: bool = false
var _route_texture: ImageTexture
var _route_length := 0.0

func _ready() -> void:
	rebuild()
	set_process(false)
	set_physics_process(false)

func set_points(from: Vector3, to: Vector3) -> void:
	start_point = from
	end_point = to

func _request_rebuild() -> void:
	if is_inside_tree() and not _queued:
		_queued = true
		call_deferred("_rebuild_queued")

func _rebuild_queued() -> void:
	if _queued:
		rebuild()

func sample_path(t: float) -> Vector3:
	t = clampf(t, 0.0, 1.0)
	if route_curve and route_curve.point_count >= 2 and _route_length > 0.01:
		return route_curve.sample_baked(t*_route_length, true)
	var delta := end_point - start_point
	var side := delta.normalized().cross(Vector3.UP)
	if side.length_squared() < 0.001:
		side = Vector3.RIGHT
	else:
		side = side.normalized()
	return start_point.lerp(end_point, t) + Vector3.UP * sin(t * PI) * arc_height + side * sin(t * TAU) * sin(t * PI) * curve_bend

func _curve_changed() -> void:
	_route_length = route_curve.get_baked_length() if route_curve and route_curve.point_count >= 2 else 0.0
	_route_texture = null
	if _route_length > 0.01:
		# Arc-length samples keep the animated mark's speed even around corners.
		var field := Image.create(256,1,false,Image.FORMAT_RGBAF)
		for i in 256:
			var point := route_curve.sample_baked(float(i)/255.0*_route_length,true)
			field.set_pixel(i,0,Color(point.x,point.y,point.z,1.0))
		_route_texture = ImageTexture.create_from_image(field)
	_update_path()

func _update_path() -> void:
	_update_materials()
	if is_instance_valid(_ribbon):
		var valid := _route_length > 0.01 or start_point.distance_squared_to(end_point) > 0.0025
		_ribbon.visible = valid
		var flat := Vector2(end_point.x - start_point.x, end_point.z - start_point.z)
		_wash.visible = valid and surface_wash_enabled and (_route_length > 0.01 or flat.length_squared() > 0.0025)
	_update_bounds()

func _update_materials() -> void:
	for material in _materials:
		for key in [&"start_point", &"end_point", &"arc_height", &"curve_bend", &"stroke_width", &"pigment_color", &"edge_color", &"highlight_color", &"opacity", &"glow_strength", &"evolution_strength", &"travel_duration", &"trail_duration", &"rest_duration", &"playback_speed", &"motion_amount", &"wash_height", &"wash_opacity"]:
			material.set_shader_parameter(key, get(key))
		material.set_shader_parameter("seed_phase", float(posmod(stroke_seed * 37, 997)) / 997.0)
		material.set_shader_parameter("route_length", _route_length if _route_texture else maxf(0.05, start_point.distance_to(end_point)))
		material.set_shader_parameter("use_route", _route_texture != null)
		material.set_shader_parameter("route_texture", _route_texture)
	for node in [_ribbon, _wash]:
		if is_instance_valid(node):
			node.visibility_range_end = visibility_distance

func _update_bounds() -> void:
	if not is_instance_valid(_ribbon):
		return
	var bounds := AABB(start_point, Vector3.ZERO)
	var wash_bounds := AABB(Vector3(start_point.x, wash_height, start_point.z), Vector3.ZERO)
	for index in range(65):
		var point := sample_path(float(index) / 64.0)
		bounds = bounds.expand(point)
		wash_bounds = wash_bounds.expand(Vector3(point.x, wash_height, point.z))
	_ribbon.custom_aabb = bounds.grow(stroke_width * 2.2 + motion_amount * 2.0 + 0.2)
	_wash.custom_aabb = wash_bounds.grow(stroke_width * 1.7 + 0.1)

func rebuild() -> void:
	_queued = false
	if not is_inside_tree():
		return
	for node in [_ribbon, _wash]:
		if is_instance_valid(node):
			remove_child(node)
			node.free()
	_materials.clear()
	_ribbon = _make_surface("PigmentRibbon", 6, false)
	_wash = _make_surface("SurfaceWash", 1, true)
	_update_path()

func _make_surface(node_name: String, columns: int, wash: bool) -> MeshInstance3D:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for row in range(detail):
		for column in range(columns):
			for corner in [Vector2(0,0), Vector2(1,0), Vector2(1,1), Vector2(0,0), Vector2(1,1), Vector2(0,1)]:
				var uv := Vector2((row + corner.x) / float(detail), (column + corner.y) / float(columns))
				surface.set_uv(uv)
				surface.set_normal(Vector3.UP)
				surface.add_vertex(Vector3(uv.x, uv.y * 2.0 - 1.0, 0))
	var material := ShaderMaterial.new()
	material.shader = PAINT
	material.set_shader_parameter("surface_layer", wash)
	_materials.append(material)
	var instance := MeshInstance3D.new()
	instance.name = node_name
	instance.mesh = surface.commit()
	instance.material_override = material
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(instance, false, Node.INTERNAL_MODE_BACK)
	return instance
