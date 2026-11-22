@tool
extends "res://components/scenery/concert/shared/concert_geometry.gd"
const TURNED = preload("res://components/scenery/conservatory/shared/turned_geometry.gd")

func quad(a: Vector3, b: Vector3, c: Vector3, d: Vector3, color: Color, kind: float = 0.0) -> void:
	for tri in [[a, b, c], [a, c, d]]:
		var n: Vector3 = (tri[1] - tri[0]).cross(tri[2] - tri[0])
		if n.length_squared() > 0.0000000001:
			for p: Vector3 in tri:
				vertex(p, n.normalized(), color, kind)

func dome(theta: float, v: float, c: Dictionary) -> Vector3:
	var radial := pow(maxf(cos(v * PI * 0.5), 0.0), 0.85)
	var x := signf(cos(theta)) * pow(absf(cos(theta)), 0.60)
	var z := signf(sin(theta)) * pow(absf(sin(theta)), 0.60)
	return Vector3(x * c.footprint.x * 0.5 * radial, 0.07 + c.tent_height * pow(sin(v * PI * 0.5), 1.05), z * c.footprint.y * 0.5 * radial)

func dome_normal(theta: float, v: float, c: Dictionary) -> Vector3:
	var dt := dome(theta + 0.001, v, c) - dome(theta - 0.001, v, c)
	var dv := dome(theta, minf(v + 0.001, 0.9999), c) - dome(theta, maxf(v - 0.001, 0.0), c)
	var n := dv.cross(dt).normalized()
	if n.length_squared() < 0.1:
		return Vector3.UP
	return -n if n.y < 0 else n

func cloth_rod(a: Vector3, b: Vector3, radius: float, color: Color) -> void:
	var y := (b - a).normalized()
	if a.distance_squared_to(b) < 0.000001:
		return
	var ref := Vector3.BACK if absf(y.dot(Vector3.BACK)) < 0.95 else Vector3.RIGHT
	var x := y.cross(ref).normalized()
	var cylinder := CylinderMesh.new()
	cylinder.height = a.distance_to(b)
	cylinder.top_radius = radius
	cylinder.bottom_radius = radius
	cylinder.radial_segments = 6
	cylinder.rings = 0
	append(cylinder, Transform3D(Basis(x, y, x.cross(y)), (a + b) * 0.5), color, 2)

func front_point(x: float, y: float, c: Dictionary, offset: float = 0.01) -> Vector3:
	var h: float = clampf((y - 0.07) / c.tent_height, 0.0, 0.999)
	var radial := pow(cos(asin(pow(h, 1.0 / 1.05))), 0.85)
	var u: float = clampf(x / maxf(c.footprint.x * 0.5 * radial, 0.001), -0.99, 0.99)
	var z: float = c.footprint.y * 0.5 * radial * pow(1.0 - pow(absf(u), 2.0 / 0.60), 0.30)
	return Vector3(x, y, z + offset)

func vestibule_point(x: float, y: float, c: Dictionary, offset: float = 0.01) -> Vector3:
	var top_y: float = 0.07 + c.tent_height * 0.76
	var top_z: float = front_point(c.footprint.x * 0.24, top_y, c).z + 0.04
	var t := clampf((y - 0.09) / (top_y - 0.09), 0, 1)
	var straight: float = lerpf(c.footprint.y * 0.5 + 0.28, top_z, t)
	var canopy: float = front_point(x, y, c, 0.006).z
	var blend := sqrt((straight - canopy) * (straight - canopy) + 0.0001)
	return Vector3(x, y, (straight + canopy + blend) * 0.5 + offset)

func vestibule_uv(u: float, v: float, c: Dictionary) -> Vector3:
	var width: float = lerpf(c.footprint.x * 0.38, c.footprint.x * 0.24, v)
	return vestibule_point((u * 2 - 1) * width, lerpf(0.09, 0.07 + c.tent_height * 0.76, v), c)

