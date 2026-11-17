@tool
class_name PainterlyShuttleBus
extends PainterlyCampingComponent
## A parked trail shuttle with editable length/livery. Ground root, front +Z.
const BUILDER = preload("res://components/vehicles/shuttle_bus/shuttle_bus_geometry.gd")

@export_group("Shuttle")
@export_range(4,7,1) var passenger_bays: int = 5:
	set(value):
		passenger_bays = clampi(value,4,7)
		_request_rebuild()
@export_range(0.6,1.4,0.05) var vehicle_scale: float = 1.0:
	set(value):
		vehicle_scale = clampf(value,0.6,1.4)
		_request_rebuild()
@export var destination_text: String = "TRAIL SHUTTLE":
	set(value):
		destination_text = value.replace("\n"," ").replace("\r"," ").replace("\t"," ").substr(0,24)
		_request_rebuild()
@export var roof_color := Color("e5e2d0"):
	set(value):
		roof_color = value
		_request_rebuild()
@export var glass_color := Color("506c77"):
	set(value):
		glass_color = value
		_request_rebuild()
@export var mountain_graphic_enabled: bool = true:
	set(value):
		mountain_graphic_enabled = value
		_request_rebuild()
@export var roof_pod_enabled: bool = true:
	set(value):
		roof_pod_enabled = value
		_request_rebuild()
@export var headlights_enabled: bool = false:
	set(value):
		headlights_enabled = value
		_update_motion()

var _bus_data: Dictionary

func _init() -> void:
	body_color = Color("608da3")
	accent_color = Color("8caa8c")
	trim_color = Color("344443")

func _config() -> Dictionary:
	var c := super._config()
	c.merge({"passenger_bays":passenger_bays,"vehicle_scale":vehicle_scale,"destination_text":destination_text,"roof_color":roof_color,"glass_color":glass_color,"mountain_graphic_enabled":mountain_graphic_enabled,"roof_pod_enabled":roof_pod_enabled})
	return c

func _build_geometry() -> Dictionary:
	_bus_data = BUILDER.new().shuttle(_config())
	return _bus_data

func _build_details() -> void:
	if contact_shadow_enabled:
		var shadow: MeshInstance3D = _generated_root.get_node("ContactShadow")
		shadow.mesh.size = Vector2(2.80*vehicle_scale,_bus_data.length_z*1.12)
		shadow.position = Vector3(0,0.009,0)

func _update_motion() -> void:
	super._update_motion()
	if _material:
		_material.set_shader_parameter("light_strength",0.65 if headlights_enabled else 0.0)
