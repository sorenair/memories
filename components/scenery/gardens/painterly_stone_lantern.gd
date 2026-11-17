@tool
class_name PainterlyStoneLantern
extends PainterlyConcertComponent
const GARDEN = preload("res://components/scenery/gardens/garden_geometry.gd")
const STONE = preload("res://components/scenery/conservatory/shared/stone_paint.gdshader")
@export_range(.8,2.5,.05) var lantern_height := 1.8:
	set(value):
		lantern_height = value
		_request_rebuild()
func _build_geometry() -> Dictionary:
	var c := _config()
	c.lantern_height = lantern_height
	return GARDEN.new().lantern(c)
func _apply_material() -> void:
	if _material: _material.shader = STONE
	super._apply_material()
