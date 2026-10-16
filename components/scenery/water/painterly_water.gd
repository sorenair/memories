@tool
class_name PainterlyWater
extends Node3D
## Opaque painted water: no screen/depth reads, reflection probes, or per-frame uploads.
signal ground_exclusion_changed
const SHAPES = preload("res://components/scenery/water/water_shapes.gd")
const WATER_SHADER = preload("res://components/scenery/water/shaders/painted_water.gdshader")
const BODY = preload("res://components/scenery/water/water_body_geometry.gd")
const SHORE_FIELD = preload("res://components/scenery/water/water_shore_field.gd")
const SETTINGS_PRESETS = [null, preload("res://components/scenery/water/settings/calm_pond.tres"), preload("res://components/scenery/water/settings/flowing_stream.tres"), preload("res://components/scenery/water/settings/open_lake.tres")]
const SETTINGS_KEYS = [&"flow_speed", &"ripple_scale", &"wave_activity", &"wave_height", &"caustic_strength", &"highlight_amount", &"paint_contrast", &"depth_distance", &"normal_strength", &"reflection_strength", &"sky_color", &"light_direction"]
const FOAM_MASK = preload("res://components/scenery/water/textures/water_paint.png")
const PIGMENT_MASK = preload("res://components/scenery/water/textures/water_pigment.png")
const NORMAL_MASK = preload("res://components/scenery/water/textures/water_normals.png")
const CAUSTIC_MASK = preload("res://components/scenery/water/textures/water_caustics.png")
const COLOR_KEYS = [&"deep_color", &"body_color", &"shallow_color", &"foam_color"]
const COLORS = [
	["175273", "2498b0", "59c9ba", "ffffff"],
	["355a9c", "6aa8d4", "b4d5d2", "fff2da"],
	["326a69", "65a996", "b8d2a0", "fff0cb"],
	["5c83a5", "9ec8da", "d5e6dd", "f5f9ed"],
	["675799", "9b8dc9", "c8b8dd", "fff1df"],
	["263e69", "426a91", "80a9b6", "d5e7df"]
]

@export_group("Shared Appearance")
@export_enum("Custom", "Calm Pond", "Flowing Stream", "Open Lake") var behavior_preset: int = 0:
	set(value):
		behavior_preset = clampi(value, 0, 3)
		if behavior_preset > 0:
			_applying_settings = true
			settings = SETTINGS_PRESETS[behavior_preset].duplicate() as WaterSettings
			_applying_settings = false
		notify_property_list_changed()
@export var settings: WaterSettings:
	set(value):
		if settings and settings.changed.is_connected(_settings_changed):
			settings.changed.disconnect(_settings_changed)
		settings = value
		if settings:
			settings.changed.connect(_settings_changed)
		if not _applying_settings:
			behavior_preset = 0
		notify_property_list_changed()
		_update_materials()
@export_group("Water Shape")
@export_enum("Pond", "Stream Section") var shape: int = 0:
	set(value):
		shape = clampi(value, 0, 1)
		_request_rebuild()
## X = width, Y = length on the ground. Stream modules connect along local Z.
@export var footprint := Vector2(4.5, 3.3):
	set(value):
		footprint = value.clamp(Vector2.ONE * 0.75, Vector2.ONE * 40.0)
		_request_rebuild()
@export var water_seed: int = 47:
	set(value):
		water_seed = value
		_request_rebuild()
@export_range(0.0, 0.25, 0.01) var irregularity: float = 0.12:
	set(value):
		irregularity = clampf(value, 0.0, 0.25)
		_request_rebuild()
@export_range(0.0, 0.8, 0.01) var stream_bend: float = 0.25:
	set(value):
		stream_bend = clampf(value, 0.0, 0.8)
		_request_rebuild()
@export var cap_stream_ends: bool = false:
	set(value):
		cap_stream_ends = value
		_request_rebuild()
@export_range(16, 96, 8) var outline_detail: int = 48:
	set(value):
		outline_detail = clampi(value, 16, 96)
		_request_rebuild()
## Optional custom closed outline in local X/Z, represented by a Curve2D.
@export var pond_outline: Curve2D:
	set(value):
		if pond_outline and pond_outline.changed.is_connected(_shape_resource_changed):
			pond_outline.changed.disconnect(_shape_resource_changed)
		pond_outline = value
		if pond_outline:
			pond_outline.changed.connect(_shape_resource_changed)
		_shape_resource_changed()
