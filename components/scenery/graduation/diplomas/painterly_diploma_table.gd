@tool
class_name PainterlyDiplomaTable
extends PainterlyConcertComponent
const CEREMONY = preload("res://components/scenery/graduation/shared/ceremony_geometry.gd")
@export_range(0.9,2.8,0.1) var table_width: float = 1.65:
	set(value):
		table_width=clampf(value,0.9,2.8)
		_request_rebuild()
@export_range(1,24,1) var diploma_count: int = 9:
	set(value):
		diploma_count=clampi(value,1,24)
		_request_rebuild()

func _build_geometry() -> Dictionary:
	var c := _config()
	c.merge({"table_width":table_width,"diploma_count":diploma_count})
	return CEREMONY.new().diploma_table(c)
