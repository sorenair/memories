@tool
class_name PainterlyCurvedPath
extends Path3D
## One continuous painted ribbon, support collider and exclusion along a Curve3D.
signal ground_exclusion_changed
const PAINT = preload("res://components/groundcover/paving/painterly_paving.gdshader")
@export_range(0.8,6.0,0.05) var path_width := 2.1:
	set(value):
		path_width = clampf(value,0.8,6.0)
		_request_rebuild()
@export_range(0.1,0.75,0.05) var sample_spacing := 0.25:
	set(value):
		sample_spacing = clampf(value,0.1,0.75)
		_request_rebuild()
@export_range(0.5,3.0,0.05) var slab_length := 1.35:
	set(value):
		slab_length = clampf(value,0.5,3.0)
		_request_rebuild()
@export var paving_seed := 137:
	set(value):
		paving_seed = value
		_request_rebuild()
@export var paving_color := Color("c7c1af"):
	set(value):
		paving_color = value
		_update_material()
@export var end_fade := Vector2(0.8,0.8):
	set(value):
		end_fade = value.max(Vector2.ZERO)
		_update_material()
@export_range(0.04,0.4,0.01) var edge_softness := 0.18:
	set(value):
		edge_softness = value
		_update_material()
@export_range(0.0,1.0,0.05) var irregularity := 0.5:
	set(value):
		irregularity = value
		_request_rebuild()
@export_range(0.15,1.0,0.05) var breakup_size := 0.48:
	set(value):
		breakup_size = value
		_update_material()
@export var collision_enabled := true:
	set(value):
		collision_enabled = value
		_request_rebuild()
@export_tool_button("Regenerate curved path") var regenerate = rebuild
var _queued := false
var _material: ShaderMaterial
var _length := 0.0

func _enter_tree() -> void:
	if not curve_changed.is_connected(_request_rebuild): curve_changed.connect(_request_rebuild)

func _ready() -> void:
	set_notify_transform(true)
	if not curve:
		curve = Curve3D.new()
		curve.add_point(Vector3(0,0,4),Vector3.ZERO,Vector3(2,0,-1))
		curve.add_point(Vector3(0,0,-4),Vector3(-2,0,1),Vector3.ZERO)
	rebuild()
	set_process(false)
	set_physics_process(false)

func _notification(what: int) -> void:
	if what==NOTIFICATION_TRANSFORM_CHANGED and is_node_ready(): ground_exclusion_changed.emit()

func _request_rebuild() -> void:
	if is_inside_tree() and not _queued:
		_queued = true
		_rebuild_queued.call_deferred()

func _rebuild_queued() -> void:
	if _queued: rebuild()

func _update_material() -> void:
	if _material:
		for key in [&"paving_color",&"end_fade",&"edge_softness",&"irregularity",&"breakup_size"]:
			_material.set_shader_parameter(key,get(key))
		_material.set_shader_parameter("footprint",Vector2(path_width,_length))
		_material.set_shader_parameter("paint_phase",float(posmod(paving_seed,997))*0.071)
		_material.set_shader_parameter("use_path_uv",true)
	ground_exclusion_changed.emit()

func get_path_length() -> float:
	return curve.get_baked_length() if curve else 0.0

func point_at(distance: float) -> Vector3:
	return curve.sample_baked(clampf(distance,0.0,get_path_length()),true) if curve and curve.point_count>1 else Vector3.ZERO

func _side_at(distance: float) -> Vector3:
	var tangent := point_at(distance+0.035)-point_at(distance-0.035)
	return Vector3(tangent.z,0,-tangent.x).normalized() if tangent.length_squared()>0.000001 else Vector3.RIGHT

func get_route_points(from_ratio: float=0.0,to_ratio: float=1.0,spacing: float=0.8,height: float=0.76) -> PackedVector3Array:
	var result := PackedVector3Array()
	var start := clampf(from_ratio,0.0,1.0)*get_path_length()
	var end := clampf(to_ratio,0.0,1.0)*get_path_length()
	var count := maxi(1,ceili(absf(end-start)/maxf(spacing,0.1)))
	for i in count+1:
		result.append(to_global(point_at(lerpf(start,end,float(i)/count)))+Vector3.UP*height)
	return result

