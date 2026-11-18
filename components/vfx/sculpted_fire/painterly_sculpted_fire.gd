@tool
class_name PainterlySculptedFire
extends Node3D
## Fused 3D fire, closed lifted wisps, rolling smoke and ember trails.
## Generated geometry is internal; animation runs in the materials.
const FLAME = preload("res://components/vfx/sculpted_fire/sculpted_flame.gdshader")
const FLOW = preload("res://components/vfx/sculpted_fire/flame_flow.res")
const FLAMELET = preload("res://components/vfx/sculpted_fire/flamelet.gdshader")
const SMOKE = preload("res://components/vfx/sculpted_fire/rolling_smoke.gdshader")
const SMOKE_FRAY = preload("res://components/vfx/sculpted_fire/smoke_fray.gdshader")
const SPARK = preload("res://components/vfx/sculpted_fire/lifted_sparks.gdshader")
const GLOW = preload("res://components/vfx/fire/ground_glow.gdshader")
const RECALL = preload("res://components/effects/recall/component_recall.gd")

@export_group("Fire")
## Width at the base and approximate height, in meters.
@export var fire_size := Vector2(1.55, 1.65):
	set(value):
		fire_size = value.max(Vector2(0.1, 0.1))
		_appearance_changed()
## Fills the lower fire without raising a solid sphere into the tongues.
@export_range(0.0, 1.0, 0.01) var body_fullness: float = 0.72:
	set(value):
		body_fullness = clampf(value, 0.0, 1.0)
		_appearance_changed()
@export_range(0.0, 1.0, 0.01) var intensity: float = 1.0:
	set(value):
		intensity = clampf(value, 0.0, 1.0)
		_appearance_changed()
## Zero freezes flames, smoke and sparks together.
@export_range(0.0, 3.0, 0.05) var animation_speed: float = 1.0:
	set(value):
		animation_speed = clampf(value, 0.0, 3.0)
		_appearance_changed()
## Strength of the rolling flow that bends and folds the upper flame.
@export_range(0.0, 1.0, 0.01) var curl_amount: float = 0.8:
	set(value):
		curl_amount = clampf(value, 0.0, 1.0)
		_appearance_changed()
## Local X/Z drift; rotates with the component.
@export var wind := Vector2(0.16, 0.04):
	set(value):
		wind = value.clamp(Vector2(-2, -2), Vector2(2, 2))
		_appearance_changed()
@export var fire_seed: int = 73:
	set(value):
		fire_seed = value
		_request_rebuild()

@export_group("Paint and Glow")
@export var core_color := Color("fff0c0"):
	set(value):
		core_color = value
		_appearance_changed()
@export var flame_color := Color("ff8825"):
	set(value):
		flame_color = value
		_appearance_changed()
@export var edge_color := Color("df3020"):
	set(value):
		edge_color = value
		_appearance_changed()
@export_range(0.0, 1.0, 0.01) var glow_strength: float = 0.55:
	set(value):
		glow_strength = clampf(value, 0.0, 1.0)
		_appearance_changed()

@export_group("Smoke")
## Optical density of the connected plume; zero disables it.
@export_range(0.0, 1.0, 0.01) var smoke_amount: float = 0.65:
	set(value):
		smoke_amount = clampf(value, 0.0, 1.0)
		_appearance_changed()
## Plume rise in meters; its warm base overlaps the top of the fire.
@export_range(0.2, 8.0, 0.1) var smoke_height: float = 2.4:
	set(value):
		smoke_height = clampf(value, 0.2, 8.0)
		_appearance_changed()
@export_range(0.1, 2.0, 0.05) var smoke_spread: float = 0.75:
	set(value):
		smoke_spread = clampf(value, 0.1, 2.0)
		_appearance_changed()
## Strength of the large rolling billows and plume meander.
@export_range(0.0, 1.0, 0.01) var smoke_turbulence: float = 0.7:
	set(value):
		smoke_turbulence = clampf(value, 0.0, 1.0)
		_appearance_changed()
## Clarity of the scalloped edges and broad toon shading; lower softens the plume.
@export_range(0.0, 1.0, 0.01) var smoke_definition: float = 0.8:
	set(value):
		smoke_definition = clampf(value, 0.0, 1.0)
		_appearance_changed()
@export var smoke_color := Color("7b7772"):
	set(value):
		smoke_color = value
		_appearance_changed()

@export_group("Sparks")
@export_range(0.0, 1.0, 0.01) var spark_amount: float = 0.65:
	set(value):
		spark_amount = clampf(value, 0.0, 1.0)
		_appearance_changed()
