@tool
class_name PainterlySmoke
extends Node3D
## Graphic curling brush strokes and watercolor-like puffs; all motion lives on the GPU.
const PUFF_SHADER = preload("res://components/vfx/smoke/smoke_puffs.gdshader")
const WISP_SHADER = preload("res://components/vfx/smoke/smoke_wisps.gdshader")
const RECALL = preload("res://components/effects/recall/component_recall.gd")
const PRESETS = [
	{},
	{"plume_height": 3.2, "emitter_width": 0.16, "spread": 0.65, "puff_size": Vector2(0.35, 0.85), "puff_count": 18, "wisp_count": 7, "wisp_width": 0.12, "wisp_length": 0.38, "curl_radius": 0.30, "curl_turns": 1.05, "wind": Vector2(0.20, 0.04), "lifetime": 5.5, "density": 0.65, "puff_opacity": 0.17, "wisp_opacity": 0.40, "base_color": Color("eeeddb"), "shade_color": Color("9ea6b3"), "highlight_color": Color("fff7e0")},
	{"plume_height": 3.8, "emitter_width": 0.25, "spread": 0.85, "puff_size": Vector2(0.60, 1.4), "puff_count": 24, "wisp_count": 5, "wisp_width": 0.20, "wisp_length": 0.42, "curl_radius": 0.50, "curl_turns": 0.85, "wind": Vector2(0.35, 0.10), "lifetime": 7.0, "density": 0.90, "puff_opacity": 0.32, "wisp_opacity": 0.24, "base_color": Color("a6a2ae"), "shade_color": Color("696477"), "highlight_color": Color("d8d0c2")},
	{"plume_height": 2.4, "emitter_width": 0.06, "spread": 0.20, "puff_size": Vector2(0.15, 0.40), "puff_count": 10, "wisp_count": 5, "wisp_width": 0.065, "wisp_length": 0.45, "curl_radius": 0.18, "curl_turns": 1.45, "wind": Vector2(0.10, 0.0), "lifetime": 7.5, "density": 0.70, "puff_opacity": 0.12, "wisp_opacity": 0.42, "base_color": Color("ddd7df"), "shade_color": Color("888198"), "highlight_color": Color("f7eee1")},
	{"plume_height": 2.8, "emitter_width": 1.0, "spread": 1.2, "puff_size": Vector2(0.50, 1.1), "puff_count": 24, "wisp_count": 8, "wisp_width": 0.18, "wisp_length": 0.45, "curl_radius": 0.60, "curl_turns": 1.0, "wind": Vector2(0.30, 0.12), "lifetime": 9.0, "density": 0.65, "puff_opacity": 0.22, "wisp_opacity": 0.30, "base_color": Color("cbc1dc"), "shade_color": Color("9389ae"), "highlight_color": Color("f3e5de")}
]
@export_group("Recall")
@export var recall_enabled: bool = false:
	set(value):
		recall_enabled = value
		if is_node_ready() and not Engine.is_editor_hint():
			_sync_recall()
@export_group("Plume")
@export_enum("Custom", "Steam", "Soft Smoke", "Candle Smoke", "Dream Mist") var preset: int = 1:
	set(value):
		preset = clampi(value, 0, 4)
		if preset > 0:
			_applying_preset = true
			for key in PRESETS[preset]:
				set(key, PRESETS[preset][key])
			_applying_preset = false
@export_range(0.2, 10.0, 0.1) var plume_height: float = 3.2:
	set(value):
		plume_height = clampf(value, 0.2, 10.0)
		_appearance_changed()
@export_range(0.0, 3.0, 0.01) var emitter_width: float = 0.16:
	set(value):
		emitter_width = clampf(value, 0.0, 3.0)
		_appearance_changed()
@export_range(0.0, 4.0, 0.05) var spread: float = 0.65:
	set(value):
		spread = clampf(value, 0.0, 4.0)
		_appearance_changed()