## Optional flat centerline, edited with a Path3D's Curve resource.
@export var stream_path: Curve3D:
	set(value):
		if stream_path and stream_path.changed.is_connected(_shape_resource_changed):
			stream_path.changed.disconnect(_shape_resource_changed)
		stream_path = value
		if stream_path:
			stream_path.changed.connect(_shape_resource_changed)
		_shape_resource_changed()
## Width multiplier along the stream, sampled from 0 to 1.
@export var stream_width_profile: Curve:
	set(value):
		if stream_width_profile and stream_width_profile.changed.is_connected(_shape_resource_changed):
			stream_width_profile.changed.disconnect(_shape_resource_changed)
		stream_width_profile = value
		if stream_width_profile:
			stream_width_profile.changed.connect(_shape_resource_changed)
		_shape_resource_changed()
## Arc-length phase offset for connecting custom stream segments (meters).
@export var stream_flow_offset: float = 0.0:
	set(value):
		stream_flow_offset = value
		_update_materials()
@export_group("Shore")
@export var block_water_entry: bool = true:
	set(value):
		block_water_entry = value
		_request_rebuild()
## Paths to boulders / rock clusters; collision or visual sections define water edges.
@export var shore_obstacles: Array[NodePath] = []:
	set(value):
		shore_obstacles = value
		_request_rebuild()
@export_enum("Mobile (64)", "Balanced (96)", "Detailed (128)") var shore_field_quality: int = 0:
	set(value):
		shore_field_quality = clampi(value, 0, 2)
		_request_rebuild()
@export_group("Water Colors")
@export_enum("Custom", "Turquoise", "Storybook Blue", "Autumn Jade", "Winter Glass", "Dream Lavender", "Moonlit") var palette_preset: int = 1:
	set(value):
		palette_preset = clampi(value, 0, 6)
		if palette_preset > 0:
			_applying_preset = true
			palette = make_palette(palette_preset)
			_applying_preset = false
		notify_property_list_changed()
@export var palette: WaterPalette:
	set(value):
		if palette and palette.changed.is_connected(_palette_changed):
			palette.changed.disconnect(_palette_changed)
		palette = value
		if palette:
			palette.changed.connect(_palette_changed)
		if not _applying_preset:
			palette_preset = 0
		_update_materials()
@export_group("Motion and Paint")
@export var flow_direction := Vector2(0.25, 1.0):
	set(value):
		flow_direction = value
		_update_materials()
## Zero freezes all water animation, including waves and foam.
@export_range(0.0, 1.0, 0.01) var flow_speed: float = 0.22:
	set(value):
		flow_speed = clampf(value, 0.0, 1.0)
		_update_materials()
@export_range(0.4, 4.0, 0.05) var ripple_scale: float = 1.6:
	set(value):
		ripple_scale = clampf(value, 0.4, 4.0)
		_update_materials()
## Legacy serialized value. Depth now uses WaterSettings.depth_distance.
@export_range(0.0, 1.0, 0.01) var depth_gradient: float = 0.72:
	set(value):
		depth_gradient = clampf(value, 0.0, 1.0)
		_update_materials()
@export_range(0.0, 1.0, 0.01) var caustic_strength: float = 0.65:
	set(value):
		caustic_strength = clampf(value, 0.0, 1.0)
		_update_materials()
@export_range(0.0, 1.0, 0.01) var highlight_amount: float = 0.65:
	set(value):
		highlight_amount = clampf(value, 0.0, 1.0)
		_update_materials()
## Strength of crossing wave distortion and crest lighting, independent of flow.
@export_range(0.0, 1.0, 0.01) var wave_activity: float = 0.72:
	set(value):
		wave_activity = clampf(value, 0.0, 1.0)
		_update_materials()
@export_range(0.0, 0.02, 0.001) var wave_height: float = 0.008:
	set(value):
		wave_height = clampf(value, 0.0, 0.02)
		_update_materials()
@export_group("Shore Foam")
@export_range(0.0, 1.0, 0.01) var foam_amount: float = 1.0:
	set(value):
		foam_amount = clampf(value, 0.0, 1.0)
		_update_materials()