func tent(c: Dictionary) -> Dictionary:
	begin(c)
	var open_front: bool = c.get("front_vestibule_open", false)
	for row in range(20):
		for col in range(64):
			var points: Array[Vector3] = []
			var normals: Array[Vector3] = []
			for uv: Vector2i in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1), Vector2i(0, 1)]:
				var a := TAU * (col + uv.x) / 64.0
				var v := (row + uv.y) / 20.0
				points.append(dome(a, v, c))
				normals.append(dome_normal(a, minf(v, 0.999), c))
			var panel := int(floor((col + 8) / 16.0)) % 2
			var tone: Color = body.lerp(accent, (0.24 if open_front else 0.50) if panel == 1 else 0.03)
			if row < (3 if open_front else 1):
				tone = brass
			for ids in [[0, 1, 2], [0, 2, 3]]:
				if (points[ids[1]] - points[ids[0]]).cross(points[ids[2]] - points[ids[0]]).length_squared() < 0.000000001:
					continue
				for id: int in ids:
					vertex(points[id], normals[id], tone, 2)
	for i in range(64):
		var a := dome(TAU*i/64.0,0,c)
		var b := dome(TAU*(i+1)/64.0,0,c)
		quad(a,b,Vector3(b.x,0.006,b.z),Vector3(a.x,0.006,a.z),brass)
	# Four curved roof seams meet at the crossed-pole crown.
	for i in range(4):
		var a := PI * 0.25 + i * PI * 0.5
		for row in range(24):
			cloth_rod(dome(a, row / 24.0, c) + Vector3.UP * 0.006, dome(a, (row + 1) / 24.0, c) + Vector3.UP * 0.006, 0.007, body.darkened(0.09))
	# Tensioned fly panels extend beyond the rounded inner dome to form vestibules.
	var bottom_w: float = c.footprint.x * 0.38
	var top_w: float = c.footprint.x * 0.24
	var top_y: float = 0.07 + c.tent_height * 0.76
	for side: float in [-1.0, 1.0]:
		var bottom_l := vestibule_point(-bottom_w, 0.09, c)
		var bottom_r := vestibule_point(bottom_w, 0.09, c)
		var upper_l := vestibule_point(-top_w, top_y, c)
		var upper_r := vestibule_point(top_w, top_y, c)
		bottom_l.z *= side
		bottom_r.z *= side
		upper_l.z *= side
		upper_r.z *= side
		for row in range(16):
			for col in range(24):
				if side > 0.0 and open_front and col < 12:
					continue
				for uv: Vector2i in [Vector2i(0,0),Vector2i(1,0),Vector2i(1,1),Vector2i(0,0),Vector2i(1,1),Vector2i(0,1)]:
					var u := (col + uv.x) / 24.0
					var v := (row + uv.y) / 16.0
					var point := vestibule_uv(u, v, c)
					var du := vestibule_uv(minf(1,u+0.001),v,c)-vestibule_uv(maxf(0,u-0.001),v,c)
					var dv := vestibule_uv(u,minf(1,v+0.001),c)-vestibule_uv(u,maxf(0,v-0.001),c)
					var n := du.cross(dv).normalized()
					point.z *= side
					n.z *= side
					vertex(point,n,body.lerp(accent,0.12 if col < 12 else 0.55),2)
		var inside_l := front_point(-top_w, top_y, c, 0.003) * Vector3(1,1,side)
		var inside_r := front_point(top_w, top_y, c, 0.003) * Vector3(1,1,side)
		if side <= 0.0 or not open_front:
			quad(bottom_l, upper_l, inside_l, dome(PI * 0.5 + 0.45, 0.0, c) * Vector3(1,1,side), body, 2)
		quad(bottom_r, dome(PI * 0.5 - 0.45, 0.0, c) * Vector3(1,1,side), inside_r, upper_r, body, 2)
		for i in range(32):
			var p := vestibule_uv(0.5,i/32.0,c) + Vector3.BACK * 0.006
			var q := vestibule_uv(0.5,(i+1)/32.0,c) + Vector3.BACK * 0.006
			p.z *= side
			q.z *= side
			cloth_rod(p,q,0.008,body.darkened(0.28))
		cloth_rod(bottom_l, upper_l, 0.006, body.darkened(0.12))
		cloth_rod(bottom_r, upper_r, 0.006, body.darkened(0.12))
		cloth_rod(upper_l, upper_r, 0.006, body.darkened(0.08))
		var pull := vestibule_uv(0.5,0.12,c) * Vector3(1,1,side) + Vector3(0.015,0,side*0.015)
		cloth_rod(pull, pull + Vector3(0.015, 0.065, 0), 0.012, brass)
	if open_front:
		_mesh_door(c)
	# Small quarter-dome brand mark, projected onto the same cloth surface.
	if c.brand_mark_enabled:
		var center := Vector2(c.footprint.x * 0.23, c.tent_height * 0.36)
		var wordmark := TextMesh.new()
		wordmark.text = "THE\nNORTH\nFACE"
		wordmark.font = ThemeDB.fallback_font
		wordmark.font_size = 48
		wordmark.pixel_size = 0.027 / 48.0
		wordmark.depth = 0
		var glyphs := wordmark.surface_get_arrays(0)
		var glyph_ids: PackedInt32Array = glyphs[Mesh.ARRAY_INDEX]
		for id in glyph_ids:
			var p: Vector3 = glyphs[Mesh.ARRAY_VERTEX][id]
			var point := vestibule_point(center.x - 0.105 + p.x, center.y + 0.025 + p.y, c, 0.026)
			vertex(point, Vector3(0,0.5,1).normalized(), brass.darkened(0.16), 2)
		for arc in range(3):
			var radius := 0.055 + arc * 0.025
			for i in range(10):
				var a := PI * 0.5 * i / 10
				var b := PI * 0.5 * (i + 1) / 10
				var p := vestibule_point(center.x + cos(a) * radius, center.y + sin(a) * radius, c, 0.020)
				var q := vestibule_point(center.x + cos(b) * radius, center.y + sin(b) * radius, c, 0.020)
				cloth_rod(p, q, 0.006, brass.darkened(0.16))
	var hull := PackedVector3Array()
	for i in range(24):
		var a := TAU * i / 24.0
		hull.append(dome(a, 0, c))
		hull.append(dome(a, 0.52, c))
	hull.append(Vector3.UP * (c.tent_height + 0.07))
	for side: float in [-1.0, 1.0]:
		hull.append(Vector3(-bottom_w,0.07,side*(c.footprint.y*0.5+0.28)))
		hull.append(Vector3(bottom_w,0.07,side*(c.footprint.y*0.5+0.28)))
	colliders.append({"name": "ClosedTent", "points": hull})
	if c.guy_lines_enabled:
		for i in range(4):
			var a := PI * 0.25 + i * PI * 0.5
			var top := dome(a, 0.23, c)
			var end := dome(a, 0, c) * Vector3(1.24, 0, 1.24) + Vector3.UP * 0.025
			rod(top, end, 0.005, accent.lightened(0.10), 6)
			rod(end - Vector3.UP * 0.015, end + Vector3(0.035, 0.08, 0.015), 0.010, brass, 8)
	anchors = {"Approach": Vector3(0, 0, c.footprint.y * 0.5 + 1.0), "Peak": Vector3(0, c.tent_height + 0.07, 0), "Door": Vector3(0, 0.15, c.footprint.y * 0.5 + 0.38)}
	return finish()

