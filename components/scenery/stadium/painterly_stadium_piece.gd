@tool
class_name PainterlyStadiumPiece
extends Node3D
## Shared batched mesh authoring, using First Meeting's vertex-painted geometry builder.
const GEOMETRY = preload("res://components/activities/arcade/shared/arcade_geometry.gd")
const PAINT = preload("res://components/scenery/stadium/stadium_paint.gdshader")

@export var paint_seed: int = 112:
	set(value):
		paint_seed = value
		_request_rebuild()
@export_range(0.0, 1.0, 0.05) var pigment_strength := 0.65:
	set(value):
		pigment_strength = value
		_request_rebuild()
@export_tool_button("Regenerate scenery") var regenerate = rebuild
var _queued := false
var _material: ShaderMaterial

func _ready() -> void:
	rebuild()

func _request_rebuild() -> void:
	if is_inside_tree() and not _queued:
		_queued = true
		_rebuild_queued.call_deferred()

func _rebuild_queued() -> void:
	if _queued:
		rebuild()

func rebuild() -> void:
	_queued = false
	if not is_inside_tree():
		return
	for child in get_children(true):
		if child.get_meta(&"stadium_generated", false):
			remove_child(child)
			child.free()
	var builder := GEOMETRY.new()
	builder.s = SurfaceTool.new()
	builder.s.begin(Mesh.PRIMITIVE_TRIANGLES)
	builder.s.set_uv(Vector2.ZERO)
	builder.rng.seed = paint_seed
	_material = ShaderMaterial.new()
	_material.shader = PAINT
	_material.set_shader_parameter("pigment_strength", pigment_strength)
	_material.set_shader_parameter("paint_phase", float(posmod(paint_seed, 997)) * 0.073)
	_build(builder)
	var mesh := MeshInstance3D.new()
	mesh.name = "Visual"
	mesh.mesh = builder.s.commit()
	mesh.material_override = _material
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_generated(mesh)

func _build(_builder: RefCounted) -> void:
	pass

func _generated(node: Node) -> void:
	node.set_meta(&"stadium_generated", true)
	add_child(node, false, Node.INTERNAL_MODE_BACK)

func _box_collision(id: String, center: Vector3, size: Vector3) -> void:
	var body := StaticBody3D.new()
	body.name = id
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	body.position = center
	body.add_child(collision)
	_generated(body)
