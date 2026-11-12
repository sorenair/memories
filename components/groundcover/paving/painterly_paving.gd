@tool
class_name PainterlyPaving
extends Node3D
## A remembered sidewalk: soft, uneven slabs whose pigment wears away at the edges.
## The strip runs along local Z. Collision stays a continuous, shallow walking surface.
signal ground_exclusion_changed
const PAINT = preload("res://components/groundcover/paving/painterly_paving.gdshader")

@export var footprint := Vector2(1.6, 13.5):
	set(value):
		footprint = value.clamp(Vector2(0.5,0.5), Vector2(8,40))
		_request_rebuild()
@export_range(0.5, 3.0, 0.05) var slab_length: float = 1.65:
	set(value):
		slab_length = clampf(value,0.5,3.0)
		_request_rebuild()
@export var paving_seed: int = 137:
	set(value):
		paving_seed = value
		_request_rebuild()
@export_range(0.0,1.0,0.05) var irregularity: float = 0.7:
	set(value):
		irregularity = clampf(value,0,1)
		_request_rebuild()
@export_group("Paint and Erosion")
@export var paving_color := Color("c7c1af"):
	set(value):
		paving_color = value
		_update_material()
## Dissolve length in meters at the negative-Z / positive-Z ends. Zero keeps an end solid.
@export var end_fade := Vector2(2.4, 2.6):
	set(value):
		end_fade = value.clamp(Vector2.ZERO,Vector2.ONE*12)
		_update_material()
@export_range(0.04,0.4,0.01) var edge_softness: float = 0.18:
	set(value):
		edge_softness = clampf(value,0.04,0.4)
		_update_material()
@export_range(0.15,1.0,0.05) var breakup_size: float = 0.48:
	set(value):
		breakup_size = clampf(value,0.15,1.0)
		_update_material()
@export_tool_button("Regenerate paving") var regenerate = rebuild

var _queued := false
var _material: ShaderMaterial
var _slabs: Array[PackedVector2Array] = []

func _ready() -> void:
	set_notify_transform(true)
	rebuild()
	set_process(false)
	set_physics_process(false)

func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSFORM_CHANGED and is_node_ready(): ground_exclusion_changed.emit()

func _request_rebuild() -> void:
	if is_inside_tree() and not _queued:
		_queued = true
		call_deferred("_rebuild_queued")

func _rebuild_queued() -> void:
	if _queued: rebuild()

func _update_material() -> void:
	if not _material: return
	for key in [&"paving_color", &"footprint", &"end_fade", &"edge_softness", &"breakup_size", &"irregularity"]:
		_material.set_shader_parameter(key,get(key))
	_material.set_shader_parameter("paint_phase", float(posmod(paving_seed,997))*0.071)
	ground_exclusion_changed.emit()