func rebuild() -> void:
	_queued = false
	if not is_inside_tree(): return
	for child in get_children(true):
		if child.get_meta(&"curved_path_generated",false):
			remove_child(child)
			child.free()
	_material = null
	_length = get_path_length()
	if _length<0.05:
		ground_exclusion_changed.emit()
		return
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rng := RandomNumberGenerator.new()
	rng.seed = paving_seed
	var slabs := maxi(1,roundi(_length/slab_length))
	for slab in slabs:
		var start := _length*slab/slabs+(0.006 if slab>0 else 0.0)
		var end := _length*(slab+1)/slabs-(0.006 if slab<slabs-1 else 0.0)
		var half := path_width*0.5+rng.randf_range(-0.045,0.045)*irregularity
		var pigment := rng.randf_range(0.30,0.80)
		var pieces := maxi(1,ceili((end-start)/sample_spacing))
		for i in pieces:
			var a := lerpf(start,end,float(i)/pieces)
			var b := lerpf(start,end,float(i+1)/pieces)
			_band(tool,a,b,-half+0.035,half-0.035,0.0125,0.0125,pigment,0.0)
			_band(tool,a,b,-half,-half+0.035,-0.009,0.0125,pigment-0.025,0.0)
			_band(tool,a,b,half-0.035,half,0.0125,-0.009,pigment-0.025,0.0)
	# A single continuous underpainting follows the bend through every slab join.
	var sections := maxi(2,ceili(_length/sample_spacing))
	var faces := PackedVector3Array()
	for i in sections:
		var a := _length*i/sections
		var b := _length*(i+1)/sections
		_band(tool,a,b,-path_width*0.5,path_width*0.5,-0.0125,-0.0125,0.6,1.0)
		var corners := [_edge(a,-path_width*0.5,0.0125),_edge(b,-path_width*0.5,0.0125),_edge(b,path_width*0.5,0.0125),_edge(a,path_width*0.5,0.0125)]
		for index in [0,1,2,0,2,3]: faces.append(corners[index])
	var visual := MeshInstance3D.new()
	visual.name = "PaintedRibbon"
	visual.mesh = tool.commit()
	_material = ShaderMaterial.new()
	_material.shader = PAINT
	_update_material()
	visual.material_override = _material
	visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_generated(visual)
	if collision_enabled:
		var body := StaticBody3D.new()
		body.name = "WalkingSurface"
		var collider := CollisionShape3D.new()
		var shape := ConcavePolygonShape3D.new()
		shape.backface_collision = true
		shape.set_faces(faces)
		collider.shape = shape
		body.add_child(collider)
		_generated(body)
	ground_exclusion_changed.emit()

func _generated(child: Node) -> void:
	child.set_meta(&"curved_path_generated",true)
	add_child(child,false,Node.INTERNAL_MODE_BACK)

func _edge(distance: float,across: float,height: float) -> Vector3:
	return point_at(distance)+_side_at(distance)*across+Vector3.UP*height

func _band(tool: SurfaceTool,a: float,b: float,left: float,right: float,left_y: float,right_y: float,pigment: float,layer: float) -> void:
	var points := [_edge(a,left,left_y),_edge(b,left,left_y),_edge(b,right,right_y),_edge(a,right,right_y)]
	var uvs := [Vector2(left,a-_length*0.5),Vector2(left,b-_length*0.5),Vector2(right,b-_length*0.5),Vector2(right,a-_length*0.5)]
	for index in [0,1,2,0,2,3]:
		tool.set_normal(Vector3.UP)
		tool.set_color(Color(pigment,0.5,0.5,1))
		tool.set_uv(uvs[index])
		tool.set_uv2(Vector2(layer,0))
		tool.add_vertex(points[index])

func excludes_ground_point(world_point: Vector3) -> bool:
	if not curve or curve.point_count<2: return false
	var local := to_local(world_point)
	var distance := curve.get_closest_offset(local)
	var nearest := point_at(distance)
	if Vector2(local.x-nearest.x,local.z-nearest.z).length()>path_width*0.5-edge_softness*0.55: return false
	return distance>=end_fade.x*0.55 and get_path_length()-distance>=end_fade.y*0.55
