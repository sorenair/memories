@tool
class_name PainterlyCoastalHeadland
extends PainterlyVietnamPiece
const COAST = preload("res://components/scenery/vietnam/shared/southern_geometry.gd")
@export var footprint := Vector2(11,8):
	set(value):
		footprint = value.clamp(Vector2(6,5),Vector2(20,16))
		_request_rebuild()
@export_range(1.5,7.0,0.25) var cliff_height := 3.2:
	set(value):
		cliff_height = clampf(value,1.5,7)
		_request_rebuild()
func _build_geometry() -> Dictionary:
	var c := _config()
	c.merge({"footprint":footprint,"cliff_height":cliff_height})
	return COAST.new().headland(c)
