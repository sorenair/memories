@tool
class_name PainterlyArcadeComponent
extends Node3D
## Reusable painted activity scenery. Generated base visuals and collision stay internal.
signal ground_exclusion_changed
const GEOMETRY = preload("res://components/activities/arcade/shared/arcade_geometry.gd")
const CONTACT_SHADOW = preload("res://shaders/contact_shadow.gdshader")
const PAINT = preload("res://components/activities/arcade/shared/arcade_paint.gdshader")

@export_group("Dimensions")
@export_range(0.6, 1.8, 0.05) var prop_scale: float = 1.0:
	set(value):
		prop_scale = clampf(value, 0.6, 1.8)
		_request_rebuild()
@export_group("Paint")
@export var cabinet_color := Color("526d70"):
	set(value):
		cabinet_color = value
		_request_rebuild()
@export var accent_color := Color("c58267"):
	set(value):
		accent_color = value
		_request_rebuild()
@export var metal_color := Color("c1a575"):
	set(value):
		metal_color = value
		_request_rebuild()
@export var cream_color := Color("eee4cd"):
	set(value):
		cream_color = value
		_request_rebuild()
@export_range(0.0, 1.0, 0.05) var pigment_strength: float = 0.65:
	set(value):
		pigment_strength = clampf(value, 0, 1)
		_update_material()
@export var prop_seed: int = 42:
	set(value):
		prop_seed = value
		_request_rebuild()
@export_group("Placement")
@export var collision_enabled: bool = true:
	set(value):
		collision_enabled = value
		_request_rebuild()
@export_tool_button("Regenerate component") var regenerate = rebuild
var _queued := false
var _material: ShaderMaterial
var _outline_mesh: Mesh
var _collision_boxes: Array[Dictionary] = []
var _anchors: Dictionary = {}

func _kind() -> StringName:
	return &"pinball"

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
	set_process(false)
	set_physics_process(false)

func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSFORM_CHANGED and is_node_ready():
		ground_exclusion_changed.emit()

func _request_rebuild() -> void:
	if is_inside_tree() and not _queued:
		_queued = true
		call_deferred("_rebuild_queued")

func _rebuild_queued() -> void:
	if _queued: rebuild()

func _update_material() -> void:
	if _material:
		_material.set_shader_parameter("pigment_strength", pigment_strength)
		_material.set_shader_parameter("paint_phase", float(posmod(prop_seed,997))*0.073)

func rebuild() -> void:
	_queued = false
	if not is_inside_tree(): return
	for child in get_children(true):
		if child.get_meta(&"arcade_generated",false):
			remove_child(child)
			child.free()
	var config := {"cabinet_color":cabinet_color,"accent_color":accent_color,"metal_color":metal_color,"cream_color":cream_color,"prop_seed":prop_seed}
	var result: Dictionary = GEOMETRY.new().create(_kind(),config)
	_outline_mesh = result.get("outline_mesh")
	_collision_boxes.assign(result.colliders)
	_material = ShaderMaterial.new()
	_material.shader = PAINT
	_update_material()
	var visual := MeshInstance3D.new()
	visual.name = "Visual"
	visual.mesh = result.mesh
	visual.material_override = _material
	visual.scale = Vector3.ONE * prop_scale
	visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_generated(visual)
	if _kind() != &"bar_corner":
		var bounds: AABB = visual.mesh.get_aabb()
		var shadow := MeshInstance3D.new()
		shadow.name = "ContactShadow"
		var plane := PlaneMesh.new()
		plane.size = Vector2(bounds.size.x*1.35,bounds.size.z*1.35)*prop_scale
		shadow.mesh = plane
		shadow.position = Vector3(bounds.get_center().x*prop_scale,0.008,bounds.get_center().z*prop_scale)
		var shadow_material := ShaderMaterial.new()
		shadow_material.shader = CONTACT_SHADOW
		shadow_material.set_shader_parameter("shadow_color",Color(0.20,0.18,0.16,0.22))
		shadow.material_override = shadow_material
		shadow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_generated(shadow)
	if collision_enabled:
		var body := StaticBody3D.new()
		body.name = "Collision"
		for info in _collision_boxes:
			var shape := BoxShape3D.new()
			shape.size = info.size * prop_scale
			var collider := CollisionShape3D.new()
			collider.name = info.name
			collider.position = info.center * prop_scale
			collider.shape = shape
			body.add_child(collider,true)
		_generated(body)
	var mount := Node3D.new()
	mount.name = "Anchors"
	_anchors.clear()
	for key in result.anchors:
		var marker := Marker3D.new()
		marker.name = key
		marker.position = result.anchors[key] * prop_scale
		mount.add_child(marker)
		_anchors[StringName(key)] = marker
	_generated(mount)
	_build_details(result)
	_sync_recall()
	ground_exclusion_changed.emit()

func _build_details(_result: Dictionary) -> void:
	pass

func _generated(node: Node) -> void:
	node.set_meta(&"arcade_generated",true)
	add_child(node,false,Node.INTERNAL_MODE_BACK)

## Stable, named placement hooks; these do not implement interaction or play sound.
func get_anchor(id: StringName) -> Marker3D:
	return _anchors.get(id) as Marker3D

func get_interaction_outline_meshes() -> Array[MeshInstance3D]:
	var result: Array[MeshInstance3D] = []
	for path in ["Visual", "Ball", "BagSwing/LeatherBag"]:
		var mesh := get_node_or_null(path) as MeshInstance3D
		if mesh: result.append(mesh)
	return result

func get_interaction_outline_mesh(source: MeshInstance3D) -> Mesh:
	# Outline the cabinet silhouette, not every painted decoration and bumper.
	return _outline_mesh if source.name == &"Visual" and _outline_mesh else source.mesh

func excludes_ground_point(world_point: Vector3) -> bool:
	var point := to_local(world_point) / prop_scale
	for info in _collision_boxes:
		var center: Vector3 = info.center
		var half: Vector3 = info.size * 0.5
		if absf(point.x-center.x) <= half.x+0.04 and absf(point.z-center.z) <= half.z+0.04:
			return true
	return false
