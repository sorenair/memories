@tool
class_name PainterlyElkHerd
extends PainterlyConcertComponent
## Six shared silhouettes, instanced coats/poses/phases, one static body per herd.
const ELK_GEOMETRY = preload("res://components/animals/elk/elk_geometry.gd")
const ELK_PAINT = preload("res://components/animals/elk/elk.gdshader")

@export_group("Herd")
@export_range(1,48,1) var count: int = 8:
	set(value):
		count = clampi(value,1,48)
		_request_rebuild()
@export var footprint := Vector2(11,8):
	set(value):
		footprint = value.max(Vector2(2,2))
		_request_rebuild()
## Spacing is never silently reduced. Increase the footprint for a larger herd.
@export_range(1.8,5.0,0.1) var minimum_spacing: float = 2.5:
	set(value):
		minimum_spacing = clampf(value,1.8,5)
		_request_rebuild()
@export_range(0.0,1.0,0.05) var bull_fraction: float = 0.25:
	set(value):
		bull_fraction = clampf(value,0,1)
		_request_rebuild()
@export_range(0.0,1.0,0.05) var calf_fraction: float = 0.20:
	set(value):
		calf_fraction = clampf(value,0,1)
		_request_rebuild()
@export_range(0.5,1.6,0.05) var elk_size: float = 1.0:
	set(value):
		elk_size = clampf(value,0.5,1.6)
		_request_rebuild()
@export_range(-180.0,180.0,5.0) var heading_degrees: float = 0.0:
	set(value):
		heading_degrees = value
		_request_rebuild()
@export_range(0.0,180.0,5.0) var heading_variation: float = 70.0:
	set(value):
		heading_variation = clampf(value,0,180)
		_request_rebuild()
@export var antler_color := Color("c5b38f"):
	set(value):
		antler_color = value
		_request_rebuild()
@export_group("Idle")
## Cycle through scanning and grazing while keeping the preferred pose as a bias.
@export var varied_idle := false:
	set(value):
		varied_idle = value
		_apply_material()
@export_range(0.0,1.0,0.05) var grazing_fraction: float = 0.45:
	set(value):
		grazing_fraction = clampf(value,0,1)
		_request_rebuild()
@export_range(0.0,1.5,0.05) var idle_motion: float = 0.7:
	set(value):
		idle_motion = clampf(value,0,1.5)
		_apply_material()
@export_range(0.0,2.0,0.05) var idle_speed: float = 1.0:
	set(value):
		idle_speed = clampf(value,0,2)
		_apply_material()

var generated_count: int = 0
var placements: Array[Dictionary] = []
var _visual_time: float = -1.0

func _init() -> void:
	body_color = Color("b29a73")
	accent_color = Color("635346")
	trim_color = Color("d7c7a4")

func _apply_material() -> void:
	if not _material: return
	super._apply_material()
	_material.set_shader_parameter("use_instance_custom",true)
	_material.set_shader_parameter("varied_idle",varied_idle)
	_material.set_shader_parameter("idle_motion",idle_motion)
	_material.set_shader_parameter("idle_speed",idle_speed)
	_material.set_shader_parameter("animation_time",_visual_time)

