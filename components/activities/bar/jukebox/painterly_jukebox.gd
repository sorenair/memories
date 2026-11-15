@tool
class_name PainterlyJukebox
extends PainterlyArcadeComponent
## Modern electronic cabinet with an opaque shader-driven portrait music display.
const BAR_GEOMETRY = preload("res://components/activities/bar/shared/bar_geometry.gd")
const DISPLAY = preload("res://components/activities/bar/jukebox/jukebox_display.gdshader")
@export_group("Electronic Display")
@export var screen_title: String = "MUSIC":
	set(value):
		screen_title = value.left(12)
		_request_rebuild()
@export var screen_accent := Color("78c8bc"):
	set(value):
		screen_accent = value
		_update_screen()
@export_range(0.0, 2.0, 0.05) var animation_speed: float = 1.0:
	set(value):
		animation_speed = clampf(value, 0, 2)
		_update_screen()
@export_range(0.0, 1.5, 0.05) var screen_brightness: float = 1.0:
	set(value):
		screen_brightness = clampf(value, 0, 1.5)
		_update_screen()
var _screen_material: ShaderMaterial
var _visual_time: float = -1.0

func _kind() -> StringName:
	return &"electronic_jukebox"

func _build_geometry() -> Dictionary:
	return BAR_GEOMETRY.new().jukebox({"cabinet_color": cabinet_color, "accent_color": accent_color, "metal_color": metal_color, "cream_color": cream_color, "prop_seed": prop_seed, "screen_title": screen_title})

func _build_details(_result: Dictionary) -> void:
	_screen_material = ShaderMaterial.new()
	_screen_material.shader = DISPLAY
	_update_screen()
	var screen := MeshInstance3D.new()
	screen.name = "MusicDisplay"
	var quad := QuadMesh.new()
	quad.size = Vector2(0.58, 0.76)
	screen.mesh = quad
	screen.material_override = _screen_material
	screen.position = Vector3(0, 1.16, 0.211) * prop_scale
	screen.scale = Vector3.ONE * prop_scale
	screen.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_generated(screen)

func _update_screen() -> void:
	if _screen_material:
		_screen_material.set_shader_parameter("accent_color", screen_accent)
		_screen_material.set_shader_parameter("animation_speed", animation_speed)
		_screen_material.set_shader_parameter("brightness", screen_brightness)
		_screen_material.set_shader_parameter("animation_time", _visual_time)

func seek_time(seconds: float) -> void:
	_visual_time = seconds
	_update_screen()
