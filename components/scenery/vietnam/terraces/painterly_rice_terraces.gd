@tool
class_name PainterlyRiceTerraces
extends PainterlyVietnamPiece
## Curved earthen shelves and batched planted rice. Static terrain, shader-only breeze.
const TERRACES = preload("res://components/scenery/vietnam/shared/rice_geometry.gd")
const RICE_PAINT = preload("res://components/scenery/vietnam/terraces/rice_paint.gdshader")
@export var footprint := Vector2(22,18):
	set(value):
		footprint = value.clamp(Vector2(12,12),Vector2(36,28))
		_request_rebuild()
@export_range(3,8,1) var tier_count := 6:
	set(value):
		tier_count = clampi(value,3,8)
		_request_rebuild()
@export_range(0.2,0.65,0.05) var terrace_rise := 0.42:
	set(value):
		terrace_rise = clampf(value,0.2,0.65)
		_request_rebuild()
@export_range(0.5,4.0,0.1) var curvature := 2.5:
	set(value):
		curvature = clampf(value,0.5,4)
		_request_rebuild()
@export_range(2.0,18.0,1.0) var plants_per_square_meter := 8.0:
	set(value):
		plants_per_square_meter = clampf(value,2,18)
		_request_rebuild()
@export var react_to_explorers := true:
	set(value):
		react_to_explorers = value
		if is_node_ready(): set_process(value and not Engine.is_editor_hint())
func edge_point(tier: int,x: float) -> Vector3:
	return TERRACES.edge(_config_with_shape(),tier,x)
func _config_with_shape() -> Dictionary:
	var c := _config()
	c.merge({"footprint":footprint,"tier_count":tier_count,"terrace_rise":terrace_rise,"curvature":curvature,"plants_per_square_meter":plants_per_square_meter})
	return c
func _build_geometry() -> Dictionary:
	return TERRACES.new().terraces(_config_with_shape())
func _apply_material() -> void:
	super._apply_material()
	if _material:
		_material.shader = RICE_PAINT
		_material.set_shader_parameter("pigment_strength",pigment_strength)
		_material.set_shader_parameter("paint_phase",float(posmod(prop_seed,997))*0.073)
func _ready() -> void:
	super._ready()
	set_process(react_to_explorers and not Engine.is_editor_hint())
func _process(_delta: float) -> void:
	var players := RECALL.explorers(self)
	for index in 2:
		var p := players[index].global_position if index<players.size() else Vector3(0,-1000,0)
		_material.set_shader_parameter("explorer_"+str(index),p)
