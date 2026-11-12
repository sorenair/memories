@tool
extends RefCounted
## Independently interchangeable standing bodies and heads; one shared paint material.
## UV2.x identifies clothing, trousers, skin, hair, or shoes; UV2.y masks head motion.
## UV.x identifies an arm side, UV.y blends its two joints, COLOR.r carries body width.
const BODY_COUNT := 8
const HEAD_COUNT := 8
static var _bodies: Dictionary = {}
static var _heads: Dictionary = {}

static func get_body(variant: int) -> ArrayMesh:
	variant = posmod(variant, BODY_COUNT)
	if not _bodies.has(variant):
		_bodies[variant] = _build_body(variant)
	return _bodies[variant]

static func get_head(variant: int) -> ArrayMesh:
	variant = posmod(variant, HEAD_COUNT)
	if not _heads.has(variant):
		_heads[variant] = _build_head(variant)
	return _heads[variant]

static func _attributes(surface: SurfaceTool, point: Vector3, arm_side: float, width: float) -> void:
	var elbow_weight := clampf((0.726 - point.y) / 0.082, 0.0, 1.0) if not is_zero_approx(arm_side) else 0.0
	surface.set_uv(Vector2(arm_side, elbow_weight))
	surface.set_color(Color(width * 0.5, 0, 0, 1))

static func _append(surface: SurfaceTool, mesh: Mesh, transform: Transform3D, kind: float, head: float = 0.0, arm_side: float = 0.0, width: float = 1.0) -> void:
	var arrays := mesh.surface_get_arrays(0)
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	var normal_basis := transform.basis.inverse().transposed()
	for index in indices:
		surface.set_normal((normal_basis * normals[index]).normalized())
		surface.set_uv2(Vector2(kind, head))
		var point := transform * vertices[index]
		_attributes(surface, point, arm_side, width)
		surface.add_vertex(point)

static func _oval(surface: SurfaceTool, center: Vector3, radii: Vector3, kind: float, head: float = 0.0, segments: int = 10, rings: int = 5, arm_side: float = 0.0, width: float = 1.0) -> void:
	var sphere := SphereMesh.new()
	sphere.radius = 1.0
	sphere.height = 2.0
	sphere.radial_segments = segments
	sphere.rings = rings
	_append(surface, sphere, Transform3D(Basis.IDENTITY.scaled(radii), center), kind, head, arm_side, width)

static func _tube(surface: SurfaceTool, points: PackedVector3Array, widths: PackedVector2Array, kind: float, sides: int = 8, arm_side: float = 0.0, width: float = 1.0) -> void:
	# Curved, softly tapered limbs and torso instead of stacked hard-edged cylinders.
	if not is_zero_approx(arm_side):
		# Extra rings localize the bend to the elbow instead of shearing an entire
		# long polygon from shoulder to wrist when a garment uses a new pose.
		var divided_points := PackedVector3Array()
		var divided_widths := PackedVector2Array()
		for index in range(points.size()):
			divided_points.append(points[index])
			divided_widths.append(widths[index])
			if index + 1 < points.size():
				divided_points.append(points[index].lerp(points[index + 1], 0.5))
				divided_widths.append(widths[index].lerp(widths[index + 1], 0.5))
		points = divided_points
		widths = divided_widths
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	for ring in range(points.size()):
		var previous := points[maxi(0, ring - 1)]
		var following := points[mini(points.size() - 1, ring + 1)]
		var tangent := (following - previous).normalized()
		var right := Vector3.RIGHT.slide(tangent).normalized()
		var forward := right.cross(tangent).normalized()
		for side in range(sides):
			var angle := float(side) * TAU / float(sides)
			vertices.append(points[ring] + right * cos(angle) * widths[ring].x + forward * sin(angle) * widths[ring].y)
			normals.append((right * cos(angle) / widths[ring].x + forward * sin(angle) / widths[ring].y).normalized())
	for ring in range(points.size() - 1):
		for side in range(sides):
			var a := ring * sides + side
			var b := ring * sides + (side + 1) % sides
			var c := (ring + 1) * sides + side
			var d := (ring + 1) * sides + (side + 1) % sides
			for index in [a, c, b, b, c, d]:
				surface.set_normal(normals[index])
				surface.set_uv2(Vector2(kind, 0.0))
				# A whole cross-section shares its joint weight, avoiding pinched,
				# triangular elbows when a forearm bends sharply across the chest.
				_attributes(surface, points[index / sides], arm_side, width)
				surface.add_vertex(vertices[index])
	# Ends are closed, including the shirt hem visible from the elevated camera.
	for ring in [0, points.size() - 1]:
		var normal := (points[0] - points[1]).normalized() if ring == 0 else (points[-1] - points[-2]).normalized()
		for side in range(sides):
			var rim := [ring * sides + side, ring * sides + (side + 1) % sides]
			if ring == 0:
				rim.reverse()
			surface.set_normal(normal)
			surface.set_uv2(Vector2(kind, 0.0))
			_attributes(surface, points[ring], arm_side, width)
			surface.add_vertex(points[ring])
			for index in rim:
				_attributes(surface, points[ring], arm_side, width)
				surface.add_vertex(vertices[index])

