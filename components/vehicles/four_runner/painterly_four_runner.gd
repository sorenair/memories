@tool
class_name PainterlyFourRunner
extends PainterlyCampingComponent
## Gray 2018-generation parked 4Runner exterior; front is local +Z.
const BUILDER = preload("res://components/vehicles/four_runner/four_runner_geometry.gd")
@export_group("4Runner Details")
@export var roof_rack_enabled: bool = true:
	set(value):
		roof_rack_enabled = value
		_request_rebuild()
@export var headlights_enabled: bool = false:
	set(value):
		headlights_enabled = value
		_update_motion()

func _build_geometry() -> Dictionary:
	var c := _config()
	c.roof_rack_enabled = roof_rack_enabled
	return BUILDER.new().car(c)

func _update_motion() -> void:
	super._update_motion()
	if _material:
		_material.set_shader_parameter("light_strength", 0.55 if headlights_enabled else 0.0)
