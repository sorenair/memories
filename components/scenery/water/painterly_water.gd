@tool
class_name PainterlyWater
extends Node3D
## Opaque painted water: no screen/depth reads, reflection probes, or per-frame uploads.
signal ground_exclusion_changed
const SHAPES = preload("res://components/scenery/water/water_shapes.gd")
const WATER_SHADER = preload("res://components/scenery/water/shaders/painted_water.gdshader")
const PAINT_MASK = preload("res://components/scenery/water/textures/water_paint.png")
const COLOR_KEYS = [&"deep_color", &"body_color", &"shallow_color", &"foam_color"]
const COLORS = [
	["175273", "2498b0", "59c9ba", "ffffff"],
	["355a9c", "6aa8d4", "b4d5d2", "fff2da"],
	["326a69", "65a996", "b8d2a0", "fff0cb"],
	["5c83a5", "9ec8da", "d5e6dd", "f5f9ed"],
	["675799", "9b8dc9", "c8b8dd", "fff1df"],
	["263e69", "426a91", "80a9b6", "d5e7df"]
]

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
@export_group("Shore")
@export var block_water_entry: bool = true:
	set(value):
		block_water_entry = value
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
## Directional painted depth for ponds; streams use a shared world field at joins.
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
	rebuild()

func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSFORM_CHANGED and is_inside_tree():
		ground_exclusion_changed.emit()

func _validate_property(property: Dictionary) -> void:
	if property.name == "palette" and palette_preset != 0:
		property.usage = property.usage & ~PROPERTY_USAGE_STORAGE

func _palette_changed() -> void:
	palette_preset = 0
	_update_materials()

func _request_rebuild() -> void:
	if is_inside_tree() and not _queued:
		_queued = true
		call_deferred("rebuild")

func _update_materials() -> void:
	if not palette:
		return
	if _water_material:
		for key in COLOR_KEYS.slice(0, 4):
			_water_material.set_shader_parameter(key, palette.get(key))
		for key in [&"flow_direction", &"flow_speed", &"ripple_scale", &"caustic_strength", &"highlight_amount", &"wave_height", &"wave_activity", &"foam_amount", &"foam_width", &"foam_cell_size"]:
			_water_material.set_shader_parameter(key, get(key))
		_water_material.set_shader_parameter("water_size", footprint)
		_water_material.set_shader_parameter("depth_gradient", depth_gradient if shape == 0 else 0.0)
		# Global phase keeps matching stream sections visually continuous.
		_water_material.set_shader_parameter("motion_phase", 0.0 if shape == 1 else SHAPES.phase(water_seed))
## Grass and other scatter components can query the same analytic shape.
func excludes_ground_point(world_point: Vector3) -> bool:
	var local := to_local(world_point)
	return SHAPES.contains(shape, Vector2(local.x, local.z), footprint, water_seed, irregularity, stream_bend, 0.06)

func _generated(node: Node) -> void:
	node.set_meta(&"generated_water", true)
	if node is GeometryInstance3D:
		node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		node.visibility_range_end = visibility_distance
	add_child(node, false, Node.INTERNAL_MODE_BACK)

func _triangle(surface: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, depths: Vector3) -> void:
	var points := [a, b, c]
	for index in range(3):
		surface.set_color(Color(depths[index], 0.0, 0.0, 1.0))
		surface.set_normal(Vector3.UP)
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
	_water_material.set_shader_parameter("paint_mask", PAINT_MASK)
	_update_materials()
	var outline := SHAPES.outline(shape, footprint, water_seed, irregularity, stream_bend, outline_detail)
	var water := SurfaceTool.new()
	water.begin(Mesh.PRIMITIVE_TRIANGLES)
	if shape == 0:
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
				for corner in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1), Vector2i(0, 1)]:
					var t := float(row + corner.y) / float(outline_detail)
					var u := float(column + corner.x) / 8.0
					points.append(_surface_point(Vector2(SHAPES.stream_center(t, footprint, stream_bend, water_seed) + (u - 0.5) * footprint.x, (t - 0.5) * footprint.y)))
					var depth := 1.0 - absf(u * 2.0 - 1.0)
					if cap_stream_ends:
						depth = minf(depth, minf(t, 1.0 - t) * footprint.y / footprint.x * 2.0)
					depths.append(depth)
				_triangle(water, points[0], points[1], points[2], Vector3(depths[0], depths[1], depths[2]))
				_triangle(water, points[0], points[2], points[3], Vector3(depths[0], depths[2], depths[3]))
	var surface := MeshInstance3D.new()
	surface.name = "PaintedWater"
	surface.mesh = water.commit()
	surface.material_override = _water_material
	surface.custom_aabb = surface.mesh.get_aabb().grow(0.025)
	_generated(surface)
	_add_shore(outline)
	ground_exclusion_changed.emit()

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
