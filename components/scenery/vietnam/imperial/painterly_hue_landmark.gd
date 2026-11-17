@tool
class_name PainterlyHueLandmark
extends PainterlyVietnamPiece
const HUE = preload("res://components/scenery/vietnam/shared/hue_geometry.gd")
@export_enum("Meridian Gate", "Thai Hoa Hall") var landmark := 0:
	set(value):
		landmark = clampi(value,0,1)
		_request_rebuild()
@export var footprint := Vector2(14,3.2):
	set(value):
		footprint = value.clamp(Vector2(10,3),Vector2(20,8))
		_request_rebuild()
func _build_geometry() -> Dictionary:
	var c := _config()
	c.merge({"landmark":landmark,"footprint":footprint})
	return HUE.new().gate(c) if landmark==0 else HUE.new().palace(c)
