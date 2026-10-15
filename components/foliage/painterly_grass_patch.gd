@tool
class_name PainterlyGrassPatch
extends Node3D
## Seeded, editor-previewable meadow. Three draw surfaces regardless of density.
## Generated children are internal: scenes save parameters, not thousands of nodes.

const FOLIAGE_SHADER = preload("res://components/foliage/shaders/foliage.gdshader")
const WASH_SHADER = preload("res://components/foliage/shaders/ground_wash.gdshader")
const DEFAULT_PALETTE = preload("res://components/foliage/palettes/meadow.tres")

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
@export var patch_size := Vector2(7.0, 5.0):
	set(value):
		patch_size = Vector2(maxf(value.x, 0.5), maxf(value.y, 0.5))
		_request_rebuild()
@export var patch_seed: int = 27:
	set(value):
		patch_seed = value
		_request_rebuild()
@export_range(0.0, 100.0, 1.0) var tufts_per_square_meter: float = 16.0:
	set(value):
		tufts_per_square_meter = value
		_request_rebuild()
@export_range(0.0, 80.0, 1.0) var leaves_per_square_meter: float = 66.0:
	set(value):
		leaves_per_square_meter = value
		_request_rebuild()
@export_range(0.1, 1.0, 0.01) var grass_height: float = 0.36:
	set(value):
		grass_height = value
		_request_rebuild()
@export_range(0.0, 0.3, 0.01) var wind_strength: float = 0.07:
	set(value):
		wind_strength = value
		_update_wind()
@export_range(0.0, 3.0, 0.05) var wind_speed: float = 0.8:
	set(value):
		wind_speed = value
		_update_wind()
@export var react_to_explorer: bool = true:
	set(value):
		react_to_explorer = value
		if is_inside_tree():
			set_process(not Engine.is_editor_hint() and value)
		if not value and _foliage_material:
			_foliage_material.set_shader_parameter("explorer_position", Vector3(0, -1000, 0))
@export_range(10.0, 150.0, 1.0) var visibility_distance: float = 45.0:
	set(value):
		visibility_distance = value
		_request_rebuild()
@export_tool_button("Regenerate patch") var regenerate = rebuild

static var _shared_tuft: ArrayMesh
static var _shared_leaves: ArrayMesh

var _applying_preset: bool = false
var _palette_materials: Array[ShaderMaterial] = []
var _queued: bool = false
var _foliage_material: ShaderMaterial
var _explorer: Node3D
var _smoothed_explorer_position := Vector3.ZERO
var _interaction_initialized: bool = false

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
	if not is_inside_tree() or _queued:
		return
	_queued = true
	call_deferred("rebuild")

func rebuild() -> void:
	_queued = false
	if not is_inside_tree():
		return
	_palette_materials.clear()
	for child in get_children(true):
		if child.get_meta(&"generated_grass", false):
			remove_child(child)
			child.queue_free()
	var active_palette: GrassPalette = palette if palette else DEFAULT_PALETTE
	_foliage_material = _make_material(FOLIAGE_SHADER, active_palette)
	_update_wind()
	var wash_material := _make_material(WASH_SHADER, active_palette)
	wash_material.set_shader_parameter("shape_phase", _phase())
	wash_material.set_shader_parameter("patch_size", patch_size)
	# Low transparent pigment wash only; all of the standing foliage is opaque.
	var wash := MeshInstance3D.new()
	wash.name = "GroundPigment"
	var plane := PlaneMesh.new()
	plane.size = patch_size * 1.25
	plane.material = wash_material
	wash.mesh = plane
	wash.position.y = 0.008
	_add_generated(wash)
	var rng := RandomNumberGenerator.new()
	rng.seed = patch_seed
	_add_batch("GrassTufts", _make_tuft(), tufts_per_square_meter, rng, false)
	_add_batch("PaintedLeaves", _make_leaves(), leaves_per_square_meter, rng, true)
	set_process(not Engine.is_editor_hint() and react_to_explorer)

