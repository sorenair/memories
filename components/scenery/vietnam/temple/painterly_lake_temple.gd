@tool
class_name PainterlyLakeTemple
extends PainterlyVietnamPiece
@export_enum("Ngoc Son Pavilion", "Turtle Tower") var landmark := 0:
	set(value):
		landmark = clampi(value,0,1)
		_request_rebuild()
@export var footprint := Vector2(5.2,3.6):
	set(value):
		footprint = value.clamp(Vector2(2,2),Vector2(8,6))
		_request_rebuild()
## Broad overlapping tile strokes, useful on nearby temple roofs.
@export var roof_tiles_enabled := false:
	set(value):
		roof_tiles_enabled = value
		_request_rebuild()
func _build_geometry() -> Dictionary:
	var c := _config()
	c.merge({"landmark":landmark,"footprint":footprint,"roof_tiles_enabled":roof_tiles_enabled})
	return BUILDER.new().temple(c)
