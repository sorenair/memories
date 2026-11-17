@tool
class_name PainterlyVietnamPiece
extends PainterlyConcertComponent
## Reuse the established static paint, collision, anchors and recall lifecycle.
const BUILDER = preload("res://components/scenery/vietnam/shared/vietnam_geometry.gd")
const MATTE_PAINT = preload("res://components/scenery/tokyo/shared/tokyo_paint.gdshader")
@export var roof_color := Color("857368"):
	set(value):
		roof_color = value
		_request_rebuild()
func _config() -> Dictionary:
	var config := super._config()
	config.roof_color = roof_color
	return config
func _apply_material() -> void:
	if _material: _material.shader = MATTE_PAINT
	super._apply_material()
	if _material: _material.set_shader_parameter("glow_strength",0.0)
