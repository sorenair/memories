@tool
class_name PainterlyFlowerBush
extends PainterlyBush
## Existing bush, with clustered opaque blossoms following the same wind/bending.
const CROWNS = preload("res://components/foliage/flowers/painterly_flower_patch.gd")
const BUILDER = preload("res://components/activities/arcade/shared/arcade_geometry.gd")
@export_group("Flowers")
@export_enum("Open Petals", "Ruffled Rosettes", "Clustered Florets") var flower_style: int = 0:
	set(value):
		flower_style = clampi(value, 0, 2)
		_request_rebuild()
## Number of blossom heads. Clustered Florets places five small flowers per head.
@export_range(0, 160, 1) var flower_count: int = 56:
	set(value):
		flower_count = clampi(value, 0, 160)
		_request_rebuild()
@export_range(0.035, 0.18, 0.005) var flower_size: float = 0.09:
	set(value):
		flower_size = clampf(value, 0.035, 0.18)
		_request_rebuild()
@export var flower_color := Color("c65a9e"):
	set(value):
		flower_color = value
		_apply_bloom_colors()
@export var flower_highlight := Color("f5bad2"):
	set(value):
		flower_highlight = value
		_apply_bloom_colors()
@export var center_color := Color("efca80"):
	set(value):
		center_color = value
		_apply_bloom_colors()
var _bloom_material: ShaderMaterial
var _masses: Array[Dictionary] = []
static var _head_meshes: Dictionary = {}

func _grow_mass(center: Vector3, radii: Vector3, rng: RandomNumberGenerator, transforms: Array[Transform3D], tints: Array[Color]) -> void:
	_masses.append({"center": center, "radii": radii})
	super._grow_mass(center, radii, rng, transforms, tints)

func rebuild() -> void:
	_masses.clear()
	_bloom_material = null
	super.rebuild()
	if not is_inside_tree() or flower_count == 0 or sprays_per_mass == 0:
		return
	_bloom_material = ShaderMaterial.new()
	_bloom_material.shader = LEAF_SHADER
	_bloom_material.set_shader_parameter("tree_height", bush_height)
	_bloom_material.set_shader_parameter("tree_phase", float(posmod(bush_seed, 1000)) * 0.173)
	_apply_bloom_colors()
	_update_wind()
	_update_disturbance_settings()
	_send_disturbance()
	var rng := RandomNumberGenerator.new()
	rng.seed = bush_seed ^ 0xB100
	var mesh := _head_mesh()
	var batch := MultiMesh.new()
	batch.transform_format = MultiMesh.TRANSFORM_3D
	batch.use_custom_data = true
	batch.mesh = mesh
	batch.instance_count = flower_count
	var bounds := AABB()
	# Repeated head positions share small growth clusters, rather than uniform dots.
	var clusters: Array[Dictionary] = []
	for index in range(maxi(5, flower_count / 4)):
		var mass: Dictionary = _masses[index % _masses.size()]
		var y := rng.randf_range(0.18, 0.98)
		var angle := rng.randf() * TAU
		var out := Vector3(cos(angle) * sqrt(1.0 - y * y), y, sin(angle) * sqrt(1.0 - y * y))
		clusters.append({"position": mass.center + out * mass.radii * 0.95, "normal": (Vector3.UP * 0.50 + out).normalized(), "tint": rng.randf_range(0.32, 0.82)})
	for index in range(flower_count):
		var cluster: Dictionary = clusters[index % clusters.size()]
		var normal: Vector3 = cluster.normal
		var side := normal.cross(Vector3.FORWARD).normalized()
		var basis := Basis(side, normal, side.cross(normal)) * Basis(Vector3.UP, rng.randf() * TAU)
		var position: Vector3 = cluster.position + basis.x * rng.randf_range(-0.095, 0.095) + basis.z * rng.randf_range(-0.095, 0.095) + normal * 0.045
		var scale_value := flower_size * rng.randf_range(0.68, 1.32)
		var transform := Transform3D(basis.scaled(Vector3.ONE * scale_value), position)
		batch.set_instance_transform(index, transform)
		batch.set_instance_custom_data(index, Color(clampf(cluster.tint + rng.randf_range(-0.08, 0.08), 0, 1), rng.randf(), rng.randf(), clampf(position.y / bush_height, 0, 1)))
		var extent := transform * mesh.get_aabb()
		bounds = extent if index == 0 else bounds.merge(extent)
	batch.custom_aabb = bounds.grow(1.0)
	var blooms := MultiMeshInstance3D.new()
	blooms.name = "Blossoms"
	blooms.multimesh = batch
	blooms.material_override = _bloom_material
	_add_generated(blooms)
	_sync_recall()

