@tool
class_name PainterlyRain
extends Node3D
## Two small GPU batches: falling strokes and occasional surface impacts.
const STREAK_SHADER = preload("res://components/weather/rain/rain_streaks.gdshader")
const SPLASH_SHADER = preload("res://components/weather/rain/rain_splashes.gdshader")
@export_group("Rain Volume")
@export var footprint := Vector2(22,28):
	set(value):
		footprint = value.max(Vector2.ONE)
		_request_rebuild()
@export_range(2.0, 20.0, 0.5) var rain_height: float = 10.0:
	set(value):
		rain_height = value
		_request_rebuild()
@export var rain_seed: int = 191:
	set(value):
		rain_seed = value
		_request_rebuild()
@export_range(0, 4000, 50) var drop_count: int = 900:
	set(value):
		drop_count = clampi(value,0,4000)
		_request_rebuild()
## Optional platform path relative to this node; rejects impacts outside its edge.
@export var platform: NodePath:
	set(value):
		platform = value
		_request_rebuild()
## Optional water paths relative to this node; use broader ripples on these surfaces.
@export var water_bodies: Array[NodePath] = []:
	set(value):
		water_bodies = value
		_request_rebuild()
@export_group("Motion and Appearance")
@export_range(0.0, 1.0, 0.01) var intensity: float = 0.7:
	set(value):
		intensity = clampf(value,0,1)
		_update_materials()
@export_range(0.0, 16.0, 0.1) var fall_speed: float = 8.0:
	set(value):
		fall_speed = value
		_update_materials()
@export var wind := Vector2(0.55,0.16):
	set(value):
		wind = value.limit_length(3.0)
		_update_materials()
		_update_bounds()
@export_range(0.1, 1.0, 0.01) var streak_length: float = 0.42:
	set(value):
		streak_length = value
		_update_materials()
@export_range(0.003, 0.025, 0.001) var streak_width: float = 0.009:
	set(value):
		streak_width = value
		_update_materials()
@export var rain_color := Color("a5b9c4"):
	set(value):
		rain_color = value
		_update_materials()
@export var highlight_color := Color("e4efec"):
	set(value):
		highlight_color = value
		_update_materials()
@export_range(0.0, 1.0, 0.01) var opacity: float = 0.42:
	set(value):
		opacity = value
		_update_materials()
@export_group("Surface Impacts")
@export_range(0, 400, 10) var splash_count: int = 100:
	set(value):
		splash_count = clampi(value,0,400)
		_request_rebuild()
## Local surface height for flat ground; registered ponds supply their own height.
@export var ground_height: float = 0.0:
	set(value):
		ground_height = value
		_request_rebuild()
@export_range(0.0, 1.0, 0.01) var splash_opacity: float = 0.32:
	set(value):
		splash_opacity = value
		_update_materials()
@export_group("Rendering")
@export_range(20.0, 120.0, 1.0) var visibility_distance: float = 60.0:
	set(value):
		visibility_distance = value
		for child in get_children(true):
			if child is GeometryInstance3D:
				child.visibility_range_end = value
@export_tool_button("Refresh rain volume") var regenerate = rebuild

var _queued: bool = false
var _streaks: MultiMeshInstance3D
var _splashes: MultiMeshInstance3D
var _streak_material: ShaderMaterial
var _splash_material: ShaderMaterial

func _ready() -> void:
	# Sibling platforms and water finish generating before positions are sampled.
	_request_rebuild()

func _request_rebuild() -> void:
	if is_inside_tree() and not _queued:
		_queued = true
		call_deferred("_rebuild_queued")

func _rebuild_queued() -> void:
	if _queued:
		rebuild()

func _update_materials() -> void:
	if _streak_material:
		for key in [&"rain_height", &"intensity", &"fall_speed", &"wind", &"streak_length", &"streak_width", &"rain_color", &"highlight_color", &"opacity"]:
			_streak_material.set_shader_parameter(key,get(key))
	if _splash_material:
		for key in [&"intensity", &"fall_speed", &"rain_color", &"highlight_color", &"splash_opacity"]:
			_splash_material.set_shader_parameter(key,get(key))
	for batch in [_streaks,_splashes]:
		if is_instance_valid(batch):
			batch.visible = intensity>0.0 and drop_count>0

