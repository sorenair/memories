@tool
class_name PainterlyWallVine
extends Node3D
## Local XY is the wall; local +Z faces away from it. Origin is the growth root.
const LEAVES = preload("res://components/foliage/shared/leaf_geometry.gd")
const LEAF_SHADER = preload("res://components/foliage/shaders/tree_canopy.gdshader")
const STEM_SHADER = preload("res://components/foliage/shaders/tree_bark.gdshader")
const PALETTES = preload("res://components/foliage/shared/foliage_palettes.gd")
const DEFAULT_PALETTE = preload("res://components/foliage/palettes/meadow.tres")
@export var vine_seed: int = 83:
	set(value):
		vine_seed = value
		_request_rebuild()
## Width and vertical reach. In hanging mode the reach extends below the origin.
@export var footprint := Vector2(2.6, 2.2):
	set(value):
		footprint = value.clamp(Vector2(0.3, 0.3), Vector2(15, 15))
		_request_rebuild()
@export_enum("Climbing", "Hanging") var growth_mode: int = 0:
	set(value):
		growth_mode = clampi(value, 0, 1)
		_request_rebuild()
@export_range(2, 10, 1) var branch_count: int = 5:
	set(value):
		branch_count = clampi(value, 2, 10)
		_request_rebuild()
@export_range(0, 1600, 1) var leaf_spray_count: int = 240:
	set(value):
		leaf_spray_count = clampi(value, 0, 1600)
		_request_rebuild()
@export_range(0.07, 0.35, 0.005) var leaf_size: float = 0.16:
	set(value):
		leaf_size = value
		_request_rebuild()
@export_range(0.05, 0.6, 0.01) var coverage_spread: float = 0.23:
	set(value):
		coverage_spread = value
		_request_rebuild()
@export_range(0.005, 0.04, 0.001) var stem_radius: float = 0.014:
	set(value):
		stem_radius = value
		_request_rebuild()
## Positive stand-off from the wall; leave room for the small amount of depth / wind.
@export_range(0.02, 0.5, 0.01) var surface_offset: float = 0.12:
	set(value):
		surface_offset = value
		_request_rebuild()
@export_group("Foliage Colors")
@export_enum("Custom", "Summer Meadow", "Spring", "Autumn Gold", "Autumn Red", "Winter Frost", "Dream Lavender", "Dream Blue", "Dream Rose", "Dusk") var palette_preset: int = 1:
	set(value):
		palette_preset = clampi(value, 0, 9)
		if palette_preset > 0:
			_applying_preset = true
			palette = PALETTES.create_preset(palette_preset)
			_applying_preset = false
@export var palette: GrassPalette = DEFAULT_PALETTE:
	set(value):
		if palette and palette.changed.is_connected(_apply_palette):
			palette.changed.disconnect(_apply_palette)
		palette = value
		if palette and not palette.changed.is_connected(_apply_palette):
			palette.changed.connect(_apply_palette)
		if not _applying_preset and not _matches_selected_preset(palette):
			palette_preset = 0
		_apply_palette()
@export_group("Motion")
@export_range(0.0, 0.12, 0.005) var wind_strength: float = 0.025:
	set(value):
		wind_strength = value
		_apply_motion()
@export_range(0.0, 3.0, 0.05) var wind_speed: float = 0.8:
	set(value):
		wind_speed = value
		_apply_motion()
@export var react_to_explorers: bool = true
@export_range(0.0, 0.25, 0.005) var disturbance_strength: float = 0.07:
	set(value):
		disturbance_strength = value
		_apply_motion()
@export_range(10.0, 100.0, 1.0) var visibility_distance: float = 45.0:
	set(value):
		visibility_distance = value
		_request_rebuild()
@export_tool_button("Regenerate vine") var regenerate = rebuild
var _queued: bool = false
var _applying_preset: bool = false
var _leaf_material: ShaderMaterial
var _stem_material: ShaderMaterial
var _generated: Array[Node] = []
var _positions: Array[Vector3] = [Vector3.ZERO, Vector3.ZERO]
var _weights := PackedFloat32Array([0.0, 0.0])

