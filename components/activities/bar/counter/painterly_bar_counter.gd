@tool
class_name PainterlyBarCounter
extends PainterlyArcadeComponent
## Standalone counter and stools; origin at ground center, stools sit on local +Z.
const COUNTER = preload("res://components/activities/bar/counter/counter_geometry.gd")
@export_group("Counter and Stools")
@export_range(2.0,8.0,0.1) var counter_length := 4.2:
	set(value):
		counter_length = clampf(value,2,8)
		_request_rebuild()
@export_range(0.65,1.3,0.05) var counter_depth := 0.85:
	set(value):
		counter_depth = clampf(value,0.65,1.3)
		_request_rebuild()
@export_range(0.9,1.25,0.05) var counter_height := 1.05:
	set(value):
		counter_height = clampf(value,0.9,1.25)
		_request_rebuild()
@export_range(0,5,1) var stool_count := 3:
	set(value):
		stool_count = clampi(value,0,5)
		_request_rebuild()
@export var stool_color := Color("a66d61"):
	set(value):
		stool_color = value
		_request_rebuild()
@export var recall_anchor: Node3D

func get_recall_anchor() -> Node3D:
	return recall_anchor

func _kind() -> StringName:
	return &"bar_counter"

func _build_geometry() -> Dictionary:
	return COUNTER.new().create_counter({"cabinet_color":cabinet_color,"accent_color":accent_color,"metal_color":metal_color,"cream_color":cream_color,"prop_seed":prop_seed,"length":counter_length,"depth":counter_depth,"height":counter_height,"stool_count":stool_count,"stool_color":stool_color})
