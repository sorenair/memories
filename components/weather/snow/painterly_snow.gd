@tool
class_name PainterlySnow
extends Node3D
## One lightweight batch of soft, drifting flakes; animation stays on the GPU.
const SNOW_SHADER = preload("res://components/weather/snow/snowflakes.gdshader")
@export_group("Snow Volume")
@export var footprint := Vector2(22,28):
	set(value):
		footprint = value.max(Vector2.ONE)
		_request_rebuild()
@export_range(2.0,20.0,0.5) var snow_height: float = 8.0:
	set(value):
		snow_height = maxf(value,2.0)
		_update_material()
		_update_bounds()
@export var snow_seed: int = 281:
	set(value):
		snow_seed = value
		_request_rebuild()
@export_range(0,4000,50) var flake_count: int = 900:
	set(value):
		flake_count = clampi(value,0,4000)
		_request_rebuild()
@export var ground_height: float = 0.0:
	set(value):
		ground_height = value
		_request_rebuild()
@export_group("Motion and Appearance")
@export_range(0.0,1.0,0.01) var intensity: float = 0.7:
	set(value):
		intensity = clampf(value,0,1)
		_update_material()
## Approximate meters per second. Zero freezes falling and lateral drift.
@export_range(0.0,3.0,0.05) var fall_speed: float = 0.65:
	set(value):
		fall_speed = maxf(value,0.0)
		_update_material()
## Local X/Z drift strength in meters, not continuous unbounded velocity.
@export var wind := Vector2(0.5,0.18):
	set(value):
		wind = value.limit_length(3.0)
		_update_material()
		_update_bounds()
@export_range(0.0,1.5,0.05) var flutter: float = 0.45:
	set(value):
		flutter = clampf(value,0,1.5)
		_update_material()
		_update_bounds()
## Min/max flake diameters in meters.
@export var flake_size := Vector2(0.04,0.11):
	set(value):
		flake_size = Vector2(maxf(minf(value.x,value.y),0.005),maxf(maxf(value.x,value.y),0.005))
		_update_material()
		_update_bounds()
@export var snow_color := Color("f6f8ef"):
	set(value):
		snow_color = value
		_update_material()
@export var shade_color := Color("b4c9da"):
	set(value):
		shade_color = value
		_update_material()
@export_range(0.0,1.0,0.01) var opacity: float = 0.85:
	set(value):
		opacity = value
		_update_material()
@export_group("Rendering")
@export_range(20.0,120.0,1.0) var visibility_distance: float = 60.0:
	set(value):
		visibility_distance = value
		if is_instance_valid(_flakes):
			_flakes.visibility_range_end = value
var _queued: bool = false
var _flakes: MultiMeshInstance3D
var _material: ShaderMaterial

func _ready() -> void:
	rebuild()

func _request_rebuild() -> void:
	if is_inside_tree() and not _queued:
		_queued = true
		call_deferred("_rebuild_queued")

func _rebuild_queued() -> void:
	if _queued:
		rebuild()

func _update_material() -> void:
	if _material:
		for key in [&"snow_height",&"intensity",&"fall_speed",&"wind",&"flutter",&"flake_size",&"snow_color",&"shade_color",&"opacity"]:
			_material.set_shader_parameter(key,get(key))
	if is_instance_valid(_flakes):
		_flakes.visible = intensity>0.0 and opacity>0.0

func _update_bounds() -> void:
	if is_instance_valid(_flakes):
		var margin := wind.length()*1.5+flutter+flake_size.y+0.1
		_flakes.custom_aabb = AABB(Vector3(-footprint.x*0.5,ground_height,-footprint.y*0.5),Vector3(footprint.x,snow_height,footprint.y)).grow(margin)

func rebuild() -> void:
	_queued = false
	if not is_inside_tree():
		return
	if is_instance_valid(_flakes):
		remove_child(_flakes)
		_flakes.queue_free()
	_flakes = null
	_material = null
	if flake_count==0:
		return
	var mesh := QuadMesh.new()
	mesh.size = Vector2.ONE
	var instances := MultiMesh.new()
	instances.transform_format = MultiMesh.TRANSFORM_3D
	instances.use_custom_data = true
	instances.mesh = mesh
	instances.instance_count = flake_count
	var rng := RandomNumberGenerator.new()
	rng.seed = snow_seed
	for index in range(flake_count):
		var origin := Vector3(rng.randf_range(-footprint.x*0.5,footprint.x*0.5),ground_height,rng.randf_range(-footprint.y*0.5,footprint.y*0.5))
		instances.set_instance_transform(index,Transform3D(Basis.IDENTITY,origin))
		instances.set_instance_custom_data(index,Color(rng.randf(),rng.randf(),rng.randf(),rng.randf()))
	_material = ShaderMaterial.new()
	_material.shader = SNOW_SHADER
	_flakes = MultiMeshInstance3D.new()
	_flakes.name = "Snowflakes"
	_flakes.multimesh = instances
	_flakes.material_override = _material
	_flakes.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_flakes.visibility_range_end = visibility_distance
	add_child(_flakes,false,Node.INTERNAL_MODE_BACK)
	_update_material()
	_update_bounds()
