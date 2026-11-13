@tool
extends "res://components/activities/arcade/shared/arcade_geometry.gd"
## Reuses the approved painted prop builder. Front is +Z; root is ground level.

func begin(config: Dictionary) -> void:
	s = SurfaceTool.new()
	s.begin(Mesh.PRIMITIVE_TRIANGLES)
	rng.seed = config.prop_seed
	body = config.body_color
	accent = config.accent_color
	brass = config.trim_color
	ivory = Color("e8e0c9")

func finish() -> Dictionary:
	s.index()
	return {"mesh": s.commit(), "colliders": colliders, "anchors": anchors}

func flat_deck(center: Vector3, width: float, depth: float, thickness: float, color: Color, bevel: float = 0.12) -> void:
	var previous := frame
	frame = Transform3D(Basis(Vector3.RIGHT, PI * 0.5), center)
	soft_box(Vector3.ZERO, Vector3(width, depth, thickness), color, bevel)
	frame = previous

func stage(config: Dictionary) -> Dictionary:
	begin(config)
	var width: float = config.footprint.x
	var depth: float = config.footprint.y
	var height: float = config.deck_height
	var front := depth * 0.5
	flat_deck(Vector3(0, height - 0.07, 0), width, depth, 0.14, body, 0.16)
	# Broad board-sized pigment planes, with inset seams rather than tiny wood grain.
	var boards := maxi(4, roundi(width / 0.5))
	for index in range(boards):
		var board_width := (width - 0.20) / float(boards)
		var x := -width * 0.5 + 0.10 + board_width * (float(index) + 0.5)
		flat_deck(Vector3(x, height + 0.004, 0), board_width - 0.012, depth - 0.18, 0.008,
			body.lightened(rng.randf_range(-0.045, 0.045)), 0.025)
	# A lightly scalloped painted apron suggests fabric without enclosing the venue.
	var pleats := maxi(6, roundi(width / 0.32))
	for index in range(pleats):
		var x0 := -width * 0.5 + width * float(index) / float(pleats)
		var x1 := -width * 0.5 + width * float(index + 1) / float(pleats)
		var xm := (x0 + x1) * 0.5
		var hem := 0.055 + sin(float(index) * 1.9) * 0.015
		var color := accent.lightened(rng.randf_range(-0.035, 0.045))
		quad(Vector3(x0, hem, front - 0.04), Vector3(xm, hem - 0.012, front + 0.015), Vector3(xm, height - 0.09, front + 0.015), Vector3(x0, height - 0.09, front - 0.04), color)
		quad(Vector3(xm, hem - 0.012, front + 0.015), Vector3(x1, hem, front - 0.04), Vector3(x1, height - 0.09, front - 0.04), Vector3(xm, height - 0.09, front + 0.015), color.darkened(0.06))
	for side: float in [-1.0, 1.0]:
		soft_box(Vector3(side * (width * 0.5 - 0.065), height * 0.46, 0), Vector3(0.12, height * 0.82, depth - 0.12), accent, 0.035)
		rod(Vector3(side * (width * 0.5 - 0.13), height + 0.02, -front + 0.12), Vector3(side * (width * 0.5 - 0.13), height + 0.02, front - 0.12), 0.016, brass, 8)
	box(Vector3(0, height - 0.05, front + 0.025), Vector3(width - 0.18, 0.028, 0.025), brass)
	collider(Vector3(0, height * 0.5 - 0.005, 0), Vector3(width, height - 0.01, depth), "Deck")
	if config.ramp_enabled:
		var half: float = config.ramp_width * 0.5
		var end: float = front + config.ramp_length
		var top_a := Vector3(-half, height + 0.012, front - 0.05)
		var top_b := Vector3(half, height + 0.012, front - 0.05)
		var low_a := Vector3(-half, 0.022, end)
		var low_b := Vector3(half, 0.022, end)
		quad(low_a, low_b, top_b, top_a, body.lightened(0.08))
		quad(low_a - Vector3.UP * 0.02, top_a - Vector3.UP * 0.07, top_a, low_a, accent)
		quad(low_b, top_b, top_b - Vector3.UP * 0.07, low_b - Vector3.UP * 0.02, accent)
		for side: float in [-1.0, 1.0]:
			rod(Vector3(side * (half - 0.03), 0.035, end - 0.04), Vector3(side * (half - 0.03), height + 0.025, front), 0.015, brass, 8)
		# Actual sloped convex collision, not stair boxes that snag CharacterBody3D.
		var ramp := PackedVector3Array([top_a, top_b, low_a, low_b,
			Vector3(-half, -0.02, front - 0.05), Vector3(half, -0.02, front - 0.05),
			Vector3(-half, -0.02, end), Vector3(half, -0.02, end)])
		colliders.append({"name": "AccessRamp", "points": ramp})
		anchors["Approach"] = Vector3(0, 0, end + 0.5)
	anchors["DeckCenter"] = Vector3(0, height + 0.025, 0)
	anchors["Performer"] = Vector3(0, height + 0.025, -depth * 0.18)
	anchors["LightingRig"] = Vector3(0, height, -depth * 0.37)
	return finish()

