@tool
extends "res://components/scenery/concert/shared/concert_geometry.gd"
## All geometry is batched. Boat origin is the waterline; bow is local +Z.

func begin(c: Dictionary) -> void:
	super.begin(c)
	if c.has("wood_color"):
		wood = c.wood_color

func quad(a: Vector3, b: Vector3, c: Vector3, d: Vector3, color: Color, kind: float = 0.0, reverse := false) -> void:
	if reverse:
		var next := b
		b = d
		d = next
	for triangle in [[a, b, c], [a, c, d]]:
		var normal: Vector3 = (triangle[1] - triangle[0]).cross(triangle[2] - triangle[0])
		if normal.length_squared() > 0.0000000001:
			for p: Vector3 in triangle:
				vertex(p, normal.normalized(), color, kind)

func flat_deck(center: Vector3, width: float, depth: float, thickness: float, color: Color, bevel: float = 0.04) -> void:
	var previous := frame
	frame = previous * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), center)
	soft_box(Vector3.ZERO, Vector3(width, depth, thickness), color, bevel)
	frame = previous

func cleat(at: Vector3, color: Color) -> void:
	rod(at, at + Vector3.UP * 0.065, 0.025, color, 10)
	rod(at + Vector3(-0.12, 0.075, 0), at + Vector3(0.12, 0.075, 0), 0.022, color, 10)

func dock_section(center: Vector3, size: Vector2, c: Dictionary) -> void:
	var height: float = c.deck_height
	var count := maxi(3, ceili(size.y / 0.27))
	var step := size.y / count
	for i in range(count):
		var z := center.z - size.y * 0.5 + (i + 0.5) * step
		var tone := body.lightened(rng.randf_range(-0.07, 0.07))
		flat_deck(Vector3(center.x, height - 0.055, z), size.x, step - 0.009, 0.11, tone, 0.025)
		# A few broad worn streaks, not a repeated photographic wood-grain texture.
		if i % 3 == 0:
			flat_deck(Vector3(center.x + rng.randf_range(-0.12, 0.12), height + 0.001, z), size.x * rng.randf_range(0.35, 0.7), 0.025, 0.002, tone.lightened(0.07), 0.007)
	for side: float in [-1.0, 1.0]:
		box(Vector3(center.x + side * (size.x * 0.5 - 0.1), height - 0.19, center.z), Vector3(0.15, 0.23, size.y), accent)
	box(Vector3(center.x, height - 0.16, center.z - size.y * 0.5 + 0.06), Vector3(size.x, 0.20, 0.12), accent)
	collider(Vector3(center.x, height - 0.09, center.z), Vector3(size.x, 0.18, size.y), "DockDeck")

func piling(at: Vector3, c: Dictionary) -> void:
	var bottom := at + Vector3(0, -c.pile_depth, 0)
	var top := at + Vector3(0, c.deck_height + 0.42, 0)
	rod(bottom, top, 0.105, accent.lightened(rng.randf_range(-0.035, 0.04)), 20)
	disc(top + Vector3.UP * 0.012, 0.112, 0.035, body.lightened(0.08), Vector3.UP, 0, 20)
	for dy: float in [-0.15, -0.22]:
		disc(top + Vector3.UP * dy, 0.112, 0.035, brass, Vector3.UP, 0, 16)
	collider((bottom + top) * 0.5, Vector3(0.21, top.y - bottom.y, 0.21), "MooringPile")

