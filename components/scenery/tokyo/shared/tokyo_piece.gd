@tool
class_name PainterlyTokyoPiece
extends PainterlyConcertComponent
## Existing generated-mesh, collision, grounding and assembled-recall lifecycle.
const TOKYO_GEOMETRY = preload("res://components/scenery/tokyo/shared/japanese_geometry.gd")
const TOKYO_PAINT = preload("res://components/scenery/tokyo/shared/tokyo_paint.gdshader")
@export_group("Tokyo Paint")
@export var roof_color := Color("596569"):
	set(value):
		roof_color=value
		_request_rebuild()
@export_range(0.0,1.5,0.05) var glow_strength: float = 0.5:
	set(value):
		glow_strength=clampf(value,0,1.5)
		_apply_material()

func _config() -> Dictionary:
	var c := super._config()
	c.roof_color=roof_color
	return c

func _apply_material() -> void:
	if _material:
		_material.shader=TOKYO_PAINT
		super._apply_material()
	if _material:
		_material.set_shader_parameter("glow_strength",glow_strength)