func _matches_selected_preset(colors: GrassPalette) -> bool:
	# Godot saves the selected preset and its generated resource. Loading that
	# matching resource should preserve the Inspector selection rather than reset it.
	if not colors or palette_preset <= 0:
		return false
	var selected: GrassPalette = PALETTES.create_preset(palette_preset)
	for key in PALETTES.COLOR_KEYS:
		var actual: Color = colors.get(key)
		var expected: Color = selected.get(key)
		if not actual.is_equal_approx(expected):
			return false
	return true

func _ready() -> void:
	if palette and not palette.changed.is_connected(_apply_palette):
		palette.changed.connect(_apply_palette)
	rebuild()
	set_process(not Engine.is_editor_hint())

func _request_rebuild() -> void:
	if is_inside_tree() and not _queued:
		_queued = true
		call_deferred("rebuild")

func _apply_palette() -> void:
	var colors: GrassPalette = palette if palette else DEFAULT_PALETTE
	PALETTES.apply(_leaf_material, colors)
	if _stem_material:
		_stem_material.set_shader_parameter("root_color", colors.root_color)
		_stem_material.set_shader_parameter("bark_shadow", colors.root_color.lerp(colors.shade_color, 0.4))
		_stem_material.set_shader_parameter("bark_light", colors.shade_color.lerp(colors.leaf_color, 0.45))

func _apply_motion() -> void:
	if _leaf_material:
		_leaf_material.set_shader_parameter("wind_strength", wind_strength)
		_leaf_material.set_shader_parameter("wind_speed", wind_speed)
		_leaf_material.set_shader_parameter("disturbance_strength", disturbance_strength)
		_leaf_material.set_shader_parameter("disturbance_radius", 0.9)

func rebuild() -> void:
	_queued = false
	if not is_inside_tree():
		return
	for node in _generated:
		if is_instance_valid(node):
			remove_child(node)
			node.free()
	_generated.clear()
	_leaf_material = ShaderMaterial.new()
	_leaf_material.shader = LEAF_SHADER
	_leaf_material.set_shader_parameter("tree_phase", float(posmod(vine_seed, 1000)) * 0.173)
	_stem_material = ShaderMaterial.new()
	_stem_material.shader = STEM_SHADER
	_apply_palette()
	_apply_motion()
	var shape_rng := RandomNumberGenerator.new()
	shape_rng.seed = vine_seed
	var paths: Array[PackedVector3Array] = []
	var stems := SurfaceTool.new()
	stems.begin(Mesh.PRIMITIVE_TRIANGLES)
	var vertical := 1.0 if growth_mode == 0 else -1.0
	for branch in range(branch_count):
		var start := Vector3(shape_rng.randf_range(-0.14, 0.14) * footprint.x, 0, surface_offset * 0.35)
		var reach := shape_rng.randf_range(0.70, 1.0)
		var end := Vector3(lerpf(-0.43, 0.43, float(branch) / float(branch_count - 1)) * footprint.x, vertical * footprint.y * reach, surface_offset * 0.35)
		var a := start.lerp(end, 0.3) + Vector3(shape_rng.randf_range(-0.2, 0.2) * footprint.x, 0, 0)
		var b := start.lerp(end, 0.7) + Vector3(shape_rng.randf_range(-0.17, 0.17) * footprint.x, 0, 0)
		var path := PackedVector3Array()
		for step in range(13):
			var t := float(step) / 12.0
			var u := 1.0 - t
			path.append(start * u * u * u + a * 3.0 * u * u * t + b * 3.0 * u * t * t + end * t * t * t)
		paths.append(path)
		_stem(stems, path)
	var stem_node := MeshInstance3D.new()
	stem_node.name = "Stems"
	stem_node.mesh = stems.commit()
	stem_node.material_override = _stem_material
	stem_node.visible = leaf_spray_count > 0
	_add_generated(stem_node)
	var rng := RandomNumberGenerator.new()
	rng.seed = vine_seed ^ 0x1EA5
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.use_custom_data = true
	multimesh.mesh = LEAVES.leaf_spray_mesh()
	multimesh.instance_count = leaf_spray_count
	var bounds := AABB()
	for index in range(leaf_spray_count):
		var path_index := index % branch_count
		# Leaves share small overlapping islands rather than uniform surface scatter.
		var island := (index / branch_count) % 8
		var progress := clampf(0.08 + float(island) / 7.0 * 0.9 + rng.randf_range(-0.04, 0.04), 0, 1)
		var path := paths[path_index]
		var segment := minf(progress * 12.0, 11.999)
		var point := path[int(segment)].lerp(path[int(segment) + 1], fposmod(segment, 1.0))
		var theta := rng.randf() * TAU
		var spread := sqrt(rng.randf()) * coverage_spread * (0.55 + sin(progress * PI) * 0.45)
		point += Vector3(cos(theta) * spread, sin(theta) * spread * 0.75, surface_offset * 0.65 + rng.randf_range(0.0, 0.06))
		var size := leaf_size * rng.randf_range(0.75, 1.25) * lerpf(1.0, 0.65, progress * progress)
		var basis := (Basis(Vector3.BACK, rng.randf_range(-PI, PI)) * Basis(Vector3.RIGHT, PI * 0.5)).scaled(Vector3(size, size * rng.randf_range(0.8, 1.1), size))
		var transform := Transform3D(basis, point)
		multimesh.set_instance_transform(index, transform)
		var tint := 0.32 + progress * 0.34 + sin(float(island) * 2.4 + path_index) * 0.10 + rng.randf_range(-0.025, 0.025)
		multimesh.set_instance_custom_data(index, Color(clampf(tint, 0.05, 0.95), rng.randf(), rng.randf(), 0.35 + progress * 0.65))
		var instance_bounds: AABB = transform * multimesh.mesh.get_aabb()
		bounds = instance_bounds if index == 0 else bounds.merge(instance_bounds)
	multimesh.custom_aabb = bounds.grow(0.7)
	var leaves := MultiMeshInstance3D.new()
	leaves.name = "Foliage"
	leaves.multimesh = multimesh
	leaves.material_override = _leaf_material
	_add_generated(leaves)