func _head_mesh() -> ArrayMesh:
	if _head_meshes.has(flower_style):
		return _head_meshes[flower_style]
	# Reuse the approved rounded petal crowns; only their arrangement changes.
	var source := CROWNS.new()
	source.petal_count = 7 if flower_style == 1 else 5
	source.bloom_radius = 1.0
	var crown := source._flower_mesh()
	source.free()
	var b := BUILDER.new()
	b.s = SurfaceTool.new()
	b.s.begin(Mesh.PRIMITIVE_TRIANGLES)
	if flower_style == 2:
		for index in range(5):
			var a := float(index) * 2.39996
			var at := Vector3(cos(a) * 0.50, 0.20 + sin(a) * 0.13, sin(a) * 0.50)
			_append_crown(b, crown, Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * 0.52), at))
	else:
		_append_crown(b, crown, Transform3D.IDENTITY)
		if flower_style == 1:
			_append_crown(b, crown, Transform3D(Basis(Vector3.UP, 0.43).scaled(Vector3.ONE * 0.62), Vector3.UP * 0.19))
	var mesh := b.s.commit()
	_head_meshes[flower_style] = mesh
	return mesh

func _append_crown(b: RefCounted, mesh: ArrayMesh, transform: Transform3D) -> void:
	var arrays := mesh.surface_get_arrays(0)
	var points: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var colors: PackedColorArray = arrays[Mesh.ARRAY_COLOR]
	var normal_basis := transform.basis.inverse().transposed()
	for index in range(points.size()):
		b.vertex(transform * points[index], (normal_basis * normals[index]).normalized(), colors[index])

func _apply_bloom_colors() -> void:
	if _bloom_material:
		_bloom_material.set_shader_parameter("root_color", flower_color.darkened(0.38))
		_bloom_material.set_shader_parameter("shade_color", flower_color.darkened(0.12))
		_bloom_material.set_shader_parameter("leaf_color", flower_color.lerp(flower_highlight, 0.30))
		_bloom_material.set_shader_parameter("sun_color", flower_highlight)
		_bloom_material.set_shader_parameter("flower_centers", flower_style == 0)
		_bloom_material.set_shader_parameter("flower_center_color", center_color)

func _update_wind() -> void:
	super._update_wind()
	if _bloom_material:
		_bloom_material.set_shader_parameter("wind_strength", wind_strength)
		_bloom_material.set_shader_parameter("wind_speed", wind_speed)

func _update_disturbance_settings() -> void:
	super._update_disturbance_settings()
	if _bloom_material:
		_bloom_material.set_shader_parameter("disturbance_strength", disturbance_strength)
		_bloom_material.set_shader_parameter("disturbance_radius", disturbance_radius)

func _send_disturbance() -> void:
	super._send_disturbance()
	if _bloom_material:
		_bloom_material.set_shader_parameter("disturbance_sources", _leaf_material.get_shader_parameter("disturbance_sources"))

func _sync_recall() -> void:
	_recall_effect = RECALL.configure(self, "res://components/effects/recall/assembled_recall.gd", _recall_effect)
	if not recall_enabled and not Engine.is_editor_hint():
		preload("res://components/effects/recall/assembled_recall.gd").restore_component(self)
