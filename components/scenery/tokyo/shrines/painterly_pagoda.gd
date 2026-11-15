@tool
class_name PainterlyPagoda
extends PainterlyTokyoPiece
@export_range(3.0,7.0,0.1) var base_width: float = 4.4:
	set(value):
		base_width=clampf(value,3,7)
		_request_rebuild()
@export_range(8.0,18.0,0.1) var tower_height: float = 11.5:
	set(value):
		tower_height=clampf(value,8,18)
		_request_rebuild()

func _build_geometry() -> Dictionary:
	var c := _config()
	c.merge({"base_width":base_width,"tower_height":tower_height})
	return TOKYO_GEOMETRY.new().pagoda(c)
