@tool
extends RefCounted
## Vector contours traced from the supplied Minnesota mark; the detached ® is omitted.
const MAROON := Color("7a0019")
const GOLD := Color("ffcc33")

const OUTER := [
	Vector2(-0.500000, 0.146029), Vector2(-0.500000, 0.296328), Vector2(-0.203672, 0.296328), Vector2(-0.203672, 0.146029),
	Vector2(-0.255764, 0.146029), Vector2(-0.256618, 0.144321), Vector2(-0.165243, -0.006832), Vector2(-0.129377, 0.052092),
	Vector2(-0.163535, 0.052946), Vector2(-0.162681, 0.204099), Vector2(0.161827, 0.204099), Vector2(0.161827, 0.052946),
	Vector2(0.129377, 0.052946), Vector2(0.128523, 0.051238), Vector2(0.161827, -0.004270), Vector2(0.164389, -0.005978),
	Vector2(0.254910, 0.143467), Vector2(0.254056, 0.146029), Vector2(0.201964, 0.146029), Vector2(0.201964, 0.296328),
	Vector2(0.499146, 0.296328), Vector2(0.499146, 0.146029), Vector2(0.437660, 0.146029), Vector2(0.435098, 0.143467),
	Vector2(0.261742, -0.145175), Vector2(0.262596, -0.146883), Vector2(0.309564, -0.146883), Vector2(0.309564, -0.297182),
	Vector2(0.018360, -0.297182), Vector2(0.018360, -0.146883), Vector2(0.065329, -0.146883), Vector2(0.066183, -0.145175),
	Vector2(-0.000427, -0.035013), Vector2(-0.067891, -0.146029), Vector2(-0.020068, -0.146883), Vector2(-0.020068, -0.297182),
	Vector2(-0.310418, -0.297182), Vector2(-0.310418, -0.146883), Vector2(-0.262596, -0.146029), Vector2(-0.438514, 0.146029),
]
const GOLD_BORDER := [
	Vector2(-0.480359, 0.164816), Vector2(-0.480359, 0.277541), Vector2(-0.223313, 0.277541), Vector2(-0.223313, 0.165670),
	Vector2(-0.289923, 0.165670), Vector2(-0.290777, 0.163108), Vector2(-0.165243, -0.044406), Vector2(-0.095218, 0.070880),
	Vector2(-0.096072, 0.072588), Vector2(-0.143894, 0.072588), Vector2(-0.143894, 0.184458), Vector2(0.142186, 0.184458),
	Vector2(0.142186, 0.072588), Vector2(0.095218, 0.072588), Vector2(0.094364, 0.070026), Vector2(0.164389, -0.044406),
	Vector2(0.289923, 0.163962), Vector2(0.221605, 0.165670), Vector2(0.221605, 0.276687), Vector2(0.479505, 0.277541),
	Vector2(0.479505, 0.165670), Vector2(0.426558, 0.165670), Vector2(0.423997, 0.163108), Vector2(0.226729, -0.164816),
	Vector2(0.289923, -0.165670), Vector2(0.289923, -0.278395), Vector2(0.038002, -0.278395), Vector2(0.038002, -0.165670),
	Vector2(0.099488, -0.165670), Vector2(0.100342, -0.163962), Vector2(-0.000427, 0.003416), Vector2(-0.102050, -0.164816),
	Vector2(-0.038856, -0.166524), Vector2(-0.039710, -0.278395), Vector2(-0.290777, -0.278395), Vector2(-0.290777, -0.166524),
	Vector2(-0.229291, -0.166524), Vector2(-0.228437, -0.164816), Vector2(-0.424851, 0.162254), Vector2(-0.427412, 0.164816),
]
const INNER := [
	Vector2(-0.461571, 0.185312), Vector2(-0.460717, 0.257899), Vector2(-0.242955, 0.257899), Vector2(-0.242955, 0.184458),
	Vector2(-0.325790, 0.183604), Vector2(-0.165243, -0.081981), Vector2(-0.061059, 0.089667), Vector2(-0.061913, 0.092229),
	Vector2(-0.124253, 0.092229), Vector2(-0.124253, 0.164816), Vector2(0.123399, 0.164816), Vector2(0.123399, 0.092229),
	Vector2(0.060205, 0.092229), Vector2(0.059351, 0.090521), Vector2(0.164389, -0.081981), Vector2(0.324082, 0.182750),
	Vector2(0.323228, 0.184458), Vector2(0.241247, 0.184458), Vector2(0.241247, 0.257899), Vector2(0.459863, 0.257899),
	Vector2(0.459863, 0.184458), Vector2(0.413749, 0.183604), Vector2(0.192570, -0.184458), Vector2(0.270282, -0.185312),
	Vector2(0.270282, -0.258753), Vector2(0.057643, -0.258753), Vector2(0.057643, -0.185312), Vector2(0.135354, -0.184458),
	Vector2(-0.000427, 0.040991), Vector2(-0.137062, -0.184458), Vector2(-0.059351, -0.185312), Vector2(-0.058497, -0.258753),
	Vector2(-0.271990, -0.258753), Vector2(-0.271136, -0.185312), Vector2(-0.193424, -0.184458), Vector2(-0.416311, 0.184458),
]

