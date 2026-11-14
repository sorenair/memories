@tool
class_name PainterlyJunglePlant
extends PainterlyTree
## Botanical forms reuse tree wood, palettes, smooth response and recall infrastructure.
signal ground_exclusion_changed
const JUNGLE_LEAVES = preload("res://components/foliage/jungle/jungle_leaf_geometry.gd")
const JUNGLE_PAINT = preload("res://components/foliage/jungle/jungle_leaves.gdshader")
const ROOT_WASH = preload("res://components/foliage/shaders/ground_wash.gdshader")
enum Form { FEATHER_PALM, FAN_PALM, BANANA, ELEPHANT_EAR, SPLIT_LEAF, FERN, BAMBOO }

@export_group("Jungle Plant")
@export_enum("Feather Palm", "Fan Palm", "Banana-like Blades", "Elephant Ears", "Split Leaves", "Fern", "Bamboo") var plant_form: int = 0:
	set(value):
		plant_form = clampi(value, 0, 6)
		_request_rebuild()
		notify_property_list_changed()
@export var plant_seed: int = 188:
	set(value):
		plant_seed = value
		_request_rebuild()
## Nominal height; individual arching fronds can extend slightly above it.
@export_range(0.25, 7.0, 0.05) var plant_height: float = 3.8:
	set(value):
		plant_height = clampf(value, 0.25, 7)
		_request_rebuild()
@export_range(0.5, 5.0, 0.05) var spread: float = 3.3:
	set(value):
		spread = clampf(value, 0.5, 5)
		_request_rebuild()
## Changes frond/leaf count, or culm count for bamboo. Zero is a sparse plant.
@export_range(0.0, 1.0, 0.05) var fullness: float = 0.65:
	set(value):
		fullness = clampf(value, 0, 1)
		_request_rebuild()
@export_range(0.0, 0.5, 0.025) var growth_curve: float = 0.15:
	set(value):
		growth_curve = clampf(value, 0, 0.5)
		_request_rebuild()

var _leaves: Array[Transform3D] = []
var _tints: Array[Color] = []
var _blockers: Array[Dictionary] = []
var _clock_override: float = -1.0

func _init() -> void:
	wind_strength = 0.065
	falling_leaf_count = 0

func _ready() -> void:
	set_notify_transform(true)
	super._ready()

func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSFORM_CHANGED and is_node_ready():
		ground_exclusion_changed.emit()

func _validate_property(property: Dictionary) -> void:
	super._validate_property(property)
	if property.name in ["tree_type", "tree_seed", "tree_height", "crown_width", "trunk_radius", "trunk_bend", "branch_count", "leaf_sprays_per_cluster", "falling_leaf_count", "falling_leaf_rate"]:
		property.usage = property.usage & ~PROPERTY_USAGE_EDITOR
	if property.name == "growth_curve" and plant_form in [2, 3, 4, 5]:
		property.usage = property.usage & ~PROPERTY_USAGE_EDITOR
	if property.name == "trunk_collision" and plant_form in [2, 3, 4, 5]:
		property.usage = property.usage & ~PROPERTY_USAGE_EDITOR
	if plant_form == Form.FERN and property.name in ["use_type_bark", "bark_shadow", "bark_light"]:
		property.usage = property.usage & ~PROPERTY_USAGE_EDITOR
	if property.name == "regenerate":
		property.hint_string = "Regenerate jungle plant"

