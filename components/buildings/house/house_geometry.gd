@tool
class_name PainterlyHouseGeometry
extends RefCounted
## Exterior bungalow kit, merged into one opaque surface. Front faces local +Z.
static func _append(s: SurfaceTool, mesh: Mesh, t: Transform3D, color: Color, kind: float = 0.0) -> void:
	var arrays := mesh.surface_get_arrays(0)
	var points: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	var normal_basis := t.basis.inverse().transposed()
	for index in indices:
		s.set_normal((normal_basis * normals[index]).normalized())
		s.set_color(color.srgb_to_linear())
		s.set_uv2(Vector2(kind, 0.0))
		s.add_vertex(t * points[index])

static func _box(s: SurfaceTool, center: Vector3, size: Vector3, color: Color, kind: float = 0.0) -> void:
	var mesh := BoxMesh.new()
	mesh.size = size.max(Vector3.ONE * 0.001)
	_append(s, mesh, Transform3D(Basis.IDENTITY, center), color, kind)

static func _quad(s: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, color: Color, kind: float = 0.0) -> void:
	var normal := (b - a).cross(c - a).normalized()
	for point in [a, b, c, a, c, d]:
		s.set_normal(normal)
		s.set_color(color.srgb_to_linear())
		s.set_uv2(Vector2(kind, 0.0))
		s.add_vertex(point)

static func _rod(s: SurfaceTool, a: Vector3, b: Vector3, radius: float, color: Color) -> void:
	var direction := b - a
	if direction.length() < 0.001:
		return
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = direction.length()
	mesh.radial_segments = 6
	mesh.rings = 1
	var y := direction.normalized()
	var x := y.cross(Vector3.BACK).normalized()
	if x.length_squared() < 0.1:
		x = y.cross(Vector3.RIGHT).normalized()
	_append(s, mesh, Transform3D(Basis(x, y, x.cross(y).normalized()), (a + b) * 0.5), color)

static func _roof_point(a: Vector3, b: Vector3, c: Vector3, d: Vector3, u: float, v: float) -> Vector3:
	return a.lerp(b, u).lerp(d.lerp(c, u), v)

static func _roof_face(s: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, color: Color, tile_size: float, rng: RandomNumberGenerator) -> void:
	_quad(s, a, b, c, d, color.darkened(0.12), 2.0)
	var normal := (b - a).cross(c - a).normalized()
	if normal.y < 0:
		normal = -normal
	var rows := maxi(1, ceili(((a + b) * 0.5).distance_to((c + d) * 0.5) / (tile_size * 0.75)))
	for row in range(rows):
		var v0 := float(row) / rows
		var v1 := minf(1.0, float(row + 1) / rows + 0.004)
		var width := a.lerp(d, v0).distance_to(b.lerp(c, v0))
		var count := maxi(1, ceili(width / tile_size))
		for column in range(count + 1):
			var stagger := 0.5 if row % 2 else 0.0
			var u0 := clampf((float(column) - stagger) / count + 0.002, 0, 1)
			var u1 := clampf((float(column + 1) - stagger) / count - 0.002, 0, 1)
			if u1 <= u0:
				continue
			# Slight seeded variation changes the brush edge, not the roof silhouette.
			var edge_drop := rng.randf_range(-0.0035, 0.0035)
			var staggered_v := clampf(v0 + edge_drop, 0.0, 1.0)
			var lift := normal * (0.018 + rng.randf_range(-0.004, 0.004))
			var p0 := _roof_point(a, b, c, d, u0, staggered_v) + lift
			var p1 := _roof_point(a, b, c, d, u1, clampf(staggered_v + rng.randf_range(-0.0015, 0.0015), 0.0, 1.0)) + lift
			var p2 := _roof_point(a, b, c, d, u1, v1) + lift * 0.4
			var p3 := _roof_point(a, b, c, d, u0, v1) + lift * 0.4
			var pigment := rng.randf_range(-0.035, 0.035)
			var paint := color.lightened(maxf(0, pigment)).darkened(maxf(0, -pigment))
			_quad(s, p0, p1, p2, p3, paint, 2.0)
			_quad(s, p0 - normal * 0.015, p1 - normal * 0.015, p1, p0, paint.darkened(0.08), 2.0)

