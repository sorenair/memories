@tool
class_name PainterlyStage
extends PainterlyConcertComponent
## Low open deck with a generous sloping approach. All dimensions are local meters.
@export_group("Stage")
@export var footprint := Vector2(6.8, 3.6):
	set(value):
		footprint = value.clamp(Vector2(3, 2), Vector2(18, 12))
		_request_rebuild()
@export_range(0.2, 1.2, 0.05) var deck_height: float = 0.45:
	set(value):
		deck_height = clampf(value, 0.2, 1.2)
		_request_rebuild()
@export_group("Access Ramp")
@export var ramp_enabled: bool = true:
	set(value):
		ramp_enabled = value
		_request_rebuild()
@export_range(1.2, 3.0, 0.1) var ramp_width: float = 1.6:
	set(value):
		ramp_width = clampf(value, 1.2, 3)
		_request_rebuild()
@export_range(1.5, 5.0, 0.1) var ramp_length: float = 2.2:
	set(value):
		ramp_length = clampf(value, 1.5, 5)
		_request_rebuild()

func _build_geometry() -> Dictionary:
	var config := _config()
	for key in ["footprint", "deck_height", "ramp_enabled", "ramp_length"]:
		config[key] = get(key)
	config.ramp_width = minf(ramp_width, footprint.x - 0.3)
	return GEOMETRY.new().stage(config)
