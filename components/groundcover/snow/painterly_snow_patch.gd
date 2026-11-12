@tool
class_name PainterlySnowPatch
extends Node3D
## Shallow sculpted snow, with a timestamped footprint field updated only on steps.
signal ground_exclusion_changed
const SNOW_SHADER = preload("res://components/groundcover/snow/snow_ground.gdshader")
@export_group("Snow Patch")
@export var patch_size := Vector2(5.2,3.6):
	set(value):
		patch_size = value.max(Vector2(1,1))
		_request_rebuild()
## Optional closed outline in local X/Z meters. Supports concave connected areas;
## leave empty for the existing soft oval. May share a platform's Custom Outline.
@export var custom_outline: Curve2D:
	set(value):
		if custom_outline and custom_outline.changed.is_connected(_request_rebuild):
			custom_outline.changed.disconnect(_request_rebuild)
		custom_outline = value
		if custom_outline:
			custom_outline.changed.connect(_request_rebuild)
		_request_rebuild()
@export var patch_seed: int = 419:
	set(value):
		patch_seed = value
		_request_rebuild()
@export_range(0.02,0.15,0.005) var snow_depth: float = 0.065:
	set(value):
		snow_depth = value
		_request_rebuild()
@export_range(0.0,0.1,0.005) var puffiness: float = 0.07:
	set(value):
		puffiness = value
		_request_rebuild()
@export_range(32,96,8) var mesh_detail: int = 64:
	set(value):
		mesh_detail = clampi(value,32,96)
		_request_rebuild()
## Relative paths to ponds or other regions where snow must not cover the ground.
@export var ground_exclusions: Array[NodePath] = []:
	set(value):
		ground_exclusions = value
		_request_rebuild()
@export_group("Snow Colors")
@export var snow_color := Color("f6f8f1"):
	set(value):
		snow_color = value
		_update_material()
@export var shade_color := Color("b9ccda"):
	set(value):
		shade_color = value
		_update_material()
## Match the memory platform/ground color to soften the outer edge.
@export var edge_color := Color("f0eee3"):
	set(value):
		edge_color = value
		_update_material()
@export_group("Footsteps")
@export var track_footprints: bool = true
## Seconds a print remains at full strength before it begins to disappear.
@export_range(0.0,60.0,0.5) var footprint_linger: float = 8.0:
	set(value):
		footprint_linger = maxf(value,0.0)
		_update_material()
@export_range(0.2,10.0,0.1) var footprint_fade_duration: float = 2.5:
	set(value):
		footprint_fade_duration = maxf(value,0.2)
		_update_material()
@export_range(0.005,0.06,0.001) var footprint_depth: float = 0.025:
	set(value):
		footprint_depth = value
		_update_material()
## Width and length of each shoe impression in meters.
@export var footprint_size := Vector2(0.17,0.30):
	set(value):
		footprint_size = value.max(Vector2(0.05,0.1))
@export_range(0.2,0.9,0.02) var step_spacing: float = 0.48
@export_group("Rendering")
@export_enum("Mobile (128)","Balanced (256)","Detailed (512)") var footprint_quality: int = 1:
	set(value):
		footprint_quality = clampi(value,0,2)
		_request_rebuild()
var _ground_regions: Array[Node3D] = []
var _outline := PackedVector2Array()
var _custom_shape := false
var _shape_bounds := Rect2()
var _field_size := Vector2(5.2,3.6)*1.12
var _field_center := Vector2.ZERO
var _noise: FastNoiseLite
var _material: ShaderMaterial
var _field: Image
var _texture: ImageTexture
var _dirty: bool = false
var _queued: bool = false
var _clock: float = 0.0
var _trackers: Dictionary = {}
var _players: Array[Node] = []
var _scan_time: float = 0.0
var _stamp_count: int = 0

func _ready() -> void:
	set_notify_transform(true)
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	rebuild()
	set_physics_process(not Engine.is_editor_hint())

func _notification(what: int) -> void:
	if what==NOTIFICATION_TRANSFORM_CHANGED and is_inside_tree():
		_trackers.clear()
		if not ground_exclusions.is_empty():
			_request_rebuild()
		ground_exclusion_changed.emit()

func _request_rebuild() -> void:
	_outline = PackedVector2Array()
	if is_inside_tree() and not _queued:
		_queued = true
		call_deferred("_rebuild_queued")

func _rebuild_queued() -> void:
	if _queued:
		rebuild()

func _radius(angle: float) -> float:
	var phase := float(posmod(patch_seed,997))*0.071
	return 1.0+sin(angle*3.0+phase)*0.035+sin(angle*7.0-phase)*0.018

