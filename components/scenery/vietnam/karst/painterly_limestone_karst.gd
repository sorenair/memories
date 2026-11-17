@tool
class_name PainterlyLimestoneKarst
extends PainterlyVietnamPiece
## Seeded scalloped limestone with stratified cliffs and vegetated upper shelves.
@export var footprint := Vector2(5.5,4.4):
	set(value):
		footprint = value.clamp(Vector2(2,2),Vector2(15,12))
		_request_rebuild()
@export_range(3.0,22.0,0.5) var karst_height := 9.0:
	set(value):
		karst_height = clampf(value,3,22)
		_request_rebuild()
@export_range(1,3,1) var peaks := 2:
	set(value):
		peaks = clampi(value,1,3)
		_request_rebuild()
func _build_geometry() -> Dictionary:
	var c := _config()
	c.merge({"footprint":footprint,"karst_height":karst_height,"peaks":peaks})
	return BUILDER.new().karst(c)