func driver(center: Vector3, radius: float) -> void:
	# A rear backing and an open annular rim leave the concave diaphragm visible.
	# Filled front discs would mask the bowl as it pulses backward.
	disc(center + Vector3(0, 0, -0.035), radius + 0.025, 0.015, Color("242e35"), Vector3.BACK, 0, 24)
	for side in range(24):
		var a := TAU * float(side) / 24.0
		var b := TAU * float(side + 1) / 24.0
		var out_a := center + Vector3(cos(a) * (radius + 0.025), sin(a) * (radius + 0.025), 0.045)
		var out_b := center + Vector3(cos(b) * (radius + 0.025), sin(b) * (radius + 0.025), 0.045)
		var in_a := center + Vector3(cos(a) * radius * 0.925, sin(a) * radius * 0.925, 0.045)
		var in_b := center + Vector3(cos(b) * radius * 0.925, sin(b) * radius * 0.925, 0.045)
		quad(out_a, out_b, in_b, in_a, brass.darkened(0.1))
	# Concentric bowl rings with smooth normals, not a noisy perforated grille.
	var rings := [Vector2(radius * 0.92, 0.033), Vector2(radius * 0.74, 0.025), Vector2(radius * 0.36, -0.005)]
	for ring in range(rings.size() - 1):
		for side in range(24):
			for id in [Vector2i(ring, side), Vector2i(ring, side + 1), Vector2i(ring + 1, side), Vector2i(ring, side + 1), Vector2i(ring + 1, side + 1), Vector2i(ring + 1, side)]:
				var angle := TAU * float(id.y) / 24.0
				var profile: Vector2 = rings[id.x]
				var point := center + Vector3(cos(angle) * profile.x, sin(angle) * profile.x, profile.y)
				vertex(point, Vector3(-cos(angle) * 0.28, -sin(angle) * 0.28, 1).normalized(), Color("4b5b63"), 3)
	ball(center + Vector3(0, 0, 0.029), Vector3(radius * 0.72, radius * 0.72, 0.09), Color("303e46"), 3)

func speakers(config: Dictionary) -> Dictionary:
	begin(config)
	var scale_x: float = config.cabinet_width
	var depth: float = config.cabinet_depth
	var y := 0.0
	if config.subwoofer_enabled:
		var h := scale_x * 0.73
		soft_box(Vector3(0, h * 0.5, 0), Vector3(scale_x * 1.15, h, depth * 1.10), body, 0.07)
		driver(Vector3(0, h * 0.55, depth * 0.55 + 0.007), scale_x * 0.265)
		soft_box(Vector3(0, h * 0.105, depth * 0.55 + 0.015), Vector3(scale_x * 0.70, h * 0.095, 0.025), ink, 0.018)
		collider(Vector3(0, h * 0.5, 0), Vector3(scale_x * 1.15, h, depth * 1.10), "Subwoofer")
		y += h + 0.035
	for index in range(config.cabinet_count):
		var h := scale_x * 0.70
		var base := Vector3(0, y, -float(index) * 0.028)
		soft_box(base + Vector3(0, h * 0.5, 0), Vector3(scale_x, h, depth), body.lightened(rng.randf_range(-0.018, 0.025)), 0.06)
		driver(base + Vector3(0, h * 0.43, depth * 0.5 + 0.008), scale_x * 0.218)
		soft_box(base + Vector3(0, h * 0.84, depth * 0.5 + 0.016), Vector3(scale_x * 0.56, h * 0.15, 0.028), ink, 0.026)
		box(base + Vector3(0, h * 0.84, depth * 0.5 + 0.034), Vector3(scale_x * 0.33, h * 0.06, 0.012), brass.darkened(0.1))
		for side: float in [-1.0, 1.0]:
			soft_box(base + Vector3(side * scale_x * 0.39, h * 0.11, depth * 0.5 + 0.017), Vector3(scale_x * 0.10, 0.025, 0.025), accent, 0.006)
			box(base + Vector3(side * (scale_x * 0.5 + 0.007), h * 0.55, 0), Vector3(0.022, h * 0.19, depth * 0.22), ink)
		collider(base + Vector3(0, h * 0.5, 0), Vector3(scale_x, h, depth), "Cabinet_%d" % index)
		y += h + 0.035
	anchors["Top"] = Vector3(0, y, 0)
	anchors["Front"] = Vector3(0, 0, depth * 0.6 + 0.5)
	return finish()