func _radial(point: Vector2) -> float:
	if _custom_shape:
		# Only the outside perimeter melts down. Interior joins have no bank/seam.
		var distance := INF
		for index in _outline.size():
			distance = minf(distance,point.distance_to(Geometry2D.get_closest_point_to_segment(
				point,_outline[index],_outline[(index+1)%_outline.size()])))
		return 1.0 + (-distance if Geometry2D.is_point_in_polygon(point,_outline) else distance)/0.75
	var scaled := point/(patch_size*0.5)
	return scaled.length()/_radius(atan2(scaled.y,scaled.x))

func _height(point: Vector2) -> float:
	var radial := _radial(point)
	var bank := smoothstep(0.0,0.24,1.0-radial)
	var puff := _noise.get_noise_2d(point.x,point.y)*0.5+0.5
	var broad := _noise.get_noise_2d(point.x*0.45+41.0,point.y*0.45-19.0)*0.5+0.5
	return 0.004+bank*(snow_depth*(0.68+broad*0.32)+puffiness*pow(puff,1.5))

func excludes_ground_point(world_point: Vector3) -> bool:
	var point := to_local(world_point)
	return _radial(Vector2(point.x,point.z)) < 1.01 and not _ground_excluded(world_point)

func _update_material() -> void:
	if not _material:
		return
	for key in [&"snow_color",&"shade_color",&"edge_color",&"footprint_linger",&"footprint_fade_duration",&"footprint_depth"]:
		_material.set_shader_parameter(key,get(key))
	_material.set_shader_parameter("field_size",_field_size)
	_material.set_shader_parameter("snow_time",_clock)

func rebuild() -> void:
	_queued = false
	if not is_inside_tree():
		return
	for child in get_children(true):
		if child.get_meta(&"generated_snow_patch",false):
			remove_child(child)
			child.queue_free()
	_trackers.clear()
	_clock = 0.0
	_stamp_count = 0
	_dirty = false
	_noise = FastNoiseLite.new()
	_noise.seed = patch_seed
	_noise.frequency = 0.85
	_noise.fractal_octaves = 2
	_prepare_shape()
	var resolution: int = [128,256,512][footprint_quality]
	_field = Image.create(resolution,resolution,false,Image.FORMAT_RGF)
	_texture = ImageTexture.create_from_image(_field)
	_material = ShaderMaterial.new()
	_material.shader = SNOW_SHADER
	_material.set_shader_parameter("footprint_field",_texture)
	_material.set_shader_parameter("field_texel",Vector2.ONE/resolution)
	_update_material()
	_bake_coverage()
	var arrays := _custom_mesh_arrays() if _custom_shape else _oval_mesh_arrays()
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	var visual := MeshInstance3D.new()
	visual.name = "SnowSurface"
	visual.mesh = mesh
	visual.material_override = _material
	visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	visual.custom_aabb = mesh.get_aabb().grow(0.08)
	visual.set_meta(&"generated_snow_patch",true)
	add_child(visual,false,Node.INTERNAL_MODE_BACK)
	ground_exclusion_changed.emit()

func _prepare_shape() -> void:
	_custom_shape = false
	_outline.clear()
	if custom_outline and custom_outline.point_count >= 3:
		_outline = custom_outline.tessellate(5,4.0)
		if _outline.size()>1 and _outline[0].is_equal_approx(_outline[-1]):
			_outline.remove_at(_outline.size()-1)
		_custom_shape = not Geometry2D.triangulate_polygon(_outline).is_empty()
	_field_center = Vector2.ZERO
	_field_size = patch_size*1.12
	if _custom_shape:
		_shape_bounds = Rect2(_outline[0],Vector2.ZERO)
		for point in _outline:
			_shape_bounds = _shape_bounds.expand(point)
		_field_center = _shape_bounds.get_center()
		_field_size = _shape_bounds.size.max(Vector2.ONE*0.1)*1.12

func _point_to_uv(point: Vector2) -> Vector2:
	return (point-_field_center)/_field_size+Vector2.ONE*0.5

func _oval_mesh_arrays() -> Array:
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var uvs := PackedVector2Array()
	var colors := PackedColorArray()
	var indices := PackedInt32Array()
	var rings: int = mesh_detail/2
	vertices.append(Vector3(0,_height(Vector2.ZERO),0))
	normals.append(Vector3.UP)
	uvs.append(Vector2.ONE*0.5)
	colors.append(Color(0,0,0,1))
	_outline.clear()
	for ring in range(1,rings+1):
		var r := float(ring)/rings
		for segment in range(mesh_detail):
			var angle := TAU*segment/mesh_detail
			var point := Vector2(cos(angle),sin(angle))*patch_size*0.5*_radius(angle)*r
			var dx := (_height(point+Vector2(0.025,0))-_height(point-Vector2(0.025,0)))/0.05
			var dz := (_height(point+Vector2(0,0.025))-_height(point-Vector2(0,0.025)))/0.05
			vertices.append(Vector3(point.x,_height(point),point.y))
			normals.append(Vector3(-dx,1,-dz).normalized())
			uvs.append(point/(patch_size*1.12)+Vector2.ONE*0.5)
			colors.append(Color(r,0,0,1))
			if ring==rings:
				_outline.append(point)
	for segment in range(mesh_detail):
		indices.append_array(PackedInt32Array([0,1+(segment+1)%mesh_detail,1+segment]))
	for ring in range(rings-1):
		for segment in range(mesh_detail):
			var a := 1+ring*mesh_detail+segment
			var b := 1+ring*mesh_detail+(segment+1)%mesh_detail
			var c := a+mesh_detail
			var d := b+mesh_detail
			indices.append_array(PackedInt32Array([a,b,d,a,d,c]))
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_INDEX] = indices
	return arrays

