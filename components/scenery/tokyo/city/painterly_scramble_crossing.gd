@tool
class_name PainterlyScrambleCrossing
extends PainterlyTokyoPiece
const CITY = preload("res://components/scenery/tokyo/shared/city_geometry.gd")
const ROAD = preload("res://components/scenery/tokyo/city/scramble_asphalt.gdshader")
@export_range(18.0,36.0,0.5) var extent: float = 24.0:
	set(value):
		extent=clampf(maxf(value,road_width+8),18,36)
		_request_rebuild()
@export_range(8.0,14.0,0.25) var road_width: float = 10.0:
	set(value):
		road_width=clampf(value,8,14)
		extent=maxf(extent,road_width+8)
		_request_rebuild()
@export var asphalt_color := Color("52666c"):
	set(value):
		asphalt_color=value
		_request_rebuild()
@export var diagonal_enabled: bool = true:
	set(value):
		diagonal_enabled=value
		_request_rebuild()
@export var signals_enabled: bool = true:
	set(value):
		signals_enabled=value
		_request_rebuild()

func _build_geometry() -> Dictionary:
	var c := _config()
	c.merge({"extent":extent,"road_width":road_width,"diagonal_enabled":diagonal_enabled,"signals_enabled":signals_enabled})
	return CITY.new().crossing(c)

func _build_details() -> void:
	var mesh := PlaneMesh.new()
	mesh.size=Vector2.ONE*extent
	var paint := ShaderMaterial.new()
	paint.shader=ROAD
	paint.set_shader_parameter("extent",extent)
	paint.set_shader_parameter("road_width",road_width)
	paint.set_shader_parameter("asphalt_color",asphalt_color)
	paint.set_shader_parameter("paint_phase",float(prop_seed)*0.07)
	_add_visual("Asphalt",mesh,paint).position.y=0.0125