## Approximate width in meters, extending inward from the water edge.
@export_range(0.03, 0.8, 0.01) var foam_width: float = 0.34:
	set(value):
		foam_width = clampf(value, 0.03, 0.8)
		_update_materials()
## Cell-size multiplier: 1 preserves the current look; larger values make larger openings.
@export_range(0.2, 4.0, 0.05) var foam_cell_size: float = 1.0:
	set(value):
		foam_cell_size = clampf(value, 0.2, 4.0)
		_update_materials()
@export_group("Rendering")
@export_range(15.0, 200.0, 1.0) var visibility_distance: float = 70.0:
	set(value):
		visibility_distance = clampf(value, 15.0, 200.0)
		for child in get_children(true):
			if child is GeometryInstance3D and child.get_meta(&"generated_water", false):
				child.visibility_range_end = visibility_distance
@export_tool_button("Regenerate water") var regenerate = rebuild
var _applying_preset: bool = false
var _applying_settings: bool = false
var _shape_data: Dictionary = {}
var _shore_data: Dictionary = {}
var _obstacle_regions: Array[PackedVector2Array] = []
var _obstacle_nodes: Array[Node] = []
var _fallback_settings: WaterSettings = WaterSettings.new()
var _queued: bool = false
var _water_material: ShaderMaterial

static func make_palette(index: int) -> WaterPalette:
	var colors := WaterPalette.new()
	var values: Array = COLORS[clampi(index - 1, 0, COLORS.size() - 1)]
	for key in range(COLOR_KEYS.size()):
		colors.set(COLOR_KEYS[key], Color(values[key]))
	return colors

func _ready() -> void:
	set_notify_transform(true)
	if not palette:
		_applying_preset = true
		palette = make_palette(maxi(1, palette_preset))
		_applying_preset = false
	if shore_obstacles.is_empty():
		rebuild()
	else:
		_request_rebuild()

func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSFORM_CHANGED and is_inside_tree():
		ground_exclusion_changed.emit()
		_update_materials()
		if not shore_obstacles.is_empty():
			_request_rebuild()

func _validate_property(property: Dictionary) -> void:
	if property.name == "depth_gradient":
		property.usage = property.usage & ~PROPERTY_USAGE_EDITOR
	if property.name == "settings" and behavior_preset > 0:
		property.usage = property.usage & ~PROPERTY_USAGE_STORAGE
	if settings and StringName(property.name) in SETTINGS_KEYS:
		property.usage = property.usage & ~PROPERTY_USAGE_EDITOR
	if property.name == "palette" and palette_preset != 0:
		property.usage = property.usage & ~PROPERTY_USAGE_STORAGE

func _settings_changed() -> void:
	behavior_preset = 0
	_update_materials()

func _shape_resource_changed() -> void:
	_shape_data = {}
	_request_rebuild()

func _make_shape_data() -> Dictionary:
	return BODY.make_shape(shape, footprint, water_seed, irregularity, stream_bend, outline_detail, pond_outline, stream_path, stream_width_profile)

func _palette_changed() -> void:
	palette_preset = 0
	_update_materials()

func _request_rebuild() -> void:
	if is_inside_tree() and not _queued:
		_queued = true
		call_deferred("rebuild")

func _update_materials() -> void:
	if not _water_material:
		return
	var colors: WaterPalette = settings.palette if settings and settings.palette else palette
	if not colors:
		colors = make_palette(1)
	for key in COLOR_KEYS:
		_water_material.set_shader_parameter(key, colors.get(key))
	for key in SETTINGS_KEYS:
		var value: Variant = settings.get(key) if settings else (get(key) if key in [&"flow_speed", &"ripple_scale", &"wave_activity", &"wave_height", &"caustic_strength", &"highlight_amount"] else _fallback_settings.get(key))
		_water_material.set_shader_parameter(key, value)
	for key in [&"flow_direction", &"foam_amount", &"foam_width", &"foam_cell_size"]:
		_water_material.set_shader_parameter(key, get(key))
	_water_material.set_shader_parameter("stream_body", shape == 1)
	var offset := stream_flow_offset
	if shape == 1 and not stream_path:
		var axis := global_basis.z.normalized()
		offset += Vector2(global_position.x, global_position.z).dot(Vector2(axis.x, axis.z))
	_water_material.set_shader_parameter("flow_offset", offset)
	_water_material.set_shader_parameter("motion_phase", 0.0 if shape == 1 else SHAPES.phase(water_seed))
	if not _shore_data.is_empty():
		_water_material.set_shader_parameter("shore_field", _shore_data.texture)
		_water_material.set_shader_parameter("field_origin", _shore_data.bounds.position)
		_water_material.set_shader_parameter("field_size", _shore_data.bounds.size)

