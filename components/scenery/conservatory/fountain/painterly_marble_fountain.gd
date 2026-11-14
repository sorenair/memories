@tool
class_name PainterlyMarbleFountain
extends PainterlyConservatoryPiece
## Sculpted basin, hourglass pedestal, scalloped bowl and GPU-animated water.
const TURNED = preload("res://components/scenery/conservatory/shared/turned_geometry.gd")
const WATER_PAINT = preload("res://components/scenery/conservatory/fountain/fountain_water.gdshader")
const PIGMENT = preload("res://components/scenery/water/textures/water_pigment.png")
const CAUSTICS = preload("res://components/scenery/water/textures/water_caustics.png")
@export_group("Fountain")
@export_range(0.85, 2.5, 0.05) var basin_radius: float = 1.45:
	set(value):
		basin_radius = clampf(value, 0.85, 2.5)
		_request_rebuild()
@export_range(1.2, 2.8, 0.05) var fountain_height: float = 1.8:
	set(value):
		fountain_height = clampf(value, 1.2, 2.8)
		_request_rebuild()
@export var marble_color := Color("e0d4b9"):
	set(value):
		marble_color = value
		_request_rebuild()
@export var water_enabled: bool = true:
	set(value):
		water_enabled = value
		_request_rebuild()
@export var water_color := Color("589f9a"):
	set(value):
		water_color = value
		_update_water()
@export_range(0.0, 2.0, 0.05) var flow_speed: float = 1.0:
	set(value):
		flow_speed = clampf(value, 0, 2)
		_update_water()
var _water_material: ShaderMaterial
var _visual_time: float = -1.0

func _profile(b: RefCounted, points: Array[Vector2], flute: float = 0.0) -> void:
	var scaled: Array[Vector2] = []
	for p in points:
		scaled.append(Vector2(p.x * basin_radius, p.y * fountain_height))
	TURNED.lathe(b, scaled, marble_color, 2, 64, flute)

func _build(b: RefCounted) -> void:
	_profile(b, [Vector2(0.001, 0.02), Vector2(1.03, 0.02), Vector2(1.03, 0.07), Vector2(1, 0.10), Vector2(0.96, 0.26), Vector2(0.99, 0.29), Vector2(1.02, 0.31), Vector2(0.86, 0.31), Vector2(0.84, 0.285), Vector2(0.83, 0.14), Vector2(0.001, 0.14)])
	_profile(b, [Vector2(0.24, 0.14), Vector2(0.25, 0.20), Vector2(0.20, 0.26), Vector2(0.13, 0.50), Vector2(0.16, 0.74), Vector2(0.23, 0.79)])
	_profile(b, [Vector2(0.001, 0.78), Vector2(0.25, 0.78), Vector2(0.44, 0.85), Vector2(0.47, 0.90), Vector2(0.42, 0.92), Vector2(0.39, 0.875), Vector2(0.001, 0.86)], 0.025)
	b.ball(Vector3.UP * fountain_height * 0.93, Vector3(0.16, 0.20, 0.16) * basin_radius, marble_color, 2)
	# Discrete carved seams suggest assembled stone without a noisy brick grid.
	for index in range(12):
		var a := TAU * float(index) / 12.0
		var out := Vector3(cos(a), 0, sin(a))
		b.rod(out * basin_radius * 1.021 + Vector3.UP * fountain_height * 0.075, out * basin_radius * 0.975 + Vector3.UP * fountain_height * 0.25, 0.006, marble_color.darkened(0.10), 5)
	if collision_enabled:
		var body := StaticBody3D.new()
		body.name = "BasinCollision"
		var collider := CollisionShape3D.new()
		var cylinder := CylinderShape3D.new()
		cylinder.radius = basin_radius * 1.03
		cylinder.height = fountain_height * 0.31
		collider.shape = cylinder
		collider.position.y = cylinder.height * 0.5
		body.add_child(collider)
		_generated(body)
	_anchor("Center", Vector3.UP * fountain_height * 0.27)
	_anchor("Approach", Vector3(0, 0, basin_radius * 1.03 + 0.75))

