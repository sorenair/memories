@tool
class_name PainterlySurfacePath
extends "res://components/groundcover/paving/painterly_curved_path.gd"
## Surface treatments share the existing Curve3D route/guidance API.
const GEOMETRY = preload("res://components/groundcover/paths/surface_path_geometry.gd")
const SURFACE_PAINT = preload("res://components/groundcover/paths/surface_path.gdshader")

@export_group("Surface")
@export_enum("Earth Trail", "Gravel Walk", "Flagstone", "Urban Pavers") var surface_style: int = 0:
	set(value):
		surface_style = clampi(value,0,3)
		notify_property_list_changed()
		_request_rebuild()
@export var shoulder_color := Color("98926f"):
	set(value):
		shoulder_color = value
		_update_material()
@export var stone_color := Color("bcb8a4"):
	set(value):
		stone_color = value
		_update_material()
@export_range(0.0,0.25,0.01) var width_variation: float = 0.14:
	set(value):
		width_variation = clampf(value,0,0.25)
		_request_rebuild()
@export_range(0.0,0.05,0.005) var crown_height: float = 0.018:
	set(value):
		crown_height = clampf(value,0,0.05)
		_request_rebuild()
@export_range(0.0,1.0,0.05) var detail_density: float = 0.5:
	set(value):
		detail_density = clampf(value,0,1)
		_request_rebuild()
## Two worn lanes with a grassy median, useful for vineyard/farm tracks.
@export var twin_tracks: bool = false:
	set(value):
		twin_tracks = value
		_update_material()
## Draw feathered ground before transparent scenery where their bounds overlap.
@export_range(-20, 20, 1) var surface_render_priority := 0:
	set(value):
		surface_render_priority = value
		if _material:
			_material.render_priority = surface_render_priority

@export_group("Stone Layout")
@export_range(0.3,1.4,0.05) var stone_size: float = 0.75:
	set(value):
		stone_size = clampf(value,0.3,1.4)
		_request_rebuild()
@export_range(0.008,0.10,0.002) var joint_width: float = 0.028:
	set(value):
		joint_width = clampf(value,0.008,0.1)
		_request_rebuild()

var generated_triangles: int = 0

func _init() -> void:
	paving_color = Color("b6a182")
	irregularity = 0.8
	edge_softness = 0.26
	end_fade = Vector2(1.0,1.0)

func _validate_property(property: Dictionary) -> void:
	if property.name=="slab_length": property.usage = PROPERTY_USAGE_NONE
	if property.name in ["stone_size","joint_width"] and surface_style<2:
		property.usage = PROPERTY_USAGE_STORAGE
	if property.name=="detail_density" and surface_style>=2:
		property.usage = PROPERTY_USAGE_STORAGE

func get_half_width(distance: float, side: float = 1.0) -> float:
	var phase := float(posmod(paving_seed,997))*0.071
	var envelope := minf(smoothstep(0,1.2,distance),smoothstep(0,1.2,_length-distance))
	var wave := sin(distance*0.83+phase+side*1.7)*0.65+sin(distance*1.71-phase+side*0.6)*0.35
	return path_width*0.5*(1.0+wave*width_variation*irregularity*envelope)

func _side_at(distance: float) -> Vector3:
	# Average the frame over a small walking-sized span, avoiding baked-curve jitters.
	var span := clampf(path_width*0.12,0.12,0.35)
	var tangent := point_at(distance+span)-point_at(distance-span)
	return Vector3(tangent.z,0,-tangent.x).normalized() if tangent.length_squared()>0.000001 else Vector3.RIGHT

func _edge(distance: float, across: float, height: float) -> Vector3:
	var ratio := across/(path_width*0.5)
	var side := -1.0 if across<0 else 1.0
	var envelope := minf(smoothstep(0,0.7,distance),smoothstep(0,0.7,_length-distance))
	var crown := crown_height*maxf(0,1.0-ratio*ratio)*envelope
	return point_at(distance)+_side_at(distance)*ratio*get_half_width(distance,side)+Vector3.UP*(height+crown)

func _update_material() -> void:
	if _material:
		for key in [&"paving_color",&"shoulder_color",&"stone_color",&"end_fade",&"edge_softness",&"breakup_size",&"surface_style",&"twin_tracks"]:
			_material.set_shader_parameter(key,get(key))
		_material.set_shader_parameter("path_width",path_width)
		_material.set_shader_parameter("path_length",_length)
		_material.set_shader_parameter("paint_phase",float(posmod(paving_seed,997))*0.071)
	ground_exclusion_changed.emit()

func rebuild() -> void:
	_queued = false
	if not is_inside_tree(): return
	for child in get_children(true):
		if child.get_meta(&"curved_path_generated",false):
			remove_child(child)
			child.free()
	_material = null
	generated_triangles = 0
	_length = get_path_length()
	if _length<0.05:
		ground_exclusion_changed.emit()
		return
	var data: Dictionary = GEOMETRY.new().build(self)
	var visual := MeshInstance3D.new()
	visual.name = "PaintedRibbon"
	visual.mesh = data.mesh
	_material = ShaderMaterial.new()
	_material.shader = SURFACE_PAINT
	_material.render_priority = surface_render_priority
	_update_material()
	visual.material_override = _material
	visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_generated(visual)
	generated_triangles = data.mesh.surface_get_array_index_len(0)/3
	if collision_enabled:
		var body := StaticBody3D.new()
		body.name = "WalkingSurface"
		var collision := CollisionShape3D.new()
		var shape := ConcavePolygonShape3D.new()
		shape.backface_collision = true
		shape.set_faces(data.faces)
		collision.shape = shape
		body.add_child(collision)
		_generated(body)
	ground_exclusion_changed.emit()

func excludes_ground_point(world_point: Vector3) -> bool:
	if not curve or curve.point_count<2: return false
	var local := to_local(world_point)
	var distance := curve.get_closest_offset(local)
	var nearest := point_at(distance)
	var across := (local-nearest).dot(_side_at(distance))
	var half := get_half_width(distance,signf(across))-edge_softness*0.6
	# Include longitudinal separation at the caps; zero end fade must not clear
	# an infinite strip of grass beyond the first/last curve point.
	if Vector2(local.x-nearest.x,local.z-nearest.z).length()>half: return false
	if twin_tracks and absf(across)<path_width*0.105: return false
	return distance>=end_fade.x*0.55 and _length-distance>=end_fade.y*0.55