func excludes_ground_point(world_point: Vector3) -> bool:
	var local := to_local(world_point)
	# Build on demand when a sibling grass patch becomes ready before this water.
	if _shape_data.is_empty():
		_shape_data = _make_shape_data()
	var point := Vector2(local.x, local.z)
	return Geometry2D.is_point_in_polygon(point, _shape_data.outline) or BODY.polygon_distance(point, _shape_data.outline) < 0.06

func _collect_obstacles() -> void:
	for node in _obstacle_nodes:
		if is_instance_valid(node) and node.has_signal("scenery_changed") and node.scenery_changed.is_connected(_request_rebuild):
			node.scenery_changed.disconnect(_request_rebuild)
	_obstacle_nodes.clear()
	_obstacle_regions.clear()
	for path in shore_obstacles:
		var node := get_node_or_null(path)
		if node and node is Node3D:
			_obstacle_nodes.append(node)
			if node.has_signal("scenery_changed") and not node.scenery_changed.is_connected(_request_rebuild):
				node.scenery_changed.connect(_request_rebuild)
			var before := _obstacle_regions.size()
			_collect_convex_sections(node)
			if _obstacle_regions.size() == before:
				_collect_visual_sections(node)

func _collect_convex_sections(node: Node) -> void:
	if node is CollisionShape3D and node.shape is ConvexPolygonShape3D and not node.disabled:
		var transform: Transform3D = global_transform.affine_inverse() * node.global_transform
		var polygon := SHORE_FIELD.convex_slice(node.shape.points, transform)
		if polygon.size() >= 3:
			_obstacle_regions.append(polygon)
	for child in node.get_children(true):
		_collect_convex_sections(child)

func _collect_visual_sections(node: Node) -> void:
	if node is MeshInstance3D and node.mesh:
		var transform: Transform3D = global_transform.affine_inverse() * node.global_transform
		_obstacle_regions.append_array(SHORE_FIELD.mesh_sections(node.mesh, transform))
	for child in node.get_children(true):
		_collect_visual_sections(child)

func _generated(node: Node) -> void:
	node.set_meta(&"generated_water", true)
	if node is GeometryInstance3D:
		node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		node.visibility_range_end = visibility_distance
	add_child(node, false, Node.INTERNAL_MODE_BACK)

func _triangle(surface: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, depths: Vector3, uvs: Array[Vector2] = []) -> void:
	var points := [a, b, c]
	for index in range(3):
		surface.set_color(Color(depths[index], 0.0, 0.0, 1.0))
		surface.set_normal(Vector3.UP)
		surface.set_uv(uvs[index] if uvs.size() == 3 else Vector2(points[index].x, points[index].z))
		surface.add_vertex(points[index])

func _surface_point(point: Vector2) -> Vector3:
	return Vector3(point.x, 0.035, point.y)

