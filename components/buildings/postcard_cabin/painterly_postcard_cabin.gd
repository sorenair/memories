@tool
class_name PainterlyPostcardCabin
extends Node3D
## Closed trailer cabin exterior. Ground-center origin; entry faces +Z, picture window -X.
signal ground_exclusion_changed
const GEOMETRY = preload("res://components/buildings/postcard_cabin/cabin_geometry.gd")
const PAINT = preload("res://components/buildings/postcard_cabin/cabin.gdshader")
const CONTACT = preload("res://shaders/contact_shadow.gdshader")
const RECALL = preload("res://components/effects/recall/component_recall.gd")

@export_group("Cabin Shape")
## Length along X, depth along Z. Use these dimensions instead of nonuniform scaling.
@export var footprint := Vector2(5.8, 2.7):
	set(value):
		footprint = value.clamp(Vector2(4.5, 2.4), Vector2(8.0, 3.8))
		_request_rebuild()
@export_range(2.3, 3.2, 0.05) var wall_height: float = 2.6:
	set(value):
		wall_height = clampf(value, 2.3, 3.2)
		_request_rebuild()
@export_range(0.35, 0.8, 0.05) var floor_height: float = 0.58:
	set(value):
		floor_height = clampf(value, 0.35, 0.8)
		_request_rebuild()
## Roof is tallest over the end picture window and falls toward the entry end.
@export_range(0.0, 0.7, 0.05) var roof_rise: float = 0.42:
	set(value):
		roof_rise = clampf(value, 0, 0.7)
		_request_rebuild()
@export_range(0.05, 0.25, 0.01) var roof_overhang: float = 0.11:
	set(value):
		roof_overhang = clampf(value, 0.05, 0.25)
		_request_rebuild()
@export_range(0.14, 0.35, 0.01) var board_width: float = 0.19:
	set(value):
		board_width = clampf(value, 0.14, 0.35)
		_request_rebuild()

@export_group("Exterior Details")
@export_range(0.20, 0.32, 0.01) var door_offset: float = 0.28:
	set(value):
		door_offset = clampf(value, 0.20, 0.32)
		_request_rebuild()
@export var side_window_enabled: bool = true:
	set(value):
		side_window_enabled = value
		_request_rebuild()
@export var wheels_enabled: bool = true:
	set(value):
		wheels_enabled = value
		_request_rebuild()
@export var steps_enabled: bool = true:
	set(value):
		steps_enabled = value
		_request_rebuild()
@export var porch_lamp_enabled: bool = true:
	set(value):
		porch_lamp_enabled = value
		_request_rebuild()

@export_group("Painterly Colors")
@export var siding_color := Color("424947"):
	set(value):
		siding_color = value
		_request_rebuild()
@export var trim_color := Color("50564f"):
	set(value):
		trim_color = value
		_request_rebuild()
@export var roof_color := Color("535b57"):
	set(value):
		roof_color = value
		_request_rebuild()
@export var step_color := Color("9a8b72"):
	set(value):
		step_color = value
		_request_rebuild()
@export var hardware_color := Color("c4aa76"):
	set(value):
		hardware_color = value
		_request_rebuild()
@export var glass_color := Color("8eaa97"):
	set(value):
		glass_color = value
		_request_rebuild()
@export_range(0.0, 1.0, 0.05) var pigment_strength: float = 0.65:
	set(value):
		pigment_strength = clampf(value, 0, 1)
		_apply_material()
## Zero favors sage forest reflections; one favors warm amber window pigment.
@export_range(0.0, 1.0, 0.05) var window_warmth: float = 0.72:
	set(value):
		window_warmth = clampf(value, 0, 1)
		_apply_material()
@export_range(0.0, 0.6, 0.02) var window_glow: float = 0.28:
	set(value):
		window_glow = clampf(value, 0, 0.6)
		_apply_material()
@export var cabin_seed: int = 29:
	set(value):
		cabin_seed = value
		_request_rebuild()

@export_group("Collision and Recall")
@export var collision_enabled: bool = true:
	set(value):
		collision_enabled = value
		_request_rebuild()
@export var contact_shadow_enabled: bool = true:
	set(value):
		contact_shadow_enabled = value
		_request_rebuild()
@export var recall_enabled: bool = false:
	set(value):
		recall_enabled = value
		if is_node_ready() and not Engine.is_editor_hint():
			_sync_recall()
@export_tool_button("Rebuild cabin") var regenerate = rebuild

var _queued: bool = false
var _generated: Node3D
var _material: ShaderMaterial
var _recall: Node
var _lamp_position := Vector3.ZERO

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

func _apply_material() -> void:
	if not _material:
		return
	for key in ["pigment_strength", "window_warmth", "window_glow", "floor_height", "porch_lamp_enabled"]:
		_material.set_shader_parameter(key, get(key))
	_material.set_shader_parameter("paint_phase", float(posmod(cabin_seed, 997)) * 0.173)
	_material.set_shader_parameter("lamp_position", _lamp_position)

