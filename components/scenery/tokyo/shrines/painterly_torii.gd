@tool
class_name PainterlyTorii
extends PainterlyTokyoPiece
@export_range(3.0,9.0,0.1) var opening_width: float = 5.2:
	set(value):
		opening_width=clampf(value,3,9)
		_request_rebuild()
@export_range(3.2,7.5,0.1) var gate_height: float = 5.0:
	set(value):
		gate_height=clampf(value,3.2,7.5)
		_request_rebuild()

func _build_geometry() -> Dictionary:
	var c := _config()
	c.merge({"opening_width":opening_width,"gate_height":gate_height})
	return TOKYO_GEOMETRY.new().torii(c)

func excludes_ground_point(world_point: Vector3) -> bool:
	# The overhead tie beam must not clear planting from the open passage.
	var p := to_local(world_point)
	for side: float in [-1.0,1.0]:
		if absf(p.x-side*(opening_width*0.5-0.05))<0.29 and absf(p.z)<0.30:
			return true
	return false
