@tool
class_name PainterlySaigonTower
extends PainterlyCityTower
## Reuse the existing tower controls, paint, billboards, collision and recall.
const SOUTH = preload("res://components/scenery/vietnam/shared/southern_geometry.gd")
@export_enum("Lotus Tower", "Clustered Spires") var skyline_form := 0:
	set(value):
		skyline_form = clampi(value,0,1)
		_request_rebuild()
func _build_geometry() -> Dictionary:
	var c := _config()
	c.merge({"footprint":footprint,"floors":floors,"floor_height":floor_height})
	return SOUTH.new().lotus_tower(c) if skyline_form==0 else SOUTH.new().clustered_tower(c)

func _validate_property(property: Dictionary) -> void:
	if property.name in ["profile","lit_fraction","sign_text"]:
		property.usage &= ~PROPERTY_USAGE_EDITOR
