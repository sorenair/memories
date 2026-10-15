@tool
class_name StonePalette
extends Resource
@export var base_color := Color("555c58"):
	set(value):
		base_color = value
		emit_changed()
@export var shadow_color := Color("697478"):
	set(value):
		shadow_color = value
		emit_changed()
@export var mid_color := Color("a8b0a6"):
	set(value):
		mid_color = value
		emit_changed()
@export var highlight_color := Color("d6d8c5"):
	set(value):
		highlight_color = value
		emit_changed()
