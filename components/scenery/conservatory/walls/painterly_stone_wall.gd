@tool
class_name PainterlyStoneWall
extends PainterlyConservatoryPiece
## Modular center-origin wall along X. Arc length stays constant when curved.
@export_group("Masonry")
@export_enum("Stacked Stone", "Cut Blocks", "Large Slabs") var masonry_style: int = 0:
	set(value):
		masonry_style = clampi(value, 0, 2)
		_request_rebuild()
@export_range(1.0, 12.0, 0.1) var length: float = 4.5:
	set(value):
		length = clampf(value, 1, 12)
		_request_rebuild()
@export_range(0.25, 3.0, 0.05) var wall_height: float = 0.8:
	set(value):
		wall_height = clampf(value, 0.25, 3)
		_request_rebuild()
@export_range(0.25, 0.85, 0.05) var thickness: float = 0.42:
	set(value):
		thickness = clampf(value, 0.25, 0.85)
		_request_rebuild()
@export_range(-120.0, 120.0, 1.0) var curve_degrees: float = 0.0:
	set(value):
		curve_degrees = clampf(value, -120, 120)
		_request_rebuild()
@export var coping_enabled: bool = true:
	set(value):
		coping_enabled = value
		_request_rebuild()
@export var stone_color := Color("b5b6a3"):
	set(value):
		stone_color = value
		_request_rebuild()

func point_at(t: float) -> Vector3:
	var angle := deg_to_rad(curve_degrees)
	if absf(angle) < 0.001:
		return Vector3((t - 0.5) * length, 0, 0)
	var radius := length / angle
	var a := (t - 0.5) * angle
	return Vector3(sin(a) * radius, 0, (cos(a) - 1.0) * radius)

func yaw_at(t: float) -> float:
	return (t - 0.5) * deg_to_rad(curve_degrees)

func _build(b: RefCounted) -> void:
	var row_height: float = [0.16, 0.30, 0.72][masonry_style]
	var block_width: float = [0.64, 0.66, 1.16][masonry_style]
	var cap := 0.085 if coping_enabled else 0.0
	var rows := maxi(1, roundi((wall_height - cap) / row_height))
	var rise := (wall_height - cap) / rows
	# A continuous, mitered mortar core prevents gaps along curved joins.
	var sections := maxi(1, ceili(absf(curve_degrees) / 8.0))
	for section in range(sections):
		var t0 := float(section) / sections
		var t1 := float(section + 1) / sections
		var a := point_at(t0)
		var c := point_at(t1)
		var side_a := Basis(Vector3.UP, yaw_at(t0)).z * (thickness * 0.45)
		var side_c := Basis(Vector3.UP, yaw_at(t1)).z * (thickness * 0.45)
		var h := Vector3.UP * (wall_height - cap)
		var mortar := stone_color.darkened(0.16)
		b.quad(a + side_a, c + side_c, c + side_c + h, a + side_a + h, mortar, 1)
		b.quad(c - side_c, a - side_a, a - side_a + h, c - side_c + h, mortar, 1)
		b.quad(a + h - side_a, a + h + side_a, c + h + side_c, c + h - side_c, mortar, 1)
		if collision_enabled:
			var body := StaticBody3D.new()
			body.name = "WallSection_%d" % section
			var shape := ConvexPolygonShape3D.new()
			var points := PackedVector3Array()
			for p in [a - side_a * 1.12, a + side_a * 1.12, c - side_c * 1.12, c + side_c * 1.12]:
				points.append(p)
				points.append(p + Vector3.UP * wall_height)
			shape.points = points
			var collider := CollisionShape3D.new()
			collider.shape = shape
			body.add_child(collider)
			_generated(body)
	# Close exposed module ends; neighboring sections can still butt together.
	for t in [0.0, 1.0]:
		var end := point_at(t)
		var side := Basis(Vector3.UP, yaw_at(t)).z * thickness * 0.45
		var h := Vector3.UP * (wall_height - cap)
		if t < 0.5:
			b.quad(end - side, end + side, end + side + h, end - side + h, stone_color.darkened(0.16), 1)
		else:
			b.quad(end + side, end - side, end - side + h, end + side + h, stone_color.darkened(0.16), 1)
	for row in range(rows):
		var cursor := 0.0
		while cursor < length - 0.005:
			var span: float = minf(length - cursor, block_width * b.rng.randf_range(0.70, 1.28) * (0.53 if cursor == 0 and row % 2 else 1.0))
			var t := (cursor + span * 0.5) / length
			var color := stone_color.lightened(b.rng.randf_range(-0.075, 0.065))
			b.frame = Transform3D(Basis(Vector3.UP, yaw_at(t)), point_at(t))
			if masonry_style == 0:
				var half := maxf(0.015, span * 0.5 - 0.008)
				var low := rise * row + 0.007
				var high := rise * (row + 1) - 0.007
				var bevel := minf(0.028, half * 0.3)
				var outline := PackedVector2Array([Vector2(-half + bevel, low), Vector2(half - bevel, low + b.rng.randf_range(-0.006, 0.006)), Vector2(half, low + 0.022), Vector2(half, high - 0.018), Vector2(half - bevel, high), Vector2(-half + bevel, high + b.rng.randf_range(-0.006, 0.006)), Vector2(-half, high - 0.022), Vector2(-half, low + 0.018)])
				b.profile(outline, Vector3(0, 0, b.rng.randf_range(-0.012, 0.012)), thickness + b.rng.randf_range(-0.025, 0.025), color, 1)
			else:
				b.soft_box(Vector3(0, rise * (row + 0.5), b.rng.randf_range(-0.01, 0.01)), Vector3(maxf(0.02, span - 0.016), rise - 0.014, thickness + b.rng.randf_range(-0.025, 0.025)), color, minf(0.028, rise * 0.12), 1)
			cursor += span
	if coping_enabled:
		var caps := ceili(length / 0.68)
		for index in range(caps):
			var t := (float(index) + 0.5) / caps
			b.frame = Transform3D(Basis(Vector3.UP, yaw_at(t)), point_at(t))
			b.soft_box(Vector3(0, wall_height - cap * 0.5, 0), Vector3(length / caps - 0.01, cap, thickness + 0.10), stone_color.lightened(0.10 + b.rng.randf_range(-0.025, 0.025)), 0.018, 1)
	b.frame = Transform3D.IDENTITY
	_anchor("Start", point_at(0), yaw_at(0))
	_anchor("End", point_at(1), yaw_at(1))

func excludes_ground_point(world_point: Vector3) -> bool:
	var at := to_local(world_point)
	var p := Vector2(at.x, at.z)
	for section in range(16):
		var a := point_at(float(section) / 16)
		var c := point_at(float(section + 1) / 16)
		if p.distance_to(Geometry2D.get_closest_point_to_segment(p, Vector2(a.x, a.z), Vector2(c.x, c.z))) < thickness * 0.5 + 0.07:
			return true
	return false
