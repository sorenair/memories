@tool
class_name PainterlyLeafLitter
extends Node3D
## A flat, seeded autumn accent. Local XZ is the surface plane; no raycast projection.
const GEOMETRY = preload("res://components/foliage/leaf_litter/leaf_litter_geometry.gd")
const PAINT = preload("res://components/foliage/leaf_litter/painted_leaf_litter.gdshader")
@export var leaf_seed: int = 83:
	set(value):
		leaf_seed = value
		_request_rebuild()
@export_range(0, 800, 1) var leaf_count: int = 70:
	set(value):
		leaf_count = clampi(value, 0, 800)
		_request_rebuild()
@export var footprint := Vector2(3.0, 1.8):
	set(value):
		footprint = value.clamp(Vector2(0.1, 0.1), Vector2(30, 30))
		_request_rebuild()
## World-space crown radius in meters. Maximum width is about twice this value.
@export var size_range := Vector2(0.06, 0.13):
	set(value):
		var limits := value.clamp(Vector2(0.015, 0.015), Vector2(0.5, 0.5))
		size_range = Vector2(minf(limits.x, limits.y), maxf(limits.x, limits.y))
		_request_rebuild()
@export_range(0.0, 1.0, 0.05) var edge_bias: float = 0.0:
	set(value):
		edge_bias = clampf(value, 0, 1)
		_request_rebuild()
@export_group("Pigment")
@export var ochre_color := Color("d48f3b"):
	set(value):
		ochre_color = value
		_apply_material()
@export var rust_color := Color("914a26"):
	set(value):
		rust_color = value
		_apply_material()
@export var cream_color := Color("ebc980"):
	set(value):
		cream_color = value
		_apply_material()
@export_group("Motion")
## Zero is fully resting. Small values lift just the edges of a few leaves.
@export_range(0.0, 0.15, 0.005) var flutter_strength: float = 0.0:
	set(value):
		flutter_strength = value
		_apply_material()
@export_range(0.0, 3.0, 0.05) var flutter_speed: float = 0.7:
	set(value):
		flutter_speed = value
		_apply_material()
@export_range(10.0, 100.0, 1.0) var visibility_distance: float = 45.0:
	set(value):
		visibility_distance = value
		_request_rebuild()
@export_tool_button("Regenerate leaf litter") var regenerate = rebuild
var _queued: bool = false
var _batch: MultiMeshInstance3D
var _material: ShaderMaterial

const RECALL = preload("res://components/effects/recall/component_recall.gd")
@export_group("Recall")
@export var recall_enabled: bool = false:
	set(value):
		recall_enabled = value
		if is_node_ready() and not Engine.is_editor_hint():
			_sync_recall()
var _recall: Node

func get_recall_controller() -> Node:
	return _recall

func _sync_recall() -> void:
	_recall = RECALL.configure(self, "res://components/effects/recall/assembled_recall.gd", _recall)
	if not recall_enabled and not Engine.is_editor_hint():
		preload("res://components/effects/recall/assembled_recall.gd").restore_component(self)


func _ready() -> void:
	rebuild()

func _request_rebuild() -> void:
	if is_inside_tree() and not _queued:
		_queued = true
		call_deferred("_rebuild_queued")

func _rebuild_queued() -> void:
	if _queued:
		rebuild()

func _apply_material() -> void:
	if not _material:
		return
	for key in ["ochre_color", "rust_color", "cream_color", "flutter_strength", "flutter_speed"]:
		_material.set_shader_parameter(key, get(key))

func rebuild() -> void:
	_queued = false
	if not is_inside_tree():
		return
	if is_instance_valid(_batch):
		remove_child(_batch)
		_batch.free()
	_material = ShaderMaterial.new()
	_material.shader = PAINT
	_apply_material()
	var layout := GEOMETRY.create_layout(leaf_seed, leaf_count, footprint, size_range, edge_bias)
	var transforms: Array[Transform3D] = layout.transforms
	var colors: Array[Color] = layout.colors
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.use_custom_data = true
	multimesh.mesh = GEOMETRY.create_mesh()
	multimesh.instance_count = transforms.size()
	var bounds := AABB()
	for index in range(transforms.size()):
		multimesh.set_instance_transform(index, transforms[index])
		multimesh.set_instance_custom_data(index, colors[index])
		var instance_bounds: AABB = transforms[index] * multimesh.mesh.get_aabb()
		bounds = instance_bounds if index == 0 else bounds.merge(instance_bounds)
	multimesh.custom_aabb = bounds.grow(size_range.y * flutter_strength + 0.015)
	_batch = MultiMeshInstance3D.new()
	_batch.name = "Leaves"
	_batch.multimesh = multimesh
	_batch.material_override = _material
	_batch.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_batch.visibility_range_end = visibility_distance
	add_child(_batch, false, Node.INTERNAL_MODE_BACK)

	_sync_recall()