func _custom_mesh_arrays() -> Array:
	# Clip a regular grid to the outline. A fan would bridge concave cutouts;
	# giant outline triangles would lose the sculpted snow and foot impressions.
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = PackedVector3Array()
	arrays[Mesh.ARRAY_NORMAL] = PackedVector3Array()
	arrays[Mesh.ARRAY_TEX_UV] = PackedVector2Array()
	arrays[Mesh.ARRAY_COLOR] = PackedColorArray()
	arrays[Mesh.ARRAY_INDEX] = PackedInt32Array()
	var cache := {}
	var spacing := maxf(_shape_bounds.size.x,_shape_bounds.size.y)/mesh_detail
	var columns := maxi(1,ceili(_shape_bounds.size.x/spacing))
	var rows := maxi(1,ceili(_shape_bounds.size.y/spacing))
	var cell := _shape_bounds.size/Vector2(columns,rows)
	for row in rows:
		for column in columns:
			var start := _shape_bounds.position+Vector2(column,row)*cell
			var rectangle := PackedVector2Array([start,start+Vector2(cell.x,0),start+cell,start+Vector2(0,cell.y)])
			for polygon in Geometry2D.intersect_polygons(_outline,rectangle):
				var triangles := Geometry2D.triangulate_polygon(polygon)
				for index in range(0,triangles.size(),3):
					var a := polygon[triangles[index]]
					var b := polygon[triangles[index+1]]
					var c := polygon[triangles[index+2]]
					if absf((b-a).cross(c-a))<0.00000001:
						continue
					# X/Z winding is reversed for an upward-facing mesh.
					if (b-a).cross(c-a)>0.0:
						var swap := b
						b = c
						c = swap
					for point in [a,b,c]:
						var key := Vector2i(roundi(point.x*100000.0),roundi(point.y*100000.0))
						if not cache.has(key):
							cache[key] = arrays[Mesh.ARRAY_VERTEX].size()
							var dx := (_height(point+Vector2(0.025,0))-_height(point-Vector2(0.025,0)))/0.05
							var dz := (_height(point+Vector2(0,0.025))-_height(point-Vector2(0,0.025)))/0.05
							arrays[Mesh.ARRAY_VERTEX].append(Vector3(point.x,_height(point),point.y))
							arrays[Mesh.ARRAY_NORMAL].append(Vector3(-dx,1,-dz).normalized())
							arrays[Mesh.ARRAY_TEX_UV].append(_point_to_uv(point))
							arrays[Mesh.ARRAY_COLOR].append(Color(clampf(_radial(point),0,1),0,0,1))
						arrays[Mesh.ARRAY_INDEX].append(cache[key])
	return arrays

## Stamp an individual shoe at a world position; also usable by future AI/animation events.
func stamp_footprint(world_point: Vector3,world_forward: Vector3) -> bool:
	if not _field:
		return false
	var local := to_local(world_point)
	var point := Vector2(local.x,local.z)
	if _radial(point)>0.97 or absf(local.y)>0.35 or _ground_excluded(world_point):
		return false
	var direction := global_basis.inverse()*world_forward
	var forward := Vector2(direction.x,direction.z).normalized()
	if forward.length_squared()<0.5:
		return false
	var side := Vector2(forward.y,-forward.x)
	var size := _field.get_width()
	var pixel_center := _point_to_uv(point)*size
	var reach := footprint_size.length()*0.6
	var pixel_radius := Vector2.ONE*reach/_field_size*size+Vector2.ONE*2.0
	var changed := false
	for y in range(maxi(0,int(pixel_center.y-pixel_radius.y)),mini(size,int(pixel_center.y+pixel_radius.y)+1)):
		for x in range(maxi(0,int(pixel_center.x-pixel_radius.x)),mini(size,int(pixel_center.x+pixel_radius.x)+1)):
			var p := (Vector2(x+0.5,y+0.5)/size-Vector2.ONE*0.5)*_field_size+_field_center-point
			var u := p.dot(side)/(footprint_size.x*0.5)
			var v := p.dot(forward)/(footprint_size.y*0.5)
			# A broad toe and narrower heel make shoe impressions rather than circles.
			var toe := Vector2(u,(v-0.25)/0.76).length()
			var heel := Vector2(u/0.72,(v+0.5)/0.45).length()
			var strength := 1.0-smoothstep(0.45,1.0,minf(toe,heel))
			var old := _field.get_pixel(x,y)
			var old_fade := 1.0-smoothstep(footprint_linger,footprint_linger+footprint_fade_duration,_clock-old.g/maxf(old.r,0.00001))
			if strength<0.01:
				# Clear expired neighbors so filtered birth times cannot age a new print.
				if old.r>0.0 and old_fade<=0.0:
					_field.set_pixel(x,y,Color(0,0,0,1))
					_dirty = true
				continue
			var combined := maxf(strength,old.r*old_fade)
			_field.set_pixel(x,y,Color(combined,_clock*combined,0,1))
			changed = true
	if changed:
		_dirty = true
		_stamp_count += 1
	return changed

