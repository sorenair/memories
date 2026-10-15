@tool
class_name GrassPalette
extends Resource
## Colors are shared by the pigment wash and foliage roots/tips.
@export var root_color := Color("526448"):
	set(value):
		root_color = value
		emit_changed()
@export var shade_color := Color("668151"):
	set(value):
		shade_color = value
		emit_changed()
@export var leaf_color := Color("97ae65"):
	set(value):
		leaf_color = value
		emit_changed()
@export var sun_color := Color("cedb8b"):
	set(value):
		sun_color = value
		emit_changed()
