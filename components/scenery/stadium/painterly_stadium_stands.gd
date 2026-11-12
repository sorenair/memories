@tool
class_name PainterlyStadiumStands
extends PainterlyStadiumPiece
const MINNESOTA = preload("res://components/scenery/stadium/minnesota_marks.gd")
## Fixed scenic bowl around a safe, separately bounded upper cross-aisle.
const DECK_HEIGHT := 10.5
const DECK_Z := 12.0
const FIELD_Z := -26.0
## Extra sideline/end-zone clearance for the rectangular field's far corners.
const FAR_BOWL_RADII := Vector2(56.0, 33.0)
@export var seat_color := Color("71616a"):
	set(value):
		seat_color = value
		_request_rebuild()
@export var concrete_color := Color("c4c5bf"):
	set(value):
		concrete_color = value
		_request_rebuild()
@export_range(8, 20, 1) var far_rows := 16:
	set(value):
		far_rows = clampi(value, 8, 20)
		_request_rebuild()
@export var minnesota_branding := false:
	set(value):
		minnesota_branding = value
		_request_rebuild()

func _build(b: RefCounted) -> void:
	var snow := Color("edeede")
	var metal := Color("626d70")
	_material.set_shader_parameter("edge_half_size", Vector2(73, 88))
	# Foreground rows descend toward the field; aisles break the long bench runs.
	for row in 14:
		var y := 2.2 + row * 0.6
		var z := -5.0 + row * 1.05
		_near_row(b, y, z, 38.0, snow)
		# A short flight of visible steps down the central aisle.
		for step in 2:
			b.box(Vector3(0, y - 0.15 + step * 0.3, z + step * 0.5),
				Vector3(1.7, 0.3, 0.5), concrete_color, 1.0)
	# Only the small upper deck is playable; surrounding tiers imply a huge bowl.
	for row in 6:
		_near_row(b, DECK_HEIGHT + 0.6 + row * 0.6, 15.0 + row * 1.05, 24.0, snow, true)
	# Two short benches on the safe deck's rear, with a generous walking corridor.
	for bench in [Vector2(-1.7, 2.6), Vector2(4.6, 6.2)]:
		var x: float = bench.x
		var width: float = bench.y
		b.box(Vector3(x, DECK_HEIGHT + 0.43, 13.45), Vector3(width, 0.14, 0.55), seat_color, 1.0)
		b.box(Vector3(x, DECK_HEIGHT + 0.85, 13.7), Vector3(width, 0.55, 0.13), seat_color, 1.0)
		b.box(Vector3(x, DECK_HEIGHT + 1.14, 13.7), Vector3(width + 0.05, 0.055, 0.18), snow, 2.0)
		_box_collision("DeckBenchLeft" if x < 0 else "DeckBenchRight",
			Vector3(x, DECK_HEIGHT + 0.6, 13.5), Vector3(width + 0.1, 1.2, 0.7))
	# Guardrails coincide with the MemoryPlatform's invisible safety rim.
	for x in range(-9, 10, 2):
		b.rod(Vector3(x, DECK_HEIGHT, 9.6), Vector3(x, DECK_HEIGHT + 1.05, 9.6), 0.045, metal)
	b.rod(Vector3(-9, DECK_HEIGHT + 1.05, 9.6), Vector3(9, DECK_HEIGHT + 1.05, 9.6), 0.055, metal)
	b.rod(Vector3(-9, DECK_HEIGHT + 0.45, 9.6), Vector3(9, DECK_HEIGHT + 0.45, 9.6), 0.035, metal)
	for x in [-9.0, 9.0]:
		b.rod(Vector3(x, DECK_HEIGHT + 1.05, 9.6), Vector3(x, DECK_HEIGHT + 1.05, 14.4), 0.055, metal)
		for z in [10.0, 12.0, 14.0]:
			b.rod(Vector3(x, DECK_HEIGHT, z), Vector3(x, DECK_HEIGHT + 1.05, z), 0.045, metal)
	# An incomplete entrance at the edge, keeping the explorer unobscured.
	b.box(Vector3(-10.4, 12.0, 13.5), Vector3(0.5, 3.0, 2.5), concrete_color, 1.0)
	b.box(Vector3(-11.3, 13.7, 13.5), Vector3(2.3, 0.4, 2.5), concrete_color, 1.0)
	b.box(Vector3(-11.3, 13.94, 13.5), Vector3(2.4, 0.08, 2.55), snow, 2.0)
	_far_bowl(b, snow)
	if minnesota_branding:
		_material.set_shader_parameter("minnesota_mark", preload("res://components/scenery/stadium/art/minnesota_m_reference.png"))
		MINNESOTA.append_seat_mark(b, 4.8, 14.5, FIELD_Z, FAR_BOWL_RADII)
		MINNESOTA.append_seat_text(b, "MINNESOTA", 12.1, 6.0, FIELD_Z, FAR_BOWL_RADII)
	for x in [-46.0, 46.0]:
		for z in [-50.0, -9.0]:
			_light_mast(b, Vector3(x, 0, z), metal)

