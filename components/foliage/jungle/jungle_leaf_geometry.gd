@tool
@static_unload
extends RefCounted
## Opaque folded botanical silhouettes. Shared once per form, no texture cards.
static var _cache: Dictionary = {}

static func mesh_for(form: int) -> ArrayMesh:
	if _cache.has(form):
		return _cache[form]
	var s := SurfaceTool.new()
	s.begin(Mesh.PRIMITIVE_TRIANGLES)
	if form == 0 or form == 5:
		_pinnate(s, 15 if form == 0 else 14, form == 5)
	elif form == 1:
		_fan(s)
	else:
		_broad(s, form)
	s.index()
	var mesh := s.commit()
	_cache[form] = mesh
	return mesh

static func _tri(s: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, tone: float = 0.5) -> void:
	if (b - a).cross(c - a).length_squared() < 0.0000000001:
		return
	var normal := (b - a).cross(c - a).normalized()
	if normal.y < 0:
		normal = -normal
	for point in [a, b, c]:
		s.set_normal(normal)
		s.set_color(Color(tone, 0.5, 0.5, 1))
		# Tip-weighted motion leaves the real root fixed to its stem.
		s.set_uv(Vector2(point.x, clampf(Vector2(point.x, point.z).length() / 1.15, 0, 1)))
		s.add_vertex(point)

static func _spine(t: float, fern: bool = false) -> Vector3:
	return Vector3(0, sin(t * PI * 0.92) * (0.42 if fern else 0.34) - t * t * 0.27, t * 1.12)

static func _leaflet(s: SurfaceTool, start: Vector3, end: Vector3, width: float, tone: float) -> void:
	var delta := end - start
	var side := Vector3(-delta.z, 0, delta.x).normalized()
	for row in range(4):
		var t0 := float(row) / 4.0
		var t1 := float(row + 1) / 4.0
		var c0 := start.lerp(end, t0) + Vector3.UP * sin(t0 * PI) * 0.018
		var c1 := start.lerp(end, t1) + Vector3.UP * sin(t1 * PI) * 0.018
		var w0 := sin(t0 * PI) * width
		var w1 := sin(t1 * PI) * width
		for sign_value: float in [-1.0, 1.0]:
			var a := c0 + side * sign_value * w0 - Vector3.UP * w0 * 0.20
			var b := c1 + side * sign_value * w1 - Vector3.UP * w1 * 0.20
			_tri(s, c0, a, b, tone)
			if row < 3:
				_tri(s, c0, b, c1, tone + 0.06)

static func _pinnate(s: SurfaceTool, pairs: int, fern: bool) -> void:
	for row in range(12):
		var a := _spine(float(row) / 12, fern)
		var b := _spine(float(row + 1) / 12, fern)
		_tri(s, a + Vector3.LEFT * 0.012, b + Vector3.LEFT * 0.008, b + Vector3.RIGHT * 0.008, 0.76)
		_tri(s, a + Vector3.LEFT * 0.012, b + Vector3.RIGHT * 0.008, a + Vector3.RIGHT * 0.012, 0.70)
	for pair in range(pairs):
		var t := 0.08 + float(pair) / float(pairs) * 0.85
		var width := pow(sin((t * 0.88 + 0.08) * PI), 0.8) * (0.29 if fern else 0.31)
		for side: float in [-1.0, 1.0]:
			var origin := _spine(t + side * 0.006, fern)
			var tip := origin + Vector3(side * width, -0.07 * t, 0.11 + t * 0.025)
			_leaflet(s, origin, tip, 0.039, 0.40 + t * 0.18 + side * 0.035)

static func _fan(s: SurfaceTool) -> void:
	var hub := Vector3(0, 0.14, 0.43)
	_tri(s, Vector3(-0.014, 0, 0), Vector3(0.014, 0, 0), hub + Vector3.RIGHT * 0.02, 0.7)
	_tri(s, Vector3(-0.014, 0, 0), hub + Vector3.RIGHT * 0.02, hub - Vector3.RIGHT * 0.02, 0.7)
	for ray in range(15):
		var a := lerpf(-1.34, 1.34, float(ray) / 15.0)
		var c := lerpf(-1.34, 1.34, float(ray + 1) / 15.0)
		var mid := (a + c) * 0.5
		var radius := 0.70 + cos(mid) * 0.12
		var left := hub + Vector3(sin(a) * radius * 0.89, -0.035, cos(a) * radius * 0.89)
		var tip_a := lerpf(a, c, 0.37)
		var tip_c := lerpf(a, c, 0.63)
		var tip := hub + Vector3(sin(tip_a) * radius, -0.015, cos(tip_a) * radius)
		var tip_end := hub + Vector3(sin(tip_c) * radius, -0.015, cos(tip_c) * radius)
		var right := hub + Vector3(sin(c) * radius * 0.89, -0.035, cos(c) * radius * 0.89)
		var ridge := hub + Vector3(sin(mid) * radius * 0.43, 0.055, cos(mid) * radius * 0.43)
		_tri(s, hub, left, ridge, 0.39)
		_tri(s, left, tip, ridge, 0.47)
		_tri(s, ridge, tip, tip_end, 0.58)
		_tri(s, ridge, tip_end, right, 0.63)
		_tri(s, hub, ridge, right, 0.58)

static func _broad(s: SurfaceTool, form: int) -> void:
	var rows := 48 if form == 4 else (8 if form == 6 else 28)
	for row in range(rows):
		var t0 := float(row) / rows
		var t1 := float(row + 1) / rows
		var c0 := Vector3(0, sin(t0 * PI) * 0.15 - t0 * t0 * 0.12, t0 * 1.12)
		var c1 := Vector3(0, sin(t1 * PI) * 0.15 - t1 * t1 * 0.12, t1 * 1.12)
		for side: float in [-1.0, 1.0]:
			var w0 := _width(t0, row, form, side)
			var w1 := _width(t1, row + 1, form, side)
			var offset0 := -0.14 * sin(t0 * TAU) if form == 3 else 0.0
			var offset1 := -0.14 * sin(t1 * TAU) if form == 3 else 0.0
			var a := c0 + Vector3(side * w0, -w0 * 0.17, offset0)
			var b := c1 + Vector3(side * w1, -w1 * 0.17, offset1)
			_tri(s, c0, a, b, 0.44 + side * 0.06)
			if row < rows - 1:
				_tri(s, c0, b, c1, 0.53 + side * 0.07)

static func _width(t: float, row: int, form: int, side: float) -> float:
	var width := pow(maxf(0.0, sin(t * PI)), 0.72) * (0.47 if form == 3 else 0.32)
	if form == 6:
		width *= 0.28
	elif form == 2:
		for cut in [0.35, 0.69]:
			width *= 1.0 - 0.28 * exp(-pow((t - cut - side * 0.014) / 0.017, 2.0))
	elif form == 4:
		# Narrow curved clefts retain broad rounded lobes between them.
		for cut in [0.23, 0.43, 0.62, 0.79]:
			width *= 1.0 - 0.66 * exp(-pow((t - cut - side * 0.012) / 0.023, 2.0))
	return width
