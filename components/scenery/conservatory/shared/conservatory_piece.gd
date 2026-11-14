@tool
class_name PainterlyConservatoryPiece
extends PainterlyStadiumPiece
## Uses the existing batched scenery lifecycle, collision and assembled recall.
signal ground_exclusion_changed
const STONE_PAINT = preload("res://components/scenery/conservatory/shared/stone_paint.gdshader")
const CONTACT_PAINT = preload("res://shaders/contact_shadow.gdshader")
@export var collision_enabled: bool = true:
	set(value):
		collision_enabled = value
		_request_rebuild()

func _ready() -> void:
	set_notify_transform(true)
	super._ready()

func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSFORM_CHANGED and is_node_ready():
		ground_exclusion_changed.emit()

func rebuild() -> void:
	super.rebuild()
	if not is_inside_tree():
		return
	_material.shader = STONE_PAINT
	_build_layers()
	_sync_recall()
	ground_exclusion_changed.emit()

func _build_layers() -> void:
	pass

func _generated(node: Node) -> void:
	if node is GeometryInstance3D:
		node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		node.visibility_range_end = 70.0
	super._generated(node)

func _box_collision(id: String, center: Vector3, size: Vector3) -> void:
	if collision_enabled:
		super._box_collision(id, center, size)

func _contact(size: Vector2, at := Vector3.ZERO) -> void:
	var shadow := MeshInstance3D.new()
	shadow.name = "ContactShadow"
	var plane := PlaneMesh.new()
	plane.size = size
	shadow.mesh = plane
	var material := ShaderMaterial.new()
	material.shader = CONTACT_PAINT
	material.set_shader_parameter("shadow_color", Color(0.31, 0.32, 0.29, 0.23))
	shadow.material_override = material
	shadow.position = at + Vector3.UP * 0.012
	_generated(shadow)

func _anchor(id: String, at: Vector3, yaw: float = 0.0) -> void:
	var marker := Marker3D.new()
	marker.name = id
	marker.position = at
	marker.rotation.y = yaw
	_generated(marker)

func get_anchor(id: StringName) -> Marker3D:
	return get_node_or_null(NodePath(String(id))) as Marker3D
