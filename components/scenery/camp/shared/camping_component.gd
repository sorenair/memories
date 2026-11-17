@tool
class_name PainterlyCampingComponent
extends PainterlyConcertComponent
## Common matte pigment, static-prop lifecycle and recall for camping gear.
const CAMP_PAINT = preload("res://components/scenery/camp/shared/camping_paint.gdshader")
var _visual_time: float = -1.0

func _apply_material() -> void:
	if _material:
		_material.shader = CAMP_PAINT
		super._apply_material()
	_update_motion()

func _update_motion() -> void:
	if _material:
		_material.set_shader_parameter("animation_time", _visual_time)

func seek_time(seconds: float) -> void:
	_visual_time = seconds
	_update_motion()
