@tool
class_name PainterlyFlowerPatch
extends Node3D
## Clustered, opaque flower geometry in one instanced batch. Origin is ground level.
const PALETTES = preload("res://components/foliage/shared/foliage_palettes.gd")
const FLOWER_SHADER = preload("res://components/foliage/flowers/painted_flowers.gdshader")
const BLOOMS = [
	[Color("fff4ce"), Color("f5d980")],
	[Color("f6a9bd"), Color("fff0df")],
	[Color("bcb1ec"), Color("f2e4ff")],
	[Color("f4c65c"), Color("f5a886")],
	[Color("a9c9ed"), Color("e6efff")]
]
@export var patch_seed: int = 51:
	set(value):
		patch_seed = value
		_request_rebuild()
@export var footprint := Vector2(2.4, 1.8):
	set(value):
		footprint = value.clamp(Vector2(0.3, 0.3), Vector2(20, 20))
		_request_rebuild()
@export_range(0, 600, 1) var flower_count: int = 40:
	set(value):
		flower_count = clampi(value, 0, 600)
		_request_rebuild()
@export_range(0.0, 0.8, 0.005) var crown_height: float = 0.16:
	set(value):
		crown_height = value
		_request_rebuild()
@export_range(0.025, 0.25, 0.005) var bloom_radius: float = 0.06:
	set(value):
		bloom_radius = value
		_request_rebuild()
## Crown scale varies independently of its height above the grass.
@export var scale_range := Vector2(0.8, 1.5):
	set(value):
		var limits := value.clamp(Vector2(0.1, 0.1), Vector2(3.0, 3.0))
		scale_range = Vector2(minf(limits.x, limits.y), maxf(limits.x, limits.y))
		_request_rebuild()
@export_range(5, 8, 1) var petal_count: int = 5:
	set(value):
		petal_count = clampi(value, 5, 8)
		_request_rebuild()
@export_group("Colors")
@export_enum("Cream and Buttercup", "Wild Rose", "Lavender", "Sunset", "Forget-me-not", "Custom") var bloom_palette: int = 0:
	set(value):
		bloom_palette = clampi(value, 0, 5)
		_apply_colors()
@export var bloom_color_a := Color("fff0dc"):
	set(value):
		bloom_color_a = value
		_apply_colors()
@export var bloom_color_b := Color("f6afbf"):
	set(value):
		bloom_color_b = value
		_apply_colors()
## Lower values borrow more meadow pigment for quiet, blended accents.
@export_range(0.0, 1.0, 0.05) var bloom_contrast: float = 0.45:
	set(value):
		bloom_contrast = value
		_apply_colors()
@export var center_color := Color("eec45d"):
	set(value):
		center_color = value
		_apply_colors()
@export_enum("Summer Meadow", "Spring", "Autumn Gold", "Autumn Red", "Winter Frost", "Dream Lavender", "Dream Blue", "Dream Rose", "Dusk") var foliage_palette: int = 0:
	set(value):
		foliage_palette = clampi(value, 0, 8)
		_apply_colors()
@export_group("Motion")
@export_range(0.0, 0.2, 0.005) var wind_strength: float = 0.025:
	set(value):
		wind_strength = value
		_apply_motion()
@export_range(0.0, 3.0, 0.05) var wind_speed: float = 0.8:
	set(value):
		wind_speed = value
		_apply_motion()
@export var react_to_explorers: bool = true
@export_group("Placement")
## Regions exposing excludes_ground_point(), e.g. water, are left empty.
@export var ground_exclusions: Array[NodePath] = []:
	set(value):
		ground_exclusions = value
		_request_rebuild()
@export_range(10.0, 100.0, 1.0) var visibility_distance: float = 45.0:
	set(value):
		visibility_distance = value
		_request_rebuild()
@export_tool_button("Regenerate flowers") var regenerate = rebuild
var _queued: bool = false
var _regions: Array[Node] = []
var _material: ShaderMaterial
var _batch: MultiMeshInstance3D
var _player_positions: Array[Vector3] = [Vector3.ZERO, Vector3.ZERO]
var _weights := PackedFloat32Array([0.0, 0.0])


