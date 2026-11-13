@tool
extends "res://components/activities/arcade/shared/arcade_geometry.gd"
## Solid exterior shell, all details merged into one vertex-painted surface.
var settings: Dictionary

func top_at(x: float) -> float:
	return settings.floor_height + settings.wall_height + settings.roof_rise * (0.5 - x / settings.footprint.x)

func wedge(x0: float, x1: float, z0: float, z1: float, low0: float, low1: float, high0: float, high1: float, color: Color, kind: float = 1.0) -> void:
	quad(Vector3(x0, low0, z1), Vector3(x1, low1, z1), Vector3(x1, high1, z1), Vector3(x0, high0, z1), color, kind)
	quad(Vector3(x1, low1, z0), Vector3(x0, low0, z0), Vector3(x0, high0, z0), Vector3(x1, high1, z0), color, kind)
	quad(Vector3(x0, low0, z0), Vector3(x0, low0, z1), Vector3(x0, high0, z1), Vector3(x0, high0, z0), color, kind)
	quad(Vector3(x1, low1, z1), Vector3(x1, low1, z0), Vector3(x1, high1, z0), Vector3(x1, high1, z1), color, kind)
	quad(Vector3(x0, high0, z1), Vector3(x1, high1, z1), Vector3(x1, high1, z0), Vector3(x0, high0, z0), color, kind)
	quad(Vector3(x0, low0, z0), Vector3(x1, low1, z0), Vector3(x1, low1, z1), Vector3(x0, low0, z1), color, kind)

func window_at(at: Vector3, size: Vector2, rotation := Basis.IDENTITY, divided: bool = false) -> void:
	var previous := frame
	frame = Transform3D(rotation, at)
	soft_box(Vector3.ZERO, Vector3(size.x + 0.13, size.y + 0.13, 0.075), settings.trim_color.darkened(0.16), 0.035)
	var half := size * 0.5
	var points := [Vector3(-half.x, -half.y, 0.041), Vector3(half.x, -half.y, 0.041), Vector3(half.x, half.y, 0.041), Vector3(-half.x, half.y, 0.041)]
	var uvs := [Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)]
	for index in [0, 1, 2, 0, 2, 3]:
		s.set_uv(uvs[index])
		vertex(points[index], Vector3.BACK, settings.glass_color, 3.0)
	s.set_uv(Vector2.ZERO)
	# Narrow frames preserve the reference's large, uninterrupted picture window.
	for side: float in [-1.0, 1.0]:
		box(Vector3(side * (half.x + 0.022), 0, 0.052), Vector3(0.044, size.y + 0.075, 0.045), settings.trim_color)
		box(Vector3(0, side * (half.y + 0.022), 0.052), Vector3(size.x + 0.075, 0.044, 0.045), settings.trim_color)
	if divided:
		box(Vector3(0, 0, 0.06), Vector3(0.045, size.y, 0.035), settings.trim_color)
	box(Vector3(0, -half.y - 0.040, 0.027), Vector3(size.x + 0.16, 0.045, 0.15), settings.trim_color.lightened(0.035))
	frame = previous

