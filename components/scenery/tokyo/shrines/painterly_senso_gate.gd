@tool
class_name PainterlySensoGate
extends PainterlyTokyoPiece
## Hozomon-inspired two-storey gate with three open passages and hanging lanterns.
@export_range(7.0,13.0,0.1) var gate_width: float = 8.7:
	set(value):
		gate_width=clampf(value,7,13)
		_request_rebuild()
@export_range(6.7,10.0,0.1) var gate_height: float = 7.0:
	set(value):
		gate_height=clampf(value,6.7,10)
		_request_rebuild()

func _build_geometry() -> Dictionary:
	var c := _config()
	c.merge({"gate_width":gate_width,"gate_height":gate_height})
	return TOKYO_GEOMETRY.new().gate(c)
