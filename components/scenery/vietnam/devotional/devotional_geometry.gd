@tool
extends "res://components/scenery/tokyo/shared/japanese_geometry.gd"

func budai(config: Dictionary) -> Dictionary:
	begin(config)
	# A lotus seat, one knee raised, the other folded, and a hand resting on each.
	disc(Vector3(0, 0.12, 0), 0.69, 0.20, brass, Vector3.UP, 0, 18)
	disc(Vector3(0, 0.26, 0), 0.62, 0.17, accent, Vector3.UP, 0, 18)
	for index in 14:
		var turn := TAU * index / 14.0
		_form(Vector3(sin(turn) * 0.55, 0.26, cos(turn) * 0.55),
			Vector3(0.145, 0.09, 0.19), body.lightened(0.06), Basis(Vector3.UP, turn))
	_form(Vector3(0.17, 0.45, 0.09), Vector3(0.49, 0.20, 0.40), accent, Basis(Vector3.UP, -0.28))
	_form(Vector3(-0.37, 0.65, 0.22), Vector3(0.24, 0.36, 0.28), accent, Basis(Vector3.BACK, 0.32))
	_form(Vector3(0, 0.95, -0.06), Vector3(0.47, 0.47, 0.29), body)
	_form(Vector3(0.035, 0.80, 0.21), Vector3(0.38, 0.32, 0.27), body.lightened(0.056))
	_form(Vector3(0.39, 0.91, 0.045), Vector3(0.145, 0.28, 0.15), accent, Basis(Vector3.BACK, 0.43))
	_form(Vector3(0.45, 0.71, 0.23), Vector3(0.105, 0.13, 0.105), body)
	_form(Vector3(-0.40, 0.95, 0.19), Vector3(0.13, 0.16, 0.19), body, Basis(Vector3.RIGHT, -0.55))
	var drape := body.lerp(accent, 0.68)
	tube([Vector3(-0.31, 1.27, 0.09), Vector3(-0.38, 1.02, 0.28), Vector3(-0.32, 0.73, 0.29),
		Vector3(-0.22, 0.59, 0.40), Vector3(0.05, 0.53, 0.49), Vector3(0.36, 0.52, 0.38)], 0.048, drape, 8)
	for index in 9:
		var angle := 0.27 + index * 0.34
		_form(Vector3(-0.40 + cos(angle) * 0.165, 0.88 - sin(angle) * 0.21, 0.365), Vector3.ONE * 0.034, brass)
	_form(Vector3(0.015, 1.51, 0.04), Vector3(0.264, 0.28, 0.225), body)
	for side: float in [-1.0, 1.0]:
		_form(Vector3(0.015 + side * 0.25, 1.45, 0.068), Vector3(0.06, 0.10, 0.055), body)
		_form(Vector3(0.015 + side * 0.122, 1.49, 0.215), Vector3(0.09, 0.075, 0.069), body.lightened(0.048))
		tube([Vector3(0.015 + side * 0.062, 1.562, 0.258), Vector3(0.015 + side * 0.103, 1.577, 0.251),
			Vector3(0.015 + side * 0.151, 1.562, 0.232)], 0.012, brass.darkened(0.55), 6)
	_form(Vector3(0.015, 1.525, 0.265), Vector3(0.052, 0.057, 0.065), body.lightened(0.03))
	tube([Vector3(-0.079, 1.455, 0.251), Vector3(-0.044, 1.421, 0.267), Vector3(0.016, 1.408, 0.276),
		Vector3(0.078, 1.424, 0.266), Vector3(0.107, 1.455, 0.247)], 0.017, accent.darkened(0.52), 8)
	collider(Vector3(0, 0.59, 0), Vector3(1.32, 1.18, 1.1), "LotusSeat")
	return finish()

func _form(center: Vector3, radii: Vector3, tint: Color, basis := Basis.IDENTITY) -> void:
	for row in 8:
		for column in 12:
			var color := tint.lightened(0.016 * sin(row + column * 1.9))
			for pair: Vector2 in [Vector2(0, 0), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0), Vector2(0, 1), Vector2(1, 1)]:
				var angle := TAU * (column + pair.x) / 12.0
				var latitude := PI * (row + pair.y) / 8.0
				var direction := Vector3(sin(angle) * sin(latitude), cos(latitude), cos(angle) * sin(latitude))
				vertex(center + basis * (direction * radii), basis * (direction / radii).normalized(), color)

