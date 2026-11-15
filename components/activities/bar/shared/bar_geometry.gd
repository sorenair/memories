@tool
extends "res://components/activities/arcade/shared/arcade_geometry.gd"
const POOL = preload("res://components/activities/bar/pool/pool_layout.gd")

func begin(config: Dictionary) -> void:
	s = SurfaceTool.new()
	s.begin(Mesh.PRIMITIVE_TRIANGLES)
	body = config.cabinet_color
	accent = config.accent_color
	brass = config.metal_color
	ivory = config.cream_color
	rng.seed = config.prop_seed

func finish() -> Dictionary:
	s.index()
	return {"mesh": s.commit(), "colliders": colliders, "anchors": anchors, "parts": {}}

func flat_box(at: Vector3, size: Vector3, color: Color, bevel: float = 0.04) -> void:
	var previous := frame
	frame = Transform3D(Basis(Vector3.RIGHT, PI * 0.5), at)
	soft_box(Vector3.ZERO, Vector3(size.x, size.z, size.y), color, bevel)
	frame = previous

func pool_table(config: Dictionary) -> Dictionary:
	begin(config)
	var hx: float = POOL.HALF.x
	var hz: float = POOL.HALF.y
	var y: float = POOL.CLOTH_Y
	var cloth: Color = config.cloth_color
	flat_box(Vector3(0, 0.71, 0), Vector3(POOL.FIELD_SIZE.x + 0.29, 0.23, POOL.FIELD_SIZE.y + 0.29), body, 0.10)
	flat_box(Vector3(0, 0.60, 0), Vector3(POOL.FIELD_SIZE.x + 0.23, 0.055, POOL.FIELD_SIZE.y + 0.23), body.darkened(0.10), 0.08)
	for x in [-hx * 0.82, hx * 0.82]:
		for z in [-hz * 0.79, hz * 0.79]:
			rod(Vector3(x * 1.08, 0.08, z * 1.03), Vector3(x, 0.65, z), 0.09, body.darkened(0.09), 12)
			disc(Vector3(x * 1.08, 0.045, z * 1.03), 0.105, 0.065, brass.darkened(0.16), Vector3.UP, 0, 16)
	var outline: PackedVector2Array = POOL.cloth_outline()
	var ids := Geometry2D.triangulate_polygon(outline)
	for index in range(0, ids.size(), 3):
		for offset in range(3):
			var p := outline[ids[index + offset]]
			vertex(Vector3(p.x, y, p.y), Vector3.UP, cloth)
	var gap: float = POOL.POCKET_RADIUS * 1.12
	# Rails/cushions really leave all six mouths clear; no obstacle under a pocket.
	for side: float in [-1.0, 1.0]:
		for end: float in [-1.0, 1.0]:
			var z := end * hz * 0.5
			var run := hz - gap * 2.0
			flat_box(Vector3(side * (hx + 0.075), y + 0.035, z), Vector3(0.17, 0.09, run), body.lightened(rng.randf_range(-0.025, 0.025)), 0.018)
			flat_box(Vector3(side * (hx + 0.030), y + 0.027, z), Vector3(0.060, 0.060, run + 0.025), cloth.darkened(0.08), 0.018)
		flat_box(Vector3(0, y + 0.035, side * (hz + 0.075)), Vector3(POOL.FIELD_SIZE.x - gap * 2.0, 0.09, 0.17), body.lightened(0.015), 0.018)
		flat_box(Vector3(0, y + 0.027, side * (hz + 0.030)), Vector3(POOL.FIELD_SIZE.x - gap * 2.0 + 0.025, 0.06, 0.06), cloth.darkened(0.08), 0.018)
	for p in POOL.pockets():
		var center := Vector3(p.x, y - 0.028, p.y)
		disc(center, POOL.POCKET_RADIUS * 1.03, 0.05, Color("26332f"), Vector3.UP, 0, 24)
		for segment in range(24):
			var a := TAU * float(segment) / 24
			var c := TAU * float(segment + 1) / 24
			var inner_a := center + Vector3(cos(a), 0, sin(a)) * POOL.POCKET_RADIUS
			var inner_c := center + Vector3(cos(c), 0, sin(c)) * POOL.POCKET_RADIUS
			var outer_a := center + Vector3(cos(a), 0, sin(a)) * POOL.POCKET_RADIUS * 1.25
			var outer_c := center + Vector3(cos(c), 0, sin(c)) * POOL.POCKET_RADIUS * 1.25
			quad(inner_a + Vector3.UP * 0.041, inner_c + Vector3.UP * 0.041, outer_c + Vector3.UP * 0.032, outer_a + Vector3.UP * 0.032, body.darkened(0.32))
	for side: float in [-1.0, 1.0]:
		for z in [-0.79, -0.40, 0.40, 0.79]:
			disc(Vector3(side * (hx + 0.088), y + 0.082, z), 0.012, 0.003, ivory, Vector3.UP, 0, 8)
	for x in [-0.26, 0.26]:
		disc(Vector3(x, y + 0.082, hz + 0.08), 0.012, 0.003, ivory, Vector3.UP, 0, 8)
	# The empty triangle hangs on the apron; it does not trap the live balls.
	var rack_z := hz + 0.151
	var a := Vector3(-0.12, 0.71, rack_z)
	var b := Vector3(0.12, 0.71, rack_z)
	var c := Vector3(0, 0.51, rack_z)
	rod(a, b, 0.012, brass, 8)
	rod(b, c, 0.012, brass, 8)
	rod(c, a, 0.012, brass, 8)
	soft_box(Vector3(0.39, 0.65, rack_z), Vector3(0.15, 0.08, 0.012), ink, 0.013)
	box(Vector3(0.39, 0.67, rack_z + 0.008), Vector3(0.08, 0.009, 0.008), brass)
	box(Vector3(-0.39, y + 0.105, hz + 0.08), Vector3.ONE * 0.043, Color("8baeb5"))
	collider(Vector3(0, 0.46, 0), Vector3(POOL.FIELD_SIZE.x + 0.32, 0.92, POOL.FIELD_SIZE.y + 0.32), "Table")
	anchors = {"Play": Vector3(0, 0, hz + 0.65), "Rack": Vector3(POOL.APEX.x, y, POOL.APEX.y)}
	return finish()