func _update_bounds() -> void:
	if is_instance_valid(_streaks):
		var padding := 1.2 + wind.length()*rain_height/8.0
		_streaks.custom_aabb = AABB(Vector3(-footprint.x*0.5,ground_height,-footprint.y*0.5),Vector3(footprint.x,rain_height,footprint.y)).grow(padding)

func _batch(name_value: String, mesh: Mesh, positions: Array[Vector3], data: Array[Color], material: Material) -> MultiMeshInstance3D:
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.use_custom_data = true
	multimesh.mesh = mesh
	multimesh.instance_count = positions.size()
	var bounds := AABB(Vector3.ZERO,Vector3.ZERO)
	for index in range(positions.size()):
		multimesh.set_instance_transform(index,Transform3D(Basis.IDENTITY,positions[index]))
		multimesh.set_instance_custom_data(index,data[index])
		bounds = bounds.expand(positions[index])
	var batch := MultiMeshInstance3D.new()
	batch.name = name_value
	batch.multimesh = multimesh
	batch.material_override = material
	batch.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	batch.visibility_range_end = visibility_distance
	batch.custom_aabb = bounds.grow(0.4)
	batch.set_meta(&"generated_rain",true)
	add_child(batch,false,Node.INTERNAL_MODE_BACK)
	return batch

func rebuild() -> void:
	_queued = false
	if not is_inside_tree():
		return
	for child in get_children(true):
		if child.get_meta(&"generated_rain",false):
			remove_child(child)
			child.queue_free()
	_streaks = null
	_splashes = null
	_streak_material = null
	_splash_material = null
	if drop_count == 0:
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = rain_seed
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for uv in [Vector2(0,0),Vector2(1,0),Vector2(1,1),Vector2(0,0),Vector2(1,1),Vector2(0,1)]:
		surface.set_uv(uv)
		surface.set_normal(Vector3.UP)
		surface.add_vertex(Vector3(uv.x*2-1,uv.y*2-1,0))
	var mesh := surface.commit()
	var points: Array[Vector3] = []
	var data: Array[Color] = []
	for index in range(drop_count):
		points.append(Vector3(rng.randf_range(-footprint.x*0.5,footprint.x*0.5),ground_height,rng.randf_range(-footprint.y*0.5,footprint.y*0.5)))
		data.append(Color(rng.randf(),rng.randf(),rng.randf(),rng.randf()))
	_streak_material = ShaderMaterial.new()
	_streak_material.shader = STREAK_SHADER
	_streaks = _batch("RainStreaks",mesh,points,data,_streak_material)
	if splash_count>0:
		points.clear()
		data.clear()
		var boundary := get_node_or_null(platform) if not platform.is_empty() else null
		for attempt in range(splash_count*12):
			if points.size()>=splash_count:
				break
			var point := Vector3(rng.randf_range(-footprint.x*0.5,footprint.x*0.5),ground_height,rng.randf_range(-footprint.y*0.5,footprint.y*0.5))
			var world := to_global(point)
			if boundary and boundary.has_method("contains_ground_point") and not boundary.contains_ground_point(world,0.35):
				continue
			var water := false
			for path in water_bodies:
				var body := get_node_or_null(path)
				if body and body.has_method("excludes_ground_point") and body.excludes_ground_point(world):
					water = true
					point.y = to_local(Vector3(world.x,body.global_position.y+0.065,world.z)).y
					break
			if not water:
				point.y+=0.035
			points.append(point)
			data.append(Color(rng.randf(),rng.randf(),rng.randf(),1.0 if water else 0.0))
		_splash_material = ShaderMaterial.new()
		_splash_material.shader = SPLASH_SHADER
		_splashes = _batch("RainImpacts",mesh,points,data,_splash_material)
	_update_materials()
	_update_bounds()