## Maximum rise from the base, in flame-height multiples.
@export_range(1.0, 4.0, 0.1) var spark_height: float = 2.2:
	set(value):
		spark_height = clampf(value, 1.0, 4.0)
		_appearance_changed()
@export_range(0.01, 0.12, 0.005) var spark_size: float = 0.03:
	set(value):
		spark_size = clampf(value, 0.01, 0.12)
		_appearance_changed()
## Variation in ember size, launch speed and flutter.
@export_range(0.0, 1.0, 0.01) var spark_variation: float = 0.65:
	set(value):
		spark_variation = clampf(value, 0.0, 1.0)
		_appearance_changed()
## Seconds of recent motion behind each ember. Zero leaves just the hot fragments.
@export_range(0.0, 0.18, 0.005) var spark_trail_length: float = 0.035:
	set(value):
		spark_trail_length = clampf(value, 0.0, 0.18)
		_appearance_changed()
## Zero distributes embers evenly; one emits overlapping small packets.
@export_range(0.0, 1.0, 0.01) var spark_burstiness: float = 0.35:
	set(value):
		spark_burstiness = clampf(value, 0.0, 1.0)
		_appearance_changed()

@export_group("Recall")
@export var recall_anchor: Node3D
@export var recall_enabled: bool = false:
	set(value):
		recall_enabled = value
		if is_node_ready() and not Engine.is_editor_hint(): _sync_recall()
@export_tool_button("Regenerate fire") var regenerate = rebuild

static var _tongue_mesh: ArrayMesh
static var _volume_mesh: BoxMesh
static var _smoke_mesh: BoxMesh
static var _fray_mesh: QuadMesh
static var _spark_mesh: ArrayMesh
var _materials: Array[ShaderMaterial] = []
var _queued := false
var _recall: Node
var _preview_time: float = -1.0
var footprint: Vector2:
	get: return Vector2.ONE * fire_size.x

func _ready() -> void:
	rebuild()

func get_recall_controller() -> Node:
	return _recall

func get_recall_anchor() -> Node3D:
	return recall_anchor

func recall_materials() -> Array[ShaderMaterial]:
	return _materials

func _sync_recall() -> void:
	_recall = RECALL.configure(self, "res://components/effects/recall/fade_recall.gd", _recall)
	if not recall_enabled:
		for material in _materials: material.set_shader_parameter("recall_visibility", 1.0)

## Deterministic material clock for render studies; negative returns to engine time.
func set_preview_time(seconds: float) -> void:
	_preview_time = seconds
	_appearance_changed()

func _request_rebuild() -> void:
	if is_inside_tree() and not _queued:
		_queued = true
		rebuild.call_deferred()

func _appearance_changed() -> void:
	for material in _materials:
		for key in [&"fire_size", &"body_fullness", &"intensity", &"animation_speed", &"curl_amount", &"wind", &"core_color", &"flame_color", &"edge_color", &"smoke_amount", &"smoke_height", &"smoke_spread", &"smoke_turbulence", &"smoke_definition", &"smoke_color", &"spark_amount", &"spark_height", &"spark_size", &"spark_variation", &"spark_trail_length", &"spark_burstiness", &"glow_strength"]:
			material.set_shader_parameter(key, get(key))
		material.set_shader_parameter("fire_phase", float(posmod(fire_seed, 997)) * 0.071)
		material.set_shader_parameter("preview_time", _preview_time)
		# The original ground wash is reused with its own private material.
		material.set_shader_parameter("flame_size", fire_size)
	if not is_inside_tree(): return
	var side := maxf(fire_size.x * 1.8 + smoke_spread + wind.length() * 2.5, smoke_spread * 1.6 + 0.1 + wind.length() * 2.1)
	var bottom := minf(-0.2, fire_size.y * lerpf(0.50, 0.62, body_fullness) - smoke_spread * 0.85)
	var top := maxf(fire_size.y * 2.0, maxf(fire_size.y * 1.1 + smoke_height + smoke_spread * 2.0, fire_size.y * spark_height + spark_size * 5.0))
	for child in get_children(true):
		if not child.get_meta(&"sculpted_fire_generated", false): continue
		child.custom_aabb = AABB(Vector3(-side, bottom, -side), Vector3(side * 2.0, top - bottom + 0.2, side * 2.0))
		child.visible = intensity > 0.0
		if child.name == &"Smoke" or child.name == &"SmokeFray":
			child.visible = intensity > 0.0 and smoke_amount > 0.0
		if child.name == &"Sparks":
			child.visible = intensity > 0.0 and spark_amount > 0.0
			child.multimesh.visible_instance_count = ceili(spark_amount * 64.0)
		if child.name == &"GroundGlow": child.visible = intensity > 0.0 and glow_strength > 0.0

