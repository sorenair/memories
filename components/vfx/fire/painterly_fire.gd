@tool
class_name PainterlyFire
extends Node3D
## Layered graphic flame, a restrained ground wash, and GPU drifting embers.
const FLAME_SHADER = preload("res://components/vfx/fire/flame.gdshader")
const EMBER_SHADER = preload("res://components/vfx/fire/embers.gdshader")
const GLOW_SHADER = preload("res://components/vfx/fire/ground_glow.gdshader")
@export_group("Fire")
## Approximate base width and flame height in meters.
@export var flame_size := Vector2(0.9,1.5):
	set(value):
		flame_size = value.max(Vector2(0.1,0.1))
		_update_materials()
		_update_bounds()
@export_range(0.0,1.0,0.01) var intensity: float = 1.0:
	set(value):
		intensity = clampf(value,0,1)
		_update_materials()
## Zero freezes flames, glow, and embers.
@export_range(0.0,3.0,0.05) var animation_speed: float = 1.0:
	set(value):
		animation_speed = value
		_update_materials()
@export_range(-0.6,0.6,0.01) var wind: float = 0.12:
	set(value):
		wind = clampf(value,-0.6,0.6)
		_update_materials()
@export var fire_seed: int = 73:
	set(value):
		fire_seed = value
		_request_rebuild()
@export_group("Colors and Embers")
@export var core_color := Color("ffdf45"):
	set(value):
		core_color = value
		_update_materials()
@export var flame_color := Color("ff8b1e"):
	set(value):
		flame_color = value
		_update_materials()
@export var tip_color := Color("e83d18"):
	set(value):
		tip_color = value
		_update_materials()
@export_range(0,64,1) var ember_count: int = 18:
	set(value):
		ember_count = clampi(value,0,64)
		_request_rebuild()
@export_range(0.0,1.0,0.01) var glow_strength: float = 0.3:
	set(value):
		glow_strength = value
		_update_materials()
var _queued: bool = false
var _materials: Array[ShaderMaterial] = []

func _ready() -> void:
	rebuild()

func _request_rebuild() -> void:
	if is_inside_tree() and not _queued:
		_queued = true
		call_deferred("_rebuild_queued")

func _rebuild_queued() -> void:
	if _queued:
		rebuild()

func _update_materials() -> void:
	for material in _materials:
		for key in [&"flame_size", &"intensity", &"animation_speed", &"wind", &"core_color", &"flame_color", &"tip_color", &"glow_strength"]:
			material.set_shader_parameter(key,get(key))
		material.set_shader_parameter("fire_phase",float(posmod(fire_seed,997))*0.071)
	for child in get_children(true):
		if child.get_meta(&"generated_fire",false):
			child.visible = intensity>0.0 and (child.name!=&"GroundGlow" or glow_strength>0.0)

func _update_bounds() -> void:
	for child in get_children(true):
		if child is GeometryInstance3D and child.get_meta(&"generated_fire",false):
			child.custom_aabb = AABB(Vector3(-flame_size.x*2.0,-0.1,-flame_size.x*2.0),Vector3(flame_size.x*4.0,flame_size.y*2.6+0.2,flame_size.x*4.0))

func _material(shader: Shader) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = shader
	_materials.append(material)
	return material

func _generated(node: GeometryInstance3D) -> void:
	node.set_meta(&"generated_fire",true)
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(node,false,Node.INTERNAL_MODE_BACK)

func rebuild() -> void:
	_queued = false
	if not is_inside_tree():
		return
	for child in get_children(true):
		if child.get_meta(&"generated_fire",false):
			remove_child(child)
			child.queue_free()
	_materials.clear()
	var quad := QuadMesh.new()
	quad.size = Vector2.ONE
	var flame := MeshInstance3D.new()
	flame.name = "Flame"
	flame.mesh = quad
	flame.material_override = _material(FLAME_SHADER)
	_generated(flame)
	var glow := MeshInstance3D.new()
	glow.name = "GroundGlow"
	glow.mesh = quad
	glow.material_override = _material(GLOW_SHADER)
	_generated(glow)
	if ember_count>0:
		var mesh := SurfaceTool.new()
		mesh.begin(Mesh.PRIMITIVE_TRIANGLES)
		# Small ten-sided discs read as round while retaining a tiny geometry budget.
		for segment in range(10):
			var a := TAU * float(segment) / 10.0
			var b := TAU * float(segment+1) / 10.0
			for point in [Vector2.ZERO,Vector2(cos(a),sin(a)),Vector2(cos(b),sin(b))]:
				mesh.set_uv(point*0.5+Vector2.ONE*0.5)
				mesh.set_normal(Vector3.FORWARD)
				mesh.add_vertex(Vector3(point.x,point.y,0))
		var instances := MultiMesh.new()
		instances.transform_format = MultiMesh.TRANSFORM_3D
		instances.use_custom_data = true
		instances.mesh = mesh.commit()
		instances.instance_count = ember_count
		var rng := RandomNumberGenerator.new()
		rng.seed = fire_seed ^ 0xF173
		for index in range(ember_count):
			instances.set_instance_transform(index,Transform3D.IDENTITY)
			instances.set_instance_custom_data(index,Color((index+rng.randf())/ember_count,rng.randf(),rng.randf(),rng.randf()))
		var embers := MultiMeshInstance3D.new()
		embers.name = "Embers"
		embers.multimesh = instances
		embers.material_override = _material(EMBER_SHADER)
		_generated(embers)
	_update_materials()
	_update_bounds()
