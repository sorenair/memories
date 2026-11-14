@tool
class_name PainterlyArcadeEchoes
extends Node3D
## A few remembered materials and suspended lights, with no architecture or collision.
const GEOMETRY = preload("res://components/activities/arcade/shared/arcade_geometry.gd")
const PAINT = preload("res://components/activities/arcade/shared/arcade_paint.gdshader")
const PIGMENT = preload("res://components/activities/arcade/echoes/echo_pigment.gdshader")
const HALO = preload("res://components/activities/arcade/echoes/bulb_halo.gdshader")
const WASH = preload("res://components/lighting/light_wash/painterly_light_wash.tscn")
@export var echo_seed: int = 517:
	set(value):
		echo_seed = value
		_request_rebuild()
@export_range(0.0, 1.0, 0.05) var floor_trace_opacity: float = 0.52:
	set(value):
		floor_trace_opacity = clampf(value,0.0,1.0)
		_request_rebuild()
@export_group("Suspended Lights")
@export var light_start := Vector3(-4.7, 2.5, -3.0):
	set(value):
		light_start = value
		_request_rebuild()
@export var light_end := Vector3(4.9, 2.8, -2.9):
	set(value):
		light_end = value
		_request_rebuild()
@export_range(0, 20, 1) var light_count: int = 11:
	set(value):
		light_count = clampi(value,0,20)
		_request_rebuild()
@export_range(0.0, 1.5, 0.05) var light_sag: float = 0.55:
	set(value):
		light_sag = clampf(value,0.0,1.5)
		_request_rebuild()
@export_range(0.0, 1.0, 0.05) var light_strength: float = 0.65:
	set(value):
		light_strength = clampf(value,0.0,1.0)
		_request_rebuild()
@export_tool_button("Regenerate echoes") var regenerate = rebuild
var _queued := false


const RECALL = preload("res://components/effects/recall/component_recall.gd")
@export_group("Recall")
@export var recall_enabled: bool = false:
	set(value):
		recall_enabled = value
		if is_node_ready() and not Engine.is_editor_hint(): _sync_recall()
var _recall: Node
func get_recall_controller() -> Node:
	return _recall
func _sync_recall() -> void:
	for child in get_children(true):
		if child is PainterlyLightWash: child.recall_enabled = recall_enabled
	_recall = RECALL.configure(self, "res://components/effects/recall/assembled_recall.gd", _recall)
	if not recall_enabled and not Engine.is_editor_hint():
		preload("res://components/effects/recall/assembled_recall.gd").restore_component(self)

func _ready() -> void:
	rebuild()
	set_process(false)
	set_physics_process(false)

func _request_rebuild() -> void:
	if is_inside_tree() and not _queued:
		_queued = true
		call_deferred("_rebuild_queued")

func _rebuild_queued() -> void:
	if _queued: rebuild()

func _generator() -> RefCounted:
	var g := GEOMETRY.new()
	g.s = SurfaceTool.new()
	g.s.begin(Mesh.PRIMITIVE_TRIANGLES)
	return g

func _add(node: Node) -> void:
	node.set_meta(&"echo_generated",true)
	add_child(node,false,Node.INTERNAL_MODE_BACK)

func _mesh(g: RefCounted, node_name: String, shader: Shader) -> void:
	var visual := MeshInstance3D.new()
	visual.name = node_name
	visual.mesh = g.s.commit()
	var paint := ShaderMaterial.new()
	paint.shader = shader
	visual.material_override = paint
	visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	visual.visibility_range_end = 45.0
	_add(visual)

func _mark(g: RefCounted, rng: RandomNumberGenerator, center: Vector3, width: float, length: float, angle: float, color: Color) -> void:
	g.frame = Transform3D(Basis(Vector3.UP,angle),center)
	var rows := 8
	var edges := PackedFloat32Array()
	for row in range(rows+1): edges.append(rng.randf_range(0.83,1.05))
	for row in range(rows):
		for col in range(2):
			for corner in [Vector2(0,0),Vector2(1,0),Vector2(1,1),Vector2(0,0),Vector2(1,1),Vector2(0,1)]:
				var r: int = row+int(corner.y)
				var c: int = col+int(corner.x)
				var along := float(r)/rows
				var across := float(c)-1.0
				var p := Vector3(across*width*0.5*edges[r],0.0,(along-0.5)*length)
				var alpha: float = pow(sin(PI*along),0.55) * (1.0-absf(across))
				var pigment := color
				pigment.a *= maxf(0.0,alpha)
				g.vertex(p,Vector3.UP,pigment)
	g.frame = Transform3D.IDENTITY