func _near_row(b: RefCounted, y: float, z: float, half_width: float, snow: Color, open_middle: bool = false) -> void:
	if not open_middle:
		b.box(Vector3(0, y - 0.25, z), Vector3(half_width * 2, 0.5, 1.0), concrete_color, 1.0)
		b.box(Vector3(0, y + 0.025, z + 0.3), Vector3(half_width * 2, 0.05, 0.28), snow, 2.0)
	else:
		for side in [-1.0, 1.0]:
			b.box(Vector3(side * 18, y - 0.25, z), Vector3(12, 0.5, 1.0), concrete_color, 1.0)
			b.box(Vector3(side * 18, y + 0.025, z + 0.3), Vector3(12, 0.05, 0.28), snow, 2.0)
	for side in [-1.0, 1.0]:
		for block in 2:
			if open_middle and block == 0: continue
			var width := half_width * 0.5 - 1.4
			var x: float = side * (1.2 + width * 0.5 + block * (width + 1.3))
			b.box(Vector3(x, y + 0.32, z), Vector3(width, 0.12, 0.48), seat_color, 1.0)
			b.box(Vector3(x, y + 0.65, z + 0.24), Vector3(width, 0.5, 0.1), seat_color, 1.0)
			b.box(Vector3(x, y + 0.92, z + 0.24), Vector3(width, 0.045, 0.16), snow, 2.0)
			for seat in int(width / 0.85):
				var sx: float = x - width * 0.5 + (seat + 0.5) * 0.85
				b.box(Vector3(sx, y + 0.63, z + 0.17), Vector3(0.035, 0.36, 0.045), concrete_color, 1.0)

func _far_bowl(b: RefCounted, snow: Color) -> void:
	for row in far_rows:
		var rx := FAR_BOWL_RADII.x + row * 0.55
		var rz := FAR_BOWL_RADII.y + row * 0.72
		var y := 1.4 + row * 0.55
		for sector in 32:
			var angle := PI + PI * (sector + 0.5) / 32.0
			var at := Vector3(cos(angle) * rx, y, FIELD_Z + sin(angle) * rz)
			var next := Vector3(cos(angle + 0.01) * rx, y, FIELD_Z + sin(angle + 0.01) * rz)
			var tangent := (next - at).normalized()
			var yaw := atan2(-tangent.z, tangent.x)
			var basis := Basis(Vector3.UP, yaw)
			var width := Vector2(sin(angle) * rx, cos(angle) * rz).length() * PI / 32.0 + 0.12
			b.box(at, Vector3(width, 0.5, 0.85), concrete_color, 1.0, basis)
			var branded_bank := minnesota_branding and absf(at.x) < 26.0 and sin(angle) < -0.8
			b.box(at + Vector3.UP * 0.28, Vector3(width, 0.08, 0.32),
				seat_color if branded_bank else snow, 1.0 if branded_bank else 2.0, basis)
			if branded_bank: continue # Clear seat lettering, as in the supplied Minnesota view.
			if sector % 5 == 0: continue # Radial stair aisles remain lighter.
			for dab in 3:
				var point := at + tangent * (dab - 1) * width * 0.27
				var color := [seat_color, Color("b6a68c"), Color("8d9290")][(sector + row + dab) % 3] as Color
				b.soft_box(point + Vector3.UP * 0.58, Vector3(0.45, 0.5, 0.4), color, 0.08, 1.0)
	# Broken roof trim and supports give the distant tiers a college-stadium silhouette.
	for sector in range(2, 31, 2):
		var angle := PI + PI * sector / 32.0
		var at := Vector3(cos(angle) * (FAR_BOWL_RADII.x + 10.0), 11.0,
			FIELD_Z + sin(angle) * (FAR_BOWL_RADII.y + 13.0))
		b.rod(at - Vector3.UP * 3, at + Vector3.UP * 1.5, 0.09, Color("919b99"))
		b.box(at + Vector3.UP * 1.7, Vector3(5.8, 0.22, 2.0), snow, 2.0, Basis(Vector3.UP, -angle + PI * 0.5))

func _light_mast(b: RefCounted, at: Vector3, metal: Color) -> void:
	b.rod(at, at + Vector3.UP * 24, 0.15, metal)
	var center := at + Vector3.UP * 24
	var facing := (Vector3(0, 0, FIELD_Z) - center).normalized()
	var right := Vector3.UP.cross(facing).normalized()
	var basis := Basis(right, facing.cross(right).normalized(), facing)
	b.box(center, Vector3(4.6, 2.0, 0.25), Color("949b95"), 1.0, basis)
	for x in 6:
		for y in 2:
			b.box(center + basis * Vector3(-1.85 + x * 0.74, -0.5 + y * 0.9, 0.16),
				Vector3(0.5, 0.5, 0.09), Color("f0dec0"), 3.0, basis)