static func _hip_roof(s: SurfaceTool, center: Vector3, size: Vector2, rise: float, color: Color, trim: Color, tiles: float, rng: RandomNumberGenerator) -> void:
	var x := size.x * 0.5
	var z := size.y * 0.5
	var ridge := maxf(0.04, (size.x - size.y) * 0.5)
	var a := center + Vector3(-x, 0, z)
	var b := center + Vector3(x, 0, z)
	var c := center + Vector3(x, 0, -z)
	var d := center + Vector3(-x, 0, -z)
	var left := center + Vector3(-ridge, rise, 0)
	var right := center + Vector3(ridge, rise, 0)
	_roof_face(s, a, b, right, left, color, tiles, rng)
	_roof_face(s, c, d, left, right, color, tiles, rng)
	_roof_face(s, b, c, right, right, color, tiles, rng)
	_roof_face(s, d, a, left, left, color, tiles, rng)
	for pair in [[a, left], [b, right], [c, right], [d, left], [left, right]]:
		_rod(s, pair[0] + Vector3.UP * 0.035, pair[1] + Vector3.UP * 0.035, 0.035, color.lightened(0.06))
	_box(s, center + Vector3(0, -0.065, z), Vector3(size.x + 0.04, 0.15, 0.10), trim)
	_box(s, center + Vector3(0, -0.065, -z), Vector3(size.x + 0.04, 0.15, 0.10), trim)
	_box(s, center + Vector3(-x, -0.065, 0), Vector3(0.10, 0.15, size.y), trim)
	_box(s, center + Vector3(x, -0.065, 0), Vector3(0.10, 0.15, size.y), trim)

static func _window(s: SurfaceTool, center: Vector3, size: Vector2, trim: Color, wood: Color, glass: Color, side: bool = false, warmth: float = 0.35) -> void:
	# Build in front-facing coordinates, then optionally rotate onto the right wall.
	var temp := SurfaceTool.new()
	temp.begin(Mesh.PRIMITIVE_TRIANGLES)
	var w := size.x
	var h := size.y
	_box(temp, Vector3.ZERO, Vector3(w + 0.18, h + 0.18, 0.10), wood.darkened(0.15))
	var window_paint := glass.lerp(Color("b7a187"), warmth * 0.24)
	_box(temp, Vector3(0, 0, 0.057), Vector3(w, h, 0.025), window_paint, 3.0)
	# Broad interior/curtain washes replace the identical diagonal stripe.
	# These remain opaque painted geometry rather than glass/reflection passes.
	_quad(temp, Vector3(-w * 0.48, -h * 0.48, 0.073), Vector3(w * 0.48, -h * 0.48, 0.073), Vector3(w * 0.48, -h * 0.06, 0.073), Vector3(-w * 0.48, h * 0.02, 0.073), window_paint.darkened(0.10), 3.0)
	var curtain := window_paint.lerp(trim, 0.22 + warmth * 0.12)
	_quad(temp, Vector3(-w * 0.47, -h * 0.42, 0.074), Vector3(-w * 0.34, -h * 0.31, 0.074), Vector3(-w * 0.29, h * 0.46, 0.074), Vector3(-w * 0.47, h * 0.46, 0.074), curtain, 3.0)
	_quad(temp, Vector3(w * 0.33, -h * 0.30, 0.074), Vector3(w * 0.47, -h * 0.43, 0.074), Vector3(w * 0.47, h * 0.46, 0.074), Vector3(w * 0.28, h * 0.46, 0.074), curtain.darkened(0.06), 3.0)
	_quad(temp, Vector3(-w * 0.28, h * 0.03, 0.075), Vector3(w * 0.06, h * 0.09, 0.075), Vector3(w * 0.10, h * 0.43, 0.075), Vector3(-w * 0.25, h * 0.43, 0.075), window_paint.lightened(0.11), 3.0)
	_quad(temp, Vector3(w * 0.08, -h * 0.31, 0.075), Vector3(w * 0.29, -h * 0.28, 0.075), Vector3(w * 0.27, -h * 0.05, 0.075), Vector3(w * 0.10, -h * 0.08, 0.075), window_paint.lerp(Color("d6b574"), warmth * 0.34 + 0.04), 3.0)
	for x in [-w * 0.5, 0.0, w * 0.5]:
		_box(temp, Vector3(x, 0, 0.09), Vector3(0.055, h + 0.09, 0.055), trim)
	for y in [-h * 0.5, 0.0, h * 0.5]:
		_box(temp, Vector3(0, y, 0.09), Vector3(w + 0.08, 0.055, 0.055), trim)
	_box(temp, Vector3(0, -h * 0.5 - 0.10, 0.04), Vector3(w + 0.32, 0.14, 0.25), wood)
	var mesh := temp.commit()
	var arrays := mesh.surface_get_arrays(0)
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var colors: PackedColorArray = arrays[Mesh.ARRAY_COLOR]
	var paint_kinds: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV2]
	var rotation := Basis(Vector3.UP, PI * 0.5) if side else Basis.IDENTITY
	for index in range(vertices.size()):
		s.set_normal(rotation * normals[index])
		s.set_color(colors[index])
		s.set_uv2(paint_kinds[index])
		s.add_vertex(center + rotation * vertices[index])

