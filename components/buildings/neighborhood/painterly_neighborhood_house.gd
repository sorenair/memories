@tool
class_name PainterlyNeighborhoodHouse
extends PainterlyHouse
## Reuses the bungalow's paint, geometry helpers, lifecycle and recall contract.
const NEIGHBORHOOD = preload("res://components/buildings/neighborhood/neighborhood_geometry.gd")
@export_group("Neighborhood Profile")
@export_enum("Bungalow", "Front Gable", "Side Gable", "Porch Duplex") var profile := 1:
	set(value):
		profile = clampi(value,0,3)
		_request_rebuild()
@export_range(1,3,1) var storeys := 2:
	set(value):
		storeys = clampi(value,1,3)
		_request_rebuild()
@export var porch_enabled := true:
	set(value):
		porch_enabled = value
		_request_rebuild()
@export_range(0.8,2.2,0.1) var porch_depth := 1.4:
	set(value):
		porch_depth = clampf(value,0.8,2.2)
		_request_rebuild()
@export var recall_anchor: Node3D

func get_recall_anchor() -> Node3D:
	return recall_anchor

func get_entrance_run() -> float:
	return (porch_depth if porch_enabled and profile!=0 else 0.0)+step_count*step_depth

func rebuild() -> void:
	if profile==0:
		super.rebuild()
		return
	_queued = false
	if not is_inside_tree(): return
	for node in _generated:
		if is_instance_valid(node):
			remove_child(node)
			node.free()
	_generated.clear()
	var config := {}
	for key in ["footprint","wall_height","foundation_height","roof_height","roof_overhang","side_windows","door_width","stair_width","step_count","step_depth","railings","wall_color","trim_color","roof_color","wood_color","glass_color","foundation_color","rail_color","house_seed","shingle_size","window_warmth","porch_lamp","profile","storeys","porch_enabled","porch_depth"]:
		config[key] = get(key)
	var material := ShaderMaterial.new()
	material.shader = PAINT
	material.set_shader_parameter("wall_top",foundation_height+wall_height*storeys)
	material.set_shader_parameter("foundation_height",foundation_height)
	material.set_shader_parameter("pigment_strength",pigment_strength)
	material.set_shader_parameter("paint_phase",float(posmod(house_seed,1000))*0.173)
	var exterior := MeshInstance3D.new()
	exterior.name = "Exterior"
	exterior.mesh = NEIGHBORHOOD.create(config)
	exterior.material_override = material
	exterior.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	exterior.visibility_range_end = 85.0
	_add_generated(exterior)
	var front := footprint.y*0.5
	var deck := porch_depth if porch_enabled else 0.0
	if collision_enabled:
		var body := StaticBody3D.new()
		body.name = "BuildingCollision"
		_box_shape(body,Vector3(0,(foundation_height+wall_height*storeys)*0.5,0),Vector3(footprint.x,foundation_height+wall_height*storeys,footprint.y))
		if porch_enabled:
			_box_shape(body,Vector3(0,foundation_height*0.5,front+deck*0.5),Vector3(footprint.x*0.94,foundation_height,deck))
			# Posts and guardrails are solid; the center stays open to the steps.
			for side in [-1.0,1.0]:
				_box_shape(body,Vector3(side*footprint.x*0.45,foundation_height+0.55,front+deck*0.5),Vector3(0.12,1.1,deck))
				if railings:
					var width := (footprint.x*0.90-stair_width)*0.5
					_box_shape(body,Vector3(side*(stair_width*0.5+width*0.5),foundation_height+0.45,front+deck-0.05),Vector3(width,0.9,0.12))
		var ramp := ConvexPolygonShape3D.new()
		var points := PackedVector3Array()
		for x in [-stair_width*0.5,stair_width*0.5]:
			points.append(Vector3(x,0,front+deck))
			points.append(Vector3(x,foundation_height,front+deck))
			points.append(Vector3(x,0,front+deck+step_count*step_depth))
		ramp.points = points
		var stairs := CollisionShape3D.new()
		stairs.name = "StairRamp"
		stairs.shape = ramp
		body.add_child(stairs)
		_add_generated(body)
	for id in ["FrontDoor","Approach"]:
		var marker := Marker3D.new()
		marker.name = id
		marker.position = Vector3(0,foundation_height,front+0.35) if id=="FrontDoor" else Vector3(0,0,front+get_entrance_run()+0.8)
		_add_generated(marker)
	_sync_recall()
	ground_exclusion_changed.emit()

func _box_shape(body: StaticBody3D,at: Vector3,size: Vector3) -> void:
	var shape := BoxShape3D.new()
	shape.size = size
	var collider := CollisionShape3D.new()
	collider.shape = shape
	collider.position = at
	body.add_child(collider)

func excludes_ground_point(world_point: Vector3) -> bool:
	if profile==0: return super.excludes_ground_point(world_point)
	var p := to_local(world_point)
	var front := footprint.y*0.5
	var deck := porch_depth if porch_enabled else 0.0
	return (absf(p.x)<=footprint.x*0.5+0.05 and absf(p.z)<=front+0.05) or (porch_enabled and absf(p.x)<=footprint.x*0.47+0.05 and p.z>=front and p.z<=front+deck) or (absf(p.x)<=stair_width*0.5+0.05 and p.z>=front+deck and p.z<=front+get_entrance_run())
