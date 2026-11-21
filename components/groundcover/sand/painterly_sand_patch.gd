@tool
class_name PainterlySandPatch
extends PainterlySnowPatch
## Reuses the snow's step field, stride tracking, shape and exclusion lifecycle.
## Real static dune geometry and matching collision replace its shallow snow relief.
const SAND_SHADER = preload("res://components/groundcover/sand/sand_ground.gdshader")
const RECALL = preload("res://components/effects/recall/component_recall.gd")
@export_group("Dune Terrain")
@export_enum("Wind-shaped Dunes", "Rolling Hills") var terrain_form: int = 0:
	set(value):
		terrain_form = clampi(value, 0, 1)
		_request_rebuild()
@export_range(0.0, 5.0, 0.05) var dune_height: float = 1.35:
	set(value):
		dune_height = clampf(value, 0, 5)
		_request_rebuild()
@export_range(2.5, 16.0, 0.25) var dune_spacing: float = 6.5:
	set(value):
		dune_spacing = clampf(value, 2.5, 16)
		_request_rebuild()
@export_range(-180.0, 180.0, 1.0) var dune_direction: float = 25.0:
	set(value):
		dune_direction = value
		_request_rebuild()
## Optional sculpted crests. Entries store local X, local Z, rise and half-length.
## Dune Direction crosses the ridges; Dune Spacing controls their slope width.
@export var dune_crests := PackedVector4Array():
	set(value):
		dune_crests = value
		_request_rebuild()
@export_range(0.5, 5.0, 0.1) var edge_feather: float = 2.2:
	set(value):
		edge_feather = clampf(value, 0.5, 5)
		_request_rebuild()
@export_group("Sand Paint")
@export var sand_color := Color("e9cfa0"):
	set(value):
		sand_color = value
		_update_material()
@export var shadow_color := Color("ac805b"):
	set(value):
		shadow_color = value
		_update_material()
@export_range(0.0, 1.0, 0.05) var ripple_strength: float = 0.38:
	set(value):
		ripple_strength = clampf(value, 0, 1)
		_update_material()
@export_group("Terrain Collision")
@export var collision_enabled: bool = true:
	set(value):
		collision_enabled = value
		_request_rebuild()
@export_group("Recall")
@export var recall_anchor: Node3D
@export var recall_enabled: bool = false:
	set(value):
		recall_enabled = value
		if is_node_ready() and not Engine.is_editor_hint():
			_sync_recall()
@export_tool_button("Rebuild sand") var regenerate_sand = rebuild
var _cutouts: Array[PackedVector2Array] = []
var _cutout_bounds: Array[Rect2] = []
var _recall_effect: Node

func _validate_property(property: Dictionary) -> void:
	if property.name in ["snow_depth", "puffiness", "snow_color", "shade_color"]:
		property.usage &= ~PROPERTY_USAGE_EDITOR
	elif property.name == "Snow Patch":
		property.name = "Surface Shape"
	elif property.name == "Snow Colors":
		property.name = "Ground Blend"

func _prepare_shape() -> void:
	super._prepare_shape()
	_noise.frequency = 0.14
	if not _custom_shape:
		for i in range(80):
			var a := TAU * i / 80.0
			_outline.append(Vector2(cos(a), sin(a)) * patch_size * 0.5 * _radius(a))
		_shape_bounds = Rect2(_outline[0], Vector2.ZERO)
		for point in _outline:
			_shape_bounds = _shape_bounds.expand(point)

func _bake_coverage() -> void:
	super._bake_coverage()
	_cutouts.clear()
	_cutout_bounds.clear()
	for region in _ground_regions:
		if not is_instance_valid(region) or not region.has_method("get_ground_outline"):
			continue
		var polygon := PackedVector2Array()
		for world: Vector3 in region.get_ground_outline():
			var local := to_local(world)
			polygon.append(Vector2(local.x, local.z))
		if polygon.size() < 3:
			continue
		if Geometry2D.is_polygon_clockwise(polygon):
			polygon.reverse()
		_cutouts.append(polygon)
		var bounds := Rect2(polygon[0], Vector2.ZERO)
		for point in polygon:
			bounds = bounds.expand(point)
		_cutout_bounds.append(bounds)

