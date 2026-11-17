@tool
class_name PainterlyHanoiHouse
extends PainterlyVietnamPiece
## Narrow Old Quarter shophouse; solid exterior, front +Z, no cutaway.
@export_enum("Parapet", "Tiled Gable", "Stepped Terrace") var profile := 0:
	set(value):
		profile = clampi(value,0,2)
		_request_rebuild()
@export var footprint := Vector2(3.2,4.6):
	set(value):
		footprint = value.clamp(Vector2(2.4,3.0),Vector2(6,8))
		_request_rebuild()
@export_range(1,5,1) var floors := 3:
	set(value):
		floors = clampi(value,1,5)
		_request_rebuild()
@export_range(1.6,2.8,0.1) var floor_height := 1.9:
	set(value):
		floor_height = clampf(value,1.6,2.8)
		_request_rebuild()
@export var balconies_enabled := true:
	set(value):
		balconies_enabled = value
		_request_rebuild()
@export var awning_enabled := true:
	set(value):
		awning_enabled = value
		_request_rebuild()
func _build_geometry() -> Dictionary:
	var c := _config()
	c.merge({"profile":profile,"footprint":footprint,"floors":floors,"floor_height":floor_height,"balconies_enabled":balconies_enabled,"awning_enabled":awning_enabled})
	return BUILDER.new().house(c)