func _mesh_door(c: Dictionary) -> void:
	# The closed inner door is visible behind the rolled-back section of the fly.
	var mesh_color := brass.lerp(Color("434943"), 0.59)
	var rim := body.darkened(0.23)
	for row in 12:
		var v0 := row / 12.0
		var v1 := (row + 1) / 12.0
		for column in 10:
			var u0 := column / 10.0
			var u1 := (column + 1) / 10.0
			quad(_door_point(u0, v0, c), _door_point(u1, v0, c), _door_point(u1, v1, c),
				_door_point(u0, v1, c), mesh_color.lightened(0.055 * sin(column * 1.5) + v0 * 0.13), 2)
		for side: float in [0.0, 1.0]:
			cloth_rod(_door_point(side, v0, c), _door_point(side, v1, c), 0.015, rim)
	for index in 8:
		var a := vestibule_uv(0.015, index / 8.0, c)
		var b := vestibule_uv(0.015, (index + 1) / 8.0, c)
		cloth_rod(a, b, 0.039, accent)
	cloth_rod(vestibule_uv(0.0, 0.30, c), vestibule_uv(0.034, 0.33, c), 0.043, brass)

func _door_point(u: float, v: float, c: Dictionary) -> Vector3:
	var half_width: float = lerpf(0.325, 0.115, pow(v, 2.45)) * c.footprint.x
	var y: float = lerpf(0.16, c.tent_height * 0.80, v)
	return front_point(lerpf(-half_width, half_width, u), y, c, 0.019)

