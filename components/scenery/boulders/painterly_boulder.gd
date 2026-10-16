@tool
class_name PainterlyBoulder
extends Node3D
## One contiguous seeded stone with clean painted planes and varied silhouettes.
signal scenery_changed
const GEOMETRY = preload("res://components/scenery/boulders/boulder_geometry.gd")
const RECALL_SHADER = preload("res://components/effects/recall/shaders/stone_recall.gdshader")
const STONE_SHADER = preload("res://components/scenery/boulders/shaders/painted_stone.gdshader")
const SHADOW_SHADER = preload("res://shaders/contact_shadow.gdshader")
const PRESETS = [null,
	preload("res://components/scenery/boulders/palettes/granite.tres"),
	preload("res://components/scenery/boulders/palettes/sandstone.tres"),
	preload("res://components/scenery/boulders/palettes/slate.tres"),
	preload("res://components/scenery/boulders/palettes/terracotta.tres"),
	preload("res://components/scenery/boulders/palettes/chalk.tres"),
	preload("res://components/scenery/boulders/palettes/dream_violet.tres")]

const RECALL = preload("res://components/effects/recall/component_recall.gd")

@export_group("Recall")
## Hide at runtime and recall this component independently on approach.
@export var recall_enabled: bool = false:
	set(value):
		if recall_enabled == value:
			return
		recall_enabled = value
		if is_node_ready() and not Engine.is_editor_hint():
			rebuild()
var _recall_effect: Node

func get_recall_controller() -> Node:
	return _recall_effect

func _sync_recall() -> void:
	_recall_effect = RECALL.configure(self, "res://components/effects/recall/solid_recall.gd", _recall_effect)

func get_recall_shader() -> Shader:
	return RECALL_SHADER

func get_recall_mesh() -> MeshInstance3D:
	return get_node_or_null("Stone") as MeshInstance3D

func get_recall_shadow_material() -> ShaderMaterial:
	return $ContactShadow.mesh.material

func get_recall_collision_body() -> Node:
	return get_node_or_null("BoulderCollision")

@export_group("Stone Colors")
@export_enum("Custom", "Granite", "Sandstone", "Slate", "Terracotta", "Chalk", "Dream Violet") var palette_preset: int = 1:
	set(value):
		palette_preset = clampi(value, 0, 6)
		if palette_preset != 0:
			_applying_preset = true
			palette = PRESETS[palette_preset].duplicate() as StonePalette
			_applying_preset = false
		notify_property_list_changed()
@export var palette: StonePalette = PRESETS[1]:
	set(value):
		if palette and palette.changed.is_connected(_on_palette_changed):
			palette.changed.disconnect(_on_palette_changed)
		palette = value
		if palette:
			palette.changed.connect(_on_palette_changed)
		if not _applying_preset:
			palette_preset = 0
		_update_colors()
@export_group("Shape")
@export var boulder_seed: int = 73:
	set(value):
		boulder_seed = value
		_request_rebuild()
@export_enum("Automatic", "Block", "Slab", "Upright", "Wedge", "Shard", "Weathered") var shape_profile: int = 0:
	set(value):
		shape_profile = clampi(value, 0, 6)
		_request_rebuild()
@export_range(0.0, 1.0, 0.05) var variability: float = 0.85:
	set(value):
		variability = clampf(value, 0.0, 1.0)
		_request_rebuild()
@export var dimensions := Vector3(1.8, 1.25, 1.4):
	set(value):
		dimensions = value.clamp(Vector3.ONE * 0.3, Vector3.ONE * 6.0)
		_request_rebuild()
@export_range(0.0, 1.0, 0.01) var roundness: float = 0.45:
	set(value):
		roundness = clampf(value, 0.0, 1.0)
		_request_rebuild()
@export_range(0.0, 0.35, 0.01) var roughness: float = 0.12:
	set(value):
		roughness = clampf(value, 0.0, 0.35)
		_request_rebuild()
@export_range(0.0, 0.35, 0.01) var burial: float = 0.12:
	set(value):
		burial = clampf(value, 0.0, 0.35)
		_request_rebuild()
@export_group("Paint")
@export_range(0.0, 0.1, 0.005) var plane_variation: float = 0.025:
	set(value):
		plane_variation = value
		_update_colors()
@export_group("")
@export var solid: bool = true:
	set(value):
		solid = value
		_request_rebuild()
@export_range(15.0, 150.0, 1.0) var visibility_distance: float = 55.0:
	set(value):
		visibility_distance = value
		_request_rebuild()
@export_tool_button("Regenerate boulder") var regenerate = rebuild

var _applying_preset: bool = false
var _queued: bool = false
var _stone_material: ShaderMaterial

func _ready() -> void:
	set_notify_transform(true)
	if palette and not palette.changed.is_connected(_on_palette_changed):
		palette.changed.connect(_on_palette_changed)
	rebuild()

func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSFORM_CHANGED and is_inside_tree():
		scenery_changed.emit()

func _validate_property(property: Dictionary) -> void:
	if property.name == "palette" and palette_preset != 0:
		property.usage = property.usage & ~PROPERTY_USAGE_STORAGE

func _on_palette_changed() -> void:
	palette_preset = 0
	_update_colors()

func _update_colors() -> void:
	if not _stone_material:
		return
	var colors: StonePalette = palette if palette else PRESETS[1]
	for key in [&"base_color", &"shadow_color", &"mid_color", &"highlight_color"]:
		_stone_material.set_shader_parameter(key, colors.get(key))
	_stone_material.set_shader_parameter("plane_variation", plane_variation)

func _request_rebuild() -> void:
	if is_inside_tree() and not _queued:
		_queued = true
		call_deferred("rebuild")

func rebuild() -> void:
	_queued = false
	if not is_inside_tree():
		return
	for child in get_children(true):
		if child.get_meta(&"generated_boulder", false):
			remove_child(child)
			child.queue_free()
	var mesh := GEOMETRY.create_mesh(boulder_seed, dimensions, roundness, roughness, burial, shape_profile, variability)
	_stone_material = ShaderMaterial.new()
	_stone_material.shader = STONE_SHADER
	_update_colors()
	var stone := MeshInstance3D.new()
	stone.name = "Stone"
	stone.mesh = mesh
	stone.material_override = _stone_material
	_add_generated(stone)
	var shadow := MeshInstance3D.new()
	shadow.name = "ContactShadow"
	var plane := PlaneMesh.new()
	var bounds := mesh.get_aabb()
	plane.size = Vector2(bounds.size.x, bounds.size.z) * 1.5
	var material := ShaderMaterial.new()
	material.shader = SHADOW_SHADER
	material.set_shader_parameter("shadow_color", Color(0.25, 0.29, 0.25, 0.28))
	plane.material = material
	shadow.mesh = plane
	shadow.position = Vector3(bounds.get_center().x, 0.014, bounds.get_center().z)
	_add_generated(shadow)
	if solid:
		var body := StaticBody3D.new()
		body.name = "BoulderCollision"
		var collision := CollisionShape3D.new()
		collision.shape = mesh.create_convex_shape()
		body.add_child(collision)
		_add_generated(body)

	_sync_recall()
	scenery_changed.emit()

func _add_generated(node: Node) -> void:
	node.set_meta(&"generated_boulder", true)
	if node is GeometryInstance3D:
		node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		node.visibility_range_end = visibility_distance
	add_child(node, false, Node.INTERNAL_MODE_BACK)