func rebuild() -> void:
	_queued = false
	if not is_inside_tree():
		return
	_palette_materials.clear()
	_leaves.clear()
	_tints.clear()
	_blockers.clear()
	for child in get_children(true):
		if child.get_meta(&"generated_tree", false):
			remove_child(child)
			child.queue_free()
	var colors: GrassPalette = palette if palette else DEFAULT_PALETTE
	_canopy_material = _material(JUNGLE_PAINT, colors)
	PALETTES.apply(_canopy_material, colors)
	_canopy_material.set_shader_parameter("tree_phase", float(posmod(plant_seed, 997)) * 0.173)
	_canopy_material.set_shader_parameter("disturbance_strength", disturbance_strength if react_to_explorers else 0)
	_canopy_material.set_shader_parameter("disturbance_radius", 1.15)
	_canopy_material.set_shader_parameter("animation_time", _clock_override)
	_update_wind()
	var wood := _material(BARK_SHADER, colors)
	wood.set_shader_parameter("bark_shadow", (Color("6d614e") if plant_form <= 1 else Color("385b38")) if use_type_bark else bark_shadow)
	wood.set_shader_parameter("bark_light", (Color("b4a17d") if plant_form <= 1 else Color("94a76c")) if use_type_bark else bark_light)
	var rng := RandomNumberGenerator.new()
	rng.seed = plant_seed
	var bark := SurfaceTool.new()
	bark.begin(Mesh.PRIMITIVE_TRIANGLES)
	if plant_form <= Form.FAN_PALM:
		_palm(bark, rng)
	elif plant_form == Form.FERN:
		_fern(rng)
	elif plant_form == Form.BAMBOO:
		_bamboo(bark, rng)
	else:
		_broadleaf(bark, rng)
	if plant_form != Form.FERN:
		_add_mesh("Stems", bark.commit(), wood)
	var mesh: ArrayMesh = JUNGLE_LEAVES.mesh_for(plant_form)
	var batch := MultiMesh.new()
	batch.transform_format = MultiMesh.TRANSFORM_3D
	batch.use_custom_data = true
	batch.mesh = mesh
	batch.instance_count = _leaves.size()
	var bounds := AABB()
	for index in range(_leaves.size()):
		batch.set_instance_transform(index, _leaves[index])
		batch.set_instance_custom_data(index, _tints[index])
		var extent: AABB = _leaves[index] * mesh.get_aabb()
		bounds = extent if index == 0 else bounds.merge(extent)
	batch.custom_aabb = bounds.grow(maxf(0.65, disturbance_strength + wind_strength + 0.20))
	var leaves := MultiMeshInstance3D.new()
	leaves.name = "Foliage"
	leaves.multimesh = batch
	leaves.material_override = _canopy_material
	_add_generated(leaves)
	_add_root_wash(colors)
	if trunk_collision and not _blockers.is_empty():
		var body := StaticBody3D.new()
		body.name = "StemCollision"
		for info in _blockers:
			var collision := CollisionShape3D.new()
			var capsule := CapsuleShape3D.new()
			capsule.radius = info.radius
			var delta: Vector3 = info.b - info.a
			capsule.height = delta.length() + info.radius * 2.0
			collision.shape = capsule
			collision.position = (info.a + info.b) * 0.5
			collision.quaternion = Quaternion(Vector3.UP, delta.normalized())
			body.add_child(collision)
		_add_generated(body)
	_sync_recall()
	ground_exclusion_changed.emit()

func _leaf(at: Vector3, yaw: float, pitch: float, size: Vector3, tint: float, rng: RandomNumberGenerator) -> void:
	var basis := Basis(Vector3.UP, yaw) * Basis(Vector3.RIGHT, pitch)
	_leaves.append(Transform3D(basis.scaled(size), at))
	_tints.append(Color(clampf(tint, 0.12, 0.90), rng.randf(), rng.randf(), 1.0))

func _palm(s: SurfaceTool, rng: RandomNumberGenerator) -> void:
	var h := plant_height * 0.82
	var radius := maxf(0.055, plant_height * 0.032)
	var angle := rng.randf() * TAU
	var lean := Vector3(cos(angle), 0, sin(angle)) * growth_curve * plant_height * 0.36
	var points: Array[Vector3] = []
	var radii: Array[float] = []
	for index in range(7):
		var t := float(index) / 6.0
		points.append(Vector3.UP * t * h + lean * sin(t * PI * 0.65))
		radii.append(radius * lerpf(1.55, 0.87, sqrt(t)))
	_tube(s, points, radii, rng)
	for index in range(4):
		_blockers.append({"a": points[index], "b": points[index + 1], "radius": radii[index] * 0.95})
	# Broad rounded leaf scars, without a fringe of thin dead-leaf spikes.
	for ring in range(8):
		var t := 0.12 + float(ring) * 0.095
		var at := Vector3.UP * h * t + lean * sin(t * PI * 0.65)
		var r := radius * lerpf(1.1, 0.88, t)
		_tube(s, [at - Vector3.UP * 0.02, at, at + Vector3.UP * 0.018], [r, r * 1.10, r], rng)
	var count := roundi(8 + fullness * 9)
	var crown := points[-1]
	for index in range(count):
		var yaw := float(index) * 2.39996 + rng.randf_range(-0.17, 0.17)
		var scale_value := spread * rng.randf_range(0.43, 0.55)
		var pitch := rng.randf_range(-0.18, 0.23) if plant_form == 0 else rng.randf_range(-0.55, 0.34)
		_leaf(crown + Vector3.UP * rng.randf_range(-0.07, 0.04), yaw, pitch, Vector3.ONE * scale_value, rng.randf_range(0.38, 0.72), rng)
	for index in range(3):
		_leaf(crown, angle + index * 2.0, -0.95, Vector3.ONE * spread * 0.26, 0.75, rng)

