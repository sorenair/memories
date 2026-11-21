@tool
extends PainterlyConcertComponent
## Scenic wooden fishing boat. Place the origin at the water surface, with the bow along +Z.
const BUILDER = preload("res://components/scenery/vietnam/fishing_boat/fishing_boat_geometry.gd")
const BOAT_PAINT = preload("res://components/scenery/sailing/shared/sailing_paint.gdshader")

@export_group("Boat")
@export_range(5.5, 10.0, 0.05) var hull_length := 7.4:
	set(value):
		hull_length = clampf(value, 5.5, 10.0)
		_request_rebuild()
@export_range(2.2, 3.5, 0.05) var beam := 2.55:
	set(value):
		beam = clampf(value, 2.2, 3.5)
		_request_rebuild()
@export var tire_fenders_enabled := true:
	set(value):
		tire_fenders_enabled = value
		_request_rebuild()
## Height of the gentle floating motion in meters. Use zero for a static display.
@export_range(0.0, 0.08, 0.005) var bob_amount := 0.035:
	set(value):
		bob_amount = clampf(value, 0.0, 0.08)
		_apply_material()

func _build_geometry() -> Dictionary:
	return BUILDER.new().build(_config(), hull_length, beam, tire_fenders_enabled)

func _apply_material() -> void:
	if _material:
		_material.shader = BOAT_PAINT
		_material.set_shader_parameter("wind_strength", 0.0)
		_material.set_shader_parameter("bob_amount", bob_amount)
	super._apply_material()

func _build_details() -> void:
	var visual: MeshInstance3D = _generated_root.get_node("PaintedProp")
	visual.custom_aabb = visual.mesh.get_aabb().grow(0.15)
