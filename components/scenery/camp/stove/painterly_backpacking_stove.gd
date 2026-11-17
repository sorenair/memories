@tool
class_name PainterlyBackpackingStove
extends PainterlyCampingComponent
const BUILDER = preload("res://components/scenery/camp/shared/backpacking_geometry.gd")
const STEAM = preload("res://components/scenery/camp/stove/cooking_steam.gdshader")
@export_group("Stove and Pot")
@export_range(0.75, 2.0, 0.05) var gear_scale: float = 1.0:
	set(value):
		gear_scale = clampf(value, 0.75, 2)
		_request_rebuild()
@export var pot_enabled: bool = true:
	set(value):
		pot_enabled = value
		_request_rebuild()
@export var lid_enabled: bool = true:
	set(value):
		lid_enabled = value
		_request_rebuild()
@export_range(0.11, 0.22, 0.01) var pot_radius: float = 0.145:
	set(value):
		pot_radius = clampf(value, 0.11, 0.22)
		_request_rebuild()
@export_group("Cooking")
@export var burner_on: bool = true:
	set(value):
		burner_on = value
		_update_motion()
@export var steam_enabled: bool = true:
	set(value):
		steam_enabled = value
		_request_rebuild()
@export_range(0.0, 1.0, 0.05) var steam_strength: float = 0.4:
	set(value):
		steam_strength = clampf(value, 0, 1)
		_update_motion()
var _steam_material: ShaderMaterial

func _build_geometry() -> Dictionary:
	var c := _config()
	c.merge({"gear_scale": gear_scale, "pot_enabled": pot_enabled, "lid_enabled": lid_enabled, "pot_radius": pot_radius})
	return BUILDER.new().stove(c)

func _build_details() -> void:
	_steam_material = null
	if not steam_enabled or not pot_enabled:
		return
	_steam_material = ShaderMaterial.new()
	_steam_material.shader = STEAM
	var quad := QuadMesh.new()
	quad.size = Vector2(0.27, 0.55) * gear_scale
	var steam := _add_visual("CookingSteam", quad, _steam_material)
	steam.position = Vector3(0.02, 0.187 + pot_radius * 1.18 + 0.29, 0) * gear_scale
	steam.custom_aabb = AABB(Vector3.ONE * -0.34 * gear_scale, Vector3.ONE * 0.68 * gear_scale)
	_update_motion()

func _update_motion() -> void:
	super._update_motion()
	if _material:
		_material.set_shader_parameter("burner_strength", 1.0 if burner_on else 0.0)
	if _steam_material:
		_steam_material.set_shader_parameter("steam_strength", steam_strength if burner_on else 0.0)
		_steam_material.set_shader_parameter("animation_time", _visual_time)