@export var emitter_seed: int = 91:
	set(value):
		emitter_seed = value
		_request_rebuild()
@export_group("Curl and Drift")
@export_range(0.0, 2.0, 0.01) var curl_radius: float = 0.30:
	set(value):
		curl_radius = clampf(value, 0.0, 2.0)
		_appearance_changed()
@export_range(0.0, 3.0, 0.05) var curl_turns: float = 1.05:
	set(value):
		curl_turns = clampf(value, 0.0, 3.0)
		_appearance_changed()
## Approximate final horizontal displacement in local X/Z meters.
@export var wind := Vector2(0.20, 0.04):
	set(value):
		wind = value.clamp(Vector2(-5, -5), Vector2(5, 5))
		_appearance_changed()
@export_range(1.0, 20.0, 0.1) var lifetime: float = 5.5:
	set(value):
		lifetime = clampf(value, 1.0, 20.0)
		_appearance_changed()
## Zero freezes the entire emitter.
@export_range(0.0, 3.0, 0.05) var animation_speed: float = 0.8:
	set(value):
		animation_speed = clampf(value, 0.0, 3.0)
		_appearance_changed()
@export_group("Puffs and Wisps")
@export_range(0, 64, 1) var puff_count: int = 18:
	set(value):
		puff_count = clampi(value, 0, 64)
		_request_rebuild()
@export var puff_size := Vector2(0.35, 0.85):
	set(value):
		var smallest := clampf(value.x, 0.05, 3.0)
		puff_size = Vector2(smallest, clampf(value.y, smallest, 4.0))
		_appearance_changed()
@export_range(0, 24, 1) var wisp_count: int = 7:
	set(value):
		wisp_count = clampi(value, 0, 24)
		_request_rebuild()
@export_range(0.01, 0.6, 0.01) var wisp_width: float = 0.12:
	set(value):
		wisp_width = clampf(value, 0.01, 0.6)
		_appearance_changed()
## Fraction of plume height occupied by each curling stroke.
@export_range(0.1, 0.7, 0.01) var wisp_length: float = 0.38:
	set(value):
		wisp_length = clampf(value, 0.1, 0.7)
		_appearance_changed()
@export_group("Pigment")
@export var base_color := Color("eeeddb"):
	set(value):
		base_color = value
		_appearance_changed()
@export var shade_color := Color("9ea6b3"):
	set(value):
		shade_color = value
		_appearance_changed()
@export var highlight_color := Color("fff7e0"):
	set(value):
		highlight_color = value
		_appearance_changed()
@export_range(0.0, 1.0, 0.01) var density: float = 0.65:
	set(value):
		density = clampf(value, 0.0, 1.0)
		_appearance_changed()
@export_range(0.0, 0.8, 0.01) var puff_opacity: float = 0.17:
	set(value):
		puff_opacity = clampf(value, 0.0, 0.8)
		_appearance_changed()
@export_range(0.0, 0.8, 0.01) var wisp_opacity: float = 0.40:
	set(value):
		wisp_opacity = clampf(value, 0.0, 0.8)
		_appearance_changed()
@export_range(0.0, 1.0, 0.01) var paint_variation: float = 0.35:
	set(value):
		paint_variation = clampf(value, 0.0, 1.0)
		_appearance_changed()
@export_group("Rendering")
@export_range(10.0, 150.0, 1.0) var visibility_distance: float = 45.0:
	set(value):
		visibility_distance = value
		if is_inside_tree():
			for child in get_children(true):
				if child is GeometryInstance3D:
					child.visibility_range_end = value

static var _puff_mesh: QuadMesh
static var _wisp_mesh: ArrayMesh
var _applying_preset: bool = false
var _queued: bool = false
var _materials: Array[ShaderMaterial] = []
var _recall_effect: Node

var footprint: Vector2:
	get:
		return Vector2.ONE * maxf(emitter_width, 0.2)

func _ready() -> void:
	rebuild()
func get_recall_controller() -> Node:
	return _recall_effect
