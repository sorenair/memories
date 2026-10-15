@tool
class_name PainterlyBush
extends Node3D
## A low, irregular shrub built from the same opaque leaf sprays as the tree.
## Two draw surfaces, editor previews, smooth player disturbance, no collisions.
const LEAF_GEOMETRY = preload("res://components/foliage/shared/leaf_geometry.gd")
const LEAF_SHADER = preload("res://components/foliage/shaders/tree_canopy.gdshader")
const WASH_SHADER = preload("res://components/foliage/shaders/ground_wash.gdshader")
const DEFAULT_PALETTE = preload("res://components/foliage/palettes/meadow.tres")
const SUN_DIRECTION = Vector3(-0.45, 0.82, -0.35)

const PALETTES = preload("res://components/foliage/shared/foliage_palettes.gd")

@export_group("Foliage Colors")
@export_enum("Custom", "Summer Meadow", "Spring", "Autumn Gold", "Autumn Red", "Winter Frost", "Dream Lavender", "Dream Blue", "Dream Rose", "Dusk") var palette_preset: int = 1:
	set(value):
		palette_preset = clampi(value, 0, 9)
		if palette_preset != 0:
			_applying_preset = true
			palette = PALETTES.create_preset(palette_preset)
			_applying_preset = false
		notify_property_list_changed()
@export var palette: GrassPalette = DEFAULT_PALETTE:
	set(value):
		if palette and palette.changed.is_connected(_on_palette_changed):
			palette.changed.disconnect(_on_palette_changed)
		palette = value
		if palette:
			palette.changed.connect(_on_palette_changed)
		if not _applying_preset:
			palette_preset = 0
		_apply_palette()
@export_group("")
@export var bush_seed: int = 136:
	set(value):
		bush_seed = value
		_request_rebuild()
@export var footprint := Vector2(1.65, 1.3):
	set(value):
		footprint = value.clamp(Vector2(0.4, 0.4), Vector2(5.0, 5.0))
		_request_rebuild()
@export_range(0.25, 2.5, 0.05) var bush_height: float = 0.95:
	set(value):
		bush_height = clampf(value, 0.25, 2.5)
		_request_rebuild()
@export_range(3, 7, 1) var mass_count: int = 4:
	set(value):
		mass_count = clampi(value, 3, 7)
		_request_rebuild()
@export_range(0, 120, 1) var sprays_per_mass: int = 54:
	set(value):
		sprays_per_mass = clampi(value, 0, 120)
		_request_rebuild()
@export_range(0.0, 0.25, 0.005) var wind_strength: float = 0.055:
	set(value):
		wind_strength = value
		_update_wind()
@export_range(0.0, 3.0, 0.05) var wind_speed: float = 0.8:
	set(value):
		wind_speed = value
		_update_wind()
@export var react_to_explorers: bool = true:
	set(value):
		react_to_explorers = value
		if is_inside_tree():
			set_process(not Engine.is_editor_hint() and value)
		if not value:
			_source_weights.fill(0.0)
			_send_disturbance()
@export_range(0.0, 0.5, 0.01) var disturbance_strength: float = 0.28:
	set(value):
		disturbance_strength = value
		_update_disturbance_settings()
@export_range(0.3, 1.5, 0.05) var disturbance_radius: float = 0.8:
	set(value):
		disturbance_radius = value
		_update_disturbance_settings()
@export_range(10.0, 100.0, 1.0) var visibility_distance: float = 40.0:
	set(value):
		visibility_distance = value
		_request_rebuild()
@export_tool_button("Regenerate bush") var regenerate = rebuild

var _applying_preset: bool = false
var _palette_materials: Array[ShaderMaterial] = []
var _queued: bool = false
var _leaf_material: ShaderMaterial
var _sources: Array[Node3D] = [null, null]
var _source_positions: Array[Vector3] = [Vector3.ZERO, Vector3.ZERO]
var _source_weights := PackedFloat32Array([0.0, 0.0])
var _scan_timer: float = 0.0

func _ready() -> void:
	if palette and not palette.changed.is_connected(_on_palette_changed):
		palette.changed.connect(_on_palette_changed)
	rebuild()

func _validate_property(property: Dictionary) -> void:
	# Presets recreate their own local resource on load. Only Custom stores it,
	# preventing saved property order from overriding the selected preset.
	if property.name == "palette" and palette_preset != 0:
		property.usage = property.usage & ~PROPERTY_USAGE_STORAGE