static func create(c: Dictionary) -> ArrayMesh:
	var s := SurfaceTool.new()
	s.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rng := RandomNumberGenerator.new()
	rng.seed = c.house_seed
	var size: Vector2 = c.footprint
	var h: float = c.wall_height
	var floor_y: float = c.foundation_height
	var top := floor_y + h
	var front := size.y * 0.5
	var wall: Color = c.wall_color
	var trim: Color = c.trim_color
	var wood: Color = c.wood_color
	var roof: Color = c.roof_color
	var glass: Color = c.glass_color
	_box(s, Vector3(0, floor_y * 0.5, 0), Vector3(size.x + 0.08, floor_y, size.y + 0.08), c.foundation_color)
	_box(s, Vector3(0, floor_y + h * 0.5, 0), Vector3(size.x, h, size.y), wall, 1.0)
	# Quiet plaster pigment at the foot of the facade; windows stay clean.
	for index in range(14):
		var x := rng.randf_range(-size.x * 0.47, size.x * 0.47)
		var y := floor_y + rng.randf_range(0.08, 0.43)
		_box(s, Vector3(x, y, front + 0.003), Vector3(rng.randf_range(0.15, 0.45), rng.randf_range(0.08, 0.22), 0.005), wall.darkened(rng.randf_range(0.005, 0.025)), 1.0)
	for x in [-size.x * 0.5, size.x * 0.5]:
		for z in [-front, front]:
			_box(s, Vector3(x, floor_y + h * 0.5, z), Vector3(0.11, h, 0.11), trim)
	var window_size := Vector2(size.x * 0.245, h * 0.49)
	for x in [-size.x * 0.30, size.x * 0.30]:
		_window(s, Vector3(x, floor_y + h * 0.57, front + 0.055), window_size, trim, wood, glass, false, c.window_warmth)
	if c.side_windows:
		for z in [-size.y * 0.25, size.y * 0.22]:
			_window(s, Vector3(size.x * 0.5 + 0.055, floor_y + h * 0.57, z), Vector2(size.y * 0.20, h * 0.46), trim, wood, glass, true, c.window_warmth)
	var door_height := h * 0.74
	var door_width: float = c.door_width
	_box(s, Vector3(0, floor_y + door_height * 0.5, front + 0.025), Vector3(door_width + 0.14, door_height + 0.08, 0.09), wood)
	_box(s, Vector3(0, floor_y + door_height * 0.5, front + 0.08), Vector3(door_width, door_height, 0.08), trim)
	_box(s, Vector3(0, floor_y + door_height * 0.69, front + 0.125), Vector3(door_width * 0.64, door_height * 0.36, 0.02), glass.lightened(0.08).lerp(Color("b7a187"), c.window_warmth * 0.2), 3.0)
	_box(s, Vector3(0, floor_y + door_height * 0.26, front + 0.13), Vector3(door_width * 0.65, door_height * 0.28, 0.035), trim.darkened(0.04))
	_box(s, Vector3(0, floor_y + door_height * 0.68, front + 0.145), Vector3(door_width * 0.69, 0.04, 0.035), trim)
	_rod(s, Vector3(door_width * 0.35, floor_y + door_height * 0.44, front + 0.13), Vector3(door_width * 0.35, floor_y + door_height * 0.44, front + 0.19), 0.025, Color("a89165"))
	if c.porch_lamp:
		var lamp_y := floor_y + door_height + 0.16
		_box(s, Vector3(0, lamp_y, front + 0.06), Vector3(0.19, 0.24, 0.07), c.rail_color)
		_box(s, Vector3(0, lamp_y, front + 0.115), Vector3(0.125, 0.165, 0.07), Color("ffdc98"), 4.0)
		_box(s, Vector3(0, lamp_y + 0.14, front + 0.11), Vector3(0.27, 0.04, 0.20), c.rail_color)
		_box(s, Vector3(0, lamp_y - 0.13, front + 0.11), Vector3(0.21, 0.035, 0.16), c.rail_color)
	var run: float = c.step_depth * c.step_count
	for index in range(c.step_count):
		var height: float = floor_y * (1.0 - float(index) / c.step_count)
		_box(s, Vector3(0, height * 0.5, front + c.step_depth * (index + 0.5)), Vector3(c.stair_width, height, c.step_depth + 0.015), c.foundation_color)
	if c.railings:
		for side in [-1.0, 1.0]:
			var a := Vector3(side * c.stair_width * 0.53, floor_y + 0.82, front + 0.1)
			var b := Vector3(side * c.stair_width * 0.53, 0.82, front + run)
			_rod(s, a, b, 0.025, c.rail_color)
			for post in range(4):
				var t := float(post) / 3.0
				var point := a.lerp(b, t)
				_rod(s, point - Vector3.UP * 0.81, point, 0.018, c.rail_color)
			_rod(s, a - Vector3.UP * 0.34, b - Vector3.UP * 0.34, 0.014, c.rail_color)
	var roof_size: Vector2 = size + Vector2.ONE * c.roof_overhang * 2.0
	_hip_roof(s, Vector3(0, top, 0), roof_size, c.roof_height, roof, trim, c.shingle_size, rng)
	if c.dormer:
		var z: float = roof_size.y * 0.31
		var bottom: float = top + c.roof_height * 0.38 - 0.08
		var dormer_top: float = top + c.roof_height - 0.20
		var width := size.x * 0.26
		var depth := size.y * 0.22
		_box(s, Vector3(0, (bottom + dormer_top) * 0.5, z - depth * 0.5), Vector3(width, dormer_top - bottom, depth), wall, 1.0)
		_window(s, Vector3(0, (bottom + dormer_top) * 0.5, z + 0.04), Vector2(width * 0.74, (dormer_top - bottom) * 0.68), trim, wood, glass, false, c.window_warmth)
		_hip_roof(s, Vector3(0, dormer_top, z - depth * 0.5), Vector2(width + 0.3, depth + 0.3), c.roof_height * 0.23, roof, trim, c.shingle_size * 0.75, rng)
	return s.commit()
