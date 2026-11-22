@tool
class_name PainterlyMountainGoat
extends PainterlyConcertComponent
## Ground-level root, front +Z. One painted mesh; light idles run on the GPU.
const GOAT_GEOMETRY = preload("res://components/animals/mountain_goat/mountain_goat_geometry.gd")
const GOAT_PAINT = preload("res://components/animals/mountain_goat/mountain_goat.gdshader")

@export_group("Mountain Goat")
@export_range(0.5,1.5,0.05) var goat_size: float = 1.0:
	set(value):
		goat_size = clampf(value,0.5,1.5)
		_request_rebuild()
@export_range(0.0,1.0,0.05) var fluffiness: float = 0.75:
	set(value):
		fluffiness = clampf(value,0,1)
		_request_rebuild()
@export_range(0.6,1.4,0.05) var horn_length: float = 1.0:
	set(value):
		horn_length = clampf(value,0.6,1.4)
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
@export_range(0.0,1.5,0.05) var idle_motion: float = 0.65:
	set(value):
		idle_motion = clampf(value,0,1.5)
		_apply_material()
@export_range(0.0,2.0,0.05) var idle_speed: float = 1.0:
	set(value):
		idle_speed = clampf(value,0,2)
		_apply_material()

var _visual_time: float = -1.0
var _goat_data: Dictionary

func _init() -> void:
	body_color = Color("f5f3eb")
	accent_color = Color("c3cdc9")
	trim_color = Color("343c3a")

func _config() -> Dictionary:
	var c := super._config()
	c.merge({"goat_size":goat_size,"fluffiness":fluffiness,"horn_length":horn_length})
	return c

func _build_geometry() -> Dictionary:
	_goat_data = GOAT_GEOMETRY.new().goat(_config())
	return _goat_data

func _apply_material() -> void:
	if not _material: return
	_material.shader = GOAT_PAINT
	super._apply_material()
	_material.set_shader_parameter("varied_idle",varied_idle)
	_material.set_shader_parameter("idle_motion",idle_motion)
	_material.set_shader_parameter("idle_speed",idle_speed)
	_material.set_shader_parameter("pose_mode",idle_pose)
	_material.set_shader_parameter("animation_time",_visual_time)
	_material.set_shader_parameter("neck_pivot",Vector3(0,0.82,0.30))
	_material.set_shader_parameter("neck_blend",Vector2(0.84,1.37))
	_material.set_shader_parameter("ear_pivot",Vector3(0.115,1.485,0.855))
	_material.set_shader_parameter("tail_pivot",Vector3(0,0.98,-0.79))
	_material.set_shader_parameter("jaw_pivot",Vector3(0,1.29,1.04))
	_material.set_shader_parameter("breath_height",Vector2(0.35,1.0))
	_material.set_shader_parameter("grazing_angle",1.15)
	_material.set_shader_parameter("alert_angle",-0.075)

func _build_details() -> void:
	_generated_root.get_node("PaintedProp").custom_aabb = _goat_data.bounds
	if contact_shadow_enabled:
		var shadow: MeshInstance3D = _generated_root.get_node("ContactShadow")
		var m: Vector3 = _goat_data.morph
		shadow.mesh.size = Vector2(1.12*m.x,1.95*m.z)
		shadow.position = Vector3(0,0.012,-0.12*m.z)

func seek_time(seconds: float) -> void:
	_visual_time = seconds
	_apply_material()