func _on_palette_changed() -> void:
	palette_preset = 0
	_apply_palette()

func _apply_palette() -> void:
	var colors: GrassPalette = palette if palette else DEFAULT_PALETTE
	for material in _palette_materials:
		PALETTES.apply(material, colors)

func _request_rebuild() -> void:
	if is_inside_tree() and not _queued:
		_queued = true
		call_deferred("rebuild")

func _update_wind() -> void:
	if _leaf_material:
		_leaf_material.set_shader_parameter("wind_strength", wind_strength)
		_leaf_material.set_shader_parameter("wind_speed", wind_speed)

func _material(shader: Shader) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = shader
	var colors: GrassPalette = palette if palette else DEFAULT_PALETTE
	for key in [&"root_color", &"shade_color", &"leaf_color", &"sun_color"]:
		material.set_shader_parameter(key, colors.get(key))
	_palette_materials.append(material)
	return material

func rebuild() -> void:
	_queued = false
	if not is_inside_tree():
		return
	_palette_materials.clear()
	for child in get_children(true):
		if child.get_meta(&"generated_bush", false):
			remove_child(child)
			child.queue_free()
	_leaf_material = _material(LEAF_SHADER)
	_leaf_material.set_shader_parameter("tree_height", bush_height)
	_leaf_material.set_shader_parameter("tree_phase", float(posmod(bush_seed, 1000)) * 0.173)
	_update_wind()
	_update_disturbance_settings()
	_send_disturbance()
	var rng := RandomNumberGenerator.new()
	rng.seed = bush_seed
	var transforms: Array[Transform3D] = []
	var tints: Array[Color] = []
	# One taller central mass, with lower offset masses creating a spreading skirt.
	# A separate stream keeps mass shape stable when only leaf density changes.
	var shape_rng := RandomNumberGenerator.new()
	shape_rng.seed = bush_seed ^ 0x73B9
	for mass in range(mass_count):
		var angle := float(mass) * 2.39996 + shape_rng.randf_range(-0.25, 0.25)
		var center := Vector3.ZERO
		var size := Vector3(footprint.x * 0.29, bush_height * 0.32, footprint.y * 0.29)
		if mass == 0:
			center.y = bush_height * 0.60
		else:
			center = Vector3(cos(angle) * footprint.x, 0, sin(angle) * footprint.y) * shape_rng.randf_range(0.23, 0.32)
			center.y = bush_height * shape_rng.randf_range(0.31, 0.48)
			size *= shape_rng.randf_range(0.75, 1.0)
		_grow_mass(center, size, rng, transforms, tints)
	var mesh := LEAF_GEOMETRY.leaf_spray_mesh()
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.use_custom_data = true
	multimesh.mesh = mesh
	multimesh.instance_count = transforms.size()
	var bounds := AABB(Vector3.ZERO, Vector3.ZERO)
	for index in range(transforms.size()):
		multimesh.set_instance_transform(index, transforms[index])
		multimesh.set_instance_custom_data(index, tints[index])
		var instance_bounds: AABB = transforms[index] * mesh.get_aabb()
		bounds = instance_bounds if index == 0 else bounds.merge(instance_bounds)
	# Covers sway, flutter, and bounded player displacement at maximum strengths.
	multimesh.custom_aabb = bounds.grow(1.0)
	var foliage := MultiMeshInstance3D.new()
	foliage.name = "Foliage"
	foliage.multimesh = multimesh
	foliage.material_override = _leaf_material
	_add_generated(foliage)
	var wash := MeshInstance3D.new()
	wash.name = "GroundPigment"
	var plane := PlaneMesh.new()
	plane.size = footprint * 1.25
	var wash_material := _material(WASH_SHADER)
	wash_material.set_shader_parameter("patch_size", footprint)
	wash_material.set_shader_parameter("shape_phase", float(posmod(bush_seed, 1000)) * 0.173)
	plane.material = wash_material
	wash.mesh = plane
	wash.position.y = 0.010
	# Empty density produces a fully empty component, including its pigment wash.
	wash.visible = not transforms.is_empty()
	_add_generated(wash)
	set_process(not Engine.is_editor_hint() and react_to_explorers)