func rebuild() -> void:
	_queued = false
	if not is_inside_tree():
		return
	for child in get_children(true):
		if child.get_meta(&"generated_water", false):
			remove_child(child)
			child.queue_free()
	_water_material = ShaderMaterial.new()
	_water_material.shader = WATER_SHADER
	_water_material.set_shader_parameter("foam_mask", FOAM_MASK)
	_water_material.set_shader_parameter("pigment_mask", PIGMENT_MASK)
	_water_material.set_shader_parameter("normal_mask", NORMAL_MASK)
	_water_material.set_shader_parameter("caustic_mask", CAUSTIC_MASK)
	_update_materials()
	_shape_data = _make_shape_data()
	_collect_obstacles()
	_shore_data = SHORE_FIELD.bake(_shape_data, _obstacle_regions, shape == 1, cap_stream_ends, flow_direction, [64, 96, 128][shore_field_quality])
	_update_materials()
	var outline: PackedVector2Array = _shape_data.outline
	var water := SurfaceTool.new()
	water.begin(Mesh.PRIMITIVE_TRIANGLES)
	if shape == 0 and pond_outline and pond_outline.point_count >= 3:
		var indices := Geometry2D.triangulate_polygon(outline)
		for index in range(0, indices.size(), 3):
			_subdivide(water, _surface_point(outline[indices[index]]), _surface_point(outline[indices[index + 1]]), _surface_point(outline[indices[index + 2]]), 2)
	elif shape == 0:
		for ring in range(6):
			var inner := float(ring) / 6.0
			var outer := float(ring + 1) / 6.0
			for index in range(outline.size()):
				var next := (index + 1) % outline.size()
				var a := _surface_point(outline[index] * inner)
				var b := _surface_point(outline[next] * inner)
				var c := _surface_point(outline[next] * outer)
				var d := _surface_point(outline[index] * outer)
				if ring > 0:
					_triangle(water, a, b, c, Vector3(1.0 - inner, 1.0 - inner, 1.0 - outer))
				_triangle(water, a, c, d, Vector3(1.0 - inner, 1.0 - outer, 1.0 - outer))
	else:
		for row in range(outline_detail):
			for column in range(8):
				var points: Array[Vector3] = []
				var depths: Array[float] = []
				var uvs: Array[Vector2] = []
				for corner in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1), Vector2i(0, 1)]:
					var t := float(row + corner.y) / float(outline_detail)
					var u := float(column + corner.x) / 8.0
					points.append(_surface_point(_shape_data.centers[row + corner.y] + _shape_data.sides[row + corner.y] * (u * 2.0 - 1.0) * _shape_data.widths[row + corner.y]))
					var along: float = _shape_data.lengths[row + corner.y] if stream_path else (t - 0.5) * footprint.y
					uvs.append(Vector2((u * 2.0 - 1.0) * _shape_data.widths[row + corner.y], along))
					var depth := 1.0 - absf(u * 2.0 - 1.0)
					if cap_stream_ends:
						depth = minf(depth, minf(t, 1.0 - t) * footprint.y / footprint.x * 2.0)
					depths.append(depth)
				_triangle(water, points[0], points[1], points[2], Vector3(depths[0], depths[1], depths[2]), [uvs[0], uvs[1], uvs[2]])
				_triangle(water, points[0], points[2], points[3], Vector3(depths[0], depths[2], depths[3]), [uvs[0], uvs[2], uvs[3]])
	var surface := MeshInstance3D.new()
	surface.name = "PaintedWater"
	surface.mesh = water.commit()
	surface.material_override = _water_material
	surface.custom_aabb = surface.mesh.get_aabb().grow(0.025)
	_generated(surface)
	_add_shore(outline)
	ground_exclusion_changed.emit()

func _subdivide(surface: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, levels: int) -> void:
	if levels == 0 or (b - a).cross(c - a).length_squared() < 0.000003:
		# Preserve narrow boundary triangles instead of subdividing into slivers.
		_triangle(surface, a, b, c, Vector3.ONE)
		return
	var ab := (a + b) * 0.5
	var bc := (b + c) * 0.5
	var ca := (c + a) * 0.5
	_subdivide(surface, a, ab, ca, levels - 1)
	_subdivide(surface, ab, b, bc, levels - 1)
	_subdivide(surface, ca, bc, c, levels - 1)
	_subdivide(surface, ab, bc, ca, levels - 1)

func _add_shore(outline: PackedVector2Array) -> void:
	if not block_water_entry:
		return
	var body := StaticBody3D.new()
	body.name = "ShoreCollision"
	for index in range(outline.size()):
		var next := (index + 1) % outline.size()
		if shape == 1 and not cap_stream_ends and (index == outline_detail or next == 0):
			continue
		var a := _surface_point(outline[index])
		var b := _surface_point(outline[next])
		var collider := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(0.08, 0.8, a.distance_to(b) + 0.04)
		collider.shape = box
		collider.position = (a + b) * 0.5 + Vector3.UP * 0.3
		collider.rotation.y = atan2(b.x - a.x, b.z - a.z)
		body.add_child(collider)
	_generated(body)