func dock(c: Dictionary) -> Dictionary:
	begin(c)
	var length: float = c.dock_length
	var width: float = c.dock_width
	var head: float = c.head_width
	var head_depth := minf(width + 0.2, length * 0.4)
	var head_center := Vector3(0, 0, -length * 0.5 + head_depth * 0.5)
	if c.layout == 2:
		head_center.x = (head - width) * 0.5
	if c.layout == 0:
		dock_section(Vector3.ZERO, Vector2(width, length), c)
	else:
		dock_section(Vector3(0, 0, head_depth * 0.5), Vector2(width, length - head_depth), c)
		dock_section(head_center, Vector2(head, head_depth), c)
	var spans := maxi(1, ceili((length - head_depth) / 2.4))
	for i in range(spans + 1):
		var z := lerpf(length * 0.5 - 0.18, -length * 0.5 + head_depth + 0.15, float(i) / spans)
		for side: float in [-1.0, 1.0]:
			piling(Vector3(side * (width * 0.5 + 0.025), 0, z), c)
	var end_width := width if c.layout == 0 else head
	var end_x := 0.0 if c.layout == 0 else head_center.x
	for side: float in [-1.0, 1.0]:
		piling(Vector3(end_x + side * (end_width * 0.5 - 0.1), 0, -length * 0.5 + 0.13), c)
		cleat(Vector3(end_x + side * (end_width * 0.5 - 0.28), c.deck_height, -length * 0.5 + head_depth * 0.65), brass)
	if c.rail_sides != 0:
		for side: float in [-1.0, 1.0]:
			if (side < 0 and c.rail_sides == 2) or (side > 0 and c.rail_sides == 1):
				continue
			var x := side * (width * 0.5 - 0.04)
			var start := Vector3(x, c.deck_height + 0.73, length * 0.5 - 0.2)
			var end := Vector3(x, c.deck_height + 0.73, -length * 0.5 + head_depth + 0.2)
			rod(start, end, 0.040, body, 12)
			rod(start - Vector3.UP * 0.36, end - Vector3.UP * 0.36, 0.026, body, 10)
			for i in range(spans + 1):
				var top := start.lerp(end, float(i) / spans)
				rod(Vector3(top.x, c.deck_height, top.z), top, 0.040, accent, 12)
			collider((start + end) * 0.5 - Vector3.UP * 0.32, Vector3(0.11, 0.75, absf(start.z - end.z)), "SideRail")
	if c.ramp_enabled:
		var z0 := length * 0.5 - 0.015
		var z1: float = length * 0.5 + c.ramp_length
		var half := width * 0.45
		var a := Vector3(-half, c.deck_height + 0.006, z0)
		var b := Vector3(half, c.deck_height + 0.006, z0)
		var e := Vector3(-half, 0.025, z1)
		var f := Vector3(half, 0.025, z1)
		quad(e, f, b, a, body)
		var boards := maxi(4, ceili(c.ramp_length / 0.3))
		for i in range(boards):
			var t := (i + 0.5) / boards
			rod(e.lerp(a, t) + Vector3.UP * 0.005, f.lerp(b, t) + Vector3.UP * 0.005, 0.009, accent, 6)
		quad(e - Vector3.UP * 0.07, a - Vector3.UP * 0.07, a, e, accent)
		quad(f, b, b - Vector3.UP * 0.07, f - Vector3.UP * 0.07, accent)
		colliders.append({"name": "ShoreRamp", "points": PackedVector3Array([a, b, e, f, a - Vector3.UP * 0.12, b - Vector3.UP * 0.12, e - Vector3.UP * 0.12, f - Vector3.UP * 0.12])})
	anchors = {"ShoreJoin": Vector3(0, c.deck_height, length * 0.5), "Approach": Vector3(0, 0.03, length * 0.5 + (c.ramp_length if c.ramp_enabled else 0.8) + 0.5), "DeckEnd": Vector3(end_x, c.deck_height + 0.02, -length * 0.5 + head_depth * 0.5), "PortBerth": Vector3(end_x - end_width * 0.5 - 0.5, 0, head_center.z), "StarboardBerth": Vector3(end_x + end_width * 0.5 + 0.5, 0, head_center.z)}
	return finish()

func hull_width(t: float) -> float:
	# Narrow tucked transom and fine bow, with the maximum beam aft of the mast.
	if t > 0.999:
		return 0.0
	return maxf(0.0, (0.52 + 0.55 * sin(PI * pow(t, 0.82))) * pow(1.0 - t, 0.27)) / 0.94

func hull_point(t: float, v: float, side: float, c: Dictionary) -> Vector3:
	var width: float = c.beam * 0.5 * hull_width(t)
	var z: float = (t - 0.5) * c.hull_length
	var sheer := 0.46 + pow(t, 3) * 0.20 + pow(1.0 - t, 4) * 0.10
	var bottom := -0.35 + pow(absf(t - 0.48) * 2.0, 2.8) * 0.46
	return Vector3(side * width * sin(v * PI * 0.5), lerpf(bottom, sheer, pow(v, 1.5)), z)

func hull_normal(t: float, v: float, side: float, c: Dictionary) -> Vector3:
	var dt := hull_point(minf(t + 0.001, 0.9998), v, side, c) - hull_point(maxf(t - 0.001, 0.0001), v, side, c)
	var dv := hull_point(t, minf(v + 0.001, 1.0), side, c) - hull_point(t, maxf(v - 0.001, 0.0), side, c)
	var n := dt.cross(dv).normalized() * -side
	return n if n.length_squared() > 0.1 else Vector3.DOWN

