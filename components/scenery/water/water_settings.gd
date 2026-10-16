@tool
class_name WaterSettings
extends Resource
## Shared appearance and motion. Shape, shoreline widths, and obstacles belong to the body.
@export var palette: WaterPalette:
	set(value):
		if palette and palette.changed.is_connected(emit_changed):
			palette.changed.disconnect(emit_changed)
		palette = value
		if palette:
			palette.changed.connect(emit_changed)
		emit_changed()
@export_group("Motion")
@export_range(0.0, 1.0, 0.01) var flow_speed: float = 0.22:
	set(value):
		flow_speed = value
		emit_changed()
@export_range(0.4, 4.0, 0.05) var ripple_scale: float = 1.4:
	set(value):
		ripple_scale = value
		emit_changed()
@export_range(0.0, 1.0, 0.01) var wave_activity: float = 0.6:
	set(value):
		wave_activity = value
		emit_changed()
@export_range(0.0, 0.02, 0.001) var wave_height: float = 0.008:
	set(value):
		wave_height = value
		emit_changed()
@export_group("Paint and Depth")
@export_range(0.0, 1.0, 0.01) var paint_contrast: float = 0.6:
	set(value):
		paint_contrast = value
		emit_changed()
@export_range(0.2, 5.0, 0.05) var depth_distance: float = 1.6:
	set(value):
		depth_distance = value
		emit_changed()
@export_range(0.0, 1.0, 0.01) var caustic_strength: float = 0.36:
	set(value):
		caustic_strength = value
		emit_changed()
@export_group("Surface Lighting")
@export_range(0.0, 1.0, 0.01) var normal_strength: float = 0.3:
	set(value):
		normal_strength = value
		emit_changed()
@export_range(0.0, 1.0, 0.01) var reflection_strength: float = 0.25:
	set(value):
		reflection_strength = value
		emit_changed()
@export_range(0.0, 1.0, 0.01) var highlight_amount: float = 0.55:
	set(value):
		highlight_amount = value
		emit_changed()
@export var sky_color := Color("c5e7df"):
	set(value):
		sky_color = value
		emit_changed()
@export var light_direction := Vector3(-0.45, 0.82, -0.35):
	set(value):
		light_direction = value
		emit_changed()
