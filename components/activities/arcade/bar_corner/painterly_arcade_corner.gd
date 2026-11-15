@tool
class_name PainterlyArcadeCorner
extends PainterlyArcadeComponent
@export var sign_title := "ARCADE":
	set(value):
		sign_title = value.left(12)
		_request_rebuild()
func _kind() -> StringName:
	return &"bar_corner"
func _build_geometry() -> Dictionary:
	return GEOMETRY.new().create(_kind(),{"cabinet_color":cabinet_color,"accent_color":accent_color,"metal_color":metal_color,"cream_color":cream_color,"prop_seed":prop_seed,"corner_sign":sign_title})