func hull(c: Dictionary) -> Dictionary:
	begin(c)
	var length: float = c.hull_length
	var beam: float = c.beam
	for side: float in [-1.0, 1.0]:
		for row in range(12):
			for col in range(40):
				for uv in [Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 0), Vector2(1, 1), Vector2(0, 1)]:
					var t := minf((col + uv.x) / 40.0, 0.9998)
					var v: float = (row + uv.y) / 12.0
					var p := hull_point(t, v, side, c)
					var color: Color = c.hull_color if p.y > 0.045 else c.keel_color
					vertex(p, hull_normal(t, v, side, c), color)
		# Gunwale strip follows the sheer; wide pigment planes replace sharp hull facets.
		var outline: Array[Vector3] = []
		for i in range(41):
			outline.append(hull_point(minf(float(i) / 40.0, 0.9998), 1, side, c))
		tube(outline, 0.025, c.deck_color, 10)
	# Fitted transom: no motor, motor bracket or propeller.
	for row in range(12):
		var v0 := float(row) / 12
		var v1 := float(row + 1) / 12
		quad(hull_point(0, v0, -1, c), hull_point(0, v0, 1, c), hull_point(0, v1, 1, c), hull_point(0, v1, -1, c), c.hull_color)
	# Continuous side decks around a truly recessed cockpit.
	var cockpit_start := 0.09
	var cockpit_end := 0.51
	for i in range(40):
		var t0 := float(i) / 40
		var t1 := minf(float(i + 1) / 40, 0.9998)
		var z := (t0 + t1) * 0.5
		var opening: bool = z > cockpit_start and z < cockpit_end
		for side: float in [-1.0, 1.0]:
			var a := hull_point(t0, 1, side, c)
			var b := hull_point(t1, 1, side, c)
			var inner0 := Vector3(side * beam * (0.34 if opening else 0), a.y + 0.012, a.z)
			var inner1 := Vector3(side * beam * (0.34 if opening else 0), b.y + 0.012, b.z)
			if side > 0:
				quad(a, inner0, inner1, b, c.deck_color)
			else:
				quad(a, b, inner1, inner0, c.deck_color)
	var cockpit_z := (cockpit_start + cockpit_end - 1.0) * length * 0.5
	var cockpit_length := (cockpit_end - cockpit_start) * length
	flat_deck(Vector3(0, 0.17, cockpit_z), beam * 0.54, cockpit_length, 0.055, wood, 0.06)
	for side: float in [-1.0, 1.0]:
		var x := side * beam * 0.30
		box(Vector3(x, 0.37, cockpit_z), Vector3(beam * 0.045, 0.46, cockpit_length), wood)
		flat_deck(Vector3(side * beam * 0.235, 0.30, cockpit_z), beam * 0.18, cockpit_length - 0.08, 0.07, wood.lightened(0.09), 0.045)
		for strip in range(3):
			box(Vector3(side * beam * 0.235 + (strip - 1) * beam * 0.047, 0.338, cockpit_z), Vector3(0.009, 0.003, cockpit_length - 0.14), wood.darkened(0.12))
		# Two quiet, rounded ports on the low forward cuddy.
		soft_box(Vector3(side * beam * 0.30, 0.81, length * 0.105), Vector3(0.018, 0.14, 0.34), Color("546f76"), 0.025)
		cleat(Vector3(side * beam * 0.32, 0.56, length * 0.38), brass)
		cleat(Vector3(side * beam * 0.22, 0.57, -length * 0.43), brass)
		disc(Vector3(side * beam * 0.355, 0.55, -length * 0.05), 0.085, 0.045, wood, Vector3.UP, 0, 16)
		disc(Vector3(side * beam * 0.355, 0.605, -length * 0.05), 0.055, 0.07, brass, Vector3.UP, 0, 16)
	flat_deck(Vector3(0, 0.65, length * 0.11), beam * 0.61, length * 0.25, 0.34, c.deck_color, 0.13)
	flat_deck(Vector3(0, 0.836, length * 0.11), beam * 0.56, length * 0.23, 0.045, c.deck_color.lightened(0.03), 0.10)
	soft_box(Vector3(0, 0.64, -length * 0.022), Vector3(beam * 0.32, 0.36, 0.04), wood.darkened(0.30), 0.035)
	# Shallow full keel and rudder remain below the authored waterline.
	var previous := frame
	frame = Transform3D(Basis(Vector3.UP, PI * 0.5), Vector3.ZERO)
	profile(PackedVector2Array([Vector2(-length * 0.28, -0.22), Vector2(length * 0.21, -0.25), Vector2(length * 0.17, -0.82), Vector2(-length * 0.18, -0.91)]), Vector3.ZERO, beam * 0.10, c.keel_color)
	profile(PackedVector2Array([Vector2(length * 0.22, -0.20), Vector2(length * 0.34, -0.10), Vector2(length * 0.30, -0.77), Vector2(length * 0.18, -0.82)]), Vector3.ZERO, beam * 0.055, c.keel_color.darkened(0.08))
	frame = previous
	rod(Vector3(0, 0.47, -length * 0.35), Vector3(0.07, 0.58, -length * 0.18), 0.028, wood.lightened(0.06), 12)
	# Convex exterior, not a rectangular obstruction spanning the mast/sails.
	var points := PackedVector3Array()
	for i in range(13):
		for side: float in [-1.0, 1.0]:
			points.append(hull_point(minf(float(i) / 12.0, 0.9998), 1, side, c))
			points.append(hull_point(minf(float(i) / 12.0, 0.9998), 0.35, side, c))
	colliders.append({"name": "HullExterior", "points": points})
	anchors = {"Bow": Vector3(0, 0.62, length * 0.44), "Stern": Vector3(0, 0.56, -length * 0.45), "Cockpit": Vector3(0, 0.21, cockpit_z), "PortMooring": Vector3(-beam * 0.5 - 0.04, 0.47, -length * 0.10), "StarboardMooring": Vector3(beam * 0.5 + 0.04, 0.47, -length * 0.10)}
	return finish()