func _add_generated(node: GeometryInstance3D) -> void:
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	node.visibility_range_end = visibility_distance
	add_child(node, false, Node.INTERNAL_MODE_BACK)
	_generated.append(node)

func _stem(surface: SurfaceTool, path: PackedVector3Array) -> void:
	var rings: Array[PackedVector3Array] = []
	var normals: Array[PackedVector3Array] = []
	for index in range(path.size()):
		var direction := (path[mini(index + 1, path.size() - 1)] - path[maxi(index - 1, 0)]).normalized()
		var side := direction.cross(Vector3.BACK).normalized()
		var up := direction.cross(side).normalized()
		var ring := PackedVector3Array()
		var normal_ring := PackedVector3Array()
		var radius := stem_radius * lerpf(1.0, 0.2, float(index) / float(path.size() - 1))
		for segment in range(6):
			var angle := float(segment) * TAU / 6.0
			var normal := side * cos(angle) + up * sin(angle)
			ring.append(path[index] + normal * radius)
			normal_ring.append(normal)
		rings.append(ring)
		normals.append(normal_ring)
	for index in range(path.size() - 1):
		for segment in range(6):
			var next := (segment + 1) % 6
			for pair in [Vector2i(index, segment), Vector2i(index + 1, segment), Vector2i(index + 1, next), Vector2i(index, segment), Vector2i(index + 1, next), Vector2i(index, next)]:
				var normal := normals[pair.x][pair.y]
				surface.set_normal(normal)
				surface.set_color(Color(normal.dot(Vector3(-0.45, 0.82, -0.35)) * 0.38 + 0.5, 0.5, 1))
				surface.add_vertex(rings[pair.x][pair.y])

func _process(delta: float) -> void:
	if not _leaf_material:
		return
	var explorers: Array = get_tree().get_nodes_in_group(&"explorers") if react_to_explorers else []
	var sources := PackedVector4Array()
	for index in range(2):
		var valid: bool = index < explorers.size() and explorers[index].get_viewport() == get_viewport()
		var was_absent := _weights[index] < 0.001
		_weights[index] = lerpf(_weights[index], 1.0 if valid else 0.0, 1.0 - exp(-delta * 8.0))
		if valid:
			var target: Vector3 = explorers[index].global_position
			_positions[index] = target if was_absent else _positions[index].lerp(target, 1.0 - exp(-delta * 12.0))
		sources.append(Vector4(_positions[index].x, _positions[index].y, _positions[index].z, _weights[index]))
	_leaf_material.set_shader_parameter("disturbance_sources", sources)
