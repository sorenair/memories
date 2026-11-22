@tool
class_name PainterlyEnsign
extends PainterlyConcertComponent
## Shared scenic sailboat controls. Origin is waterline; bow is local +Z.
const BUILDER = preload("res://components/scenery/sailing/shared/sailing_geometry.gd")
const BOAT_PAINT = preload("res://components/scenery/sailing/shared/sailing_paint.gdshader")
@export_group("Hull Proportions")
@export_enum("Pearson Ensign", "Club 420") var hull_style: int = 0:
	set(value):
		hull_style = value
		_request_rebuild()
		notify_property_list_changed()
@export_range(3.8, 8.0, 0.05) var hull_length: float = 6.86:
	set(value):
		hull_length = clampf(value, 3.8, 8)
		_request_rebuild()
@export_range(1.45, 2.6, 0.05) var beam: float = 2.13:
	set(value):
		beam = clampf(value, 1.45, 2.6)
		_request_rebuild()
@export_range(5.0, 9.5, 0.1) var mast_height: float = 7.9:
	set(value):
		mast_height = clampf(value, 5, 9.5)
		_request_rebuild()
@export_group("Boat Colors")
@export var hull_color := Color("e4e2cf"):
	set(value):
		hull_color = value
		_request_rebuild()
@export var deck_color := Color("e9e3ce"):
	set(value):
		deck_color = value
		_request_rebuild()
@export var keel_color := Color("698b91"):
	set(value):
		keel_color = value
		_request_rebuild()
@export var sail_color := Color("f2ebd6"):
	set(value):
		sail_color = value
		_request_rebuild()
@export var wood_color := Color("a17d56"):
	set(value):
		wood_color = value
		_request_rebuild()
@export_group("Sails and Fittings")
@export var sails_enabled: bool = true:
	set(value):
		sails_enabled = value
		_request_rebuild()
@export_range(-35.0, 35.0, 1.0) var sail_angle: float = 18.0:
	set(value):
		sail_angle = clampf(value, -35, 35)
		_request_rebuild()
@export_range(0.05, 0.5, 0.025) var sail_fullness: float = 0.26:
	set(value):
		sail_fullness = clampf(value, 0.05, 0.5)
		_request_rebuild()
@export var fenders_enabled: bool = true:
	set(value):
		fenders_enabled = value
		_request_rebuild()
@export_group("Lake Motion")
@export_range(0.0, 0.08, 0.005) var wind_strength: float = 0.035:
	set(value):
		wind_strength = clampf(value, 0, 0.08)
		_update_motion()
@export_range(0.0, 0.06, 0.005) var bob_amount: float = 0.025:
	set(value):
		bob_amount = clampf(value, 0, 0.06)
		_update_motion()
@export_range(0.0, 2.0, 0.05) var motion_speed: float = 1.0:
	set(value):
		motion_speed = clampf(value, 0, 2)
		_update_motion()
var _visual_time: float = -1.0

func _boat_config() -> Dictionary:
	var c := _config()
	c.merge({"dinghy": hull_style == 1, "hull_length": hull_length, "beam": beam, "mast_height": mast_height, "hull_color": hull_color, "deck_color": deck_color, "keel_color": keel_color, "sail_color": sail_color, "wood_color": wood_color, "sail_angle": sail_angle, "sail_fullness": sail_fullness, "fenders_enabled": fenders_enabled})
	return c

func _validate_property(property: Dictionary) -> void:
	if property.name == "body_color" or (property.name == "accent_color" and hull_style == 0):
		property.usage &= ~PROPERTY_USAGE_EDITOR

func _build_geometry() -> Dictionary:
	var builder := BUILDER.new()
	var config := _boat_config()
	return builder.dinghy(config) if hull_style == 1 else builder.hull(config)

func _build_details() -> void:
	_add_visual("Rigging", BUILDER.new().rig(_boat_config()).mesh)
	if sails_enabled:
		_add_visual("Sails", BUILDER.new().sails(_boat_config()).mesh)
	for child in _generated_root.get_children():
		if child is MeshInstance3D and child.name != "ContactShadow":
			child.custom_aabb = child.mesh.get_aabb().grow(0.4)

func _apply_material() -> void:
	if _material:
		_material.shader = BOAT_PAINT
		super._apply_material()
	_update_motion()

func _update_motion() -> void:
	if _material:
		_material.set_shader_parameter("wind_strength", wind_strength)
		_material.set_shader_parameter("bob_amount", bob_amount)
		_material.set_shader_parameter("motion_speed", motion_speed)
		_material.set_shader_parameter("animation_time", _visual_time)

func seek_time(seconds: float) -> void:
	_visual_time = seconds
	_update_motion()