func stove(c: Dictionary) -> Dictionary:
	begin(c)
	var scale: float = c.gear_scale
	frame = Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * scale), Vector3.ZERO)
	for i in range(3):
		var previous := frame
		frame = previous * Transform3D(Basis(Vector3.UP, TAU * i / 3.0), Vector3.ZERO)
		profile(PackedVector2Array([Vector2(0.035, 0.065), Vector2(0.145, 0.008), Vector2(0.17, 0.008), Vector2(0.09, 0.105), Vector2(0.095, 0.18), Vector2(0.055, 0.18)]), Vector3.ZERO, 0.014, brass)
		rod(Vector3(0.06, 0.181, 0), Vector3(0.13, 0.181, 0), 0.009, brass, 8)
		frame = previous
	TURNED.lathe(self, [Vector2(0, 0.07), Vector2(0.046, 0.07), Vector2(0.074, 0.11), Vector2(0.075, 0.13), Vector2(0.048, 0.14), Vector2(0, 0.14)], brass.darkened(0.23), 0, 32)
	for i in range(24):
		var a := TAU * i / 24.0
		var b := TAU * (i + 1) / 24.0
		var p := Vector3(cos(a), 0, sin(a)) * 0.057
		var q := Vector3(cos(b), 0, sin(b)) * 0.057
		quad(p + Vector3.UP * 0.13, q + Vector3.UP * 0.13, q * 0.75 + Vector3.UP * (0.168 + 0.005 * sin(b * 7)), p * 0.75 + Vector3.UP * (0.168 + 0.005 * sin(a * 7)), Color("8bbdd3"), 3)
	# A horizontal red liquid-fuel bottle and pump, connected by a flexible hose.
	var previous := frame
	frame = previous * Transform3D(Basis(Vector3.BACK, PI * 0.5), Vector3(0.52, 0.055, 0.05))
	TURNED.lathe(self, [Vector2(0, 0), Vector2(0.035, 0), Vector2(0.05, 0.012), Vector2(0.05, 0.235), Vector2(0.033, 0.255), Vector2(0.022, 0.26), Vector2(0, 0.26)], accent, 0, 40)
	frame = previous
	rod(Vector3(0.26, 0.055, 0.05), Vector3(0.21, 0.055, 0.05), 0.023, Color("8a8c7e"), 16)
	rod(Vector3(0.225, 0.06, 0.05), Vector3(0.225, 0.12, 0.05), 0.012, accent, 12)
	disc(Vector3(0.225, 0.12, 0.05), 0.021, 0.015, accent, Vector3.UP, 0, 16)
	var hose: Array[Vector3] = []
	for i in range(17):
		var t := float(i) / 16
		hose.append(Vector3(lerpf(0.22, 0.03, t), 0.035 + 0.025 * cos(t * TAU), 0.05 + sin(t * PI) * 0.14))
	tube(hose, 0.006, Color("4d514b"), 8)
	text("MSR", Vector3(0.40, 0.107, 0.055), 0.029, Color("642d2b"), Basis(Vector3.RIGHT, -PI * 0.5))
	if c.pot_enabled:
		var r: float = c.pot_radius
		var bottom := 0.187
		var top := bottom + r * 1.18
		TURNED.lathe(self, [Vector2(0, bottom), Vector2(r * 0.91, bottom), Vector2(r, bottom + 0.018), Vector2(r, top), Vector2(r * 0.94, top), Vector2(r * 0.94, bottom + 0.025), Vector2(0, bottom + 0.025)], body, 0, 48)
		var handle: Array[Vector3] = [Vector3(-r * 0.96, top - 0.04, -0.025), Vector3(-r - 0.07, top - 0.04, -0.025), Vector3(-r - 0.23, top - 0.015, -0.025), Vector3(-r - 0.24, top - 0.015, 0.025), Vector3(-r - 0.07, top - 0.04, 0.025), Vector3(-r * 0.96, top - 0.04, 0.025)]
		tube(handle, 0.009, body.darkened(0.2), 8)
		if c.lid_enabled:
			TURNED.lathe(self, [Vector2(0, top + 0.015), Vector2(r * 0.75, top + 0.012), Vector2(r * 1.025, top + 0.005), Vector2(r * 1.025, top - 0.005)], body.lightened(0.10), 0, 48)
			disc(Vector3(0, top + 0.025, 0), r * 0.11, 0.03, Color("414b49"), Vector3.UP, 0, 20)
		collider(Vector3(0, (top + 0.01) * 0.5, 0) * scale, Vector3(r * 2, top + 0.01, r * 2) * scale, "StoveAndPot")
	else:
		collider(Vector3(0, 0.1, 0) * scale, Vector3(0.30, 0.20, 0.30) * scale, "Stove")
	collider(Vector3(0.39, 0.06, 0.05) * scale, Vector3(0.29, 0.12, 0.11) * scale, "FuelBottle")
	anchors = {"Approach": Vector3(0, 0, 0.65) * scale, "Burner": Vector3(0, 0.145, 0) * scale, "PotTop": Vector3(0, 0.21 + c.pot_radius * 1.18, 0) * scale, "FuelBottle": Vector3(0.39, 0.06, 0.05) * scale}
	return finish()
