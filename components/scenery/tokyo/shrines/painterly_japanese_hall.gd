@tool
class_name PainterlyJapaneseHall
extends PainterlyTokyoPiece
@export_enum("Meiji Worship Hall","Senso-ji Main Hall") var hall_style: int = 0:
	set(value):
		hall_style=clampi(value,0,1)
		_request_rebuild()
@export var footprint := Vector2(8.5,4.5):
	set(value):
		footprint=value.clamp(Vector2(6,3.5),Vector2(15,9))
		_request_rebuild()
@export_range(2.2,4.5,0.1) var wall_height: float = 2.6:
	set(value):
		wall_height=clampf(value,2.2,4.5)
		_request_rebuild()
@export_range(1.2,3.5,0.1) var roof_rise: float = 1.8:
	set(value):
		roof_rise=clampf(value,1.2,3.5)
		_request_rebuild()

func _build_geometry() -> Dictionary:
	var c := _config()
	c.merge({"hall_style":hall_style,"footprint":footprint,"wall_height":wall_height,"roof_rise":roof_rise})
	return TOKYO_GEOMETRY.new().hall(c)
