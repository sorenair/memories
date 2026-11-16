@tool
extends "res://components/scenery/concert/shared/concert_geometry.gd"
const TURNED = preload("res://components/scenery/conservatory/shared/turned_geometry.gd")
## Ground root, entrance on +Z. Dimensions are authored, not randomized.

func lathe(profile_points: Array[Vector2], color: Color, kind: float = 0.0) -> void:
	TURNED.lathe(self, profile_points, color, kind, 64)

func ring(at: Vector3, radius: float, thickness: float, color: Color) -> void:
	for i in range(48):
		for j in range(8):
			for uv: Vector2i in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1), Vector2i(0, 0), Vector2i(1, 1), Vector2i(0, 1)]:
				var a := TAU * (i + uv.x) / 48.0
				var b := TAU * (j + uv.y) / 8.0
				var n := Vector3(cos(a) * cos(b), sin(b), sin(a) * cos(b))
				vertex(at + Vector3(cos(a) * radius, 0, sin(a) * radius) + n * thickness, n, color)

func shaft_radius(y: float, c: Dictionary) -> float:
	return c.base_radius * lerpf(1.0, 0.83, clampf((y - 0.3) / (c.tower_height - 0.3), 0, 1))

func mounted_point(p: Vector2, angle: float, outward: float, c: Dictionary) -> Vector3:
	var r := shaft_radius(p.y, c)
	var z := sqrt(maxf(0.001, r * r - p.x * p.x)) + outward
	return Basis(Vector3.UP, angle) * Vector3(p.x, p.y, z)

func arch(center_y: float, width: float, height: float, angle: float, outward: float, color: Color, c: Dictionary) -> void:
	var outline := PackedVector2Array([Vector2(-width * 0.5, center_y - height * 0.5), Vector2(width * 0.5, center_y - height * 0.5)])
	for i in range(13):
		var a := PI * i / 12.0
		outline.append(Vector2(cos(a) * width * 0.5, center_y + height * 0.5 - width * 0.5 + sin(a) * width * 0.5))
	var ids := Geometry2D.triangulate_polygon(outline)
	# Subdivide before projection so the wide door follows the cylinder as closely
	# as the small slits; one flat triangle would cut back through the plaster.
	for i in range(0, ids.size(), 3):
		var a := outline[ids[i]]
		var b := outline[ids[i + 1]]
		var e := outline[ids[i + 2]]
		for row in range(4):
			for col in range(4 - row):
				var points := [Vector2i(col, row), Vector2i(col + 1, row), Vector2i(col, row + 1)]
				if row + col < 3:
					points.append_array([Vector2i(col + 1, row), Vector2i(col + 1, row + 1), Vector2i(col, row + 1)])
				for uv: Vector2i in points:
					var u := float(uv.x) / 4
					var v := float(uv.y) / 4
					var p := a * (1 - u - v) + b * u + e * v
					var point := mounted_point(p, angle, outward, c)
					var n := Basis(Vector3.UP, angle) * Vector3(p.x / shaft_radius(p.y, c), 0, 1).normalized()
					vertex(point, n, color, 1)

func window(y: float, angle: float, c: Dictionary) -> void:
	var w: float = c.base_radius * 0.23
	var h := minf(0.68, c.tower_height * 0.075)
	arch(y, w + 0.09, h + 0.10, angle, 0.013, body.darkened(0.12), c)
	arch(y, w, h, angle, 0.026, Color("566a70"), c)
	arch(y - h * 0.04, w * 0.54, h * 0.72, angle, 0.032, Color("778b8e"), c)