func _build_layers() -> void:
	_water_material = null
	_contact(Vector2.ONE * basin_radius * 2.6)
	if not water_enabled:
		return
	var b := GEOMETRY.new()
	b.s = SurfaceTool.new()
	b.s.begin(Mesh.PRIMITIVE_TRIANGLES)
	b.s.set_uv(Vector2.ZERO)
	# Two thin opaque water disks stay inside the stone lips.
	for level in [Vector2(0.837, 0.27), Vector2(0.385, 0.892)]:
		var center: Vector3 = Vector3.UP * fountain_height * level.y
		for index in range(64):
			var a := TAU * float(index) / 64.0
			var c := TAU * float(index + 1) / 64.0
			for point in [center, center + Vector3(cos(c), 0, sin(c)) * basin_radius * level.x, center + Vector3(cos(a), 0, sin(a)) * basin_radius * level.x]:
				b.vertex(point, Vector3.UP, Color.WHITE, 0)
	# Gentle overflow arcs and a small central jet, kept in one water batch.
	for index in range(8):
		var angle := TAU * float(index) / 8.0 + 0.18
		var out := Vector3(cos(angle), 0, sin(angle))
		var start := out * basin_radius * 0.435 + Vector3.UP * fountain_height * 0.90
		var control := out * basin_radius * 0.62 + Vector3.UP * fountain_height * 0.92
		var end := out * basin_radius * 0.72 + Vector3.UP * fountain_height * 0.273
		_water_arc(b, start, control, end, 0.0065 * basin_radius)
	_water_arc(b, Vector3.UP * fountain_height * 0.97, Vector3.UP * fountain_height * 1.23 + Vector3.RIGHT * 0.10, Vector3(0.23, fountain_height * 0.895, 0), 0.015)
	_water_material = ShaderMaterial.new()
	_water_material.shader = WATER_PAINT
	_water_material.set_shader_parameter("pigment_mask", PIGMENT)
	_water_material.set_shader_parameter("caustic_mask", CAUSTICS)
	_update_water()
	var water := MeshInstance3D.new()
	water.name = "LivingWater"
	water.mesh = b.s.commit()
	water.material_override = _water_material
	water.custom_aabb = water.mesh.get_aabb().grow(0.02)
	_generated(water)

func _water_arc(b: RefCounted, start: Vector3, control: Vector3, end: Vector3, radius: float) -> void:
	for row in range(14):
		for side in range(6):
			for corner in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1), Vector2i(0, 0), Vector2i(1, 1), Vector2i(0, 1)]:
				var t := float(row + corner.x) / 14.0
				var u := 1.0 - t
				var center := start * u * u + control * 2.0 * u * t + end * t * t
				var tangent := ((control - start) * u + (end - control) * t).normalized()
				var x := tangent.cross(Vector3.FORWARD).normalized()
				if x.length_squared() < 0.1:
					x = tangent.cross(Vector3.RIGHT).normalized()
				var angle := TAU * float(side + corner.y) / 6.0
				var normal := x * cos(angle) + tangent.cross(x) * sin(angle)
				b.s.set_uv(Vector2(float(side) / 6.0, t))
				b.vertex(center + normal * radius, normal, Color.WHITE, 1)

func _update_water() -> void:
	if _water_material:
		_water_material.set_shader_parameter("water_color", water_color)
		_water_material.set_shader_parameter("flow_speed", flow_speed)
		_water_material.set_shader_parameter("animation_time", _visual_time)

func seek_time(seconds: float) -> void:
	_visual_time = seconds
	_update_water()

func excludes_ground_point(world_point: Vector3) -> bool:
	var p := to_local(world_point)
	return Vector2(p.x, p.z).length() < basin_radius * 1.03 + 0.06