func _flush_field() -> void:
	if _dirty:
		_texture.update(_field)
		_dirty = false

func _physics_process(delta: float) -> void:
	_clock += delta
	if not is_visible_in_tree():
		return
	if _material:
		_material.set_shader_parameter("snow_time",_clock)
	if track_footprints:
		_scan_time -= delta
		if _scan_time<=0.0:
			_players = get_tree().get_nodes_in_group(&"explorers")
			_scan_time = 0.5
		for player in _players:
			if not is_instance_valid(player) or not player is Node3D:
				continue
			_track_player(player)
	_flush_field()

func _track_player(player: Node3D) -> void:
	var id := player.get_instance_id()
	var current := player.global_position
	if not _trackers.has(id):
		_trackers[id] = {"position":current,"travel":0.0,"left":false}
		return
	var state: Dictionary = _trackers[id]
	var previous: Vector3 = state.position
	state.position = current
	var movement := current-previous
	movement.y = 0.0
	var distance := movement.length()
	if distance>1.5 or (player is CharacterBody3D and not player.is_on_floor()) or not excludes_ground_point(current):
		state.travel = 0.0
		return
	if distance<0.001:
		return
	var forward := movement/distance
	var side := Vector3(forward.z,0,-forward.x)
	var carried: float = state.travel
	var spacing := maxf(step_spacing,0.2)
	var next := spacing-carried
	while next<=distance:
		var location := previous.lerp(current,next/distance)
		location += side*(0.105 if state.left else -0.105)
		stamp_footprint(location,forward)
		state.left = not state.left
		next += spacing
	state.travel = fmod(carried+distance,spacing)

func _ground_excluded(point: Vector3) -> bool:
	for path in ground_exclusions:
		var region := get_node_or_null(path)
		if region and region!=self and region.has_method("excludes_ground_point") and region.excludes_ground_point(point):
			return true
	return false

func _bake_coverage() -> void:
	for region in _ground_regions:
		if is_instance_valid(region) and region.has_signal("ground_exclusion_changed") and region.ground_exclusion_changed.is_connected(_request_rebuild):
			region.ground_exclusion_changed.disconnect(_request_rebuild)
	_ground_regions.clear()
	var polygons: Array[PackedVector2Array] = []
	var generic: Array[Node3D] = []
	for path in ground_exclusions:
		var region := get_node_or_null(path)
		if not region or region==self or not region is Node3D:
			continue
		_ground_regions.append(region)
		if region.has_signal("ground_exclusion_changed") and not region.ground_exclusion_changed.is_connected(_request_rebuild):
			region.ground_exclusion_changed.connect(_request_rebuild)
		if region.has_method("get_ground_outline"):
			var polygon := PackedVector2Array()
			for world in region.get_ground_outline():
				var point := to_local(world)
				polygon.append(Vector2(point.x,point.z))
			polygons.append(polygon)
		else:
			generic.append(region)
	var resolution := 128
	var image := Image.create(resolution,resolution,false,Image.FORMAT_L8)
	image.fill(Color.WHITE)
	for y in range(resolution):
		for x in range(resolution):
			var point := (Vector2(x+0.5,y+0.5)/resolution-Vector2.ONE*0.5)*_field_size+_field_center
			var excluded := false
			for polygon in polygons:
				if Geometry2D.is_point_in_polygon(point,polygon):
					excluded = true
					break
			if not excluded and not generic.is_empty():
				for region in generic:
					if region.has_method("excludes_ground_point") and region.excludes_ground_point(to_global(Vector3(point.x,0,point.y))):
						excluded = true
						break
			if excluded:
				image.set_pixel(x,y,Color.BLACK)
	_material.set_shader_parameter("coverage_mask",ImageTexture.create_from_image(image))