static func append_field_mark(b: RefCounted, center: Vector3, width: float) -> void:
	var layers := [OUTER, GOLD_BORDER, INNER]
	for layer in 3:
		var points := PackedVector2Array(layers[layer])
		var indices := Geometry2D.triangulate_polygon(points)
		var color := GOLD if layer == 1 else MAROON
		for index in indices:
			var point := points[index]
			b.vertex(center + Vector3(point.x * width, layer * 0.004, point.y * width),
				Vector3.UP, color, 4.0)

static func append_seat_mark(b: RefCounted, center_row: float, width: float, field_z: float, bowl_radii: Vector2) -> void:
	# A finely curved paint surface follows the actual rows. Sampling the supplied
	# mark preserves its outline without long vector triangles cutting into steps.
	var columns := 24
	var rows := 16
	var aspect := 696.0 / 1171.0
	var corners := [Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 0), Vector2(1, 1), Vector2(0, 1)]
	for row in rows:
		for column in columns:
			for corner: Vector2 in corners:
				var uv := Vector2((column + corner.x) / columns, (row + corner.y) / rows)
				var x := (uv.x - 0.5) * width
				var seat_row := center_row - (uv.y - 0.5) * width * aspect / Vector2(0.55, 0.72).length()
				b.s.set_uv((Vector2(7, 12) + uv * Vector2(1171, 696)) / Vector2(1280, 720))
				b.vertex(seat_point(x, seat_row, field_z, bowl_radii) + Vector3(0, 0.12, 0.09),
					Vector3(0, 0.8, 0.6), Color.WHITE, 6.0)
	b.s.set_uv(Vector2.ZERO)

static func seat_point(x: float, row: float, field_z: float, bowl_radii: Vector2) -> Vector3:
	var radius_x := bowl_radii.x + row * 0.55
	var radius_z := bowl_radii.y + row * 0.72
	var z := field_z - radius_z * sqrt(maxf(0.0, 1.0 - pow(x / radius_x, 2.0)))
	return Vector3(x, 1.4 + row * 0.55 + 0.36, z + 0.25)

static func append_seat_text(b: RefCounted, value: String, center_row: float, height: float, field_z: float, bowl_radii: Vector2) -> void:
	var mesh := _text_mesh(value, height)
	var arrays := mesh.surface_get_arrays(0)
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	var center := mesh.get_aabb().get_center()
	for index in indices:
		var point := vertices[index] - center
		var row := center_row + point.y / Vector2(0.55, 0.72).length()
		b.vertex(seat_point(point.x, row, field_z, bowl_radii), Vector3(0, 0.8, 0.6), GOLD, 4.0)

static func append_end_zone_text(b: RefCounted, center: Vector3, side: float, height: float, max_width: float) -> void:
	var mesh := _text_mesh("MINNESOTA", height)
	var offset := mesh.get_aabb().get_center()
	var scale := minf(1.0, max_width / mesh.get_aabb().size.x)
	var basis := Basis(Vector3(0, 0, -side), Vector3(-side, 0, 0), Vector3.UP).scaled(Vector3.ONE * scale)
	b.append(mesh, Transform3D(basis, center - basis * offset), GOLD, 4.0)

static func _text_mesh(value: String, height: float) -> TextMesh:
	var font := SystemFont.new()
	font.font_names = PackedStringArray(["Arial Black", "DejaVu Sans", "Arial"])
	font.font_weight = 900
	var mesh := TextMesh.new()
	mesh.font = font
	mesh.text = value
	mesh.font_size = 64
	mesh.pixel_size = height / 64.0
	mesh.depth = 0.0
	return mesh