func rebuild() -> void:
	_queued = false
	if not is_inside_tree():
		return
	if is_instance_valid(_generated):
		remove_child(_generated)
		_generated.free()
	_generated = Node3D.new()
	_generated.name = "Generated"
	add_child(_generated, false, Node.INTERNAL_MODE_BACK)
	var config := {}
	for key in ["footprint", "wall_height", "floor_height", "roof_rise", "roof_overhang", "board_width", "door_offset", "side_window_enabled", "wheels_enabled", "steps_enabled", "porch_lamp_enabled", "siding_color", "trim_color", "roof_color", "step_color", "hardware_color", "glass_color", "cabin_seed"]:
		config[key] = get(key)
	var data: Dictionary = GEOMETRY.new().build_cabin(config)
	_lamp_position = data.lamp_position
	_material = ShaderMaterial.new()
	_material.shader = PAINT
	_apply_material()
	var exterior := MeshInstance3D.new()
	exterior.name = "Exterior"
	exterior.mesh = data.mesh
	exterior.material_override = _material
	exterior.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	exterior.visibility_range_end = 80.0
	_generated.add_child(exterior)
	if collision_enabled:
		_build_collision(data.door_x, data.step_run)
	if contact_shadow_enabled:
		var shadow := MeshInstance3D.new()
		shadow.name = "ContactShadow"
		var plane := PlaneMesh.new()
		plane.size = footprint * Vector2(1.24, 1.5)
		shadow.mesh = plane
		var material := ShaderMaterial.new()
		material.shader = CONTACT
		material.set_shader_parameter("shadow_color", Color(0.29, 0.32, 0.29, 0.26))
		shadow.material_override = material
		shadow.position.y = 0.012
		shadow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		shadow.visibility_range_end = 80.0
		_generated.add_child(shadow)
	var hooks := Node3D.new()
	hooks.name = "Anchors"
	var anchors := {
		"FrontDoor": Vector3(data.door_x, floor_height, footprint.y * 0.5 + 0.35),
		"Approach": Vector3(data.door_x, 0, footprint.y * 0.5 + (data.step_run if steps_enabled else 0.0) + 0.65),
		"PictureWindow": Vector3(-footprint.x * 0.5 - 0.15, floor_height + (wall_height + roof_rise) * 0.52, 0)
	}
	for key in anchors:
		var marker := Marker3D.new()
		marker.name = key
		marker.position = anchors[key]
		hooks.add_child(marker)
	_generated.add_child(hooks)
	_sync_recall()
	ground_exclusion_changed.emit()

func _build_collision(door_x: float, step_run: float) -> void:
	var body := StaticBody3D.new()
	body.name = "BuildingCollision"
	var shell := CollisionShape3D.new()
	shell.name = "SolidExterior"
	var shape := ConvexPolygonShape3D.new()
	var points := PackedVector3Array()
	for x in [-footprint.x * 0.5, footprint.x * 0.5]:
		for z in [-footprint.y * 0.5, footprint.y * 0.5]:
			points.append(Vector3(x, 0, z))
			points.append(Vector3(x, floor_height + wall_height + roof_rise * (0.5 - x / footprint.x) + 0.075, z))
	shape.points = points
	shell.shape = shape
	body.add_child(shell)
	if steps_enabled:
		var ramp := CollisionShape3D.new()
		ramp.name = "StairRamp"
		var slope := ConvexPolygonShape3D.new()
		var corners := PackedVector3Array()
		for x in [door_x - 0.55, door_x + 0.55]:
			corners.append(Vector3(x, 0, footprint.y * 0.5))
			corners.append(Vector3(x, floor_height, footprint.y * 0.5))
			corners.append(Vector3(x, 0, footprint.y * 0.5 + step_run))
		slope.points = corners
		ramp.shape = slope
		body.add_child(ramp)
	_generated.add_child(body)

func get_anchor(id: StringName) -> Marker3D:
	return _generated.get_node_or_null(NodePath("Anchors/" + String(id))) as Marker3D if is_instance_valid(_generated) else null

func get_recall_controller() -> Node:
	return _recall

func _sync_recall() -> void:
	_recall = RECALL.configure(self, "res://components/effects/recall/assembled_recall.gd", _recall)
	if not recall_enabled:
		preload("res://components/effects/recall/assembled_recall.gd").restore_component(self)

func excludes_ground_point(world_point: Vector3) -> bool:
	var point := to_local(world_point)
	var half := footprint * 0.5
	var cabin := absf(point.x) <= half.x + 0.10 and absf(point.z) <= half.y + 0.12
	var stairs := steps_enabled and absf(point.x - door_offset * footprint.x) <= 0.60 and point.z >= half.y and point.z <= half.y + 0.86
	return cabin or stairs
