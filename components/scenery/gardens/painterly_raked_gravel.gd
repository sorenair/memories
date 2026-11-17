@tool
class_name PainterlyRakedGravel
extends PainterlyConcertComponent
## A feathered dry-garden bed. Existing boulders can sit at the rake centers.
const GARDEN = preload("res://components/scenery/gardens/garden_geometry.gd")
const RAKE = preload("res://components/scenery/gardens/raked_gravel.gdshader")
@export var footprint := Vector2(11,9):
	set(value):
		footprint = value.clamp(Vector2(3,3),Vector2(24,24))
		_request_rebuild()
@export var rock_centers := PackedVector2Array([Vector2(-2.2,-.9),Vector2(1.6,1.0),Vector2(3.2,-2.1)]):
	set(value):
		rock_centers = value
		_update_rakes()
@export_range(.12,.5,.01) var rake_spacing := .24:
	set(value):
		rake_spacing = value
		_update_rakes()
@export_range(0,1,.05) var rake_strength := .65:
	set(value):
		rake_strength = value
		_update_rakes()
func _build_geometry() -> Dictionary:
	var c := _config()
	c.footprint = footprint
	return GARDEN.new().gravel(c)
func _apply_material() -> void:
	if _material: _material.shader = RAKE
	super._apply_material()
	_update_rakes()
func _update_rakes() -> void:
	if not _material: return
	var centers := PackedVector2Array()
	for i in 3: centers.append(rock_centers[i] if i<rock_centers.size() else Vector2(1000,1000))
	_material.set_shader_parameter("rock_centers",centers)
	_material.set_shader_parameter("rake_spacing",rake_spacing)
	_material.set_shader_parameter("rake_strength",rake_strength)
	_material.set_shader_parameter("footprint",footprint)
func excludes_ground_point(world_point: Vector3) -> bool:
	var p := to_local(world_point)
	return Vector2(p.x/(footprint.x*.5),p.z/(footprint.y*.5)).length()<.97
func get_ground_outline() -> PackedVector3Array:
	var points := PackedVector3Array()
	for i in 64:
		var a := TAU*i/64.0
		points.append(to_global(Vector3(cos(a)*footprint.x*.5,0,sin(a)*footprint.y*.5)))
	return points