func _edge_distance(point: Vector2) -> float:
	var radial := _radial(point)
	var distance := maxf(0.0, (1.0 - radial) * (0.75 if _custom_shape else minf(patch_size.x, patch_size.y) * 0.5))
	for i in range(_cutouts.size()):
		if not _cutout_bounds[i].grow(edge_feather).has_point(point):
			continue
		var polygon := _cutouts[i]
		if Geometry2D.is_point_in_polygon(point, polygon):
			return 0.0
		for j in range(polygon.size()):
			distance = minf(distance, point.distance_to(Geometry2D.get_closest_point_to_segment(point, polygon[j], polygon[(j + 1) % polygon.size()])))
	return distance

func _height(point: Vector2) -> float:
	if not _noise:
		return 0.004
	var distance := _edge_distance(point)
	var bank := smoothstep(0.0, edge_feather, distance)
	if not dune_crests.is_empty():
		return 0.004 + bank * (0.12 + _crest_height(point))
	var q := (point - _field_center).rotated(-deg_to_rad(dune_direction))
	var phase := float(posmod(patch_seed, 997)) * 0.071
	var warp := _noise.get_noise_2d(q.y * 0.60 + 55, q.x * 0.18) * dune_spacing * 0.55
	var a := (q.x + warp) * TAU / dune_spacing + phase
	var b := q.y * TAU / dune_spacing * 0.68 + phase * 0.7
	var swell: float
	if terrain_form == 0:
		# Broad windward slope and a shorter lee shoulder; warped crests avoid stripes.
		swell = pow(0.5 + 0.5 * sin(a + 0.28 * sin(a)), 1.45) * (0.78 + 0.22 * cos(b * 0.52))
	else:
		swell = pow((0.5 + 0.5 * sin(a * 0.72)) * (0.5 + 0.5 * sin(b)), 0.8)
	return 0.004 + bank * (0.035 + dune_height * (0.09 + swell * 0.91))

func _crest_height(point: Vector2) -> float:
	var height := 0.0
	var angle := -deg_to_rad(dune_direction)
	for crest in dune_crests:
		var q := (point - Vector2(crest.x, crest.y)).rotated(angle)
		var along := absf(q.y) / maxf(1.0, crest.w)
		# The ends of each crescent curve downwind and fall back into the sand.
		var across := q.x - 1.75 * (minf(along, 1.4) ** 2.0)
		var flank := dune_spacing * (0.67 if across < 0.0 else 0.57)
		var profile := 1.0 - smoothstep(0.0, flank, absf(across))
		var taper := 1.0 - smoothstep(0.12, 1.23, along)
		var ridge := crest.z * profile * taper
		# Round the meeting of two lee slopes without filling their swale.
		var overlap := 1.0 - clampf(absf(height - ridge) / 0.38, 0.0, 1.0)
		var smoothing := smoothstep(0.0, 0.38, minf(height, ridge))
		height = maxf(height, ridge) + 0.095 * overlap * overlap * smoothing
	return height

func _oval_mesh_arrays() -> Array:
	return _terrain_arrays()

func _custom_mesh_arrays() -> Array:
	return _terrain_arrays()

