@tool
class_name PainterlyStreet
extends Node3D
## Continuous asphalt along local Z, with worn pigment dissolving into the void.
signal ground_exclusion_changed
const PAINT = preload("res://components/groundcover/street/painted_street.gdshader")
@export_range(2.0,200.0,0.5) var length := 42.0:
	set(value):
		length = clampf(value,2,200)
		_request_rebuild()
@export_range(2.0,24.0,0.1) var width := 9.4:
	set(value):
		width = clampf(value,2,24)
		_request_rebuild()
@export var asphalt_color := Color("a2aba7"):
	set(value):
		asphalt_color = value
		_update_material()
@export var street_seed := 42526:
	set(value):
		street_seed = value
		_update_material()
@export var end_fade := Vector2(3.0,3.0):
	set(value):
		end_fade = value.max(Vector2.ZERO)
		_update_material()
@export_range(0.05,1.0,0.05) var edge_softness := 0.35:
	set(value):
		edge_softness = clampf(value,0.05,1.0)
		_update_material()
@export var collision_enabled := true:
	set(value):
		collision_enabled = value
		_request_rebuild()
@export_tool_button("Regenerate street") var regenerate = rebuild
var _queued := false
var _material: ShaderMaterial

func _ready() -> void:
	set_notify_transform(true)
	rebuild()

func _notification(what: int) -> void:
	if what==NOTIFICATION_TRANSFORM_CHANGED and is_node_ready(): ground_exclusion_changed.emit()

func _request_rebuild() -> void:
	if is_inside_tree() and not _queued:
		_queued = true
		_rebuild_queued.call_deferred()

func _rebuild_queued() -> void:
	if _queued: rebuild()

func _update_material() -> void:
	if _material:
		_material.set_shader_parameter("footprint",Vector2(width,length))
		_material.set_shader_parameter("asphalt_color",asphalt_color)
		_material.set_shader_parameter("end_fade",end_fade)
		_material.set_shader_parameter("edge_softness",edge_softness)
		_material.set_shader_parameter("paint_phase",float(posmod(street_seed,997))*0.071)
	ground_exclusion_changed.emit()

func rebuild() -> void:
	_queued = false
	if not is_inside_tree(): return
	for child in get_children(true):
		if child.get_meta(&"street_generated",false):
			remove_child(child)
			child.free()
	var surface := MeshInstance3D.new()
	surface.name = "Asphalt"
	var mesh := PlaneMesh.new()
	mesh.size = Vector2(width,length)
	surface.mesh = mesh
	surface.position.y = 0.0125
	surface.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_material = ShaderMaterial.new()
	_material.shader = PAINT
	_update_material()
	surface.material_override = _material
	_generated(surface)
	if collision_enabled:
		var body := StaticBody3D.new()
		body.name = "WalkingSurface"
		var collider := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = Vector3(width,0.025,length)
		collider.shape = shape
		body.add_child(collider)
		_generated(body)
	ground_exclusion_changed.emit()

func _generated(node: Node) -> void:
	node.set_meta(&"street_generated",true)
	add_child(node,false,Node.INTERNAL_MODE_BACK)

func excludes_ground_point(world_point: Vector3) -> bool:
	var p := to_local(world_point)
	return absf(p.x)<width*0.5-edge_softness*0.5 and p.z>-length*0.5+end_fade.x*0.5 and p.z<length*0.5-end_fade.y*0.5
