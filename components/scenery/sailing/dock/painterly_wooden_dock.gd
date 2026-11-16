@tool
class_name PainterlyWoodenDock
extends PainterlyConcertComponent
## Root is the water/shore datum. The shore-facing end is local +Z.
const BUILDER = preload("res://components/scenery/sailing/shared/sailing_geometry.gd")
const DOCK_PAINT = preload("res://components/scenery/sailing/shared/sailing_paint.gdshader")
@export_group("Dock")
@export_enum("Straight", "T Landing", "L Landing") var layout: int = 1:
	set(value):
		layout = clampi(value, 0, 2)
		_request_rebuild()
@export_range(3.0, 16.0, 0.25) var dock_length: float = 8.0:
	set(value):
		dock_length = clampf(value, 3, 16)
		_request_rebuild()
@export_range(1.4, 3.0, 0.1) var dock_width: float = 2.0:
	set(value):
		dock_width = clampf(value, 1.4, 3)
		_request_rebuild()
@export_range(3.5, 9.0, 0.25) var head_width: float = 5.0:
	set(value):
		head_width = clampf(value, 3.5, 9)
		_request_rebuild()
@export_range(0.2, 1.0, 0.05) var deck_height: float = 0.55:
	set(value):
		deck_height = clampf(value, 0.2, 1)
		_request_rebuild()
@export_range(0.3, 2.5, 0.1) var pile_depth: float = 1.1:
	set(value):
		pile_depth = clampf(value, 0.3, 2.5)
		_request_rebuild()
@export_enum("None", "Left", "Right", "Both") var rail_sides: int = 0:
	set(value):
		rail_sides = clampi(value, 0, 3)
		_request_rebuild()
@export_group("Shore Access")
@export var ramp_enabled: bool = true:
	set(value):
		ramp_enabled = value
		_request_rebuild()
@export_range(1.5, 4.5, 0.25) var ramp_length: float = 2.5:
	set(value):
		ramp_length = clampf(value, 1.5, 4.5)
		_request_rebuild()

func _build_geometry() -> Dictionary:
	var c := _config()
	c.merge({"layout": layout, "dock_length": dock_length, "dock_width": dock_width, "head_width": head_width, "deck_height": deck_height, "pile_depth": pile_depth, "rail_sides": rail_sides, "ramp_enabled": ramp_enabled, "ramp_length": ramp_length})
	return BUILDER.new().dock(c)

func _apply_material() -> void:
	if _material:
		_material.shader = DOCK_PAINT
		super._apply_material()
	if _material:
		_material.set_shader_parameter("bob_amount", 0.0)
		_material.set_shader_parameter("wind_strength", 0.0)
		_material.set_shader_parameter("motion_speed", 0.0)
