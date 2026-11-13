extends RefCounted
## A small remembered light held in four open, curved brushstroke veils.
## All geometry lives in 3D. UV2 selects seed / veil / drifting fleck and its phase.
static var _mesh: ArrayMesh

static func create() -> ArrayMesh:
	if _mesh:
		return _mesh
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for row in range(10):
		for column in range(16):
			var uv := Vector2(column / 16.0, row / 10.0)
			var step := Vector2(1.0 / 16.0, 0.1)
			var coords := [uv, uv + Vector2(step.x, 0), uv + step, uv + Vector2(0, step.y)]
			var points: Array[Vector3] = []
			for at: Vector2 in coords:
				var angle := at.x * TAU
				var latitude := at.y * PI
				var radius := 0.48 * (1.0 + sin(angle * 3.0 + latitude * 2.0) * 0.12)
				points.append(Vector3(sin(latitude) * cos(angle), cos(latitude) * 1.12, sin(latitude) * sin(angle)) * radius)
			_quad(surface, points, coords, Vector2.ZERO)
	# Open, tapered strands at different azimuths: no hollow container or closed rings.
	for piece in range(4):
		for segment in range(28):
			for band in range(4):
				var uv := Vector2(band / 4.0, segment / 28.0)
				var step := Vector2(0.25, 1.0 / 28.0)
				var coords := [uv, uv + Vector2(step.x, 0), uv + step, uv + Vector2(0, step.y)]
				var points: Array[Vector3] = []
				for at: Vector2 in coords:
					points.append(_veil(at, piece))
				_quad(surface, points, coords, Vector2(1, piece))
	for fleck in range(16):
		var points := [Vector3.UP * 0.070, Vector3.DOWN * 0.070,
			Vector3.RIGHT * 0.026, Vector3.BACK * 0.026, Vector3.LEFT * 0.026, Vector3.FORWARD * 0.026]
		for side in range(4):
			var a: Vector3 = points[2 + side]
			var b: Vector3 = points[2 + (side + 1) % 4]
			_triangle(surface, [points[0], a, b], [Vector2(0.5, 0), Vector2(0, 0.5), Vector2(1, 0.5)], Vector2(2, fleck))
			_triangle(surface, [points[1], b, a], [Vector2(0.5, 1), Vector2(1, 0.5), Vector2(0, 0.5)], Vector2(2, fleck))
	surface.index()
	_mesh = surface.commit()
	return _mesh

static func _veil(uv: Vector2, piece: int) -> Vector3:
	var t := uv.y
	var side := uv.x * 2.0 - 1.0
	var phase := piece * 1.91
	var angle := phase + t * TAU * (0.59 + piece * 0.045)
	var opening := pow(maxf(sin(t * PI), 0.0), 0.75)
	var radius := 0.28 + opening * (0.76 + 0.08 * sin(phase))
	var center := Vector3(cos(angle) * radius, lerpf(-1.35, 1.55, t), sin(angle) * radius * 0.86)
	center.y += sin(t * TAU + phase) * 0.12
	var across := Vector3(-sin(angle), 0.20 * cos(t * PI + phase), cos(angle)).normalized()
	var width := opening * (0.38 + piece * 0.025)
	var bend := Vector3(cos(angle), 0, sin(angle)) * side * side * opening * 0.14
	return center + across * side * width + bend

static func _quad(surface: SurfaceTool, points: Array, coords: Array, tag: Vector2) -> void:
	_triangle(surface, [points[0], points[1], points[2]], [coords[0], coords[1], coords[2]], tag)
	_triangle(surface, [points[0], points[2], points[3]], [coords[0], coords[2], coords[3]], tag)

static func _triangle(surface: SurfaceTool, points: Array, coords: Array, tag: Vector2) -> void:
	var face: Vector3 = (points[1] - points[0]).cross(points[2] - points[0]).normalized()
	for index in range(3):
		var point: Vector3 = points[index]
		surface.set_normal(point.normalized() if tag.x == 0.0 else face)
		surface.set_uv(coords[index])
		surface.set_uv2(tag)
		surface.add_vertex(point)