func dinghy(c: Dictionary) -> Dictionary:
	begin(c)
	var length: float = c.hull_length
	var half_beam: float = c.beam * 0.5
	# Stations store longitudinal position, half-beam fraction, and gunwale height.
	var stations := [
		Vector3(-0.50, 0.80, 0.31), Vector3(-0.36, 0.92, 0.32),
		Vector3(-0.16, 1.00, 0.34), Vector3(0.08, 0.97, 0.37),
		Vector3(0.25, 0.81, 0.41), Vector3(0.38, 0.53, 0.49),
		Vector3(0.50, 0.00, 0.55)]
	var points := PackedVector3Array()
	for side: float in [-1.0, 1.0]:
		var tops: Array[Vector3] = []
		for station: Vector3 in stations:
			tops.append(Vector3(station.y * half_beam * side, station.z, station.x * length))
		for i in range(tops.size() - 1):
			var a := tops[i]
			var b := tops[i + 1]
			var port := side < 0.0
			var chine_a := Vector3(a.x * 0.80, maxf(-0.07, a.y - 0.44), a.z)
			var chine_b := Vector3(b.x * 0.80, maxf(-0.07, b.y - 0.44), b.z)
			var stripe_a := a.lerp(chine_a, 0.28)
			var stripe_b := b.lerp(chine_b, 0.28)
			quad(a, b, stripe_b, stripe_a, c.hull_color, 0, port)
			quad(stripe_a, stripe_b, stripe_b.lerp(chine_b, 0.14), stripe_a.lerp(chine_a, 0.14), c.accent_color, 0, port)
			quad(stripe_a.lerp(chine_a, 0.14), stripe_b.lerp(chine_b, 0.14), chine_b, chine_a, c.hull_color, 0, port)
			quad(chine_a, chine_b, Vector3(0, -0.16, b.z), Vector3(0, -0.16, a.z), c.keel_color, 0, port)
			if i in [1, 2]:
				var edge_a := Vector3(a.x * 0.70, a.y - 0.025, a.z)
				var edge_b := Vector3(b.x * 0.70, b.y - 0.025, b.z)
				var sole_a := Vector3(edge_a.x * 0.80, 0.035, a.z)
				var sole_b := Vector3(edge_b.x * 0.80, 0.035, b.z)
				quad(a, b, edge_b, edge_a, c.deck_color, 0, not port)
				quad(edge_a, edge_b, sole_b, sole_a, c.deck_color.darkened(0.16), 0, not port)
				quad(sole_a, sole_b, Vector3(0, 0.035, b.z), Vector3(0, 0.035, a.z), c.deck_color.darkened(0.27), 0, not port)
			else:
				quad(a, b, Vector3(0, b.y + 0.025, b.z), Vector3(0, a.y + 0.025, a.z), c.deck_color, 0, not port)
			points.append(a)
			points.append(chine_a)
		points.append(tops[-1])
		tube(tops, 0.021, c.deck_color, 8)
	var stern_z := -length * 0.5
	var stern_width := half_beam * 0.80
	var left_chine := Vector3(-stern_width * 0.80, -0.07, stern_z)
	var right_chine := Vector3(stern_width * 0.80, -0.07, stern_z)
	quad(left_chine, Vector3(-stern_width, 0.31, stern_z),
		Vector3(stern_width, 0.31, stern_z), right_chine, c.hull_color)
	quad(left_chine, right_chine, Vector3(0, -0.16, stern_z), Vector3(0, -0.16, stern_z), c.keel_color)
	for i in [1, 3]:
		var station: Vector3 = stations[i]
		var z := station.x * length
		var width := station.y * half_beam * 0.70
		quad(Vector3(-width, 0.035, z), Vector3(width, 0.035, z),
			Vector3(width, station.z, z), Vector3(-width, station.z, z), c.deck_color.darkened(0.09), 0, i == 3)
	soft_box(Vector3(0, 0.17, -0.14), Vector3(0.17, 0.27, 1.19), c.deck_color, 0.035)
	for side: float in [-1.0, 1.0]:
		rod(Vector3(side * 0.25, 0.067, -length * 0.33), Vector3(side * 0.25, 0.083, length * 0.04),
			0.023, c.trim_color, 6)
	soft_box(Vector3(0, 0.015, -length * 0.52), Vector3(0.075, 0.64, 0.26), c.keel_color, 0.025)
	rod(Vector3(0, 0.36, -length * 0.54), Vector3(0.06, 0.42, -length * 0.30), 0.023, c.trim_color, 8)
	colliders.append({"name": "HullExterior", "points": points})
	anchors = {"Bow": Vector3(0, 0.55, length * 0.50), "Stern": Vector3(0, 0.31, -length * 0.50),
		"Cockpit": Vector3(0, 0.035, -length * 0.16),
		"PortMooring": Vector3(-half_beam, 0.34, -length * 0.16),
		"StarboardMooring": Vector3(half_beam, 0.34, -length * 0.16)}
	return finish()

