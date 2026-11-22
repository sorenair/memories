@tool
extends PainterlyConcertComponent
## Enger Tower's octagonal masonry silhouette, open window bays, and roof lookout.
const APOTHEM := 1.54
const PARAPET_Y := 7.35

func _build_geometry() -> Dictionary:
	var builder := GEOMETRY.new()
	builder.begin(_config())
	var dark := accent_color.darkened(0.28)
	builder.disc(Vector3(0, 0.18, 0), 2.42, 0.38, body_color.darkened(0.21), Vector3.UP, 0, 8)
	builder.disc(Vector3(0, 0.39, 0), 2.29, 0.08, trim_color.darkened(0.09), Vector3.UP, 0, 8)
	for step in range(4):
		var z := 2.08 + step * 0.25
		var height := (4 - step) * 0.104
		builder.box(Vector3(0, height * 0.5, z), Vector3(1.98, height, 0.255),
			body_color.lightened(0.04 - step * 0.025))
	# An inset core gives windows depth without sealing them at the facade.
	builder.disc(Vector3(0, 3.89, 0), 1.38, 6.91, dark, Vector3.UP, 0, 8)
	for face in range(8):
		var turn := Basis(Vector3.UP, face * TAU / 8.0)
		for level in range(5):
			_build_storey(builder, turn, face, level)
		_deck_rail(builder, turn)
	builder.disc(Vector3(0, PARAPET_Y + 0.28, 0), 1.89, 0.16, trim_color, Vector3.UP, 0, 8)
	builder.disc(Vector3(0, PARAPET_Y + 0.42, 0), 1.48, 0.14, trim_color.darkened(0.16), Vector3.UP, 0, 8)
	builder.disc(Vector3(0, PARAPET_Y + 0.55, 0), 0.97, 0.15, trim_color, Vector3.UP, 0, 8)
	builder.rod(Vector3(0, PARAPET_Y + 0.5, 0), Vector3(0, PARAPET_Y + 1.50, 0), 0.034, trim_color.lightened(0.13), 8)
	builder.disc(Vector3(0, PARAPET_Y + 1.40, 0), 0.20, 0.045, trim_color.lightened(0.13), Vector3.UP, 0, 12)
	builder.colliders.append({"name": "TowerExterior", "center": Vector3(0, 3.76, 0), "size": Vector3(2.83, 7.52, 2.83)})
	builder.anchors["Roof"] = Vector3(0, PARAPET_Y + 1.50, 0)
	return builder.finish()

func _build_storey(builder: RefCounted, turn: Basis, face: int, level: int) -> void:
	var floor_y := 0.43 + level * 1.31
	var opening := (face == 0 if level == 0 else (level > 1 or face % 2 == 0))
	var half_opening := 0.414 if level == 0 else 0.36
	var sill := 0.077 if level == 0 else 0.40
	var half_width := APOTHEM * tan(PI / 8.0)
	var mortar := Color("8c7b68")
	for row in range(5):
		var y0 := row * 0.262
		var y1 := y0 + 0.262
		var inset := half_opening if row < 4 else half_opening * 0.72
		if opening and y1 > sill and row < 4:
			if y0 < sill:
				_course(builder, turn, -half_width, half_width, floor_y + y0, floor_y + sill, mortar)
			_course(builder, turn, -half_width, -inset, floor_y + maxf(y0, sill), floor_y + y1, mortar)
			_course(builder, turn, inset, half_width, floor_y + maxf(y0, sill), floor_y + y1, mortar)
		else:
			_course(builder, turn, -half_width, half_width, floor_y + y0, floor_y + y1, mortar)
	if opening:
		_opening_trim(builder, turn, floor_y, sill, half_opening, level)

func _course(builder: RefCounted, face: Basis, left: float, right: float, low: float, high: float, mortar: Color) -> void:
	_wall(builder, face, left, right, low, high, APOTHEM - 0.01, mortar)
	var width := right - left
	var tiles := maxi(1, roundi(width / builder.rng.randf_range(0.24, 0.37)))
	for i in range(tiles):
		var from := lerpf(left, right, float(i) / tiles) + 0.008
		var to := lerpf(left, right, float(i + 1) / tiles) - 0.008
		var rock := body_color.lerp(accent_color, builder.rng.randf_range(0.0, 0.60)).lightened(builder.rng.randf_range(-0.14, 0.11))
		_wall(builder, face, from, to, low + 0.009, high - 0.009,
			APOTHEM + builder.rng.randf_range(0.001, 0.013), rock)

func _opening_trim(builder: RefCounted, face: Basis, floor_y: float, sill: float, half_width: float, level: int) -> void:
	var lintel := floor_y + 1.05
	var lower := floor_y + sill
	var depth := APOTHEM - 0.16
	for side: float in [-1, 1]:
		var x := side * half_width
		builder.quad(face * Vector3(x, lower, APOTHEM), face * Vector3(x, lintel, APOTHEM),
			face * Vector3(x, lintel, depth), face * Vector3(x, lower, depth), accent_color)
	builder.box(face * Vector3(0, lower - 0.04, APOTHEM - 0.041),
		Vector3(half_width * 2.07, 0.083, 0.245), body_color.lightened(0.04), 0, face)
	builder.box(face * Vector3(0, lintel + 0.014, APOTHEM - 0.038),
		Vector3(half_width * 2.17, 0.13, 0.24), body_color.lightened(0.07), 0, face)
	if level > 0:
		builder.rod(face * Vector3(-half_width, lower + 0.16, depth),
			face * Vector3(half_width, lower + 0.16, depth), 0.023, trim_color.darkened(0.17), 8)

func _deck_rail(builder: RefCounted, face: Basis) -> void:
	var edge := 1.62
	var half := edge * tan(PI / 8.0)
	_wall(builder, face, -half, half, 6.98, 7.13, edge, body_color.darkened(0.11))
	for x: float in [-half, 0.0]:
		builder.rod(face * Vector3(x, 7.08, edge), face * Vector3(x, 7.61, edge), 0.034, trim_color, 8)
	for h: float in [7.30, 7.61]:
		builder.rod(face * Vector3(-half, h, edge), face * Vector3(half, h, edge), 0.032, trim_color, 8)

func _wall(builder: RefCounted, face: Basis, left: float, right: float, bottom: float, top: float, depth: float, color: Color) -> void:
	builder.quad(face * Vector3(left, bottom, depth), face * Vector3(right, bottom, depth),
		face * Vector3(right, top, depth), face * Vector3(left, top, depth), color)
