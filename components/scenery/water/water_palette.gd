@tool
class_name WaterPalette
extends Resource
## Pigment colors, independent of lighting and reflection probes.
@export var deep_color := Color("175273"):
	set(value):
		deep_color = value
		emit_changed()
@export var body_color := Color("2498b0"):
	set(value):
		body_color = value
		emit_changed()
@export var shallow_color := Color("59c9ba"):
	set(value):
		shallow_color = value
		emit_changed()
@export var foam_color := Color("ffffff"):
	set(value):
		foam_color = value
		emit_changed()