const RECALL = preload("res://components/effects/recall/component_recall.gd")
@export_group("Recall")
@export var recall_enabled: bool = false:
	set(value):
		recall_enabled = value
		if is_node_ready() and not Engine.is_editor_hint(): _sync_recall()
var _recall: Node
func get_recall_controller() -> Node:
	return _recall
func _sync_recall() -> void:
	_recall = RECALL.configure(self, "res://components/effects/recall/assembled_recall.gd", _recall)
	if not recall_enabled and not Engine.is_editor_hint():
		preload("res://components/effects/recall/assembled_recall.gd").restore_component(self)

func _ready() -> void:
	set_notify_transform(true)
	rebuild()
	set_process(not Engine.is_editor_hint())

func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSFORM_CHANGED and not ground_exclusions.is_empty():
		_request_rebuild()

func _request_rebuild() -> void:
	if is_inside_tree() and not _queued:
		_queued = true
		call_deferred("rebuild")

func _apply_colors() -> void:
	if not _material:
		return
	PALETTES.apply(_material, PALETTES.create_preset(foliage_palette + 1))
	var colors: Array = BLOOMS[bloom_palette] if bloom_palette < 5 else [bloom_color_a, bloom_color_b]
	_material.set_shader_parameter("bloom_a", colors[0])
	_material.set_shader_parameter("bloom_b", colors[1])
	_material.set_shader_parameter("center_color", center_color)
	_material.set_shader_parameter("bloom_contrast", bloom_contrast)

func _apply_motion() -> void:
	if _material:
		_material.set_shader_parameter("wind_strength", wind_strength)
		_material.set_shader_parameter("wind_speed", wind_speed)

func rebuild() -> void:
	_queued = false
	if not is_inside_tree():
		return
	if is_instance_valid(_batch):
		remove_child(_batch)
		_batch.free()
	_material = ShaderMaterial.new()
	_material.shader = FLOWER_SHADER
	_apply_colors()
	_apply_motion()
	var rng := RandomNumberGenerator.new()
	rng.seed = patch_seed
	var positions: Array[Transform3D] = []
	var colors: Array[Color] = []
	var anchors: Array[Vector2] = []
	for index in range(5):
		var angle := rng.randf() * TAU
		anchors.append(Vector2(cos(angle), sin(angle)) * sqrt(rng.randf()) * 0.75)
	for region in _regions:
		if is_instance_valid(region) and region.has_signal("ground_exclusion_changed") and region.is_connected("ground_exclusion_changed", _request_rebuild):
			region.disconnect("ground_exclusion_changed", _request_rebuild)
	_regions.clear()
	var exclusions: Array[Node] = []
	for path in ground_exclusions:
		var region := get_node_or_null(path)
		if region and region.has_method("excludes_ground_point"):
			exclusions.append(region)
			_regions.append(region)
			if region.has_signal("ground_exclusion_changed") and not region.is_connected("ground_exclusion_changed", _request_rebuild):
				region.connect("ground_exclusion_changed", _request_rebuild)
	for index in range(flower_count):
		var anchor_index := rng.randi_range(0, anchors.size() - 1)
		var angle := rng.randf() * TAU
		var scatter := sqrt(rng.randf()) * 0.45
		var p := anchors[anchor_index] + Vector2(cos(angle), sin(angle)) * scatter
		p = p.limit_length(0.97) * footprint * 0.5
		var point := Vector3(p.x, 0.0, p.y)
		var excluded := false
		for region in exclusions:
			if region.excludes_ground_point(to_global(point)):
				excluded = true
				break
		var scale_y := rng.randf_range(0.68, 1.15)
		var scale_x := lerpf(scale_range.x, scale_range.y, pow(rng.randf(), 1.5))
		var basis := Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3(scale_x, scale_y, scale_x))
		var tint := clampf(float(anchor_index) / 4.0 * 0.8 + rng.randf_range(-0.1, 0.2), 0.0, 1.0)
		var phase := rng.randf()
		point.y = crown_height * lerpf(0.90, 1.10, phase)
		if excluded:
			continue
		positions.append(Transform3D(basis, point))
		colors.append(Color(tint, rng.randf(), phase, scale_y))
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.use_custom_data = true
	multimesh.mesh = _flower_mesh()
	multimesh.instance_count = positions.size()
	for index in range(positions.size()):
		multimesh.set_instance_transform(index, positions[index])
		multimesh.set_instance_custom_data(index, colors[index])
	_batch = MultiMeshInstance3D.new()
	_batch.name = "Flowers"
	_batch.multimesh = multimesh
	_batch.material_override = _material
	_batch.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_batch.visibility_range_end = visibility_distance
	var reach := bloom_radius * scale_range.y * 1.2 + wind_strength + 0.25
	var top := crown_height * 1.1 + bloom_radius * 0.4 + 0.2
	_batch.custom_aabb = AABB(Vector3(-footprint.x * 0.5 - reach, -0.2, -footprint.y * 0.5 - reach), Vector3(footprint.x + reach * 2, top + 0.2, footprint.y + reach * 2))
	add_child(_batch, false, Node.INTERNAL_MODE_BACK)
	_sync_recall()

