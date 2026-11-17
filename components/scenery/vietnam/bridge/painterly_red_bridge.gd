@tool
class_name PainterlyRedBridge
extends PainterlyVietnamPiece
## Gentle red footbridge; +Z shore, -Z island, continuous convex walking deck.
@export_range(4.0,16.0,0.25) var bridge_length := 9.0:
	set(value):
		bridge_length = clampf(value,4,16)
		_request_rebuild()
@export_range(1.8,3.5,0.1) var bridge_width := 2.4:
	set(value):
		bridge_width = clampf(value,1.8,3.5)
		_request_rebuild()
@export_range(0.0,1.0,0.05) var arch_rise := 0.42:
	set(value):
		arch_rise = clampf(value,0,1)
		_request_rebuild()
func surface_height(z: float) -> float:
	var t := clampf((z+bridge_length*0.5)/bridge_length,0,1)
	return 0.06+arch_rise*sin(t*PI)
func _build_geometry() -> Dictionary:
	var c := _config()
	c.merge({"bridge_length":bridge_length,"bridge_width":bridge_width,"arch_rise":arch_rise})
	return BUILDER.new().bridge(c)
