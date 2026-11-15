@tool
class_name PainterlyFrozenWater
extends PainterlyWater
## Reuse water shapes, snow exclusions, shoreline barriers and proximity recall.
const ICE = preload("res://components/scenery/water/shaders/painted_ice.gdshader")
@export_group("Ice")
@export var ice_color := Color(0.66,0.78,0.85):
	set(value):
		ice_color = value
		_update_materials()
@export var frost_color := Color(0.91,0.94,0.93):
	set(value):
		frost_color = value
		_update_materials()
@export_range(0.0,1.0,0.05) var crack_strength := 0.28:
	set(value):
		crack_strength = value
		_update_materials()

func _update_materials() -> void:
	if _water_material: _water_material.shader = ICE
	super._update_materials()
	if _water_material:
		_water_material.set_shader_parameter("ice_color",ice_color)
		_water_material.set_shader_parameter("frost_color",frost_color)
		_water_material.set_shader_parameter("crack_strength",crack_strength)
		_water_material.set_shader_parameter("ice_seed",float(posmod(water_seed,997))*0.071)

func _validate_property(property: Dictionary) -> void:
	super._validate_property(property)
	if property.name in ["settings","behavior_preset","palette_preset","palette","flow_direction","flow_speed","ripple_scale","wave_activity","wave_height","caustic_strength","highlight_amount","foam_amount","foam_width","foam_cell_size","depth_gradient","stream_flow_offset"]:
		property.usage &= ~PROPERTY_USAGE_EDITOR