func truss(config: Dictionary) -> Dictionary:
	begin(config)
	var half: float = config.rig_width * 0.5
	var height: float = config.mount_height
	if config.supports_enabled:
		for side: float in [-1.0, 1.0]:
			soft_box(Vector3(side * half, 0.035, 0), Vector3(0.54, 0.07, 0.50), body, 0.045)
			for dz: float in [-0.11, 0.11]:
				rod(Vector3(side * half, 0.07, dz), Vector3(side * half, height + 0.11, dz), 0.029, brass, 8)
			for step in range(maxi(1, roundi(height / 0.40))):
				var y0 := float(step) * height / float(maxi(1, roundi(height / 0.40)))
				var y1 := minf(height, y0 + 0.40)
				rod(Vector3(side * half, y0, -0.11), Vector3(side * half, y1, 0.11), 0.013, brass, 6)
			collider(Vector3(side * half, height * 0.5, 0), Vector3(0.30, height, 0.32), "TrussFoot")
	for dy: float in [-0.10, 0.10]:
		for dz: float in [-0.10, 0.10]:
			rod(Vector3(-half, height + dy, dz), Vector3(half, height + dy, dz), 0.027, brass, 8)
	var bays := maxi(2, roundi(config.rig_width / 0.48))
	for index in range(bays):
		var x0 := lerpf(-half, half, float(index) / float(bays))
		var x1 := lerpf(-half, half, float(index + 1) / float(bays))
		rod(Vector3(x0, height - 0.10, 0.10), Vector3(x1, height + 0.10, 0.10), 0.012, brass, 6)
	# Compact hanging yokes connect the moving heads to the truss.
	for index in range(config.light_count):
		var x := 0.0 if config.light_count == 1 else lerpf(-half + 0.45, half - 0.45, float(index) / float(config.light_count - 1))
		box(Vector3(x, height - 0.10, 0), Vector3(0.10, 0.10, 0.14), body)
		rod(Vector3(x - 0.17, height - 0.16, 0), Vector3(x + 0.17, height - 0.16, 0), 0.023, brass, 8)
		for side: float in [-1.0, 1.0]:
			rod(Vector3(x + side * 0.17, height - 0.16, 0), Vector3(x + side * 0.17, height - 0.32, 0), 0.022, brass, 8)
	anchors["Center"] = Vector3(0, height, 0)
	return finish()

func fixture(config: Dictionary, color: Color) -> Dictionary:
	begin(config)
	soft_box(Vector3(0, 0, -0.04), Vector3(0.27, 0.25, 0.36), body, 0.045)
	box(Vector3(0, -0.06, -0.225), Vector3(0.17, 0.04, 0.018), accent)
	disc(Vector3(0, 0, 0.16), 0.135, 0.07, brass, Vector3.BACK, 0, 20)
	disc(Vector3(0, 0, 0.204), 0.111, 0.018, color, Vector3.BACK, 2, 20)
	disc(Vector3(-0.027, 0.025, 0.216), 0.051, 0.006, color.lightened(0.4), Vector3.BACK, 2, 16)
	return finish()

func display(config: Dictionary) -> Dictionary:
	begin(config)
	var size: Vector2 = config.display_size
	var center := Vector3(0, config.bottom_height + size.y * 0.5, 0)
	soft_box(center, Vector3(size.x + 0.18, size.y + 0.18, 0.20), body, 0.10)
	# Painted bezel fittings: large, quiet accents rather than a fine LED grid.
	for side: float in [-1.0, 1.0]:
		box(center + Vector3(side * (size.x * 0.5 + 0.054), 0, 0.106), Vector3(0.020, size.y * 0.62, 0.012), brass)
		soft_box(center + Vector3(side * (size.x * 0.5 - 0.13), -size.y * 0.5 - 0.048, 0.108), Vector3(0.11, 0.022, 0.012), accent, 0.008)
	collider(center, Vector3(size.x + 0.18, size.y + 0.18, 0.23), "ScreenCase")
	if config.supports_enabled:
		for side: float in [-1.0, 1.0]:
			var x := side * size.x * 0.34
			soft_box(Vector3(x, 0.04, -0.02), Vector3(0.62, 0.08, 0.72), body, 0.045)
			rod(Vector3(x, 0.06, -0.08), Vector3(x, center.y, -0.08), 0.044, brass, 10)
			collider(Vector3(x, config.bottom_height * 0.5, -0.08), Vector3(0.15, config.bottom_height, 0.18), "Stand")
			collider(Vector3(x, 0.04, -0.02), Vector3(0.62, 0.08, 0.72), "Foot")
	anchors["DisplayCenter"] = center + Vector3(0, 0, 0.112)
	anchors["RearMount"] = center + Vector3(0, 0, -0.12)
	anchors["Front"] = Vector3(0, 0, 0.85)
	return finish()