func make(c: Dictionary) -> Dictionary:
	begin(c)
	var r: float = c.base_radius
	var h: float = c.tower_height
	# Broad white plinth and a gently tapering continuous plaster shaft.
	lathe([Vector2(0, 0.01), Vector2(r * 1.38, 0.01), Vector2(r * 1.40, 0.08), Vector2(r * 1.36, 0.26), Vector2(r * 1.07, 0.29), Vector2(0, 0.29)], body.darkened(0.06))
	lathe([Vector2(0, 0.26), Vector2(r, 0.26), Vector2(r, 0.4), Vector2(r * 0.97, h * 0.23), Vector2(r * 0.92, h * 0.49), Vector2(r * 0.87, h * 0.75), Vector2(r * 0.83, h - 0.24), Vector2(r * 0.91, h - 0.15), Vector2(r * 1.05, h - 0.07), Vector2(r * 1.26, h + 0.03), Vector2(r * 1.29, h + 0.13), Vector2(0, h + 0.13)], body)
	lathe([Vector2(r * 1.05, 0.29), Vector2(r * 1.075, 0.32), Vector2(r * 1.075, 0.37), Vector2(r, 0.40)], body.lightened(0.035))
	# Inset-looking narrow arched lights, staggered on opposite sides of the tower.
	for i in range(c.window_count):
		var y := lerpf(1.9, h - 1.05, (i + 0.5) / c.window_count)
		window(y, 0, c)
		if i % 2 == 0:
			window(y - 0.35, PI, c)
	# A closed timber door: the component is a scenic exterior.
	arch(1.04, r * 0.66, 1.65, 0, 0.018, body.darkened(0.16), c)
	arch(1.03, r * 0.51, 1.49, 0, 0.033, Color("66746d"), c)
	for x: float in [-0.13, 0.0, 0.13]:
		var a := mounted_point(Vector2(x * r, 0.34), 0, 0.042, c)
		var b := mounted_point(Vector2(x * r, 1.47), 0, 0.042, c)
		rod(a, b, 0.008, Color("51635e"), 6)
	ball(mounted_point(Vector2(r * 0.15, 0.99), 0, 0.075, c), Vector3.ONE * 0.065, Color("bba06d"))
	# Three simple approach steps, with a continuous convex access ramp.
	var front := r * 1.36
	var width := r * 1.05
	for i in range(3):
		var step_h := 0.29 * (3 - i) / 3.0
		box(Vector3(0, step_h * 0.5, front + 0.15 + i * 0.28), Vector3(width, step_h, 0.29), body.darkened(0.07 + i * 0.012))
	var ramp := PackedVector3Array()
	for x in [-width * 0.5, width * 0.5]:
		ramp.append(Vector3(x, -0.01, front))
		ramp.append(Vector3(x, 0.298, front))
		ramp.append(Vector3(x, -0.01, front + 0.86))
	colliders.append({"name": "EntrySteps", "points": ramp})
	var plinth := PackedVector3Array()
	var tower := PackedVector3Array()
	for i in range(32):
		var a := TAU * i / 32.0
		var axis := Vector3(cos(a), 0, sin(a))
		plinth.append(axis * r * 1.37 + Vector3.UP * 0.01)
		plinth.append(axis * r * 1.37 + Vector3.UP * 0.29)
		tower.append(axis * r + Vector3.UP * 0.29)
		tower.append(axis * r * 0.85 + Vector3.UP * h)
	colliders.append({"name": "Plinth", "points": plinth})
	colliders.append({"name": "ClosedTower", "points": tower})
	# Gallery railing and rounded white brackets support the lantern enclosure.
	if c.gallery_enabled:
		for i in range(16):
			var a := TAU * i / 16.0
			var p := Vector3(sin(a), 0, cos(a)) * r * 1.23
			rod(p + Vector3.UP * (h + 0.15), p + Vector3.UP * (h + 0.69), r * 0.018, brass, 10)
			var previous := frame
			frame = Transform3D(Basis(Vector3.UP, a), Vector3.ZERO)
			profile(PackedVector2Array([Vector2(r * 0.83, h - 0.34), Vector2(r * 0.87, h - 0.045), Vector2(r * 1.22, h - 0.045)]), Vector3.ZERO, r * 0.10, body.darkened(0.04))
			frame = previous
		ring(Vector3.UP * (h + 0.68), r * 1.23, r * 0.027, brass)
		ring(Vector3.UP * (h + 0.34), r * 1.23, r * 0.016, brass)
	var lantern_r := r * 0.63
	disc(Vector3(0, h + 0.16, 0), lantern_r * 1.14, 0.12, accent.darkened(0.24), Vector3.UP, 0, 32)
	for i in range(8):
		var a := TAU * i / 8.0 + PI * 0.125
		var p := Vector3(sin(a), 0, cos(a)) * lantern_r
		rod(p + Vector3.UP * (h + 0.20), p + Vector3.UP * (h + 1.29), r * 0.026, brass, 12)
	# Warm Fresnel-like core, broad bands rather than high-frequency glass detail.
	lathe([Vector2(0, h + 0.36), Vector2(r * 0.23, h + 0.39), Vector2(r * 0.30, h + 0.53), Vector2(r * 0.30, h + 0.91), Vector2(r * 0.23, h + 1.04), Vector2(0, h + 1.06)], c.beacon_color, 2)
	for y: float in [h + 0.52, h + 0.73, h + 0.94]:
		ring(Vector3.UP * y, r * 0.307, r * 0.012, accent.lightened(0.25))
	rod(Vector3.UP * (h + 0.21), Vector3.UP * (h + 0.40), r * 0.055, brass, 12)
	# A compact copper bell cap with a small vent and pointed weather finial.
	lathe([Vector2(0, h + 1.26), Vector2(r * 0.87, h + 1.26), Vector2(r * 0.89, h + 1.34), Vector2(r * 0.77, h + 1.39), Vector2(r * 0.62, h + 1.60), Vector2(r * 0.37, h + 1.88), Vector2(r * 0.15, h + 2.02), Vector2(r * 0.09, h + 2.10), Vector2(0, h + 2.10)], accent)
	disc(Vector3.UP * (h + 2.12), r * 0.12, 0.10, accent.darkened(0.15), Vector3.UP, 0, 24)
	rod(Vector3.UP * (h + 2.15), Vector3.UP * (h + 2.54), r * 0.022, brass, 12)
	anchors = {"Approach": Vector3(0, 0, front + 1.45), "Door": Vector3(0, 0.30, r + 0.29), "Lantern": Vector3(0, h + 0.73, 0), "Gallery": Vector3(r * 1.08, h + 0.14, 0), "Roof": Vector3(0, h + 2.6, 0)}
	return finish()

func glass(c: Dictionary) -> Mesh:
	begin(c)
	var r: float = c.base_radius * 0.628
	var h: float = c.tower_height
	for i in range(8):
		var a := TAU * i / 8.0 + PI * 0.125
		var b := TAU * (i + 1) / 8.0 + PI * 0.125
		var x := Vector3(sin(a), 0, cos(a)) * r
		var y := Vector3(sin(b), 0, cos(b)) * r
		quad(x + Vector3.UP * (h + 0.23), y + Vector3.UP * (h + 0.23), y + Vector3.UP * (h + 1.26), x + Vector3.UP * (h + 1.26), Color.WHITE)
	return finish().mesh
