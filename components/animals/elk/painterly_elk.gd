@tool
class_name PainterlyElk
extends PainterlyConcertComponent
## A single standing/grazing elk. Root at hooves, front +Z; idles run on the GPU.
const ELK_GEOMETRY = preload("res://components/animals/elk/elk_geometry.gd")
const ELK_PAINT = preload("res://components/animals/elk/elk.gdshader")

@export_group("Elk")
@export_enum("Bull", "Cow", "Calf", "Young Bull") var elk_type: int = 0:
	set(value):
		elk_type = clampi(value,0,3)
		_request_rebuild()
@export_range(0.5,1.6,0.05) var elk_size: float = 1.0:
	set(value):
		elk_size = clampf(value,0.5,1.6)
		_request_rebuild()
@export_range(0.5,1.5,0.05) var antler_size: float = 1.0:
	set(value):
		antler_size = clampf(value,0.5,1.5)
		_request_rebuild()
@export_range(0.6,1.6,0.05) var antler_spread: float = 1.0:
	set(value):
		antler_spread = clampf(value,0.6,1.6)
		_request_rebuild()
@export var antler_color := Color("c5b38f"):
	set(value):
		antler_color = value
		_request_rebuild()
@export_group("Idle")
## Cycle through scanning and grazing while keeping the preferred pose as a bias.
@export var varied_idle := false:
	set(value):
		varied_idle = value
		_apply_material()
@export_enum("Relaxed", "Alert", "Grazing") var idle_pose: int = 0:
	set(value):
		idle_pose = clampi(value,0,2)
		_apply_material()
@export_range(0.0,1.5,0.05) var idle_motion: float = 0.7:
	set(value):
		idle_motion = clampf(value,0,1.5)
		_apply_material()
@export_range(0.0,2.0,0.05) var idle_speed: float = 1.0:
	set(value):
		idle_speed = clampf(value,0,2)
		_apply_material()
var _visual_time: float = -1.0
var _elk_data: Dictionary

func _init() -> void:
	body_color = Color("b29a73")
	accent_color = Color("635346")
	trim_color = Color("d7c7a4")

func _config() -> Dictionary:
	var c := super._config()
	c.merge({"elk_type":elk_type,"elk_size":elk_size,"antler_size":antler_size,"antler_spread":antler_spread,"antler_color":antler_color})
	return c

func _build_geometry() -> Dictionary:
	_elk_data = ELK_GEOMETRY.new().elk(_config())
	return _elk_data

func _apply_material() -> void:
	if not _material: return
	_material.shader = ELK_PAINT
	super._apply_material()
	_material.set_shader_parameter("varied_idle",varied_idle)
	_material.set_shader_parameter("idle_motion",idle_motion)
	_material.set_shader_parameter("idle_speed",idle_speed)
	_material.set_shader_parameter("pose_mode",idle_pose)
	_material.set_shader_parameter("animation_time",_visual_time)

func _build_details() -> void:
	_generated_root.get_node("PaintedProp").custom_aabb = _elk_data.bounds
	if contact_shadow_enabled:
		var shadow: MeshInstance3D = _generated_root.get_node("ContactShadow")
		var m: Vector3 = _elk_data.morph
		shadow.mesh.size = Vector2(1.0*m.x,2.30*m.z)
		shadow.position = Vector3(0,0.012,-0.15*m.z)

## Negative resumes live shader time. Useful for deterministic visual previews.
func seek_time(seconds: float) -> void:
	_visual_time = seconds
	_apply_material()