func _process(delta: float) -> void:
	if not _material:
		return
	var explorers := RECALL.explorers(self) if react_to_explorers else []
	for index in range(2):
		var valid := index < explorers.size() and explorers[index].get_viewport() == get_viewport()
		var weight := 1.0 if valid else 0.0
		var was_absent := _weights[index] < 0.001
		_weights[index] = lerpf(_weights[index], weight, 1.0 - exp(-delta * 8.0))
		if valid:
			var target: Vector3 = explorers[index].global_position
			_player_positions[index] = target if was_absent else _player_positions[index].lerp(target, 1.0 - exp(-delta * 12.0))
		_material.set_shader_parameter("explorer_" + str(index), Vector4(_player_positions[index].x, _player_positions[index].y, _player_positions[index].z, _weights[index]))

func _triangle(surface: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, category: float, paint: float = 0.5) -> void:
	var normal := (b - a).cross(c - a).normalized()
	for point in [a, b, c]:
		surface.set_normal(normal)
		surface.set_color(Color(category, paint, 0.0, 1.0))
		surface.set_uv(Vector2(paint, 1.0))
		surface.add_vertex(point)

func _flower_mesh() -> ArrayMesh:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var center := Vector3.ZERO
	# Rounded, overlapping petal fans. Broad facets make small painted color planes.
	for petal in range(petal_count):
		var angle := float(petal) * TAU / float(petal_count)
		var out := Vector3(cos(angle), 0, sin(angle))
		var side := Vector3(-sin(angle), 0, cos(angle))
		var base := center + out * bloom_radius * 0.12
		var rim := PackedVector3Array()
		for step in range(7):
			var arc := -PI * 0.5 + float(step) * PI / 6.0
			var along := 0.42 + cos(arc) * 0.6
			var across := sin(arc) * 0.47
			rim.append(center + out * bloom_radius * along + side * bloom_radius * across + Vector3.UP * bloom_radius * (0.08 + along * along * 0.18))
		for step in range(rim.size() - 1):
			_triangle(surface, base, rim[step], rim[step + 1], 0.5, 0.35 + float(step) * 0.09)
	# Small warm center, raised above the petal roots.
	for side in range(10):
		var a := float(side) * TAU / 10.0
		var b := float(side + 1) * TAU / 10.0
		_triangle(surface, center + Vector3.UP * bloom_radius * 0.12, center + Vector3(cos(a) * bloom_radius * 0.20, bloom_radius * 0.08, sin(a) * bloom_radius * 0.20), center + Vector3(cos(b) * bloom_radius * 0.20, bloom_radius * 0.08, sin(b) * bloom_radius * 0.20), 1.0, 0.65)
	return surface.commit()
