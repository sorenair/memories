@tool
extends "res://components/scenery/sailing/shared/sailing_geometry.gd"

# Lengthwise stations in meters at the default size, from transom to prow.
# Each station stores Z, half-beam and the deck height at the gunwale.
const STATIONS := [
	Vector3(-3.70, 0.87, 0.78), Vector3(-3.36, 1.00, 0.73),
	Vector3(-2.72, 1.13, 0.68), Vector3(-1.90, 1.23, 0.63),
	Vector3(-1.00, 1.275, 0.61), Vector3(0.0, 1.26, 0.61),
	Vector3(0.86, 1.19, 0.63), Vector3(1.67, 1.04, 0.67),
	Vector3(2.31, 0.83, 0.73), Vector3(2.85, 0.59, 0.81),
	Vector3(3.31, 0.31, 0.91), Vector3(3.70, 0.035, 1.02),
]
# Width fraction, height above the waterline and aft rake at the bow.
const STRAKES := [
	Vector3(0.23, -0.59, 0.79), Vector3(0.62, -0.29, 0.44),
	Vector3(0.82, -0.075, 0.25), Vector3(0.85, 0.009, 0.20),
	Vector3(0.94, 0.26, 0.12), Vector3(0.95, 0.30, 0.10),
	Vector3(1.0, 0.53, 0.04), Vector3(1.0, 0.61, 0.0),
]
const RUBBER := Color("273237")
const ROPE := Color("ae9472")
const WINDOW := Color("324748")

func build(config: Dictionary, length: float, beam: float, fenders: bool) -> Dictionary:
	begin(config)
	var dimensions := Vector3(beam / 2.55, 1.0, length / 7.4)
	frame = Transform3D(Basis.from_scale(dimensions), Vector3.ZERO)
	_build_hull()
	_build_wheelhouse()
	_build_fittings(fenders)
	# The optional collision stays at the authored waterline during the small visual bob.
	var hull_points := PackedVector3Array()
	for station: Vector3 in STATIONS:
		for side: float in [-1.0, 1.0]:
			hull_points.append(frame * _hull_point(station, STRAKES.front(), side))
			hull_points.append(frame * _deck_point(station, side))
	colliders.append({"name": "Hull", "points": hull_points})
	collider(Vector3(0, 1.47, -1.69) * dimensions, Vector3(1.62, 1.65, 2.18) * dimensions, "Wheelhouse")
	anchors = {
		"Bow": frame * Vector3(0, 1.04, 3.52),
		"Stern": frame * Vector3(0, 0.8, -3.54),
		"PortMooring": frame * Vector3(-1.11, 0.86, 1.02),
		"StarboardMooring": frame * Vector3(1.11, 0.86, 1.02),
	}
	return finish()

func _hull_point(station: Vector3, strake: Vector3, side: float) -> Vector3:
	var t := clampf((station.x + 3.70) / 7.40, 0.0, 1.0)
	var rise := (station.z - 0.61) * smoothstep(-0.59, 0.61, strake.y)
	var tuck := pow(t, 5.0) * strake.z
	return Vector3(side * station.y * strake.x, strake.y + rise, station.x - tuck)

func _deck_point(station: Vector3, across: float) -> Vector3:
	return Vector3(across * station.y, station.z + (1.0 - absf(across)) * 0.025, station.x)

