@tool
class_name PainterlyLightPattern
extends Node3D
## Local animated light for paint shaders using painted_light.gdshaderinc.
## Local +Z faces the source. Assign meshes or component roots to one pattern each.

@export var receivers: Array[Node3D] = []:
	set(value):
		receivers = value
		_queue_update()
@export_enum("Leaf Dapple", "Color Spill", "Canopy Shade") var pattern: int = 0:
	set(value):
		pattern = value
		_queue_update()
## Full width, height and depth along the local axes.
@export var footprint := Vector3(6.0, 4.0, 8.0):
	set(value):
		footprint = value.max(Vector3.ONE * 0.1)
		_queue_update()
@export var light_color := Color("ffe2a0"):
	set(value):
		light_color = value
		_queue_update()
## Leaf shadow tint or the second color of a spill.
@export var accent_color := Color("a8897d"):
	set(value):
		accent_color = value
		_queue_update()
@export_range(0.0, 1.0, 0.01) var strength := 0.65:
	set(value):
		strength = value
		_queue_update()
@export_range(0.1, 8.0, 0.05, "suffix:/m") var pattern_scale := 2.3:
	set(value):
		pattern_scale = value
		_queue_update()
@export_range(0.0, 3.0, 0.05) var motion_speed := 0.75:
	set(value):
		motion_speed = value
		_queue_update()

var _listening_to: Array[Node3D] = []
var _meshes: Array[MeshInstance3D] = []
var _update_queued := false

func _enter_tree() -> void:
	set_notify_transform(true)
	_queue_update()

func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSFORM_CHANGED or what == NOTIFICATION_VISIBILITY_CHANGED:
		_queue_update()

func _exit_tree() -> void:
	_reset_meshes()
	_disconnect_receivers()

func _queue_update() -> void:
	if is_inside_tree() and not _update_queued:
		_update_queued = true
		_apply.call_deferred()

func _disconnect_receivers() -> void:
	for receiver in _listening_to:
		if is_instance_valid(receiver):
			receiver.child_order_changed.disconnect(_queue_update)
	_listening_to.clear()

func _reset_meshes() -> void:
	for mesh in _meshes:
		if is_instance_valid(mesh):
			mesh.set_instance_shader_parameter(&"painted_light_settings", null)
	_meshes.clear()

func _apply() -> void:
	_update_queued = false
	if not is_inside_tree():
		return
	_reset_meshes()
	_disconnect_receivers()
	for receiver in receivers:
		if is_instance_valid(receiver) and receiver.is_inside_tree() and not _listening_to.has(receiver):
			_listening_to.append(receiver)
			receiver.child_order_changed.connect(_queue_update)
			_collect_meshes(receiver)
	var basis := global_basis.orthonormalized()
	var axes := [basis.x, basis.y, basis.z]
	var axis_names := [&"painted_light_x", &"painted_light_y", &"painted_light_z"]
	var settings := Vector4(strength if is_visible_in_tree() else 0.0, pattern_scale, motion_speed, pattern)
	for mesh in _meshes:
		mesh.set_instance_shader_parameter(&"painted_light_settings", settings)
		mesh.set_instance_shader_parameter(&"painted_light_origin", global_position)
		for index in axes.size():
			var axis: Vector3 = axes[index]
			var extent := footprint[index] * global_basis[index].length() * 0.5
			mesh.set_instance_shader_parameter(axis_names[index], Vector4(axis.x, axis.y, axis.z, 1.0 / maxf(extent, 0.05)))
		mesh.set_instance_shader_parameter(&"painted_light_color", light_color)
		mesh.set_instance_shader_parameter(&"painted_light_accent", accent_color)

func _collect_meshes(node: Node3D) -> void:
	if node is MeshInstance3D and node.mesh and not _meshes.has(node):
		_meshes.append(node)
	for child in node.get_children(true):
		if child is Node3D:
			_collect_meshes(child)
