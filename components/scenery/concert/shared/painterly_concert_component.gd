@tool
class_name PainterlyConcertComponent
extends Node3D
## Shared seeded paint, collision, grounding, placement anchors, and optional recall.
signal ground_exclusion_changed
const GEOMETRY = preload("res://components/scenery/concert/shared/concert_geometry.gd")
const PAINT = preload("res://components/scenery/concert/shared/concert_paint.gdshader")
const CONTACT = preload("res://shaders/contact_shadow.gdshader")
const RECALL = preload("res://components/effects/recall/component_recall.gd")

@export_group("Paint")
@export var prop_seed: int = 71:
	set(value):
		prop_seed = value
		_request_rebuild()
@export var body_color := Color("536272"):
	set(value):
		body_color = value
		_request_rebuild()
@export var accent_color := Color("756386"):
	set(value):
		accent_color = value
		_request_rebuild()
@export var trim_color := Color("b9ac90"):
	set(value):
		trim_color = value
		_request_rebuild()
@export_range(0.0, 1.0, 0.05) var pigment_strength: float = 0.55:
	set(value):
		pigment_strength = clampf(value, 0, 1)
		_apply_material()
@export_group("Collision and Rendering")
@export var collision_enabled: bool = true:
	set(value):
		collision_enabled = value
		_request_rebuild()
@export var contact_shadow_enabled: bool = true:
	set(value):
		contact_shadow_enabled = value
		_request_rebuild()
@export_range(10.0, 160.0, 1.0) var visibility_distance: float = 60.0:
	set(value):
		visibility_distance = clampf(value, 10, 160)
		_request_rebuild()
@export_group("Recall")
@export var recall_enabled: bool = false:
	set(value):
		recall_enabled = value
		if is_node_ready() and not Engine.is_editor_hint():
			_sync_recall()
@export_tool_button("Rebuild component") var regenerate = rebuild

var _queued: bool = false
var _generated_root: Node3D
var _material: ShaderMaterial
var _recall_effect: Node
var _collision_data: Array[Dictionary] = []
var _anchors: Dictionary = {}

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

func _config() -> Dictionary:
	return {"prop_seed": prop_seed, "body_color": body_color, "accent_color": accent_color, "trim_color": trim_color}

func _build_geometry() -> Dictionary:
	return {}

func _build_details() -> void:
	pass

func _apply_material() -> void:
	if _material:
		_material.set_shader_parameter("pigment_strength", pigment_strength)
		_material.set_shader_parameter("paint_phase", float(posmod(prop_seed, 997)) * 0.073)

func _add_visual(mesh_name: String, mesh: Mesh, material: Material = null) -> MeshInstance3D:
	var visual := MeshInstance3D.new()
	visual.name = mesh_name
	visual.mesh = mesh
	visual.material_override = _material if material == null else material
	visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	visual.visibility_range_end = visibility_distance
	_generated_root.add_child(visual)
	return visual

func rebuild() -> void:
	_queued = false
	if not is_inside_tree():
		return
	if is_instance_valid(_generated_root):
		remove_child(_generated_root)
		_generated_root.free()
	_generated_root = Node3D.new()
	_generated_root.name = "Generated"
	add_child(_generated_root, false, Node.INTERNAL_MODE_BACK)
	var data := _build_geometry()
	_collision_data.assign(data.get("colliders", []))
	_material = ShaderMaterial.new()
	_material.shader = PAINT
	_apply_material()
	var visual := _add_visual("PaintedProp", data.mesh)
	if collision_enabled and not _collision_data.is_empty():
		var body := StaticBody3D.new()
		body.name = "Collision"
		for info in _collision_data:
			var collider := CollisionShape3D.new()
			collider.name = info.name
			if info.has("points"):
				var shape := ConvexPolygonShape3D.new()
				shape.points = info.points
				collider.shape = shape
			else:
				var shape := BoxShape3D.new()
				shape.size = info.size
				collider.shape = shape
				collider.position = info.center
			body.add_child(collider, true)
		_generated_root.add_child(body)
	if contact_shadow_enabled:
		var bounds := visual.mesh.get_aabb()
		var plane := PlaneMesh.new()
		plane.size = Vector2(bounds.size.x * 1.15, bounds.size.z * 1.18)
		var paint := ShaderMaterial.new()
		paint.shader = CONTACT
		paint.set_shader_parameter("shadow_color", Color(0.31, 0.32, 0.31, 0.20))
		var shadow := _add_visual("ContactShadow", plane, paint)
		shadow.position = Vector3(bounds.get_center().x, 0.009, bounds.get_center().z)
	_anchors.clear()
	var hooks := Node3D.new()
	hooks.name = "Anchors"
	for key in data.get("anchors", {}):
		var marker := Marker3D.new()
		marker.name = key
		marker.position = data.anchors[key]
		hooks.add_child(marker)
		_anchors[StringName(key)] = marker
	_generated_root.add_child(hooks)
	_build_details()
	_sync_recall()
	ground_exclusion_changed.emit()

func get_anchor(id: StringName) -> Marker3D:
	return _anchors.get(id) as Marker3D

func get_recall_controller() -> Node:
	return _recall_effect

func _sync_recall() -> void:
	_recall_effect = RECALL.configure(self, "res://components/effects/recall/assembled_recall.gd", _recall_effect)
	if not recall_enabled:
		preload("res://components/effects/recall/assembled_recall.gd").restore_component(self)

func excludes_ground_point(world_point: Vector3) -> bool:
	var point := to_local(world_point)
	for info in _collision_data:
		if info.has("size"):
			var offset: Vector3 = point - info.center
			var half: Vector3 = info.size * 0.5
			if absf(offset.x) < half.x + 0.06 and absf(offset.z) < half.z + 0.06:
				return true
		elif info.has("points"):
			var bounds := AABB(info.points[0], Vector3.ZERO)
			for vertex: Vector3 in info.points:
				bounds = bounds.expand(vertex)
			if Rect2(Vector2(bounds.position.x, bounds.position.z), Vector2(bounds.size.x, bounds.size.z)).grow(0.06).has_point(Vector2(point.x, point.z)):
				return true
	return false