func _make_material(shader: Shader, colors: GrassPalette) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = shader
	for key in [&"root_color", &"shade_color", &"leaf_color", &"sun_color"]:
		material.set_shader_parameter(key, colors.get(key))
	_palette_materials.append(material)
	return material

func _update_wind() -> void:
	if _foliage_material:
		_foliage_material.set_shader_parameter("wind_strength", wind_strength)
		_foliage_material.set_shader_parameter("wind_speed", wind_speed)

func _phase() -> float:
	return float(posmod(patch_seed, 1000)) * 0.173

func _radius(point: Vector2) -> float:
	var q := point / (patch_size * 0.5)
	var angle := atan2(q.y, q.x)
	var boundary := 1.0 + 0.07 * sin(angle * 5.0 + _phase()) + 0.045 * sin(angle * 9.0 - _phase())
	return q.length() / boundary

func _add_generated(node: GeometryInstance3D) -> void:
	node.set_meta(&"generated_grass", true)
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	node.visibility_range_end = visibility_distance
	add_child(node, false, Node.INTERNAL_MODE_BACK)

func _add_batch(batch_name: String, mesh: ArrayMesh, density: float, rng: RandomNumberGenerator, is_leaf: bool) -> void:
	var transforms: Array[Transform3D] = []
	var colors: Array[Color] = []
	# A strict cap keeps accidental Inspector edits from exhausting mobile memory.
	var candidates := mini(int(patch_size.x * patch_size.y * maxf(density, 0.0) * 1.35), 12000)
	for index in range(candidates):
		var point := Vector2(rng.randf_range(-0.55, 0.55) * patch_size.x, rng.randf_range(-0.55, 0.55) * patch_size.y)
		var radius := _radius(point)
		var edge := 1.0 - smoothstep(0.68, 1.04, radius)
		var meadow := clampf(sin(point.x * 0.9 + _phase()) * cos(point.y * 1.1 - _phase()) * 0.3 + 0.5 - point.y / patch_size.y * 0.45, 0.0, 1.0)
		var clump := 0.62 + 0.38 * sin(point.x * 3.2 + sin(point.y * 2.6)) * sin(point.y * 3.5)
		if rng.randf() > edge * clump:
			continue
		var scale_factor := rng.randf_range(0.65, 1.25) * lerpf(0.28, 1.0, edge)
		var basis := Basis(Vector3.UP, rng.randf() * TAU)
		var height := grass_height * rng.randf_range(0.65, 1.35)
		if is_leaf:
			basis = basis.scaled(Vector3.ONE * scale_factor * lerpf(0.7, 1.2, meadow))
		else:
			basis = basis.scaled(Vector3(scale_factor, height * scale_factor, scale_factor))
		transforms.append(Transform3D(basis, Vector3(point.x, 0.012, point.y)))
		colors.append(Color(clampf((meadow - 0.5) * 1.8 + 0.5 + rng.randf_range(-0.12, 0.12), 0.0, 1.0), rng.randf(), rng.randf(), edge))
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.use_custom_data = true
	multimesh.mesh = mesh
	multimesh.instance_count = transforms.size()
	for index in range(transforms.size()):
		multimesh.set_instance_transform(index, transforms[index])
		multimesh.set_instance_custom_data(index, colors[index])
	# Include animated tips, wind and player bending in the culling bounds.
	multimesh.custom_aabb = AABB(Vector3(-patch_size.x * 0.6 - 0.6, -0.3, -patch_size.y * 0.6 - 0.6), Vector3(patch_size.x * 1.2 + 1.2, grass_height * 2.0 + 0.8, patch_size.y * 1.2 + 1.2))
	var batch := MultiMeshInstance3D.new()
	batch.name = batch_name
	batch.multimesh = multimesh
	batch.material_override = _foliage_material
	_add_generated(batch)

