@tool
class_name PainterlyHouse
extends Node3D
## Exterior bungalow family. Origin is ground center; front door faces local +Z.
signal ground_exclusion_changed

const GEOMETRY = preload("res://components/buildings/house/house_geometry.gd")
const PAINT = preload("res://components/buildings/house/house.gdshader")
@export_group("Shape")
@export var footprint := Vector2(7.2, 5.8):
	set(value):
		footprint = value.clamp(Vector2(5.0, 4.0), Vector2(12, 10))
		_request_rebuild()
@export_range(2.2, 4.0, 0.05) var wall_height: float = 2.8:
	set(value):
		wall_height = value
		_request_rebuild()
@export_range(0.15, 0.8, 0.05) var foundation_height: float = 0.45:
	set(value):
		foundation_height = value
		_request_rebuild()
@export_range(1.0, 3.0, 0.05) var roof_height: float = 1.9:
	set(value):
		roof_height = value
		_request_rebuild()
@export_range(0.15, 0.65, 0.05) var roof_overhang: float = 0.3:
	set(value):
		roof_overhang = value
		_request_rebuild()
@export var dormer: bool = true:
	set(value):
		dormer = value
		_request_rebuild()
@export var side_windows: bool = true:
	set(value):
		side_windows = value
		_request_rebuild()
@export_group("Entrance")
@export_range(0.8, 1.3, 0.05) var door_width: float = 1.0:
	set(value):
		door_width = value
		_request_rebuild()
@export_range(1.4, 2.2, 0.05) var stair_width: float = 1.6:
	set(value):
		stair_width = value
		_request_rebuild()
@export_range(2, 5, 1) var step_count: int = 3:
	set(value):
		step_count = clampi(value, 2, 5)
		_request_rebuild()
@export_range(0.3, 0.5, 0.05) var step_depth: float = 0.35:
	set(value):
		step_depth = value
		_request_rebuild()
@export var railings: bool = true:
	set(value):
		railings = value
		_request_rebuild()
@export_group("Paint")
@export var wall_color := Color("e9dfc5"):
	set(value):
		wall_color = value
		_request_rebuild()
@export var trim_color := Color("f4efdf"):
	set(value):
		trim_color = value
		_request_rebuild()
@export var roof_color := Color("85847d"):
	set(value):
		roof_color = value
		_request_rebuild()
@export var wood_color := Color("75604d"):
	set(value):
		wood_color = value
		_request_rebuild()
@export var glass_color := Color("4f5956"):
	set(value):
		glass_color = value
		_request_rebuild()
@export var foundation_color := Color("b9b3a3"):
	set(value):
		foundation_color = value
		_request_rebuild()
@export var rail_color := Color("514e47"):
	set(value):
		rail_color = value
		_request_rebuild()
## Broad, low-contrast brush washes. No fine noise or texture assets.
@export_range(0.0, 1.0, 0.05) var pigment_strength: float = 0.65:
	set(value):
		pigment_strength = value
		_request_rebuild()
@export_range(0.0, 1.0, 0.05) var window_warmth: float = 0.35:
	set(value):
		window_warmth = value
		_request_rebuild()
@export var porch_lamp: bool = true:
	set(value):
		porch_lamp = value
		_request_rebuild()
@export_group("Detail")
@export var house_seed: int = 24:
	set(value):
		house_seed = value
		_request_rebuild()
@export_range(0.3, 0.8, 0.05) var shingle_size: float = 0.46:
	set(value):
		shingle_size = value
		_request_rebuild()
@export var collision_enabled: bool = true:
	set(value):
		collision_enabled = value
		_request_rebuild()
@export_tool_button("Regenerate house") var regenerate = rebuild
var _queued: bool = false
var _generated: Array[Node] = []

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
	set_notify_transform(true)
	rebuild()

func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSFORM_CHANGED and is_node_ready():
		ground_exclusion_changed.emit()

func _request_rebuild() -> void:
	if is_inside_tree() and not _queued:
		_queued = true
		call_deferred("_rebuild_queued")

func _rebuild_queued() -> void:
	if _queued:
		rebuild()

func rebuild() -> void:
	_queued = false
	if not is_inside_tree():
		return
	for node in _generated:
		if is_instance_valid(node):
			remove_child(node)
			node.free()
	_generated.clear()
	var settings := {}
	for key in ["footprint", "wall_height", "foundation_height", "roof_height", "roof_overhang", "dormer", "side_windows", "door_width", "stair_width", "step_count", "step_depth", "railings", "wall_color", "trim_color", "roof_color", "wood_color", "glass_color", "foundation_color", "rail_color", "house_seed", "shingle_size", "window_warmth", "porch_lamp"]:
		settings[key] = get(key)
	var material := ShaderMaterial.new()
	material.shader = PAINT
	material.set_shader_parameter("wall_top", foundation_height + wall_height)
	material.set_shader_parameter("foundation_height", foundation_height)
	material.set_shader_parameter("pigment_strength", pigment_strength)
	material.set_shader_parameter("paint_phase", float(posmod(house_seed, 1000)) * 0.173)
	var exterior := MeshInstance3D.new()
	exterior.name = "Exterior"
	exterior.mesh = GEOMETRY.create(settings)
	exterior.material_override = material
	exterior.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_add_generated(exterior)
	if collision_enabled:
		var body := StaticBody3D.new()
		body.name = "BuildingCollision"
		var walls := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(footprint.x, wall_height + foundation_height, footprint.y)
		walls.shape = box
		walls.position.y = box.size.y * 0.5
		body.add_child(walls)
		var stairs := CollisionShape3D.new()
		stairs.name = "StairRamp"
		var ramp := ConvexPolygonShape3D.new()
		var points := PackedVector3Array()
		for x in [-stair_width * 0.5, stair_width * 0.5]:
			points.append(Vector3(x, 0, footprint.y * 0.5))
			points.append(Vector3(x, foundation_height, footprint.y * 0.5))
			points.append(Vector3(x, 0, footprint.y * 0.5 + step_count * step_depth))
		ramp.points = points
		stairs.shape = ramp
		body.add_child(stairs)
		_add_generated(body)
	for key in ["FrontDoor", "Approach"]:
		var marker := Marker3D.new()
		marker.name = key
		marker.position = Vector3(0, foundation_height, footprint.y * 0.5 + 0.35) if key == "FrontDoor" else Vector3(0, 0, footprint.y * 0.5 + step_count * step_depth + 1.0)
		_add_generated(marker)
	_sync_recall()
	ground_exclusion_changed.emit()

func _add_generated(node: Node) -> void:
	add_child(node, false, Node.INTERNAL_MODE_BACK)
	_generated.append(node)

func excludes_ground_point(world_point: Vector3) -> bool:
	var point := to_local(world_point)
	var in_building := absf(point.x) <= footprint.x * 0.5 + 0.05 and absf(point.z) <= footprint.y * 0.5 + 0.05
	var in_steps := absf(point.x) <= stair_width * 0.5 + 0.03 and point.z >= footprint.y * 0.5 and point.z <= footprint.y * 0.5 + step_count * step_depth
	return in_building or in_steps
