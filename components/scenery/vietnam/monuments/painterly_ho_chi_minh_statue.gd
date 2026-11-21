@tool
extends PainterlyVietnamPiece
## A standing bronze figure, facing +Z, on a solid stone pedestal.

func _build_geometry() -> Dictionary:
	var b := BUILDER.new()
	b.begin(_config())
	b.soft_box(Vector3(0, 0.09, 0), Vector3(2.80, 0.18, 2.48), accent_color, 0.076)
	b.soft_box(Vector3(0, 0.71, 0), Vector3(2.52, 1.14, 2.16), accent_color.lightened(0.03), 0.070)
	b.soft_box(Vector3(0, 1.32, 0), Vector3(2.65, 0.16, 2.30), accent_color, 0.055)
	b.soft_box(Vector3(0, 1.45, 0), Vector3(1.78, 0.18, 1.42), trim_color.darkened(0.22), 0.038)
	b.collider(Vector3(0, 0.73, 0), Vector3(2.80, 1.46, 2.48), "Pedestal")

	for side: float in [-1.0, 1.0]:
		var x := side * 0.33
		b.tapered_post(Vector3(x, 1.66, -0.04), Vector3(x * 0.91, 3.22, -0.07), 0.295, body_color.darkened(0.06))
		b.soft_box(Vector3(x, 1.63, 0.12), Vector3(0.50, 0.24, 0.80), body_color.darkened(0.13), 0.09)
		b.tube([Vector3(x, 1.78, 0.21), Vector3(x, 2.41, 0.23), Vector3(x, 2.82, 0.23)], 0.023, body_color.lightened(0.05), 6)
	# The high-collared jacket flares at the hem and narrows at the waist.
	var jacket := PackedVector2Array([Vector2(-0.69, 2.88), Vector2(0.69, 2.88), Vector2(0.57, 3.46),
		Vector2(0.68, 4.08), Vector2(0.58, 4.27), Vector2(0.26, 4.40), Vector2(-0.26, 4.40),
		Vector2(-0.59, 4.28), Vector2(-0.69, 4.10), Vector2(-0.55, 3.50)])
	b.profile(jacket, Vector3(0, 0, -0.04), 0.63, body_color)
	b.box(Vector3(0.015, 3.59, 0.284), Vector3(0.043, 1.31, 0.035), body_color.darkened(0.11))
	for row in 5:
		_form(b, Vector3(0.062, 3.06 + row * 0.22, 0.32), Vector3(0.031, 0.033, 0.023), trim_color)
	for side: float in [-1.0, 1.0]:
		b.soft_box(Vector3(side * 0.32, 3.88, 0.293), Vector3(0.35, 0.26, 0.036), body_color.lightened(0.07), 0.024)
		b.box(Vector3(side * 0.32, 4.02, 0.317), Vector3(0.36, 0.063, 0.048), body_color.lightened(0.13))
		b.box(Vector3(side * 0.12, 4.28, 0.29), Vector3(0.15, 0.23, 0.068), trim_color.darkened(0.13), 0.0,
			Basis(Vector3.BACK, side * 0.34))

	var elbow := Vector3(-1.02, 4.18, 0.13)
	var cuff := Vector3(-1.12, 4.87, 0.30)
	b.tube([Vector3(-0.58, 4.10, -0.05), elbow, cuff], 0.202, body_color, 10)
	_form(b, elbow, Vector3(0.205, 0.205, 0.205), body_color)
	_form(b, Vector3(-1.12, 5.02, 0.33), Vector3(0.147, 0.23, 0.084), body_color.lightened(0.12), Basis(Vector3.BACK, -0.23))
	for finger in 4:
		var x := -1.21 + finger * 0.054
		var tip := 5.36 - absf(finger - 1.4) * 0.044
		b.rod(Vector3(x, 5.11, 0.34), Vector3(x + 0.065, tip, 0.36), 0.032, body_color.lightened(0.12), 6)
	b.rod(Vector3(-1.02, 5.00, 0.33), Vector3(-0.94, 5.19, 0.38), 0.045, body_color.lightened(0.09), 7)
	var low_elbow := Vector3(0.78, 3.68, -0.025)
	b.tube([Vector3(0.59, 4.08, -0.06), low_elbow, Vector3(0.91, 3.02, 0.06)], 0.183, body_color.darkened(0.035), 10)
	_form(b, low_elbow, Vector3(0.18, 0.19, 0.18), body_color)
	_form(b, Vector3(0.92, 2.89, 0.10), Vector3(0.104, 0.219, 0.092), body_color.lightened(0.07))

	_form(b, Vector3(0, 4.38, 0.01), Vector3(0.178, 0.25, 0.16), body_color)
	_form(b, Vector3(0, 4.70, 0.07), Vector3(0.270, 0.36, 0.25), body_color.lightened(0.11))
	for side: float in [-1.0, 1.0]:
		_form(b, Vector3(side * 0.26, 4.69, 0.084), Vector3(0.062, 0.102, 0.062), body_color)
		b.rod(Vector3(side * 0.035, 4.78, 0.315), Vector3(side * 0.175, 4.80, 0.28), 0.028, body_color.darkened(0.22), 7)
		b.rod(Vector3(side * 0.02, 4.61, 0.332), Vector3(side * 0.115, 4.58, 0.304), 0.023, body_color.darkened(0.16), 7)
	_form(b, Vector3(0, 4.68, 0.322), Vector3(0.064, 0.079, 0.059), body_color.lightened(0.16))
	_form(b, Vector3(0, 4.46, 0.27), Vector3(0.095, 0.173, 0.072), body_color.darkened(0.17))
	b.rod(Vector3(-0.018, 4.43, 0.33), Vector3(0, 4.29, 0.28), 0.022, body_color.lightened(0.05), 6)
	b.anchors["Crown"] = Vector3(0, 5.05, 0)
	return b.finish()

func _form(builder: RefCounted, center: Vector3, radii: Vector3, tint: Color, pose := Basis.IDENTITY) -> void:
	var mesh := SphereMesh.new()
	mesh.radius = 1.0
	mesh.height = 2.0
	mesh.radial_segments = 12
	mesh.rings = 6
	builder.append(mesh, Transform3D(pose.scaled(radii), center), tint)
