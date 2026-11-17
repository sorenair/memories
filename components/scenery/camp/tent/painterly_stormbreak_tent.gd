@tool
class_name PainterlyStormbreakTent
extends PainterlyCampingComponent
const BUILDER = preload("res://components/scenery/camp/shared/backpacking_geometry.gd")
@export_group("Tent Shape")
## Main canopy coverage. Closed vestibules extend 0.28 m from each Z end.
@export var footprint := Vector2(2.5, 2.65):
	set(value):
		footprint = value.clamp(Vector2(1.7, 2.0), Vector2(3.5, 4.0))
		_request_rebuild()
@export_range(0.9, 1.8, 0.05) var tent_height: float = 1.2:
	set(value):
		tent_height = clampf(value, 0.9, 1.8)
		_request_rebuild()
@export var guy_lines_enabled: bool = true:
	set(value):
		guy_lines_enabled = value
		_request_rebuild()
@export var brand_mark_enabled: bool = true:
	set(value):
		brand_mark_enabled = value
		_request_rebuild()
@export_group("Fabric Motion")
@export_range(0.0, 0.04, 0.002) var wind_strength: float = 0.012:
	set(value):
		wind_strength = clampf(value, 0, 0.04)
		_update_motion()

func _build_geometry() -> Dictionary:
	var c := _config()
	c.merge({"footprint": footprint, "tent_height": tent_height, "guy_lines_enabled": guy_lines_enabled, "brand_mark_enabled": brand_mark_enabled})
	return BUILDER.new().tent(c)

func _update_motion() -> void:
	super._update_motion()
	if _material:
		_material.set_shader_parameter("wind_strength", wind_strength)
		_material.set_shader_parameter("fabric_height", tent_height)
		_material.set_shader_parameter("fabric_size", footprint)

func _build_details() -> void:
	var fly := _generated_root.get_node("PaintedProp") as MeshInstance3D
	fly.custom_aabb = fly.mesh.get_aabb().grow(0.06)