func _grow_mass(center: Vector3, radii: Vector3, rng: RandomNumberGenerator, transforms: Array[Transform3D], tints: Array[Color]) -> void:
	for clump in range(8):
		var azimuth := float(clump) * 2.39996 + rng.randf_range(-0.2, 0.2)
		var elevation := rng.randf_range(-0.65, 0.95)
		var radial := sqrt(1.0 - elevation * elevation)
		var outward := Vector3(radial * cos(azimuth), elevation, radial * sin(azimuth))
		var origin := center + outward * radii * rng.randf_range(0.4, 0.7)
		var light := 0.26 + origin.y / bush_height * 0.43 + outward.dot(SUN_DIRECTION) * 0.12
		var count := sprays_per_mass / 8 + (1 if clump < sprays_per_mass % 8 else 0)
		for leaf in range(count):
			var y := rng.randf_range(-1.0, 1.0)
			var phi := rng.randf() * TAU
			var r := sqrt(1.0 - y * y)
			var direction := Vector3(r * cos(phi), y, r * sin(phi))
			var position := origin + direction * radii * pow(rng.randf(), 0.33333) * 0.40
			position.y = maxf(position.y, 0.045)
			var normal := (Vector3.UP * 0.75 + outward * 0.5 + direction * 0.25).normalized()
			var side := normal.cross(Vector3.FORWARD).normalized()
			if side.length_squared() < 0.1:
				side = normal.cross(Vector3.RIGHT).normalized()
			var forward := side.cross(normal).normalized()
			var basis := Basis(side, normal, forward) * Basis(Vector3.UP, rng.randf() * TAU)
			var leaf_size := rng.randf_range(0.105, 0.17) * sqrt(footprint.x * footprint.y / (1.65 * 1.3))
			basis = basis.scaled(Vector3.ONE * leaf_size)
			transforms.append(Transform3D(basis, position))
			tints.append(Color(clampf(light + rng.randf_range(-0.035, 0.035), 0.02, 0.95), rng.randf(), rng.randf(), clampf(position.y / bush_height, 0.0, 1.0)))

func _add_generated(node: GeometryInstance3D) -> void:
	node.set_meta(&"generated_bush", true)
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	node.visibility_range_end = visibility_distance
	add_child(node, false, Node.INTERNAL_MODE_BACK)

func _update_disturbance_settings() -> void:
	if _leaf_material:
		_leaf_material.set_shader_parameter("disturbance_strength", disturbance_strength)
		_leaf_material.set_shader_parameter("disturbance_radius", disturbance_radius)

func _send_disturbance() -> void:
	if not _leaf_material:
		return
	var data := PackedVector4Array()
	for index in range(2):
		var p := _source_positions[index]
		data.append(Vector4(p.x, p.y, p.z, _source_weights[index]))
	_leaf_material.set_shader_parameter("disturbance_sources", data)

func _process(delta: float) -> void:
	_scan_timer -= delta
	if _scan_timer <= 0.0:
		_scan_timer = 0.25
		# Preserve source slots so join/leave events never exchange player positions.
		var explorers := get_tree().get_nodes_in_group("explorers")
		for index in range(2):
			if not is_instance_valid(_sources[index]) or not _sources[index] in explorers:
				_sources[index] = null
		for explorer in explorers:
			if explorer is Node3D and not explorer in _sources:
				var empty_slot := _sources.find(null)
				if empty_slot == -1:
					break
				_sources[empty_slot] = explorer
				_source_weights[empty_slot] = 0.0
	_update_disturbance(delta)

func _update_disturbance(delta: float) -> void:
	for index in range(2):
		if react_to_explorers and is_instance_valid(_sources[index]):
			var target := _sources[index].get_global_transform_interpolated().origin
			# Reset after teleports instead of dragging the interaction across scenery.
			if _source_weights[index] < 0.001 or _source_positions[index].distance_squared_to(target) > 16.0:
				_source_positions[index] = target
				_source_weights[index] = 0.0
			else:
				_source_positions[index] = _source_positions[index].lerp(target, 1.0 - exp(-10.0 * delta))
			_source_weights[index] = lerpf(_source_weights[index], 1.0, 1.0 - exp(-10.0 * delta))
		else:
			# Removed players leave a short, smooth release rather than a snap.
			_source_weights[index] = lerpf(_source_weights[index], 0.0, 1.0 - exp(-6.0 * delta))
	_send_disturbance()