static func _hair(surface: SurfaceTool, variant: int, head_radii: Vector3) -> void:
	var segments := 12
	var rings := 5
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var radii := head_radii + Vector3(0.010, 0.013, 0.010)
	if variant == 1:
		radii += Vector3(0.012, 0.0, 0.008)
	var center := Vector3(0, 1.105, -0.004)
	for ring in range(rings + 1):
		for side in range(segments + 1):
			var angle := float(side) * TAU / float(segments)
			var front := sin(angle) * 0.5 + 0.5
			var hem := lerpf(2.00 if variant != 1 else 2.65, 1.14, pow(front, 3.0))
			var phi := float(ring) / float(rings) * hem
			var n := Vector3(cos(angle) * sin(phi), cos(phi), sin(angle) * sin(phi))
			var point := center + n * radii
			point.y += sin(angle * 2.0 + float(variant)) * 0.007 * sin(phi)
			if variant == 0:
				point.y += (n.x * 0.5 + 0.5) * maxf(0.0, n.y) * 0.020
			vertices.append(point)
			normals.append((n / radii).normalized())
	for ring in range(rings):
		for side in range(segments):
			var a := ring * (segments + 1) + side
			var b := a + 1
			var c := a + segments + 1
			var d := c + 1
			for index in [a, b, c, b, d, c]:
				surface.set_normal(normals[index])
				surface.set_uv2(Vector2(3.0, 1.0))
				_attributes(surface, vertices[index], 0.0, 1.0)
				surface.add_vertex(vertices[index])

static func _build_head(variant: int) -> ArrayMesh:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var widths := [0.098, 0.094, 0.108, 0.093, 0.101, 0.094, 0.102, 0.100]
	var heights := [0.121, 0.123, 0.114, 0.127, 0.116, 0.122, 0.124, 0.119]
	var radii := Vector3(widths[variant], heights[variant], 0.096)
	if variant == 3:
		# Long hair is a fitted mass behind the head, not a helmet over the face.
		_oval(surface, Vector3(0, 1.045, -0.066), Vector3(0.109, 0.182, 0.072), 3, 1)
	_oval(surface, Vector3(0, 1.105, 0), radii, 2, 1, 12, 6)
	for sign_x: float in [-1.0, 1.0]:
		_oval(surface, Vector3(sign_x * radii.x, 1.091, 0), Vector3(0.016, 0.024, 0.021), 2, 1, 6, 3)
	if variant < 6:
		_hair(surface, variant, radii)
	if variant == 2:
		# Broad rounded curls change the silhouette without adding strand-level noise.
		for tuft in range(7):
			var a := float(tuft) * TAU / 7.0
			_oval(surface, Vector3(cos(a) * 0.074, 1.201 + sin(a * 2.0) * 0.014, sin(a) * 0.061), Vector3(0.052, 0.050, 0.050), 3, 1, 8, 3)
	elif variant == 4:
		_oval(surface, Vector3(0.012, 1.213, -0.105), Vector3(0.067, 0.067, 0.061), 3, 1, 10, 4)
	elif variant == 5:
		_oval(surface, Vector3(0.012, 1.054, -0.120), Vector3(0.055, 0.110, 0.064), 3, 1, 10, 4)
	elif variant == 6:
		_oval(surface, Vector3(0, 1.091, -0.080), Vector3(0.091, 0.078, 0.040), 3, 1, 10, 4)
		for sign_x: float in [-1.0, 1.0]:
			_oval(surface, Vector3(sign_x * 0.094, 1.099, -0.027), Vector3(0.018, 0.064, 0.052), 3, 1, 8, 3)
	elif variant == 7:
		_oval(surface, Vector3(0, 1.208, -0.010), Vector3(0.112, 0.074, 0.112), 5, 1, 12, 4)
		_oval(surface, Vector3(0, 1.166, 0.074), Vector3(0.124, 0.012, 0.125), 5, 1, 12, 3)
	surface.index()
	return surface.commit()

static func _arm(surface: SurfaceTool, shoulder: Vector3, elbow: Vector3, wrist: Vector3, sleeve: float, width: float) -> void:
	var side := signf(shoulder.x)
	# A small smooth shoulder closes the joint, avoiding the first pass's cylinder caps.
	_oval(surface, shoulder, Vector3(0.047, 0.052, 0.049) * width, 0, 0, 8, 3, side, width)
	var path := PackedVector3Array([wrist, elbow, shoulder])
	var sizes := PackedVector2Array([Vector2(0.031, 0.034), Vector2(0.041, 0.043), Vector2(0.053, 0.054)])
	if sleeve < 0.9:
		var end := shoulder.lerp(elbow, sleeve)
		_tube(surface, PackedVector3Array([wrist, elbow, end]),
			PackedVector2Array([Vector2(0.024, 0.027), Vector2(0.031, 0.033), Vector2(0.033, 0.034)]), 2, 8, side, width)
		path = PackedVector3Array([end, shoulder.lerp(elbow, sleeve * 0.4), shoulder])
	for index in range(sizes.size()):
		sizes[index] *= width
	_tube(surface, path, sizes, 0, 8, side, width)
	_oval(surface, wrist, Vector3(0.029, 0.040, 0.028), 2, 0, 8, 3, side, width)