func _material(shader: Shader) -> ShaderMaterial:
	var result := ShaderMaterial.new()
	result.shader = shader
	if shader == FLAME or shader == FLAMELET: result.set_shader_parameter("flow_noise", FLOW)
	_materials.append(result)
	return result

func _generated(node: GeometryInstance3D) -> void:
	node.set_meta(&"sculpted_fire_generated", true)
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(node, false, Node.INTERNAL_MODE_BACK)

func _batch(id: String, mesh: Mesh, count: int, shader: Shader, salt: int) -> MultiMeshInstance3D:
	var instances := MultiMesh.new()
	instances.transform_format = MultiMesh.TRANSFORM_3D
	instances.use_custom_data = true
	instances.mesh = mesh
	instances.instance_count = count
	var rng := RandomNumberGenerator.new()
	rng.seed = fire_seed ^ salt
	for index in count:
		instances.set_instance_transform(index, Transform3D.IDENTITY)
		# Low-discrepancy ages keep reduced smoke/spark counts spread through life.
		instances.set_instance_custom_data(index, Color(fposmod(float(index) * 0.618034 + rng.randf() * 0.08, 1.0), rng.randf(), rng.randf(), rng.randf()))
	var batch := MultiMeshInstance3D.new()
	batch.name = id
	batch.multimesh = instances
	batch.material_override = _material(shader)
	_generated(batch)
	return batch

static func tongue_mesh() -> ArrayMesh:
	if _tongue_mesh: return _tongue_mesh
	_tongue_mesh = loft_mesh(12, 16)
	return _tongue_mesh

static func loft_mesh(sides: int, rings: int) -> ArrayMesh:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for ring in rings + 1:
		var h := float(ring) / rings
		for side in sides + 1:
			var angle := TAU * float(side) / sides
			surface.set_uv(Vector2(float(side) / sides, h))
			surface.set_normal(Vector3(cos(angle), 0.3, sin(angle)).normalized())
			surface.add_vertex(Vector3(cos(angle), h, sin(angle)))
	for ring in rings:
		for side in sides:
			var a := ring * (sides + 1) + side
			var b := a + sides + 1
			for index in [a, b, a + 1, a + 1, b, b + 1]: surface.add_index(index)
	return surface.commit()

static func spark_mesh() -> ArrayMesh:
	if _spark_mesh: return _spark_mesh
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for ring in 17:
		for side in 2:
			var uv := Vector2(float(side), float(ring) / 16.0)
			surface.set_uv(uv)
			surface.set_normal(Vector3.FORWARD)
			surface.add_vertex(Vector3(uv.x - 0.5, uv.y, 0.0))
	for ring in 16:
		var a := ring * 2
		for index in [a, a + 2, a + 1, a + 1, a + 2, a + 3]: surface.add_index(index)
	_spark_mesh = surface.commit()
	return _spark_mesh

func rebuild() -> void:
	_queued = false
	if not is_inside_tree(): return
	for child in get_children(true):
		if child.get_meta(&"sculpted_fire_generated", false):
			remove_child(child)
			child.queue_free()
	_materials.clear()
	if not _volume_mesh:
		_volume_mesh = BoxMesh.new()
		_volume_mesh.size = Vector3(4.0, 1.9, 4.0)
	var flame := MeshInstance3D.new()
	flame.name = "Flames"
	flame.mesh = _volume_mesh
	flame.material_override = _material(FLAME)
	_generated(flame)
	var tips := _batch("Flamelets", tongue_mesh(), 3, FLAMELET, 0xCA7)
	for index in 3:
		var data := tips.multimesh.get_instance_custom_data(index)
		data.r = float(index)
		tips.multimesh.set_instance_custom_data(index, data)
	if not _smoke_mesh:
		_smoke_mesh = BoxMesh.new()
		_smoke_mesh.size = Vector3.ONE
	var smoke := MeshInstance3D.new()
	smoke.name = "Smoke"
	smoke.mesh = _smoke_mesh
	smoke.material_override = _material(SMOKE)
	smoke.material_override.render_priority = -2
	_generated(smoke)
	if not _fray_mesh:
		_fray_mesh = QuadMesh.new()
		_fray_mesh.size = Vector2.ONE
	var fray := _batch("SmokeFray", _fray_mesh, 16, SMOKE_FRAY, 0x5A2)
	fray.material_override.render_priority = -1
	_batch("Sparks", spark_mesh(), 64, SPARK, 0x5A1)
	var glow := MeshInstance3D.new()
	glow.name = "GroundGlow"
	glow.mesh = QuadMesh.new()
	glow.material_override = _material(GLOW)
	_generated(glow)
	_appearance_changed()
	_sync_recall()