func _make_tuft() -> ArrayMesh:
	if _shared_tuft:
		return _shared_tuft
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	# Three bent brushstroke ribbons with gently rounded ends.
	for blade in range(3):
		var angle := float(blade) * 2.399
		var side := Vector3(cos(angle), 0.0, sin(angle))
		var lean := Vector3(-sin(angle), 0.0, cos(angle))
		var blade_height := 1.0 - float(blade) * 0.15
		for segment in range(6):
			var t0 := float(segment) / 6.0
			var t1 := float(segment + 1) / 6.0
			var center0 := Vector3.UP * t0 * blade_height + lean * (t0 * t0 * 0.24)
			var center1 := Vector3.UP * t1 * blade_height + lean * (t1 * t1 * 0.24)
			var width0 := sin(t0 * PI * 0.88 + 0.25) * 0.075
			var width1 := sin(t1 * PI * 0.88 + 0.25) * 0.075
			if segment == 5:
				width1 = 0.012
			_quad(surface, center0 - side * width0, center0 + side * width0, center1 + side * width1, center1 - side * width1, t0, t1, Color(1, 1, 1))
	_shared_tuft = surface.commit()
	return _shared_tuft

func _make_leaves() -> ArrayMesh:
	if _shared_leaves:
		return _shared_leaves
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	# Three small, faceted oval dabs: dimensional groundcover, not billboards.
	for leaf in range(3):
		var angle := float(leaf) * TAU / 3.0
		var forward := Vector3(cos(angle), 0.0, sin(angle))
		var side := Vector3(-sin(angle), 0.0, cos(angle))
		var center := forward * 0.16 + Vector3.UP * (0.06 + leaf * 0.025)
		for segment in range(10):
			var a0 := float(segment) * TAU / 10.0
			var a1 := float(segment + 1) * TAU / 10.0
			var p0 := center + forward * cos(a0) * 0.22 + side * sin(a0) * 0.15
			var p1 := center + forward * cos(a1) * 0.22 + side * sin(a1) * 0.15
			p0.y += cos(a0) * 0.035
			p1.y += cos(a1) * 0.035
			var paint := Color(1.0, 1.0, 1.0) if segment < 5 else Color(0.97, 0.985, 0.96)
			_vertex(surface, center, Vector2(0.5, 0.90), paint)
			_vertex(surface, p0, Vector2(0.0, 0.90), paint)
			_vertex(surface, p1, Vector2(1.0, 0.90), paint)
	_shared_leaves = surface.commit()
	return _shared_leaves

func _quad(surface: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, bottom: float, top: float, color: Color) -> void:
	_vertex(surface, a, Vector2(0, bottom), color)
	_vertex(surface, b, Vector2(1, bottom), color)
	_vertex(surface, c, Vector2(1, top), color)
	_vertex(surface, a, Vector2(0, bottom), color)
	_vertex(surface, c, Vector2(1, top), color)
	_vertex(surface, d, Vector2(0, top), color)

func _vertex(surface: SurfaceTool, position: Vector3, uv: Vector2, color: Color) -> void:
	surface.set_normal(Vector3.UP)
	surface.set_uv(uv)
	surface.set_color(color)
	surface.add_vertex(position)

func _process(delta: float) -> void:
	if not is_instance_valid(_explorer):
		_explorer = get_tree().get_first_node_in_group("explorers") as Node3D
	var position_to_send := Vector3(0, -1000, 0)
	if react_to_explorer and is_instance_valid(_explorer):
		# Match the displayed character between fixed physics ticks.
		var target := _explorer.get_global_transform_interpolated().origin
		# Initialize at the player, and reset after teleports instead of sweeping
		# the bend across the meadow. Normal movement follows continuously.
		if not _interaction_initialized or _smoothed_explorer_position.distance_squared_to(target) > 16.0:
			_smoothed_explorer_position = target
			_interaction_initialized = true
		else:
			_smoothed_explorer_position = _smoothed_explorer_position.lerp(target, 1.0 - exp(-10.0 * delta))
		position_to_send = _smoothed_explorer_position
	else:
		_interaction_initialized = false
	_foliage_material.set_shader_parameter("explorer_position", position_to_send)