func sample_light(t: float) -> Vector3:
	return light_start.lerp(light_end,t) + Vector3(0,-sin(PI*t)*light_sag,sin(PI*t)*0.55)

func _wash(center: Vector3, size: Vector2, color: Color, strength: float) -> void:
	var wash: PainterlyLightWash = WASH.instantiate()
	wash.name = "PigmentPool"
	wash.position = center
	wash.footprint = size
	wash.light_color = color
	wash.intensity = strength
	wash.softness = 0.95
	wash.paint_variation = 0.55
	wash.wash_seed = echo_seed
	wash.surface_offset = 0.005
	_add(wash)

func rebuild() -> void:
	_queued = false
	if not is_inside_tree(): return
	for child in get_children(true):
		if child.get_meta(&"echo_generated",false):
			remove_child(child)
			child.free()
	var rng := RandomNumberGenerator.new()
	rng.seed = echo_seed
	var traces := _generator()
	# The sidewalk loses its certainty: three faint, separated impressions.
	for i in range(4):
		var color := Color("c9c0ac")
		color.a = floor_trace_opacity * (0.75-i*0.12)
		_mark(traces,rng,Vector3(-7.8+i*0.95,0.009,5.4-i*0.22),1.13-i*0.10,1.35-i*0.08,PI*0.5+rng.randf_range(-0.10,0.10),color)
	# A short fan of floorboards remembered around the pinball's feet.
	for i in range(5):
		var color := Color("bcaa8e").lightened(rng.randf_range(0.03,0.11))
		color.a = floor_trace_opacity * rng.randf_range(0.5,0.85)
		_mark(traces,rng,Vector3(-3.75+i*0.27,0.011,-0.62+rng.randf_range(-0.17,0.17)),0.25,rng.randf_range(1.1,1.9),-0.12,color)
	# A couple of loose grain marks beside the band's existing wooden plinth.
	for i in range(3):
		var color := Color("c8b699")
		color.a = floor_trace_opacity*0.35
		_mark(traces,rng,Vector3(0.9+i*0.24,0.009,0.75),0.22,rng.randf_range(0.6,1.1),PI*0.25,color)
	if light_count>0:
		for i in range(36):
			if i in [15,16,28]: continue
			var t: float = (i+0.5)/36.0
			var color := Color("867d6c")
			color.a = sin(PI*t)*0.34
			traces.rod(sample_light(float(i)/36.0),sample_light(float(i+1)/36.0),0.006,color,5)
	_mesh(traces,"FadingTraces",PIGMENT)
	if light_count>0:
		var bulbs := _generator()
		var batch := MultiMesh.new()
		batch.transform_format = MultiMesh.TRANSFORM_3D
		batch.use_custom_data = true
		var quad := QuadMesh.new()
		quad.size = Vector2.ONE
		batch.mesh = quad
		batch.instance_count = light_count
		var bounds := AABB(light_start,Vector3.ZERO)
		for i in range(light_count):
			var t := float(i+1)/(light_count+1)
			var p := sample_light(t)-Vector3.UP*rng.randf_range(0.08,0.14)
			bulbs.rod(sample_light(t),p,0.008,Color("a79b81"),6)
			bulbs.ball(p,Vector3(0.06,0.095,0.06),Color("fff1d0"),2.0)
			batch.set_instance_transform(i,Transform3D(Basis.IDENTITY.scaled(Vector3.ONE*0.55),p))
			batch.set_instance_custom_data(i,Color(t,0,0,1))
			bounds = bounds.expand(p)
		batch.custom_aabb = bounds.grow(0.5)
		_mesh(bulbs,"SuspendedBulbs",PAINT)
		var glows := MultiMeshInstance3D.new()
		glows.name = "BulbHalos"
		glows.multimesh = batch
		var material := ShaderMaterial.new()
		material.shader = HALO
		material.set_shader_parameter("light_strength",light_strength)
		glows.material_override = material
		glows.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		glows.visibility_range_end = 45.0
		_add(glows)
	_wash(Vector3(-3.1,0,-0.7),Vector2(3.3,2.8),Color("d6c8ad"),0.13)
	_wash(Vector3(-0.3,0,-2.9),Vector2(2.7,2.4),Color("e8d5bd"),0.10)
	_wash(Vector3(2.3,0,0.3),Vector2(5,3.9),Color("e8d8bc"),0.10)

	_sync_recall()