func recall_materials() -> Array[ShaderMaterial]:
	return _materials
func _sync_recall() -> void:
	_recall_effect = RECALL.configure(self, "res://components/vfx/smoke/smoke_recall.gd", _recall_effect)
	if not recall_enabled:
		for material in _materials:
			material.set_shader_parameter("recall_visibility", 1.0)
func _mark_custom() -> void:
	if not _applying_preset and is_inside_tree():
		preset = 0
func _appearance_changed() -> void:
	_mark_custom()
	_update_materials()
	_update_bounds()
func _request_rebuild() -> void:
	_mark_custom()
	if is_inside_tree() and not _queued:
		_queued = true
		call_deferred("rebuild")
func _update_materials() -> void:
	for material in _materials:
		for key in [&"plume_height", &"emitter_width", &"spread", &"puff_size", &"wisp_width", &"wisp_length", &"curl_radius", &"curl_turns", &"wind", &"lifetime", &"animation_speed", &"density", &"puff_opacity", &"wisp_opacity", &"paint_variation", &"base_color", &"shade_color", &"highlight_color"]:
			material.set_shader_parameter(key, get(key))
	if is_inside_tree():
		for child in get_children(true):
			if child is GeometryInstance3D:
				child.visible = density > 0.0
func _update_bounds() -> void:
	if not is_inside_tree():
		return
	var side := emitter_width * 0.5 + spread * 0.5 + curl_radius + wind.length()
	var padding := puff_size.y * 0.8 + wisp_width + 0.1
	var bounds := AABB(Vector3(-side, 0, -side), Vector3(side * 2.0, plume_height, side * 2.0)).grow(padding)
	for child in get_children(true):
		if child is GeometryInstance3D:
			child.custom_aabb = bounds
func _add_batch(name: String, mesh: Mesh, count: int, shader: Shader, seed_offset: int) -> void:
	if count == 0:
		return
	var material := ShaderMaterial.new()
	material.shader = shader
	material.render_priority = 0 if name == "Puffs" else 1
	_materials.append(material)
	var multi := MultiMesh.new()
	multi.transform_format = MultiMesh.TRANSFORM_3D
	multi.use_custom_data = true
	multi.mesh = mesh
	multi.instance_count = count
	var rng := RandomNumberGenerator.new()
	rng.seed = emitter_seed + seed_offset
	for index in range(count):
		multi.set_instance_transform(index, Transform3D.IDENTITY)
		multi.set_instance_custom_data(index, Color((index + rng.randf()) / count, rng.randf(), rng.randf(), rng.randf()))
	var batch := MultiMeshInstance3D.new()
	batch.name = name
	batch.multimesh = multi
	batch.material_override = material
	batch.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	batch.visibility_range_end = visibility_distance
	add_child(batch, false, Node.INTERNAL_MODE_BACK)
func rebuild() -> void:
	_queued = false
	if not is_inside_tree():
		return
	_materials.clear()
	for child in get_children(true):
		if child is GeometryInstance3D:
			remove_child(child)
			child.queue_free()
	if not _puff_mesh:
		_puff_mesh = QuadMesh.new()
	if not _wisp_mesh:
		var surface := SurfaceTool.new()
		surface.begin(Mesh.PRIMITIVE_TRIANGLES)
		for segment in range(18):
			for corner in [Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 0), Vector2(1, 1), Vector2(0, 1)]:
				var uv := Vector2(corner.x, (segment + corner.y) / 18.0)
				surface.set_uv(uv)
				surface.set_normal(Vector3.FORWARD)
				surface.add_vertex(Vector3(uv.x * 2.0 - 1.0, uv.y, 0))
		_wisp_mesh = surface.commit()
	_add_batch("Puffs", _puff_mesh, puff_count, PUFF_SHADER, 0)
	_add_batch("Wisps", _wisp_mesh, wisp_count, WISP_SHADER, 401)
	_update_materials()
	_update_bounds()
	_sync_recall()