func rebuild() -> void:
	_queued = false
	if not is_inside_tree(): return
	for child in get_children(true):
		if child.get_meta(&"paving_generated",false):
			remove_child(child)
			child.free()
	_slabs.clear()
	var rng := RandomNumberGenerator.new()
	rng.seed = paving_seed
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var count := maxi(1, roundi(footprint.y/slab_length))
	var joints := PackedFloat32Array([-footprint.y*0.5])
	for i in range(1,count):
		joints.append(lerpf(-footprint.y*0.5,footprint.y*0.5,float(i)/count) + rng.randf_range(-0.14,0.14)*irregularity)
	joints.append(footprint.y*0.5)
	for i in count:
		var center := Vector2(rng.randf_range(-0.045,0.045)*irregularity, (joints[i]+joints[i+1])*0.5)
		var half := Vector2(footprint.x*0.5+rng.randf_range(-0.07,0.055)*irregularity, (joints[i+1]-joints[i])*0.5-0.003)
		var angle := rng.randf_range(-0.025,0.025)*irregularity
		var polygon := _outline(half,center,angle,rng)
		_slabs.append(polygon)
		var inner := PackedVector2Array()
		for point in polygon:
			inner.append(center+(point-center)*Vector2(1.0-0.055/half.x,1.0-0.055/half.y))
		var pigment := rng.randf_range(0.30,0.80)
		for j in polygon.size():
			var next := (j+1)%polygon.size()
			_vertex(tool,center,0.0125,Vector3.UP,pigment)
			_vertex(tool,inner[j],0.0125,Vector3.UP,pigment)
			_vertex(tool,inner[next],0.0125,Vector3.UP,pigment)
			var outward := (polygon[j]-center).normalized()
			var normal := Vector3(outward.x,0.8,outward.y).normalized()
			for index in [0,1,2,0,2,3]:
				var point: Vector2 = [inner[j],polygon[j],polygon[next],inner[next]][index]
				_vertex(tool,point,0.0125 if index in [0,3] else -0.009,normal,pigment-0.025)
	# A faint underpainting joins the slabs without outlining them with bright grout.
	# It shares the same batch and erosion mask, and never writes a solid rectangle.
	var wash := [Vector2(-footprint.x,-footprint.y)*0.5,Vector2(footprint.x,-footprint.y)*0.5,
		Vector2(footprint.x,footprint.y)*0.5,Vector2(-footprint.x,footprint.y)*0.5]
	for index in [0,1,2,0,2,3]: _vertex(tool,wash[index],-0.0125,Vector3.UP,0.6,1.0)
	var mesh := MeshInstance3D.new()
	mesh.name = "PaintedSlabs"
	mesh.mesh = tool.commit()
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_material = ShaderMaterial.new()
	_material.shader = PAINT
	_update_material()
	mesh.material_override = _material
	_add_generated(mesh)
	# Preserve the old sidewalk's support height and the original LAN arrival.
	var body := StaticBody3D.new()
	body.name = "WalkingSurface"
	var shape := BoxShape3D.new()
	shape.size = Vector3(footprint.x,0.025,footprint.y)
	var collision := CollisionShape3D.new()
	collision.shape = shape
	body.add_child(collision)
	_add_generated(body)
	ground_exclusion_changed.emit()

func _add_generated(node: Node) -> void:
	node.set_meta(&"paving_generated",true)
	add_child(node,false,Node.INTERNAL_MODE_BACK)

func _vertex(tool: SurfaceTool, point: Vector2, height: float, normal: Vector3, pigment: float, layer: float = 0.0) -> void:
	tool.set_normal(normal)
	tool.set_color(Color(pigment,0.5,0.5,1))
	tool.set_uv2(Vector2(layer,0))
	tool.add_vertex(Vector3(point.x,height,point.y))

func _outline(half: Vector2, center: Vector2, angle: float, rng: RandomNumberGenerator) -> PackedVector2Array:
	# Rounded corners with gently uneven shoulders, rather than a grid of boxes.
	var result := PackedVector2Array()
	var radius := minf(0.10,minf(half.x,half.y)*0.30)
	for corner in 4:
		var signs := Vector2(1 if corner in [0,3] else -1,1 if corner in [0,1] else -1)
		var pivot := signs*(half-Vector2.ONE*radius)
		for step in 4:
			var a := PI*0.5*corner + PI*0.5*float(step)/3.0
			var offset := Vector2(cos(a),sin(a))*radius
			# Trace four rounded shoulders around the XZ perimeter.
			var p := pivot + offset
			p += Vector2(rng.randf_range(-0.012,0.012),rng.randf_range(-0.012,0.012))*irregularity
			result.append(center+p.rotated(angle))
	return result

func excludes_ground_point(world_point: Vector3) -> bool:
	var local := to_local(world_point)
	var p := Vector2(local.x,local.z)
	# Let foliage nibble into the worn pigment instead of leaving a rectangular cutout.
	if absf(p.x)>footprint.x*0.5-edge_softness*0.55: return false
	if end_fade.x>0 and p.y+footprint.y*0.5<end_fade.x*0.55: return false
	if end_fade.y>0 and footprint.y*0.5-p.y<end_fade.y*0.55: return false
	for polygon in _slabs:
		if Geometry2D.is_point_in_polygon(p,polygon): return true
	return false