func _build_hull() -> void:
	var planks := [accent.darkened(0.51), accent.darkened(0.36), ivory.lerp(body, 0.22),
		body.darkened(0.14), body.darkened(0.30), body, body.lightened(0.11)]
	for i in STATIONS.size() - 1:
		var aft: Vector3 = STATIONS[i]
		var fore: Vector3 = STATIONS[i + 1]
		for row in planks.size():
			var tone: Color = planks[row]
			tone = tone.lightened(rng.randf_range(-0.032, 0.032))
			var low: Vector3 = STRAKES[row]
			var high: Vector3 = STRAKES[row + 1]
			for side: float in [-1.0, 1.0]:
				var a := _hull_point(aft, low, side)
				var b := _hull_point(aft, high, side)
				var c := _hull_point(fore, high, side)
				var d := _hull_point(fore, low, side)
				if side > 0.0:
					quad(a, b, c, d, tone)
				else:
					quad(d, c, b, a, tone)
		quad(_hull_point(aft, STRAKES[0], -1), _hull_point(aft, STRAKES[0], 1),
			_hull_point(fore, STRAKES[0], 1), _hull_point(fore, STRAKES[0], -1),
			accent.darkened(0.53))
		for side: float in [-1.0, 1.0]:
			_bulwark(_deck_point(aft, side), _deck_point(fore, side), side)
	# Cap both hull ends and run six full-length deck boards inside the curved outline.
	for end in [0, STATIONS.size() - 1]:
		var station: Vector3 = STATIONS[end]
		var side := -1.0 if end == 0 else 1.0
		for row in planks.size():
			var a := _hull_point(station, STRAKES[row], -side)
			var b := _hull_point(station, STRAKES[row], side)
			var c := _hull_point(station, STRAKES[row + 1], side)
			var d := _hull_point(station, STRAKES[row + 1], -side)
			quad(a, b, c, d, planks[row].darkened(0.07))
		var left := _deck_point(station, -side)
		var right := _deck_point(station, side)
		quad(left, right, right + Vector3.UP * 0.17,
			left + Vector3.UP * 0.17, accent.darkened(0.13))
	for board in 6:
		var across := -1.0 + board / 3.0
		var edge := across + 1.0 / 3.0
		var tone := accent.lightened(rng.randf_range(-0.075, 0.07))
		for i in STATIONS.size() - 1:
			var aft: Vector3 = STATIONS[i]
			var fore: Vector3 = STATIONS[i + 1]
			quad(_deck_point(aft, across), _deck_point(fore, across),
				_deck_point(fore, edge), _deck_point(aft, edge), tone)
			if board > 0:
				var start := _deck_point(aft, across) + Vector3.UP * 0.001
				var end := _deck_point(fore, across) + Vector3.UP * 0.001
				quad(start, end, end + Vector3.RIGHT * 0.012,
					start + Vector3.RIGHT * 0.012, accent.darkened(0.23))
	# Upturned painted stem and a broad ochre cargo hatch on the foredeck.
	rod(Vector3(0, 0.89, 3.59), Vector3(0, 1.33, 3.88), 0.057, accent.darkened(0.09), 8)
	flat_deck(Vector3(0, 0.71, 0.98), 0.94, 2.10, 0.16, accent.darkened(0.20), 0.035)
	for i in 5:
		flat_deck(Vector3(0, 0.80, 0.16 + i * 0.41), 0.91, 0.402, 0.08,
			brass.lightened(rng.randf_range(-0.07, 0.08)), 0.028)

func _bulwark(a: Vector3, b: Vector3, side: float) -> void:
	var top := Vector3.UP * 0.17
	var inset := Vector3(-side * 0.078, 0, 0)
	var a_top := a + top
	var b_top := b + top
	if side > 0:
		quad(a, a_top, b_top, b, accent.darkened(0.08))
		quad(b + inset, b_top + inset, a_top + inset, a + inset, accent.darkened(0.17))
	else:
		quad(b, b_top, a_top, a, accent.darkened(0.08))
		quad(a + inset, a_top + inset, b_top + inset, b + inset, accent.darkened(0.17))
	var edge := inset - Vector3.RIGHT * side * 0.015
	var cap := Vector3.RIGHT * side * 0.023
	var left := cap if side < 0 else edge
	var right := edge if side < 0 else cap
	quad(a_top + left, b_top + left, b_top + right, a_top + right, accent.lightened(0.13))

