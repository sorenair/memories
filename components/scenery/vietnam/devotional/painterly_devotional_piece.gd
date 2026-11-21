@tool
class_name PainterlyDevotionalPiece
extends PainterlyVietnamPiece

const DEVOTIONAL_GEOMETRY = preload("res://components/scenery/vietnam/devotional/devotional_geometry.gd")

@export_enum("Seated Budai", "Field Shrine", "Censer") var profile := 0:
	set(value):
		profile = clampi(value, 0, 2)
		_request_rebuild()

func _build_geometry() -> Dictionary:
	var builder := DEVOTIONAL_GEOMETRY.new()
	var config := _config()
	match profile:
		1: return builder.shrine(config)
		2: return builder.censer(config)
	return builder.budai(config)