func _broadleaf(s: SurfaceTool, rng: RandomNumberGenerator) -> void:
	var count := roundi(6 + fullness * 10)
	for index in range(count):
		var yaw := index * 2.39996 + rng.randf_range(-0.3, 0.3)
		var out := Vector3(sin(yaw), 0, cos(yaw))
		var tier := float(index % 3) / 2.0
		var root := out * rng.randf_range(0.035, 0.12)
		var end := out * spread * rng.randf_range(0.13, 0.22) + Vector3.UP * plant_height * (0.40 + tier * 0.29)
		_tube(s, [root, root.lerp(end, 0.48) + Vector3.UP * plant_height * 0.09, end], [0.023, 0.017, 0.008], rng)
		var pitch := lerpf(0.40, -0.48, tier) + rng.randf_range(-0.10, 0.10)
		if plant_form == Form.ELEPHANT_EAR:
			pitch = rng.randf_range(0.34, 0.78)
		var scale_value := spread * rng.randf_range(0.40, 0.53)
		_leaf(end, yaw, pitch, Vector3.ONE * scale_value, rng.randf_range(0.35, 0.76), rng)

func _fern(rng: RandomNumberGenerator) -> void:
	var count := roundi(9 + fullness * 12)
	for index in range(count):
		var tier := float(index % 3) / 2.0
		var scale_value := spread * (0.50 - tier * 0.14) * rng.randf_range(0.85, 1.08)
		var size := Vector3(scale_value, plant_height * 1.65, scale_value)
		_leaf(Vector3.UP * 0.035, index * 2.39996 + rng.randf_range(-0.15, 0.15), lerpf(0.05, -0.48, tier), size, rng.randf_range(0.36, 0.74), rng)

func _bamboo(s: SurfaceTool, rng: RandomNumberGenerator) -> void:
	var count := roundi(3 + fullness * 6)
	for stem in range(count):
		var a := stem * 2.39996 + rng.randf_range(-0.2, 0.2)
		var root := Vector3(cos(a), 0, sin(a)) * sqrt(rng.randf()) * spread * 0.24
		var h := plant_height * rng.randf_range(0.80, 1.06)
		var lean := Vector3(cos(a), 0, sin(a)) * h * growth_curve * rng.randf_range(0.3, 0.6)
		var radius := rng.randf_range(0.027, 0.040) * sqrt(plant_height / 2.5)
		var points: Array[Vector3] = []
		for index in range(5):
			var t := float(index) / 4.0
			points.append(root + Vector3.UP * t * h + lean * t * t)
		_tube(s, points, [radius * 1.2, radius, radius * 0.95, radius * 0.85, radius * 0.45], rng)
		_blockers.append({"a": root, "b": points[2], "radius": radius * 1.2})
		for node in range(1, 7):
			var t := float(node) / 7.0
			var at := root + Vector3.UP * h * t + lean * t * t
			_tube(s, [at - Vector3.UP * 0.012, at, at + Vector3.UP * 0.012], [radius, radius * 1.24, radius], rng)
		for branch in range(3):
			var t := 0.43 + branch * 0.21
			var at := root + Vector3.UP * h * t + lean * t * t
			var yaw := a + branch * 2.4
			var end := at + Vector3(sin(yaw), 0.2, cos(yaw)) * spread * 0.19
			_tube(s, [at, end], [0.011, 0.004], rng)
			for leaf in range(5):
				_leaf(end, yaw + (leaf - 2) * 0.48, rng.randf_range(-0.4, 0.35), Vector3.ONE * spread * rng.randf_range(0.20, 0.30), rng.randf_range(0.38, 0.72), rng)

func _add_root_wash(colors: GrassPalette) -> void:
	var width := minf(1.1, plant_height * 0.30) if plant_form <= 1 else spread * (0.60 if plant_form == Form.FERN else 0.65)
	var wash := MeshInstance3D.new()
	wash.name = "GroundPigment"
	var plane := PlaneMesh.new()
	plane.size = Vector2.ONE * width
	wash.mesh = plane
	var material := _material(ROOT_WASH, colors)
	PALETTES.apply(material, colors)
	material.set_shader_parameter("patch_size", Vector2.ONE * width * 0.8)
	material.set_shader_parameter("shape_phase", float(plant_seed) * 0.173)
	wash.material_override = material
	wash.position.y = 0.013
	_add_generated(wash)

func _sync_recall() -> void:
	_recall_effect = RECALL.configure(self, "res://components/effects/recall/assembled_recall.gd", _recall_effect)
	if not recall_enabled and not Engine.is_editor_hint():
		preload("res://components/effects/recall/assembled_recall.gd").restore_component(self)

func seek_time(seconds: float) -> void:
	_clock_override = seconds
	if _canopy_material:
		_canopy_material.set_shader_parameter("animation_time", seconds)

func excludes_ground_point(world_point: Vector3) -> bool:
	var p := to_local(world_point)
	var radius := maxf(0.15, plant_height * 0.052) if plant_form <= 1 else (spread * 0.25 if plant_form == Form.BAMBOO else 0.10)
	return Vector2(p.x, p.z).length() < radius