func jukebox(config: Dictionary) -> Dictionary:
	begin(config)
	flat_box(Vector3(0, 0.055, 0), Vector3(0.73, 0.11, 0.50), body.darkened(0.16), 0.07)
	soft_box(Vector3(0, 0.89, -0.025), Vector3(0.78, 1.66, 0.37), body, 0.095)
	soft_box(Vector3(0, 1.16, 0.175), Vector3(0.68, 1.04, 0.045), ink, 0.055)
	for side: float in [-1.0, 1.0]:
		soft_box(Vector3(side * 0.356, 1.10, 0.179), Vector3(0.022, 1.10, 0.022), accent if side < 0 else brass, 0.009, 2)
		soft_box(Vector3(side * 0.345, 1.10, 0.178), Vector3(0.054, 1.20, 0.012), body.lightened(0.055), 0.022)
	text(config.screen_title, Vector3(0, 1.61, 0.205), 0.085, ivory)
	soft_box(Vector3(0, 0.36, 0.178), Vector3(0.62, 0.38, 0.03), ink, 0.04)
	for row in range(7):
		box(Vector3(0, 0.21 + row * 0.042, 0.199), Vector3(0.49, 0.014, 0.015), body.lightened(0.045))
	soft_box(Vector3(0, 0.61, 0.199), Vector3(0.21, 0.09, 0.018), body.lightened(0.06), 0.018)
	for index in range(3):
		disc(Vector3(-0.052 + index * 0.052, 0.61, 0.213), 0.009, 0.004, brass, Vector3.BACK, 2, 10)
	collider(Vector3(0, 0.87, 0), Vector3(0.80, 1.74, 0.48), "Jukebox")
	anchors = {"Screen": Vector3(0, 1.16, 0.211), "Approach": Vector3(0, 0, 0.95)}
	return finish()