static func _build_body(variant: int) -> ArrayMesh:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var widths := [0.96, 1.18, 1.05, 0.98, 0.90, 1.01, 1.12, 0.93]
	var broad: float = widths[variant]
	var hem: float = [0.52, 0.48, 0.54, 0.36, 0.33, 0.53, 0.49, 0.41][variant]
	var waist: float = [0.126, 0.146, 0.132, 0.123, 0.101, 0.112, 0.140, 0.117][variant]
	var hips := 0.185 if variant == 4 else (0.151 if variant in [3, 7] else 0.137 * broad)
	var short_pants := variant == 2
	# Distinct stances: resting on one hip, open feet, or a slightly bent knee.
	var stance: float = [0.070, 0.085, 0.090, 0.064, 0.060, 0.075, 0.083, 0.065][variant]
	for sign_x: float in [-1.0, 1.0]:
		var ankle := Vector3(sign_x * stance, 0.065, 0.040 if variant in [0, 5, 7] and sign_x < 0 else 0)
		var knee := Vector3(sign_x * (stance + 0.006), 0.266, ankle.z * 0.4)
		var thigh := Vector3(sign_x * 0.068, 0.52, 0)
		if short_pants:
			var shorts_hem := knee.lerp(thigh, 0.38)
			_tube(surface, PackedVector3Array([ankle, knee, shorts_hem]), PackedVector2Array([Vector2(0.029, 0.033), Vector2(0.037, 0.040), Vector2(0.042, 0.046)]), 2)
			_tube(surface, PackedVector3Array([shorts_hem, thigh]), PackedVector2Array([Vector2(0.062, 0.065), Vector2(0.064, 0.066)]), 1)
		else:
			var flare := 1.25 if variant == 5 else 1.0
			_tube(surface, PackedVector3Array([ankle, knee, thigh]), PackedVector2Array([Vector2(0.036, 0.041) * flare, Vector2(0.046, 0.049), Vector2(0.060, 0.062)]), 2 if variant == 4 else 1)
		_oval(surface, ankle + Vector3(0, -0.028, 0.024), Vector3(0.048, 0.034, 0.086), 4, 0, 8, 3)
	_tube(surface, PackedVector3Array([Vector3(0, hem, 0), Vector3(0, hem + 0.025, 0), Vector3(0, 0.735, 0), Vector3(0, 0.864, 0), Vector3(0, 0.914, 0), Vector3(0, 0.941, 0)]),
		PackedVector2Array([Vector2(hips * 0.98, 0.089), Vector2(hips, 0.092), Vector2(waist, 0.082), Vector2(0.156 * broad, 0.083), Vector2(0.111 * broad, 0.063), Vector2(0.047, 0.043)]), 0, 12)
	_oval(surface, Vector3(0, 0.955, 0), Vector3(0.041, 0.064, 0.041), 2, 0, 8, 3)
	for sign_x: float in [-1.0, 1.0]:
		var shoulder := Vector3(sign_x * 0.126 * broad, 0.861, 0)
		var elbow := Vector3(sign_x * 0.178 * broad, 0.685, 0.018)
		var wrist := Vector3(sign_x * 0.169 * broad, 0.506, 0.035)
		# One shared rest pose. Shader joint transforms apply the independently chosen
		# stance to every garment, without multiplying cached meshes or draw batches.
		var sleeve := 0.55 if variant in [2, 4, 5] else 1.0
		_arm(surface, shoulder, elbow, wrist, sleeve, broad)
	if variant == 1 or variant == 7:
		# A narrow inset and two broad lapels make the jacket read as layered clothing.
		_tube(surface, PackedVector3Array([Vector3(0, hem + 0.03, 0.088), Vector3(0, 0.83, 0.081), Vector3(0, 0.907, 0.055)]), PackedVector2Array([Vector2(0.047, 0.010), Vector2(0.044, 0.011), Vector2(0.030, 0.010)]), 5, 8)
	if variant == 3:
		# A folded scarf is a single quiet accent, shared by every body of this type.
		_oval(surface, Vector3(0, 0.929, 0), Vector3(0.069, 0.034, 0.060), 5, 0, 10, 3)
		_tube(surface, PackedVector3Array([Vector3(0.038, 0.744, 0.093), Vector3(0.022, 0.914, 0.062)]), PackedVector2Array([Vector2(0.027, 0.012), Vector2(0.031, 0.015)]), 5, 6)
	if variant == 6:
		# A soft hood folded behind the neck changes the shoulder silhouette.
		_oval(surface, Vector3(0, 0.899, -0.075), Vector3(0.095, 0.057, 0.064), 5, 0, 10, 3)
	surface.index()
	return surface.commit()
