@tool
class_name PainterlyLightWash
extends Node3D
## A feathered painted pool on a flat floor or wall, using one transparent quad.
const SHADER = preload("res://components/lighting/light_wash/light_wash.gdshader")
const RECALL = preload("res://components/effects/recall/component_recall.gd")

@export_group("Recall")
@export var recall_enabled: bool = false:
	set(value):
		recall_enabled = value
		if is_node_ready() and not Engine.is_editor_hint():
			_sync_recall()
@export_group("Light Wash")
@export_enum("Pool", "Soft Rectangle", "Window Panes") var wash_shape: int = 0:
	set(value):
		wash_shape = clampi(value, 0, 2)
		_update_material()
@export var footprint := Vector2(4.5, 3.0):
	set(value):
		footprint = value.clamp(Vector2.ONE * 0.1, Vector2.ONE * 30.0)
		_request_rebuild()
@export var light_color := Color(1.0, 0.90, 0.65, 1.0):
	set(value):
		light_color = value
		_update_material()
@export_range(0.0, 1.0, 0.01) var intensity: float = 0.65:
	set(value):
		intensity = clampf(value, 0.0, 1.0)
		_update_material()
@export_range(0.05, 1.0, 0.01) var softness: float = 0.65:
	set(value):
		softness = clampf(value, 0.05, 1.0)
		_update_material()
@export_range(0.0, 1.0, 0.01) var paint_variation: float = 0.18:
	set(value):
		paint_variation = clampf(value, 0.0, 1.0)
		_update_material()
@export var wash_seed: int = 57:
	set(value):
		wash_seed = value
		_update_material()
@export_group("Window Panes")
@export var window_grid := Vector2i(2, 2):
	set(value):
		window_grid = value.clamp(Vector2i.ONE, Vector2i(8, 8))
		_update_material()
@export_range(0.0, 0.4, 0.01) var pane_gap: float = 0.08:
	set(value):
		pane_gap = clampf(value, 0.0, 0.4)
		_update_material()
@export_group("Motion")
@export_enum("Steady", "Candle Flicker", "Slow Pulse") var motion: int = 0:
	set(value):
		motion = clampi(value, 0, 2)
		_update_material()
@export_range(0.0, 3.0, 0.05) var motion_speed: float = 1.0:
	set(value):
		motion_speed = clampf(value, 0.0, 3.0)
		_update_material()
@export_range(0.0, 1.0, 0.01) var motion_amount: float = 0.18:
	set(value):
		motion_amount = clampf(value, 0.0, 1.0)
		_update_material()
@export_group("Placement")
@export_enum("Floor", "Wall") var surface: int = 0:
	set(value):
		surface = clampi(value, 0, 1)
		_place_surface()
## Keep the component root at floor level; raise only the painted wall surface.
@export_range(0.1, 8.0, 0.1) var wall_center_height: float = 2.2:
	set(value):
		wall_center_height = maxf(value, 0.1)
		_place_surface()
@export_group("Rendering")
## Offset along local Y to avoid z-fighting with the receiving plane.
@export_range(0.001, 0.05, 0.001) var surface_offset: float = 0.012:
	set(value):
		surface_offset = clampf(value, 0.001, 0.05)
		_place_surface()
@export_range(10.0, 150.0, 1.0) var visibility_distance: float = 50.0:
	set(value):
		visibility_distance = value
		if is_inside_tree() and has_node("Wash"):
			$Wash.visibility_range_end = value

var _material: ShaderMaterial
var _queued: bool = false
var _recall_effect: Node

func _ready() -> void:
	rebuild()

func get_recall_controller() -> Node:
	return _recall_effect

func _sync_recall() -> void:
	_recall_effect = RECALL.configure(self, "res://components/lighting/light_wash/light_wash_recall.gd", _recall_effect)
	if not recall_enabled and _material:
		_material.set_shader_parameter("recall_visibility", 1.0)

func _request_rebuild() -> void:
	if is_inside_tree() and not _queued:
		_queued = true
		call_deferred("rebuild")

func rebuild() -> void:
	_queued = false
	if not is_inside_tree():
		return
	var old := get_node_or_null("Wash")
	if old:
		remove_child(old)
		old.queue_free()
	_material = ShaderMaterial.new()
	_material.shader = SHADER
	_material.render_priority = -2
	_update_material()
	var plane := PlaneMesh.new()
	plane.size = footprint
	var wash := MeshInstance3D.new()
	wash.name = "Wash"
	wash.mesh = plane
	wash.material_override = _material
	wash.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	wash.visibility_range_end = visibility_distance
	add_child(wash, false, Node.INTERNAL_MODE_BACK)
	_place_surface()
	_sync_recall()

func _place_surface() -> void:
	if not is_inside_tree() or not has_node("Wash"):
		return
	$Wash.rotation.x = PI * 0.5 if surface == 1 else 0.0
	$Wash.position = Vector3(0, wall_center_height, surface_offset) if surface == 1 else Vector3(0, surface_offset, 0)

func _update_material() -> void:
	if not _material:
		return
	for key in [&"wash_shape", &"light_color", &"intensity", &"softness", &"paint_variation", &"pane_gap", &"motion", &"motion_speed", &"motion_amount"]:
		_material.set_shader_parameter(key, get(key))
	_material.set_shader_parameter("window_grid", Vector2(window_grid))
	_material.set_shader_parameter("paint_seed", float(posmod(wash_seed, 1000)) * 0.173)