func sail_point(a: Vector3, b: Vector3, e: Vector3, u: float, v: float, fullness: float) -> Vector3:
	var belly := maxf(0, 27.0 * u * v * (1.0 - u - v))
	return a * (1.0 - u - v) + b * u + e * v + Vector3.RIGHT * fullness * belly

func cloth_vertex(a: Vector3, b: Vector3, e: Vector3, uv: Vector2, fullness: float, color: Color, offset: float = 0.0) -> void:
	var u := uv.x
	var v := uv.y
	var p := sail_point(a, b, e, u, v, fullness)
	var du := b - a + Vector3.RIGHT * fullness * 27 * v * (1 - 2 * u - v)
	var dv := e - a + Vector3.RIGHT * fullness * 27 * u * (1 - u - 2 * v)
	var n := du.cross(dv).normalized()
	s.set_normal((frame.basis.inverse().transposed() * n).normalized())
	s.set_color(color.srgb_to_linear())
	s.set_uv2(Vector2(3, maxf(0, 27.0 * u * v * (1.0 - u - v))))
	s.add_vertex(frame * (p + n * offset))

func sail_mark(a: Vector3, b: Vector3, e: Vector3, fullness: float) -> void:
	# The simple Ensign E is painted into the curved cloth on both faces.
	var patches := [Rect2(0.635, 0.10, 0.06, 0.009), Rect2(0.687, 0.10, 0.008, 0.072), Rect2(0.662, 0.10, 0.008, 0.053), Rect2(0.635, 0.10, 0.008, 0.072)]
	for patch: Rect2 in patches:
		var p := patch.position
		var q := patch.end
		for offset: float in [-0.012, 0.012]:
			for uv: Vector2 in [p, Vector2(q.x, p.y), q, p, q, Vector2(p.x, q.y)]:
				cloth_vertex(a, b, e, uv, fullness, Color("718a92"), offset)

