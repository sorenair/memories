@tool
class_name PainterlyLighthouse
extends PainterlyConcertComponent
const BUILDER = preload("res://components/scenery/lighthouse/lighthouse_geometry.gd")
const LIGHTHOUSE_PAINT = preload("res://components/scenery/lighthouse/lighthouse_paint.gdshader")
const GLASS = preload("res://components/scenery/lighthouse/lantern_glass.gdshader")
const BEACON = preload("res://components/scenery/lighthouse/beacon.gdshader")
@export_group("Lighthouse Shape")
## Height from the ground to the lantern gallery; roof/finial add 2.54 m.
@export_range(5.0, 18.0, 0.25) var tower_height: float = 9.0:
	set(value):
		tower_height = clampf(value, 5, 18)
		_request_rebuild()
@export_range(0.8, 2.0, 0.05) var base_radius: float = 1.1:
	set(value):
		base_radius = clampf(value, 0.8, 2)
		_request_rebuild()
@export_range(1, 5, 1) var window_count: int = 3:
	set(value):
		window_count = clampi(value, 1, 5)
		_request_rebuild()
@export var gallery_enabled: bool = true:
	set(value):
		gallery_enabled = value
		_request_rebuild()
@export_group("Beacon")
@export var beacon_enabled: bool = true:
	set(value):
		beacon_enabled = value
		_request_rebuild()
@export var beacon_color := Color("fff0c7"):
	set(value):
		beacon_color = value
		_request_rebuild()
@export_range(0.0, 1.5, 0.05) var beacon_strength: float = 0.65:
	set(value):
		beacon_strength = clampf(value, 0, 1.5)
		_update_beacon()
## Revolutions per second. Zero holds the beam at Beam Heading.
@export_range(0.0, 0.15, 0.005) var rotation_speed: float = 0.035:
	set(value):
		rotation_speed = clampf(value, 0, 0.15)
		_update_beacon()
@export_range(-180.0, 180.0, 1.0) var beam_heading: float = 35.0:
	set(value):
		beam_heading = value
		_update_beacon()
@export_range(3.0, 16.0, 0.5) var beam_length: float = 8.0:
	set(value):
		beam_length = clampf(value, 3, 16)
		_update_beacon()
var _beacon_materials: Array[ShaderMaterial] = []
var _visual_time: float = -1.0

func _lighthouse_config() -> Dictionary:
	var c := _config()
	c.merge({"tower_height": tower_height, "base_radius": base_radius, "window_count": window_count, "gallery_enabled": gallery_enabled, "beacon_color": beacon_color})
	return c

func _build_geometry() -> Dictionary:
	return BUILDER.new().make(_lighthouse_config())

func _apply_material() -> void:
	if _material:
		_material.shader = LIGHTHOUSE_PAINT
		super._apply_material()
	_update_beacon()

func _build_details() -> void:
	_beacon_materials.clear()
	var glass_paint := ShaderMaterial.new()
	glass_paint.shader = GLASS
	_add_visual("LanternGlazing", BUILDER.new().glass(_lighthouse_config()), glass_paint)
	if beacon_enabled:
		var glow := ShaderMaterial.new()
		glow.shader = BEACON
		glow.set_shader_parameter("halo", true)
		var quad := QuadMesh.new()
		quad.size = Vector2.ONE * base_radius * 2.2
		var halo := _add_visual("LanternGlow", quad, glow)
		halo.position = Vector3(0, tower_height + 0.73, 0)
		halo.custom_aabb = AABB(Vector3.ONE * -base_radius * 1.2, Vector3.ONE * base_radius * 2.4)
		_beacon_materials.append(glow)
		var beam_paint := ShaderMaterial.new()
		beam_paint.shader = BEACON
		var tool := SurfaceTool.new()
		tool.begin(Mesh.PRIMITIVE_TRIANGLES)
		for uv in [Vector2.ZERO, Vector2.RIGHT, Vector2.ONE, Vector2.ZERO, Vector2.ONE, Vector2.DOWN]:
			tool.set_uv(uv)
			tool.set_normal(Vector3.UP)
			tool.add_vertex(Vector3(uv.x, 0, uv.y))
		_add_visual("BeaconBeam", tool.commit(), beam_paint)
		_beacon_materials.append(beam_paint)
	_update_beacon()

func _update_beacon() -> void:
	var materials: Array[ShaderMaterial] = _beacon_materials.duplicate()
	if _material:
		materials.append(_material)
	for paint in materials:
		paint.set_shader_parameter("beacon_strength", beacon_strength if beacon_enabled else 0.0)
		paint.set_shader_parameter("beacon_color", beacon_color)
		paint.set_shader_parameter("rotation_speed", rotation_speed)
		paint.set_shader_parameter("beam_heading", deg_to_rad(beam_heading))
		paint.set_shader_parameter("beam_length", beam_length)
		paint.set_shader_parameter("beacon_height", tower_height + 0.73)
		paint.set_shader_parameter("animation_time", _visual_time)
	if is_instance_valid(_generated_root) and _generated_root.has_node("BeaconBeam"):
		var reach := beam_length * 1.15
		_generated_root.get_node("BeaconBeam").custom_aabb = AABB(Vector3(-reach, tower_height - 2, -reach), Vector3(reach * 2, 4, reach * 2))

func seek_time(seconds: float) -> void:
	_visual_time = seconds
	_update_beacon()

func get_recall_anchor() -> Node3D:
	# The rotating shaft must not enlarge the lighthouse's proximity trigger.
	return recall_anchor if is_instance_valid(recall_anchor) else self

func excludes_ground_point(world_point: Vector3) -> bool:
	var p := to_local(world_point)
	return Vector2(p.x, p.z).length() < base_radius * 1.40 or (absf(p.x) < base_radius * 0.53 and p.z > base_radius * 1.35 and p.z < base_radius * 1.36 + 0.88)

func get_ground_outline() -> PackedVector3Array:
	var circle := PackedVector2Array()
	for i in range(48):
		var a := TAU * i / 48.0
		circle.append(Vector2(cos(a), sin(a)) * base_radius * 1.40)
	var z := base_radius * 1.36
	var half := base_radius * 0.53
	var stair := PackedVector2Array([Vector2(-half, z - 0.2), Vector2(half, z - 0.2), Vector2(half, z + 0.88), Vector2(-half, z + 0.88)])
	var union := Geometry2D.merge_polygons(circle, stair)
	var polygon: PackedVector2Array = union[0] if not union.is_empty() else circle
	var outline := PackedVector3Array()
	for p in polygon:
		outline.append(to_global(Vector3(p.x, 0, p.y)))
	return outline