func shrine(config: Dictionary) -> Dictionary:
	begin(config)
	flat_deck(Vector3(0, 0.045, 0), 3.50, 2.52, 0.09, brass, 0.09)
	for x: float in [-1.33, 1.33]:
		for z: float in [-0.93, 0.93]:
			tapered_post(Vector3(x, 0.10, z), Vector3(x, 2.04, z), 0.095, body)
			box(Vector3(x, 0.13, z), Vector3(0.28, 0.20, 0.28), accent.darkened(0.12))
			collider(Vector3(x, 1.0, z), Vector3(0.20, 2.0, 0.20), "ShrinePost")
			if z > 0:
				_column_relief(x, z)
	box(Vector3(0, 1.93, 0.90), Vector3(3.18, 0.22, 0.22), accent)
	roof(Vector3(0, 2.05, 0), Vector2(4.10, 3.05), 0.71, roof_paint, 0.21)
	rod(Vector3(-1.23, 2.8, 0), Vector3(1.23, 2.8, 0), 0.045, brass, 8)
	for side: float in [-1.0, 1.0]:
		tube([Vector3(side * 1.23, 2.8, 0), Vector3(side * 1.40, 2.84, 0), Vector3(side * 1.53, 3.00, 0)], 0.04, brass, 8)
	soft_box(Vector3(0, 0.48, -0.71), Vector3(1.27, 0.71, 0.44), accent, 0.05)
	box(Vector3(0, 0.87, -0.71), Vector3(1.40, 0.12, 0.56), brass)
	box(Vector3(0, 1.27, -0.91), Vector3(0.76, 0.61, 0.08), accent.darkened(0.38))
	box(Vector3(0, 1.28, -0.856), Vector3(0.55, 0.45, 0.05), brass.darkened(0.11))
	collider(Vector3(0, 0.49, -0.71), Vector3(1.34, 0.83, 0.54), "ShrineAltar")
	anchors["Approach"] = Vector3(0, 0, 1.45)
	return finish()

func _column_relief(x: float, z: float) -> void:
	var spiral: Array[Vector3] = []
	for index in 27:
		var t := index / 26.0
		var angle := t * TAU * 2.8 + signf(x) * PI
		spiral.append(Vector3(x + 0.097 * sin(angle), 0.25 + t * 1.63, z + 0.097 * cos(angle)))
	tube(spiral, 0.024, Color("568476"), 6)
	_form(spiral[-3], Vector3(0.065, 0.051, 0.055), brass)

func censer(config: Dictionary) -> Dictionary:
	begin(config)
	TURNED.lathe(self, [Vector2(0, 0.14), Vector2(0.20, 0.14), Vector2(0.32, 0.22),
		Vector2(0.38, 0.36), Vector2(0.35, 0.48), Vector2(0.39, 0.53), Vector2(0.35, 0.56),
		Vector2(0.30, 0.54), Vector2(0.29, 0.43)], body, 0, 24, 0.009)
	disc(Vector3(0, 0.445, 0), 0.30, 0.05, accent.darkened(0.50), Vector3.UP, 0, 20)
	for index in 3:
		var angle := TAU * index / 3.0
		var side := Vector3(sin(angle), 0, cos(angle))
		tube([side * 0.22 + Vector3.UP * 0.24, side * 0.28 + Vector3.UP * 0.12, side * 0.25 + Vector3.UP * 0.025],
			0.066, brass.darkened(0.1), 8)
	for side: float in [-1.0, 1.0]:
		tube([Vector3(side * 0.31, 0.30, 0), Vector3(side * 0.49, 0.43, 0), Vector3(side * 0.43, 0.64, 0),
			Vector3(side * 0.36, 0.56, 0)], 0.042, brass, 8)
	collider(Vector3(0, 0.28, 0), Vector3(0.80, 0.56, 0.72), "Censer")
	anchors["Flame"] = Vector3(0, 0.48, 0)
	return finish()