func sail(a: Vector3, b: Vector3, e: Vector3, fullness: float, color: Color) -> void:
	var detail := 20
	for row in range(detail):
		for col in range(detail - row):
			var cells := [Vector2i(col, row), Vector2i(col + 1, row), Vector2i(col, row + 1)]
			if col + row < detail - 1:
				cells.append_array([Vector2i(col + 1, row), Vector2i(col + 1, row + 1), Vector2i(col, row + 1)])
			for cell in cells:
				var u := float(cell.x) / detail
				var v := float(cell.y) / detail
				var panel_tone := color.lightened(0.014 * sin(v * 19.0) - 0.014 * float(row % 4 == 0))
				cloth_vertex(a, b, e, Vector2(u, v), fullness, panel_tone)

func rig(c: Dictionary) -> Dictionary:
	begin(c)
	var length: float = c.hull_length
	var dinghy: bool = c.get("dinghy", false)
	var mast_z := length * 0.08
	var mast_base := Vector3(0, 0.39 if dinghy else 0.85, mast_z)
	var mast_top := Vector3(0, c.mast_height, mast_z - 0.05)
	rod(mast_base, mast_top, 0.036, Color("a2aaa6"), 20)
	var spreader := mast_base.lerp(mast_top, 0.52)
	rod(spreader + Vector3.LEFT * c.beam * 0.36, spreader + Vector3.RIGHT * c.beam * 0.36, 0.020, brass, 12)
	var boom_height := 1.04 if dinghy else 1.55
	var boom_end := Vector3(sin(deg_to_rad(c.sail_angle)) * length * 0.46, boom_height, mast_z - cos(deg_to_rad(c.sail_angle)) * length * 0.46)
	rod(Vector3(0, boom_height, mast_z), boom_end, 0.032, Color("a2aaa6"), 16)
	var stay := mast_base.lerp(mast_top, 0.87)
	rod(stay, Vector3(0, 0.64, length * 0.46), 0.009, Color("989b8c"), 6)
	if not dinghy:
		rod(mast_top, Vector3(0, 0.59, -length * 0.44), 0.008, Color("989b8c"), 6)
	var shroud_height := 0.33 if dinghy else 0.51
	for side: float in [-1.0, 1.0]:
		var shroud_base := Vector3(side * c.beam * 0.40, shroud_height, length * 0.035)
		rod(stay, shroud_base, 0.008, Color("989b8c"), 6)
		rod(spreader + Vector3(side * c.beam * 0.36, 0, 0), shroud_base, 0.007, Color("989b8c"), 6)
	rod(boom_end, Vector3(0, 0.38, -length * 0.34), 0.010, wood.lightened(0.3), 8)
	if c.fenders_enabled:
		for z: float in [-0.22, 0.21]:
			var x: float = -c.beam * 0.48
			rod(Vector3(x, 0.55, z * length), Vector3(x - 0.10, 0.10, z * length), 0.010, ivory, 6)
			var fender := SphereMesh.new()
			fender.radius = 0.5
			fender.height = 1.0
			fender.radial_segments = 20
			fender.rings = 10
			append(fender, Transform3D(Basis.IDENTITY.scaled(Vector3(0.18, 0.38, 0.18)), Vector3(x - 0.10, 0.10, z * length)), Color("b4c8c5"))
	return finish()

func sails(c: Dictionary) -> Dictionary:
	begin(c)
	var dinghy: bool = c.get("dinghy", false)
	var mast_z: float = c.hull_length * 0.08
	var angle := deg_to_rad(c.sail_angle)
	var foot_height := 1.08 if dinghy else 1.59
	var clew := Vector3(sin(angle) * c.hull_length * 0.445, foot_height, mast_z - cos(angle) * c.hull_length * 0.445)
	var tack := Vector3(0.035, foot_height + 0.02, mast_z)
	var head := Vector3(0.035, c.mast_height - 0.26, mast_z - 0.04)
	sail(tack, head, clew, c.sail_fullness, c.sail_color)
	if not dinghy:
		sail_mark(tack, head, clew, c.sail_fullness)
	var stay_top := Vector3(0.025, lerpf(0.39 if dinghy else 0.85, c.mast_height, 0.87) - 0.10, mast_z)
	var jib_clew := Vector3(sin(angle) * c.hull_length * 0.13, 0.84 if dinghy else 1.19, mast_z - 0.25)
	sail(Vector3(0.025, 0.60 if dinghy else 0.72, c.hull_length * 0.445), stay_top, jib_clew, c.sail_fullness * 0.7, c.sail_color.darkened(0.025))
	return finish()