func _terrain_arrays() -> Array:
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = PackedVector3Array()
	arrays[Mesh.ARRAY_NORMAL] = PackedVector3Array()
	arrays[Mesh.ARRAY_TEX_UV] = PackedVector2Array()
	arrays[Mesh.ARRAY_COLOR] = PackedColorArray()
	arrays[Mesh.ARRAY_INDEX] = PackedInt32Array()
	var cache := {}
	var spacing := maxf(_shape_bounds.size.x, _shape_bounds.size.y) / mesh_detail
	var columns := maxi(1, ceili(_shape_bounds.size.x / spacing))
	var rows := maxi(1, ceili(_shape_bounds.size.y / spacing))
	var cell := _shape_bounds.size / Vector2(columns, rows)
	for row in range(rows):
		for column in range(columns):
			var start := _shape_bounds.position + Vector2(column, row) * cell
			var rectangle := PackedVector2Array([start, start + Vector2(cell.x, 0), start + cell, start + Vector2(0, cell.y)])
			var pieces: Array[PackedVector2Array] = Geometry2D.intersect_polygons(_outline, rectangle)
			for i in range(_cutouts.size()):
				if not Rect2(start, cell).intersects(_cutout_bounds[i]):
					continue
				var clipped: Array[PackedVector2Array] = []
				for piece in pieces:
					clipped.append_array(Geometry2D.clip_polygons(piece, _cutouts[i]))
				pieces = clipped
			for polygon in pieces:
				if Geometry2D.is_polygon_clockwise(polygon):
					continue
				var ids := Geometry2D.triangulate_polygon(polygon)
				for index in range(0, ids.size(), 3):
					var a := polygon[ids[index]]
					var b := polygon[ids[index + 1]]
					var c := polygon[ids[index + 2]]
					if absf((b - a).cross(c - a)) < 0.00000001:
						continue
					if _ground_excluded(to_global(Vector3((a.x + b.x + c.x) / 3, 0, (a.y + b.y + c.y) / 3))):
						continue
					if (b - a).cross(c - a) > 0:
						var swap := b
						b = c
						c = swap
					for point in [a, b, c]:
						var key := Vector2i(roundi(point.x * 100000), roundi(point.y * 100000))
						if not cache.has(key):
							cache[key] = arrays[Mesh.ARRAY_VERTEX].size()
							arrays[Mesh.ARRAY_VERTEX].append(Vector3(point.x, _height(point), point.y))
							arrays[Mesh.ARRAY_NORMAL].append(_local_normal(point))
							arrays[Mesh.ARRAY_TEX_UV].append(_point_to_uv(point))
							arrays[Mesh.ARRAY_COLOR].append(Color(1.0 - clampf(_edge_distance(point) / 0.8, 0, 1), 0, 0, 1))
						arrays[Mesh.ARRAY_INDEX].append(cache[key])
	return arrays

func _local_normal(point: Vector2) -> Vector3:
	var dx := (_height(point + Vector2(0.025, 0)) - _height(point - Vector2(0.025, 0))) / 0.05
	var dz := (_height(point + Vector2(0, 0.025)) - _height(point - Vector2(0, 0.025))) / 0.05
	return Vector3(-dx, 1, -dz).normalized()

func _update_material() -> void:
	if not _material:
		return
	_material.shader = SAND_SHADER
	super._update_material()
	_material.set_shader_parameter("sand_color", sand_color)
	_material.set_shader_parameter("shadow_color", shadow_color)
	_material.set_shader_parameter("ripple_strength", ripple_strength)
	_material.set_shader_parameter("dune_direction", deg_to_rad(dune_direction))
	_material.set_shader_parameter("paint_phase", float(posmod(patch_seed, 997)) * 0.071)

func rebuild() -> void:
	super.rebuild()
	if not is_inside_tree():
		return
	var visual := get_node_or_null("SnowSurface") as MeshInstance3D
	if not visual:
		_sync_recall()
		return
	visual.name = "SandSurface"
	if collision_enabled:
		var body := StaticBody3D.new()
		body.name = "SandCollision"
		body.set_meta(&"generated_snow_patch", true)
		var shape := CollisionShape3D.new()
		var terrain := ConcavePolygonShape3D.new()
		terrain.backface_collision = true
		terrain.set_faces(visual.mesh.get_faces())
		shape.shape = terrain
		body.add_child(shape)
		add_child(body, false, Node.INTERNAL_MODE_BACK)
	_sync_recall()

func stamp_footprint(world_point: Vector3, world_forward: Vector3) -> bool:
	var local := to_local(world_point)
	if absf(local.y - _height(Vector2(local.x, local.z))) > 0.30:
		return false
	# Reuse snow's timestamp/stride implementation after validating terrain height.
	return super.stamp_footprint(to_global(Vector3(local.x, 0, local.z)), world_forward)

func get_surface_height(world_point: Vector3) -> float:
	var local := to_local(world_point)
	return to_global(Vector3(local.x, _height(Vector2(local.x, local.z)), local.z)).y

func get_surface_normal(world_point: Vector3) -> Vector3:
	var local := to_local(world_point)
	return (global_basis.inverse().transposed() * _local_normal(Vector2(local.x, local.z))).normalized()

func get_ground_outline() -> PackedVector3Array:
	var result := PackedVector3Array()
	for point in _outline:
		result.append(to_global(Vector3(point.x, 0, point.y)))
	return result

func get_recall_controller() -> Node:
	return _recall_effect

func get_recall_anchor() -> Node3D:
	return recall_anchor

func _sync_recall() -> void:
	_recall_effect = RECALL.configure(self, "res://components/effects/recall/assembled_recall.gd", _recall_effect)
	if not recall_enabled:
		preload("res://components/effects/recall/assembled_recall.gd").restore_component(self)