func _build_wheelhouse() -> void:
	var cabin_z := -1.69
	var fore := cabin_z + 1.09
	var aft := cabin_z - 1.09
	var half := 0.81
	var sill := 1.58
	var window_top := 2.12
	var roof := 2.35
	flat_deck(Vector3(0, 0.752, cabin_z), 1.79, 2.36, 0.19, accent.darkened(0.07), 0.045)
	# Recessed dark interior leaves real depth behind four bands of window openings.
	box(Vector3(0, 1.68, cabin_z), Vector3(1.15, 1.06, 1.67), WINDOW)
	for face: float in [-1.0, 1.0]:
		var z := cabin_z + 1.09 * face
		soft_box(Vector3(0, 1.20, z), Vector3(1.62, 0.80, 0.11), brass, 0.035)
		box(Vector3(0, 2.19, z), Vector3(1.62, 0.18, 0.11), brass.darkened(0.06))
		for i in 5:
			var x := -0.77 + i * 0.385
			box(Vector3(x, (sill + window_top) * 0.5, z), Vector3(0.073, window_top - sill + 0.06, 0.105), brass.lightened(0.10))
		for i in 6:
			var x := -0.65 + i * 0.26
			box(Vector3(x, 1.20, z + face * 0.057), Vector3(0.235, 0.62, 0.025),
				brass.lightened(rng.randf_range(-0.15, 0.065)))
		for y in [0.86, sill, window_top]:
			box(Vector3(0, y, z + face * 0.04), Vector3(1.73, 0.06, 0.10), brass.lightened(0.12))
		var x := face * half
		soft_box(Vector3(x, 1.20, cabin_z), Vector3(0.12, 0.80, 2.18), brass, 0.035)
		box(Vector3(x, 2.19, cabin_z), Vector3(0.12, 0.18, 2.18), brass.darkened(0.06))
		for i in 5:
			var pane_z := lerpf(aft, fore, i / 4.0)
			box(Vector3(x, 1.85, pane_z), Vector3(0.12, 0.58, 0.072), brass.lightened(0.10))
		for i in 7:
			var panel_z := aft + 0.18 + i * 0.302
			box(Vector3(x + face * 0.059, 1.21, panel_z), Vector3(0.035, 0.60, 0.276),
				brass.lightened(rng.randf_range(-0.12, 0.065)))
		for y in [0.86, sill, window_top]:
			box(Vector3(x + face * 0.03, y, cabin_z), Vector3(0.13, 0.062, 2.22), brass.lightened(0.10))
		# The fore side panel is a closed wheelhouse door with a dark latch.
		var door := Vector3(face * 0.897, 1.17, fore - 0.27)
		box(door, Vector3(0.065, 0.66, 0.45), brass.darkened(0.19))
		box(door + Vector3(face * 0.035, 0.07, -0.10), Vector3(0.056, 0.045, 0.10), RUBBER)
		flat_deck(Vector3(face * 0.96, 0.78, door.z), 0.29, 0.54, 0.08, accent.darkened(0.20), 0.025)
	var roof_back := -2.97
	var roof_front := -0.36
	flat_deck(Vector3(0, roof - 0.025, cabin_z), 1.98, 2.65, 0.14, brass.darkened(0.06), 0.05)
	for i in 6:
		var left := -0.99 + i * 0.33
		var right := left + 0.33
		var y0 := roof + 0.04 + 0.075 * (1.0 - absf(left))
		var y1 := roof + 0.04 + 0.075 * (1.0 - absf(right))
		quad(Vector3(left, y0, roof_back), Vector3(left, y0, roof_front),
			Vector3(right, y1, roof_front), Vector3(right, y1, roof_back),
			brass.lightened(rng.randf_range(-0.05, 0.07)))
		quad(Vector3(left, roof + 0.02, roof_front), Vector3(right, roof + 0.02, roof_front),
			Vector3(right, y1, roof_front), Vector3(left, y0, roof_front), brass)
		quad(Vector3(right, roof + 0.02, roof_back), Vector3(left, roof + 0.02, roof_back),
			Vector3(left, y0, roof_back), Vector3(right, y1, roof_back), brass.darkened(0.08))
	for side: float in [-1.0, 1.0]:
		var x := side * 0.88
		rod(Vector3(x, roof + 0.082, roof_back + 0.07),
			Vector3(x, roof + 0.082, roof_front - 0.07), 0.038, body.darkened(0.06), 8)
	flat_deck(Vector3(-0.47, 2.49, -0.72), 0.30, 0.44, 0.11, WINDOW.lightened(0.11), 0.026)
	tube([Vector3(0.94, 0.74, -1.98), Vector3(0.995, 2.66, -1.98),
		Vector3(0.995, 2.82, -2.04), Vector3(0.995, 3.03, -2.30)], 0.058, RUBBER.lerp(accent, 0.35), 10)

func _build_fittings(fenders: bool) -> void:
	for side: float in [-1.0, 1.0]:
		for at in [Vector3(0.89, 0.78, -3.42), Vector3(1.18, 0.61, -0.32),
				Vector3(1.11, 0.65, 1.02), Vector3(0.56, 0.82, 2.78)]:
			var post := Vector3(side * at.x, at.y, at.z)
			soft_box(post + Vector3.UP * 0.15, Vector3(0.13, 0.34, 0.15), accent.lightened(0.09), 0.032)
			box(post + Vector3.UP * 0.21, Vector3(0.143, 0.056, 0.164), ROPE.darkened(0.29))
		if fenders:
			_tire_fender(side, Vector3(1.11, 0.88, 1.02), Vector3(1.26, 0.26, 0.97), 0.225)
			_tire_fender(side, Vector3(1.18, 0.88, -0.32), Vector3(1.39, 0.25, -0.40), 0.25)
	# Keep the cargo deck readable from the high exploration camera.
	cleat(Vector3(0, 1.00, 3.36), RUBBER)
	soft_box(Vector3(-0.66, 0.77, -0.16), Vector3(0.40, 0.26, 0.47), body.darkened(0.18), 0.038)
	for z in [-0.31, -0.02]:
		box(Vector3(-0.66, 0.889, z), Vector3(0.43, 0.07, 0.09), body.lightened(0.16))
	var coil := TorusMesh.new()
	coil.inner_radius = 0.083
	coil.outer_radius = 0.142
	coil.rings = 14
	coil.ring_segments = 6
	append(coil, Transform3D(Basis.IDENTITY, Vector3(0.36, 0.812, 2.32)), ROPE)
	append(coil, Transform3D(Basis.IDENTITY, Vector3(0.38, 0.859, 2.31)), ROPE.lightened(0.08))

func _tire_fender(side: float, tie: Vector3, center: Vector3, radius: float) -> void:
	tie.x *= side
	center.x *= side
	var tire := TorusMesh.new()
	tire.inner_radius = radius * 0.56
	tire.outer_radius = radius
	tire.rings = 18
	tire.ring_segments = 8
	var orientation := Basis(Vector3.BACK, PI * 0.5).scaled(Vector3(0.58, 1.0, 1.0))
	append(tire, Transform3D(orientation, center), RUBBER)
	for offset: float in [-0.052, 0.052]:
		tube([tie + Vector3(0, 0, offset), tie + Vector3(side * 0.11, -0.14, offset),
			center + Vector3(0, radius * 0.69, offset)], 0.014, ROPE, 6)
