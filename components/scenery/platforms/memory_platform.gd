@tool
class_name MemoryPlatform
extends Node3D
## A finite walkable memory surface, with a pale pillar dissolving into the void.
const SURFACE_SHADER = preload("res://components/scenery/platforms/memory_platform.gdshader")
@export_group("Platform Shape")
@export_enum("Soft Oval", "Rounded Rectangle") var shape: int = 1:
	set(value):
		shape = value
		_request_rebuild()
@export var footprint := Vector2(22, 28):
	set(value):
		footprint = value.max(Vector2(2,2))
		_request_rebuild()
@export var platform_seed: int = 47:
	set(value):
		platform_seed = value
		_request_rebuild()
@export_range(0.0, 0.12, 0.005) var irregularity: float = 0.035:
	set(value):
		irregularity = value
		_request_rebuild()
@export_range(24, 96, 8) var outline_detail: int = 64:
	set(value):
		outline_detail = clampi(value, 24, 96)
		_request_rebuild()
## Optional simple closed outline in local X/Z meters; overrides Footprint/Shape.
@export var custom_outline: Curve2D:
	set(value):
		if custom_outline and custom_outline.changed.is_connected(_request_rebuild):
			custom_outline.changed.disconnect(_request_rebuild)
		custom_outline = value
		if custom_outline:
			custom_outline.changed.connect(_request_rebuild)
		_request_rebuild()
@export_group("Pillar")
@export_range(8.0, 80.0, 1.0) var pillar_depth: float = 32.0:
	set(value):
		pillar_depth = value
		_request_rebuild()
@export_range(0.0, 0.3, 0.01) var taper: float = 0.08:
	set(value):
		taper = value
		_request_rebuild()
@export_range(0.0, 8.0, 0.1) var fade_start: float = 1.2:
	set(value):
		fade_start = value
		_update_material()
@export_range(2.0, 60.0, 0.5) var fade_depth: float = 15.0:
	set(value):
		fade_depth = value
		_update_material()
@export_group("Colors")
@export var top_color := Color("f0eee3"):
	set(value):
		top_color = value
		_update_material()
@export var side_color := Color("dfded5"):
	set(value):
		side_color = value
		_update_material()
## The world sets this to its background/fog color when the memory is entered.
@export var void_color := Color(0.94, 0.935, 0.89):
	set(value):
		void_color = value
		_update_material()
@export_range(0.0, 0.03, 0.001) var pigment_strength: float = 0.006:
	set(value):
		pigment_strength = value
		_update_material()
@export_group("Boundary")
## Invisible rim collision stops the player a small distance before the visible lip.
@export_range(0.0, 1.0, 0.05) var edge_inset: float = 0.25:
	set(value):
		edge_inset = value
		_request_rebuild()
@export_range(1.0, 4.0, 0.1) var boundary_height: float = 2.0:
	set(value):
		boundary_height = value
		_request_rebuild()
var _outline := PackedVector2Array()
var _material: ShaderMaterial
var _queued: bool = false

func _ready() -> void:
	add_to_group(&"memory_platforms")
	rebuild()

func _request_rebuild() -> void:
	if is_inside_tree() and not _queued:
		_queued = true
		call_deferred("_rebuild_queued")

func _rebuild_queued() -> void:
	if _queued:
		rebuild()

func _update_material() -> void:
	if not _material:
		return
	for key in [&"top_color", &"side_color", &"void_color", &"pigment_strength", &"fade_start"]:
		_material.set_shader_parameter(key, get(key))
	# Always disappear before the mesh terminates, even on a short pillar.
	_material.set_shader_parameter("fade_depth", minf(fade_depth, pillar_depth * 0.92))

func make_outline() -> PackedVector2Array:
	var polygon := PackedVector2Array()
	if custom_outline and custom_outline.point_count >= 3:
		var curve := custom_outline.duplicate() as Curve2D
		curve.bake_interval = 0.05
		if not curve.get_point_position(0).is_equal_approx(curve.get_point_position(curve.point_count-1)):
			curve.add_point(curve.get_point_position(0),curve.get_point_in(0),curve.get_point_out(0))
		var length := curve.get_baked_length()
		for index in range(outline_detail):
			polygon.append(curve.sample_baked(length * index / outline_detail))
		if Geometry2D.triangulate_polygon(polygon).is_empty():
			polygon.clear()
	if polygon.is_empty():
		var phase := float(posmod(platform_seed, 997)) * 0.071
		var power := 1.0 if shape == 0 else 0.58
		for index in range(outline_detail):
			var angle := TAU * index / outline_detail
			var x := cos(angle)
			var z := sin(angle)
			var radius := 1.0 + irregularity * (sin(angle*3.0+phase)*0.65 + sin(angle*5.0-phase)*0.35)
			polygon.append(Vector2(signf(x)*pow(absf(x),power),signf(z)*pow(absf(z),power))*footprint*0.5*radius)
	if Geometry2D.is_polygon_clockwise(polygon):
		polygon.reverse()
	return polygon