func build_cabin(config: Dictionary) -> Dictionary:
	settings = config
	s = SurfaceTool.new()
	s.begin(Mesh.PRIMITIVE_TRIANGLES)
	s.set_uv(Vector2.ZERO)
	rng.seed = settings.cabin_seed
	var width: float = settings.footprint.x
	var depth: float = settings.footprint.y
	var half := width * 0.5
	var front := depth * 0.5
	var floor_y: float = settings.floor_height
	var wall: Color = settings.siding_color
	var trim: Color = settings.trim_color
	var roof: Color = settings.roof_color
	var chassis := trim.darkened(0.28)
	wedge(-half, half, -front, front, floor_y, floor_y, top_at(-half), top_at(half), wall.darkened(0.035))
	# Siding is broad plank pigment with very shallow seams, not a texture map.
	var columns := maxi(12, ceili(width / settings.board_width))
	for index in range(columns):
		var x0 := -half + width * float(index) / columns + 0.004
		var x1 := -half + width * float(index + 1) / columns - 0.004
		for side: float in [-1.0, 1.0]:
			var color := wall.lightened(rng.randf_range(-0.018, 0.023))
			var z := side * (front + 0.009)
			if side > 0:
				quad(Vector3(x0, floor_y + 0.018, z), Vector3(x1, floor_y + 0.018, z), Vector3(x1, top_at(x1) - 0.035, z), Vector3(x0, top_at(x0) - 0.035, z), color, 1)
			else:
				quad(Vector3(x1, floor_y + 0.018, z), Vector3(x0, floor_y + 0.018, z), Vector3(x0, top_at(x0) - 0.035, z), Vector3(x1, top_at(x1) - 0.035, z), color, 1)
	var end_boards := maxi(8, ceili(depth / settings.board_width))
	for side: float in [-1.0, 1.0]:
		for index in range(end_boards):
			var z0 := -front + depth * float(index) / end_boards + 0.004
			var z1 := -front + depth * float(index + 1) / end_boards - 0.004
			var x := side * (half + 0.009)
			var y := top_at(side * half) - 0.035
			var color := wall.lightened(rng.randf_range(-0.018, 0.023))
			if side < 0:
				quad(Vector3(x, floor_y, z0), Vector3(x, floor_y, z1), Vector3(x, y, z1), Vector3(x, y, z0), color, 1)
			else:
				quad(Vector3(x, floor_y, z1), Vector3(x, floor_y, z0), Vector3(x, y, z0), Vector3(x, y, z1), color, 1)
		for z in [-front, front]:
			box(Vector3(side * half, (floor_y + top_at(side * half)) * 0.5, z), Vector3(0.055, top_at(side * half) - floor_y, 0.055), trim)
	# Thin shed roof and fascia follow the same structural slope.
	var overhang: float = settings.roof_overhang
	var left := -half - overhang
	var right := half + overhang
	wedge(left, right, -front - overhang, front + overhang, top_at(left) - 0.035, top_at(right) - 0.035, top_at(left) + 0.075, top_at(right) + 0.075, roof, 2)
	for side: float in [-1.0, 1.0]:
		var z := side * (front + overhang + 0.004)
		if side > 0:
			quad(Vector3(left, top_at(left) - 0.035, z), Vector3(right, top_at(right) - 0.035, z), Vector3(right, top_at(right) + 0.028, z), Vector3(left, top_at(left) + 0.028, z), trim, 2)
		else:
			quad(Vector3(right, top_at(right) - 0.035, z), Vector3(left, top_at(left) - 0.035, z), Vector3(left, top_at(left) + 0.028, z), Vector3(right, top_at(right) + 0.028, z), trim, 2)
	# Quiet standing seams lie on the roof instead of multiplying tiny shingles.
	for index in range(1, maxi(2, ceili(depth / 0.56))):
		var z := lerpf(-front, front, float(index) / maxi(2, ceili(depth / 0.56)))
		rod(Vector3(left + 0.02, top_at(left) + 0.081, z), Vector3(right - 0.02, top_at(right) + 0.081, z), 0.012, roof.lightened(0.04), 6)
	var end_basis := Basis(Vector3.UP, -PI * 0.5)
	window_at(Vector3(-half - 0.018, floor_y + (settings.wall_height + settings.roof_rise) * 0.52, 0), Vector2(depth * 0.80, (settings.wall_height + settings.roof_rise) * 0.80), end_basis)
	if settings.side_window_enabled:
		window_at(Vector3(-width * 0.14, floor_y + settings.wall_height * 0.58, front + 0.018), Vector2(width * 0.255, settings.wall_height * 0.235), Basis.IDENTITY, true)
	# Closed entry: opaque painted glazing and a restrained brass handle.
	var door_x: float = settings.door_offset * width
	var door_h := minf(2.1, settings.wall_height * 0.85)
	var door_w := minf(0.88, width * 0.18)
	soft_box(Vector3(door_x, floor_y + door_h * 0.5, front + 0.033), Vector3(door_w + 0.12, door_h + 0.09, 0.10), trim.lightened(0.02), 0.028)
	box(Vector3(door_x, floor_y + door_h * 0.5, front + 0.090), Vector3(door_w, door_h, 0.035), wall.darkened(0.12), 1)
	window_at(Vector3(door_x, floor_y + door_h * 0.64, front + 0.11), Vector2(door_w * 0.71, door_h * 0.56))
	box(Vector3(door_x, floor_y + door_h * 0.16, front + 0.116), Vector3(door_w * 0.73, door_h * 0.20, 0.020), trim.darkened(0.06), 1)
	var handle := Vector3(door_x - door_w * 0.36, floor_y + door_h * 0.45, front + 0.15)
	rod(handle, handle + Vector3.UP * 0.14, 0.013, settings.hardware_color, 10)
	var lamp := Vector3(door_x - door_w * 0.68, floor_y + door_h + 0.12, front + 0.07)
	if settings.porch_lamp_enabled:
		box(lamp, Vector3(0.13, 0.19, 0.09), trim.darkened(0.2))
		soft_box(lamp + Vector3(0, -0.025, 0.055), Vector3(0.085, 0.09, 0.05), Color("ffce81"), 0.015, 4)
		box(lamp + Vector3(0, 0.055, 0.03), Vector3(0.18, 0.05, 0.18), trim)
	# Raised chassis and four stable jack feet keep it recognizably trailer-like.
	box(Vector3(0, floor_y - 0.07, 0), Vector3(width + 0.04, 0.14, depth + 0.06), chassis)
	for x in [-half + 0.35, half - 0.35]:
		for z in [-front + 0.20, front - 0.20]:
			rod(Vector3(x, 0.065, z), Vector3(x, floor_y - 0.08, z), 0.032, chassis, 8)
			soft_box(Vector3(x, 0.035, z), Vector3(0.24, 0.07, 0.24), trim, 0.035)
	if settings.wheels_enabled:
		var radius := minf(0.30, floor_y * 0.48)
		for x in [width * 0.035, width * 0.18]:
			for side: float in [-1.0, 1.0]:
				var at := Vector3(x, radius + 0.015, side * (front - 0.055))
				disc(at, radius, 0.19, Color("303735"), Vector3.BACK, 0, 24)
				disc(at + Vector3(0, 0, side * 0.105), radius * 0.61, 0.022, trim, Vector3.BACK, 0, 20)
				disc(at + Vector3(0, 0, side * 0.121), radius * 0.34, 0.012, chassis, Vector3.BACK, 0, 16)
	# Small timber steps. Their solid ramp is added by the component controller.
	var step_run := 0.82
	if settings.steps_enabled:
		for index in range(3):
			var height := floor_y * (1.0 - float(index) / 3.0)
			soft_box(Vector3(door_x, height - 0.045, front + (float(index) + 0.5) * step_run / 3.0), Vector3(1.10, 0.09, step_run / 3.0 + 0.025), settings.step_color.lightened(rng.randf_range(-0.025, 0.025)), 0.024, 1)
		for dx in [-0.41, 0.41]:
			rod(Vector3(door_x + dx, 0.045, front + 0.72), Vector3(door_x + dx, floor_y - 0.08, front + 0.15), 0.035, chassis, 8)
	s.index()
	return {"mesh": s.commit(), "door_x": door_x, "lamp_position": lamp, "step_run": step_run}