func rebuild() -> void:
	_queued = false
	if not is_inside_tree(): return
	if is_instance_valid(_generated_root):
		remove_child(_generated_root)
		_generated_root.free()
	_generated_root = Node3D.new()
	_generated_root.name = "Generated"
	add_child(_generated_root,false,Node.INTERNAL_MODE_BACK)
	_material = ShaderMaterial.new()
	_material.shader = ELK_PAINT
	_apply_material()
	var rng := RandomNumberGenerator.new()
	rng.seed = prop_seed
	var variants: Array[Dictionary] = []
	var buckets: Array = [[],[],[],[],[],[]]
	var types := [0,0,1,1,2,3]
	for i in range(types.size()):
		var c := _config()
		c.merge({"elk_type":types[i],"elk_size":elk_size,"antler_color":antler_color,"antler_size":1.0,"antler_spread":rng.randf_range(0.85,1.15)})
		c.prop_seed = prop_seed+i*127
		variants.append(ELK_GEOMETRY.new().elk(c))
	placements.clear()
	_collision_data.clear()
	var body := StaticBody3D.new()
	body.name = "Collision"
	var bulls := mini(count,roundi(count*bull_fraction))
	var calves := mini(count-bulls,roundi(count*calf_fraction))
	for i in range(count):
		var found := false
		var position_2d := Vector2.ZERO
		for attempt in range(320):
			position_2d = Vector2(rng.randf_range(-1,1),rng.randf_range(-1,1))
			if position_2d.length_squared() > 1.0: continue
			position_2d *= footprint*0.5
			found = true
			for existing: Dictionary in placements:
				var p: Vector3 = existing.transform.origin
				if position_2d.distance_to(Vector2(p.x,p.z)) < minimum_spacing*elk_size:
					found = false
					break
			if found: break
		if not found: break
		var variant: int = (i%2 if i%3 != 2 else 5) if i < bulls else (4 if i < bulls+calves else 2+i%2)
		var scale_factor := rng.randf_range(0.94,1.06)
		var rotation := deg_to_rad(heading_degrees+rng.randf_range(-heading_variation,heading_variation))
		var transform_3d := Transform3D(Basis(Vector3.UP,rotation).scaled(Vector3.ONE*scale_factor),Vector3(position_2d.x,0,position_2d.y))
		var pose := 2 if rng.randf() < grazing_fraction else rng.randi_range(0,1)
		var custom := Color(rng.randf(),float(pose)*0.5,rng.randf(),rng.randf_range(0.75,1.0))
		var item := {"transform":transform_3d,"custom":custom,"variant":variant,"morph":variants[variant].morph}
		placements.append(item)
		buckets[variant].append(item)
		if collision_enabled:
			var info: Dictionary = variants[variant].colliders[0]
			var shape := BoxShape3D.new()
			shape.size = info.size*scale_factor
			var collision := CollisionShape3D.new()
			collision.name = "Elk%d" % i
			collision.shape = shape
			collision.transform = Transform3D(Basis(Vector3.UP,rotation),transform_3d*info.center)
			body.add_child(collision)
	generated_count = placements.size()
	if collision_enabled: _generated_root.add_child(body)
	else: body.free()
	for variant in range(variants.size()):
		var items: Array = buckets[variant]
		if items.is_empty(): continue
		var instances := MultiMesh.new()
		instances.transform_format = MultiMesh.TRANSFORM_3D
		instances.use_custom_data = true
		instances.mesh = variants[variant].mesh
		instances.instance_count = items.size()
		var bounds: AABB = items[0].transform*variants[variant].bounds
		for j in range(items.size()):
			instances.set_instance_transform(j,items[j].transform)
			instances.set_instance_custom_data(j,items[j].custom)
			bounds = bounds.merge(items[j].transform*variants[variant].bounds)
		var visual := MultiMeshInstance3D.new()
		visual.name = "ElkVariant%d" % variant
		visual.multimesh = instances
		visual.material_override = _material
		visual.custom_aabb = bounds
		visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		visual.visibility_range_end = visibility_distance
		_generated_root.add_child(visual)
	if contact_shadow_enabled and generated_count > 0:
		var plane := PlaneMesh.new()
		plane.size = Vector2(1.0,2.30)
		var shadows := MultiMesh.new()
		shadows.transform_format = MultiMesh.TRANSFORM_3D
		shadows.mesh = plane
		shadows.instance_count = generated_count
		for i in range(generated_count):
			var item: Dictionary = placements[i]
			shadows.set_instance_transform(i,item.transform*Transform3D(Basis.IDENTITY.scaled(Vector3(item.morph.x,1,item.morph.z)),Vector3(0,0.012,-0.15*item.morph.z)))
		var visual := MultiMeshInstance3D.new()
		visual.name = "Contact_Herd"
		visual.multimesh = shadows
		var paint := ShaderMaterial.new()
		paint.shader = CONTACT
		paint.set_shader_parameter("shadow_color",Color(0.31,0.32,0.31,0.22))
		visual.material_override = paint
		visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		visual.visibility_range_end = visibility_distance
		_generated_root.add_child(visual)
	_sync_recall()
	update_configuration_warnings()
	ground_exclusion_changed.emit()

func _get_configuration_warnings() -> PackedStringArray:
	if is_node_ready() and generated_count < count:
		return ["Only %d of %d elk fit at the requested spacing. Increase Footprint or reduce Count." % [generated_count,count]]
	return []

func seek_time(seconds: float) -> void:
	_visual_time = seconds
	_apply_material()