func contains_ground_point(world_point: Vector3, margin: float = 0.0) -> bool:
	var local := to_local(world_point)
	var point := Vector2(local.x,local.z)
	var polygon := _outline if not _outline.is_empty() else make_outline()
	if not Geometry2D.is_point_in_polygon(point,polygon):
		return false
	if margin > 0.0:
		for index in range(polygon.size()):
			if point.distance_to(Geometry2D.get_closest_point_to_segment(point,polygon[index],polygon[(index+1)%polygon.size()])) < margin:
				return false
	return true

func _triangle(surface: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, top: bool = false) -> void:
	var normal := Vector3.UP if top else (b-a).cross(c-a).normalized()
	for point in [a,b,c]:
		surface.set_normal(normal)
		surface.set_color(Color(1,0,0,1) if top else Color(0,0,0,1))
		surface.add_vertex(point)

func _add_generated(node: Node) -> void:
	node.set_meta(&"generated_platform", true)
	add_child(node,false,Node.INTERNAL_MODE_BACK)

func rebuild() -> void:
	_queued = false
	if not is_inside_tree():
		return
	for child in get_children(true):
		if child.get_meta(&"generated_platform",false):
			remove_child(child)
			child.queue_free()
	_outline = make_outline()
	_material = ShaderMaterial.new()
	_material.shader = SURFACE_SHADER
	_update_material()
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var floor_faces := PackedVector3Array()
	var indices := Geometry2D.triangulate_polygon(_outline)
	for index in range(0,indices.size(),3):
		var a2 := _outline[indices[index]]
		var b2 := _outline[indices[index+1]]
		var c2 := _outline[indices[index+2]]
		var a := Vector3(a2.x,0,a2.y)
		var b := Vector3(b2.x,0,b2.y)
		var c := Vector3(c2.x,0,c2.y)
		# Up-facing collision triangles, regardless of outline winding conventions.
		if (b-a).cross(c-a).y < 0:
			var swap := b
			b = c
			c = swap
		_triangle(surface,a,b,c,true)
		# Godot collision faces use clockwise front-face winding.
		floor_faces.append_array(PackedVector3Array([c,b,a]))
	var rings: Array[PackedVector3Array] = []
	for depth_fraction in [0.0,0.008,0.07,0.2,0.4,0.65,1.0]:
		var ring := PackedVector3Array()
		for index in range(_outline.size()):
			var point := _outline[index]
			var offset := sin(index*1.7+platform_seed)*0.015 * sin(depth_fraction*PI*0.5)
			point *= 1.0 - taper*depth_fraction + offset
			ring.append(Vector3(point.x,-pillar_depth*depth_fraction,point.y))
		rings.append(ring)
	for row in range(rings.size()-1):
		for index in range(_outline.size()):
			var next := (index+1)%_outline.size()
			_triangle(surface,rings[row][index],rings[row+1][index],rings[row+1][next])
			_triangle(surface,rings[row][index],rings[row+1][next],rings[row][next])
	var visual := MeshInstance3D.new()
	visual.name = "PlatformSurface"
	visual.mesh = surface.commit()
	visual.material_override = _material
	visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_add_generated(visual)
	var body := StaticBody3D.new()
	body.name = "PlatformCollision"
	var floor_shape := ConcavePolygonShape3D.new()
	floor_shape.set_faces(floor_faces)
	var floor_collider := CollisionShape3D.new()
	floor_collider.name = "Floor"
	floor_collider.shape = floor_shape
	body.add_child(floor_collider)
	for index in range(_outline.size()):
		var a := _outline[index]
		var b := _outline[(index+1)%_outline.size()]
		var delta := b-a
		var inward := Vector2(-delta.y,delta.x).normalized()
		var middle := (a+b)*0.5
		if not Geometry2D.is_point_in_polygon(middle+inward*0.02,_outline):
			inward = -inward
		middle += inward*edge_inset
		var wall := CollisionShape3D.new()
		wall.name = "Rim_%02d" % index
		var box := BoxShape3D.new()
		box.size = Vector3(0.16,boundary_height,delta.length()+0.18)
		wall.shape = box
		wall.position = Vector3(middle.x,boundary_height*0.5-0.05,middle.y)
		wall.rotation.y = atan2(delta.x,delta.y)
		body.add_child(wall)
	_add_generated(body)
