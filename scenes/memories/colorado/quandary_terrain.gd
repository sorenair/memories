@tool
extends PainterlyConcertComponent
## Cut faces and steep banks around the rock ledges and summit saddle.
## The route curves describe the tread elevation. Their surrounding rock and
## the collision are generated together so the climbing surface stays flush.
const ROCK_PAINT = preload("res://scenes/memories/colorado/quandary_rock.gdshader")
const TREAD_HALF_WIDTH := 1.25

@export var stone_palette: StonePalette
@export var ascent: Path3D
@export var descent: Path3D
@export var crown := Vector3(0.0, 3.6, -1.0):
	set(value):
		crown = value
		_request_rebuild()
@export var crown_extent := Vector2(6.1, 5.25):
	set(value):
		crown_extent = value.max(Vector2.ONE)
		_request_rebuild()
## Irregular outer edge in local X/Z meters. Ends taper into the memory floor.
@export var outline: PackedVector2Array:
	set(value):
		outline = value
		_request_rebuild()

var _segments: Array[Vector4] = []
var _grades: Array[Vector2] = []
var _rock_mesh: ArrayMesh

func _ready() -> void:
	for route in [ascent, descent]:
		if route and route.curve and not route.curve.changed.is_connected(_request_rebuild):
			route.curve.changed.connect(_request_rebuild)
	super._ready()

func _build_geometry() -> Dictionary:
	_rock_mesh = ArrayMesh.new()
	_sample_routes()
	if outline.size() < 3 or _segments.is_empty():
		return {"mesh": _rock_mesh}

	var rim := _rim_points()
	var points := rim.duplicate()
	var bounds := Rect2(outline[0], Vector2.ZERO)
	for point in outline:
		bounds = bounds.expand(point)
	var rng := RandomNumberGenerator.new()
	rng.seed = prop_seed
	# Keep large faces on the shoulders and resolve only the walking grade finely.
	_add_samples(points, bounds, rng, 1.38, false)
	_add_samples(points, bounds, rng, 0.47, true)
	var vertices := PackedVector3Array()
	for point in points:
		var route := _tread_at(point)
		vertices.append(Vector3(point.x, _elevation(point, route), point.y))

	var indices := Geometry2D.triangulate_delaunay(points)
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(0, indices.size(), 3):
		var a := indices[i]
		var b := indices[i + 1]
		var c := indices[i + 2]
		var center := (points[a] + points[b] + points[c]) / 3.0
		if not Geometry2D.is_point_in_polygon(center, outline):
			continue
		# Discard hull triangles that cross concave gaps in the silhouette.
		if not _inside_edge(points[a], points[b]) or not _inside_edge(points[b], points[c]) or not _inside_edge(points[c], points[a]):
			continue
		# Godot uses clockwise faces. Keep the visible/colliding side facing up.
		var normal := (vertices[c] - vertices[a]).cross(vertices[b] - vertices[a]).normalized()
		if normal.y < 0.0:
			var swap := b
			b = c
			c = swap
			normal = -normal
		# Coherent tint across a slab, with small jumps at the natural joints.
		var panel := floori((center.x + center.y * 0.52) * 0.69)
		var tint := float(posmod(panel * 19 + prop_seed, 17)) / 16.0
		_emit_face(surface, vertices[a], vertices[b], vertices[c], normal, tint)
	_add_cliff_faces(surface, rim, vertices)
	surface.commit(_rock_mesh)
	return {"mesh": _rock_mesh}

func _add_samples(
	points: PackedVector2Array, bounds: Rect2, rng: RandomNumberGenerator,
	spacing: float, tread_samples: bool
) -> void:
	for row in range(ceili(bounds.size.y / spacing)):
		for column in range(ceili(bounds.size.x / spacing)):
			var point := bounds.position + Vector2(column, row) * spacing
			point += Vector2(rng.randf_range(-0.25, 0.25), rng.randf_range(-0.25, 0.25)) * spacing
			if not Geometry2D.is_point_in_polygon(point, outline):
				continue
			var beside_tread := absf(_tread_at(point).y) < 1.65
			if beside_tread == tread_samples:
				points.append(point)

func _emit_face(surface: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, normal: Vector3, tint: float) -> void:
	surface.set_color(Color(tint, 0.0, 0.0))
	surface.set_normal(normal)
	surface.add_vertex(a)
	surface.add_vertex(b)
	surface.add_vertex(c)

func _rim_points() -> PackedVector2Array:
	# Anchor concave corners in the triangulation so the top meets the face at
	# the narrow notches. Authored straight edges keep the same silhouette.
	var rim := PackedVector2Array()
	for i in outline.size():
		var a := outline[i]
		var b := outline[(i + 1) % outline.size()]
		var steps := maxi(1, ceili(a.distance_to(b) / 0.68))
		for step in steps:
			rim.append(a.lerp(b, float(step) / steps))
	return rim

