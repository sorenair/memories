@tool
class_name PainterlyYardFence
extends Node3D
## A straight, ground-centered local-X span. The mesh occupies the local XY plane.
const PAINT := preload("res://components/scenery/fences/painted_metal.gdshader")
@export_range(0.5, 20.0, 0.1) var length: float = 4.0:
	set(value):
		length = clampf(value, 0.5, 20.0)
		_request_rebuild()
@export_range(0.4, 2.0, 0.05) var height: float = 0.95:
	set(value):
		height = clampf(value, 0.4, 2.0)
		_request_rebuild()
@export_range(0.8, 3.0, 0.1) var post_spacing: float = 2.0:
	set(value):
		post_spacing = clampf(value, 0.8, 3.0)
		_request_rebuild()
## Vertical distance between same-direction wires; gives the diamond scale.
@export_range(0.12, 0.4, 0.01) var diamond_size: float = 0.18:
	set(value):
		diamond_size = clampf(value, 0.12, 0.4)
		_request_rebuild()
@export_range(0.004, 0.015, 0.001) var wire_radius: float = 0.007:
	set(value):
		wire_radius = clampf(value, 0.004, 0.015)
		_request_rebuild()
@export_range(0.02, 0.06, 0.002) var post_radius: float = 0.028:
	set(value):
		post_radius = clampf(value, 0.02, 0.06)
		_request_rebuild()
@export var wire_color := Color("b8beb3"):
	set(value):
		wire_color = value
		_request_rebuild()
@export var post_color := Color("c9ccc1"):
	set(value):
		post_color = value
		_request_rebuild()
@export var collision_enabled: bool = true:
	set(value):
		collision_enabled = value
		_request_rebuild()
@export_tool_button("Regenerate fence") var regenerate = rebuild
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
	rebuild()

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
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var bottom := 0.09
	var top := height - 0.055
	var span := top - bottom
	# Both wire families are analytically clipped to the panel rectangle. There
	# are no transparent cards, so the edge silhouette remains clean up close.
	for slope in [-1.0, 1.0]:
		var first := -length if slope > 0 else 0.0
		var last := span if slope > 0 else span + length
		var start := floorf(first / diamond_size) * diamond_size
		var count := ceili((last - start) / diamond_size)
		for index in range(count + 1):
			var intercept := start + float(index) * diamond_size
			var x0 := maxf(0.0, -intercept) if slope > 0 else maxf(0.0, intercept - span)
			var x1 := minf(length, span - intercept) if slope > 0 else minf(length, intercept)
			if x1 - x0 < 0.01:
				continue
			var a := Vector3(x0 - length * 0.5, bottom + slope * x0 + intercept, 0)
			var b := Vector3(x1 - length * 0.5, bottom + slope * x1 + intercept, 0)
			var tint := 0.018 * sin(float(index) * 1.7 + slope)
			var color := wire_color.lightened(maxf(0, tint)).darkened(maxf(0, -tint))
			_rod(surface, a, b, wire_radius, color, 4)
	var bays := maxi(1, ceili(length / post_spacing))
	for index in range(bays + 1):
		var x := lerpf(-length * 0.5, length * 0.5, float(index) / bays)
		_rod(surface, Vector3(x, 0.0, 0), Vector3(x, height, 0), post_radius, post_color, 8, true)
		_cap(surface, Vector3(x, height, 0), post_radius * 1.18, post_color)
	_rod(surface, Vector3(-length * 0.5, top, 0), Vector3(length * 0.5, top, 0), post_radius * 0.67, post_color, 6)
	_rod(surface, Vector3(-length * 0.5, bottom, 0), Vector3(length * 0.5, bottom, 0), wire_radius * 1.2, wire_color, 4)
	var mesh := MeshInstance3D.new()
	mesh.name = "Fence"
	mesh.mesh = surface.commit()
	var material := ShaderMaterial.new()
	material.shader = PAINT
	mesh.material_override = material
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_add_generated(mesh)
	if collision_enabled:
		var body := StaticBody3D.new()
		body.name = "FenceCollision"
		var collision := CollisionShape3D.new()
		collision.name = "CollisionShape3D"
		var shape := BoxShape3D.new()
		shape.size = Vector3(length, height, maxf(0.08, post_radius * 2.0))
		collision.shape = shape
		collision.position.y = height * 0.5
		body.add_child(collision)
		_add_generated(body)
	_sync_recall()

func _add_generated(node: Node) -> void:
	add_child(node, false, Node.INTERNAL_MODE_BACK)
	_generated.append(node)

func _rod(surface: SurfaceTool, a: Vector3, b: Vector3, radius: float, color: Color, sides: int, cap: bool = false) -> void:
	var axis := (b - a).normalized()
	var side := axis.cross(Vector3.BACK).normalized()
	if side.length_squared() < 0.1:
		side = axis.cross(Vector3.UP).normalized()
	var up := axis.cross(side).normalized()
	for segment in range(sides):
		var angle0 := float(segment) * TAU / sides
		var angle1 := float(segment + 1) * TAU / sides
		var n0 := side * cos(angle0) + up * sin(angle0)
		var n1 := side * cos(angle1) + up * sin(angle1)
		var p0 := a + n0 * radius
		var p1 := a + n1 * radius
		var q0 := b + n0 * radius
		var q1 := b + n1 * radius
		_triangle(surface, p0, q0, q1, n0, n0, n1, color)
		_triangle(surface, p0, q1, p1, n0, n1, n1, color)
		if cap:
			_triangle(surface, a, p1, p0, -axis, -axis, -axis, color)

func _cap(surface: SurfaceTool, center: Vector3, radius: float, color: Color) -> void:
	# A small rounded cap softens the post silhouette without ornate hardware.
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 1.4
	mesh.radial_segments = 8
	mesh.rings = 4
	var arrays := mesh.surface_get_arrays(0)
	var points: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	for index in indices:
		surface.set_normal(normals[index])
		surface.set_color(color.srgb_to_linear())
		surface.add_vertex(center + points[index])

func _triangle(surface: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, na: Vector3, nb: Vector3, nc: Vector3, color: Color) -> void:
	var points: Array[Vector3] = [a, b, c]
	var normals: Array[Vector3] = [na, nb, nc]
	for index in range(3):
		surface.set_normal(normals[index])
		surface.set_color(color.srgb_to_linear())
		surface.add_vertex(points[index])
