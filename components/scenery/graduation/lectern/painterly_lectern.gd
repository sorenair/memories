@tool
class_name PainterlyLectern
extends PainterlyConcertComponent
const CEREMONY = preload("res://components/scenery/graduation/shared/ceremony_geometry.gd")
@export_range(0.85,1.35,0.05) var lectern_height: float = 1.1:
	set(value):
		lectern_height=clampf(value,0.85,1.35)
		_request_rebuild()
@export_range(0.5,0.9,0.05) var lectern_width: float = 0.64:
	set(value):
		lectern_width=clampf(value,0.5,0.9)
		_request_rebuild()

func _build_geometry() -> Dictionary:
	var c := _config()
	c.merge({"lectern_height":lectern_height,"lectern_width":lectern_width})
	return CEREMONY.new().lectern(c)