func _add_cliff_faces(surface: SurfaceTool, rim: PackedVector2Array, top: PackedVector3Array) -> void:
	# Explicit rock faces, with long planes raked back into the buried foot.
	# Their upper vertices are the very same points as the walkable top.
	var foot := PackedVector3Array()
	var clockwise := Geometry2D.is_polygon_clockwise(outline)
	for i in rim.size():
		var previous := rim[posmod(i - 1, rim.size())]
		var next := rim[(i + 1) % rim.size()]
		var edge := (next - previous).normalized()
		var outward := Vector2(edge.y, -edge.x)
		if clockwise:
			outward = -outward
		var shoulder := rim[i] + outward * minf(0.62, maxf(0.0, top[i].y * 0.21))
		foot.append(Vector3(shoulder.x, -0.48, shoulder.y))

	for i in rim.size():
		var next := (i + 1) % rim.size()
		var a := top[i]
		var b := top[next]
		var below_a := foot[i]
		var below_b := foot[next]
		var center := (rim[i] + rim[next]) * 0.5
		var panel := floori((center.x + center.y * 0.52) * 0.69)
		var tint := float(posmod(panel * 19 + prop_seed, 17)) / 16.0
		var wall_normal := (below_a - a).cross(b - a).normalized()
		var outward := ((below_a + below_b) - (a + b)) * Vector3(1.0, 0.0, 1.0)
		if wall_normal.dot(outward) < 0.0:
			_emit_face(surface, a, below_a, b, -wall_normal, tint)
			_emit_face(surface, b, below_a, below_b, -wall_normal, tint)
		else:
			_emit_face(surface, a, b, below_a, wall_normal, tint)
			_emit_face(surface, b, below_b, below_a, wall_normal, tint)

func _sample_routes() -> void:
	_segments.clear()
	_grades.clear()
	for route in [ascent, descent]:
		if not route or not route.curve:
			continue
		var length: float = route.curve.get_baked_length()
		var steps := maxi(1, ceili(length / 0.45))
		var previous := to_local(route.to_global(route.curve.sample_baked(0.0)))
		for index in range(1, steps + 1):
			var current := to_local(route.to_global(route.curve.sample_baked(length * index / steps)))
			_segments.append(Vector4(previous.x, previous.z, current.x, current.z))
			_grades.append(Vector2(previous.y, current.y))
			previous = current

## The tread's grade in X and its distance from here in Y. Negative Y points uphill.
func _tread_at(point: Vector2) -> Vector2:
	var nearest := INF
	var result := Vector2.ZERO
	for i in _segments.size():
		var segment := _segments[i]
		var start := Vector2(segment.x, segment.y)
		var direction := Vector2(segment.z, segment.w) - start
		var offset := point - start
		var weight := clampf(offset.dot(direction) / maxf(direction.length_squared(), 0.0001), 0.0, 1.0)
		var separation := offset - direction * weight
		var squared := separation.length_squared()
		if squared < nearest:
			nearest = squared
			var side := -1.0 if direction.cross(offset) < 0.0 else 1.0
			result = Vector2(lerpf(_grades[i].x, _grades[i].y, weight), sqrt(squared) * side)
	return result

func _elevation(point: Vector2, tread: Vector2) -> float:
	var distance := absf(tread.y)
	var crown_distance := ((point - Vector2(crown.x, crown.z)) / crown_extent).length()
	var rise := smoothstep(0.12, 1.7, tread.x)
	# The narrow cut has a rising inner face and a lower outer lip.
	# A few strong planes replace the previous rolling surface profile.
	var flank := clampf((distance - TREAD_HALF_WIDTH) / 1.6, 0.0, 1.0)
	var rib := 1.0 - absf(fposmod(point.x * 0.42 - point.y * 0.28, 2.0) - 1.0)
	var ledge := tread.x
	if tread.y < 0.0:
		ledge += flank * rise * (0.83 + rib * 0.51)
	else:
		ledge -= flank * rise * (0.71 + rib * 0.38)
	# The saddle is an exposed sheet of bedrock, open around the goats.
	return lerpf(ledge, crown.y, 1.0 - smoothstep(0.82, 1.09, crown_distance))

func _inside_edge(a: Vector2, b: Vector2) -> bool:
	return Geometry2D.is_point_in_polygon((a + b) * 0.5, outline)

func _apply_material() -> void:
	if not _material:
		return
	_material.shader = ROCK_PAINT
	if stone_palette:
		_material.set_shader_parameter("shadow_color", stone_palette.shadow_color)
		_material.set_shader_parameter("mid_color", stone_palette.mid_color)
		_material.set_shader_parameter("highlight_color", stone_palette.highlight_color)

func _build_details() -> void:
	if not collision_enabled or _rock_mesh.get_surface_count() == 0:
		return
	var walking_surface := StaticBody3D.new()
	walking_surface.name = "WalkingSurface"
	var shape := CollisionShape3D.new()
	shape.shape = _rock_mesh.create_trimesh_shape()
	walking_surface.add_child(shape)
	_generated_root.add_child(walking_surface)
