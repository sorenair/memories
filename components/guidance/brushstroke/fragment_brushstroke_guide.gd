@tool
class_name FragmentBrushstrokeGuide
extends LivingBrushstroke
## An authored safe route and a reusable, explicitly requested one-shot brush.
## Runtime creation and note completion never start playback.
signal finished

@export_group("Fragment Route")
@export var start_anchor: Node3D:
	set(value):
		start_anchor = value
		_request_route()
@export var end_anchor: Node3D:
	set(value):
		end_anchor = value
		_request_route()
## Local-space positions between the authored anchors, including height.
@export var waypoints := PackedVector3Array():
	set(value):
		waypoints = value
		_request_route()
@export_range(0.4,4.0,0.05) var meters_per_second: float = 1.6:
	set(value):
		meters_per_second = clampf(value,0.4,4.0)
		_request_route()
@export_range(0.3,1.4,0.05) var ground_anchor_height: float = 0.72:
	set(value):
		ground_anchor_height = value
		_request_route()
@export_tool_button("Preview one brushstroke") var preview_once = preview_route

var _clock := 0.0
var _playing := false
var _route_queued := false

func _validate_property(property: Dictionary) -> void:
	if property.name in ["start_point","end_point","route_curve","travel_duration","playback_speed","rest_duration","arc_height","curve_bend"]:
		property.usage &= ~(PROPERTY_USAGE_EDITOR | PROPERTY_USAGE_STORAGE)

func _ready() -> void:
	super._ready()
	_build_route()
	stop()

func _request_route() -> void:
	if is_inside_tree() and not _route_queued:
		_route_queued = true
		call_deferred("_build_route")

func _anchor_point(anchor: Node3D) -> Vector3:
	if anchor is MemoryFragment:
		return anchor.to_global(Vector3.UP*anchor.float_height)
	return anchor.global_position + Vector3.UP*ground_anchor_height

func get_route_points() -> PackedVector3Array:
	# Always return the authored backbone, even while a shortened request is playing.
	var points := PackedVector3Array()
	if not is_instance_valid(start_anchor) or not is_instance_valid(end_anchor): return points
	points.append(_anchor_point(start_anchor))
	for point in waypoints:
		var world := to_global(point)
		if points[-1].distance_squared_to(world)>0.0025: points.append(world)
	var last := _anchor_point(end_anchor)
	if points[-1].distance_squared_to(last)>0.0025: points.append(last)
	return points

func _build_route() -> void:
	_route_queued = false
	if not is_inside_tree() or _playing: return
	var points := get_route_points()
	if points.size()>=2: _set_curve(points,true)
	stop()

func _set_curve(world_points: PackedVector3Array, smooth: bool) -> void:
	var curve := Curve3D.new()
	curve.bake_interval = 0.08
	var points := PackedVector3Array()
	for point in world_points:
		points.append(to_local(point))
	for i in points.size():
		var tangent := Vector3.ZERO
		if smooth and i>0 and i<points.size()-1:
			var previous := points[i]-points[i-1]
			var next := points[i+1]-points[i]
			tangent = (previous.normalized()+next.normalized()).normalized()*minf(previous.length(),next.length())*0.14
		curve.add_point(points[i],-tangent,tangent)
	start_point = points[0]
	end_point = points[-1]
	route_curve = curve
	var distance := 0.0
	var previous := to_global(sample_path(0.0))
	for i in range(1,129):
		var point := to_global(sample_path(float(i)/128.0))
		distance += previous.distance_to(point)
		previous = point
	travel_duration = maxf(0.15,distance/meters_per_second)
	_apply_guide_materials()

func play_route(world_points: PackedVector3Array, smooth: bool = true) -> bool:
	if not is_inside_tree() or world_points.size()<2: return false
	stop()
	_set_curve(world_points,smooth)
	_playing = true
	_apply_guide_materials()
	show()
	set_process(true)
	return true

func preview_route() -> void:
	play_route(get_route_points())

func stop() -> void:
	_playing = false
	_clock = 0.0
	hide()
	set_process(false)
	_apply_guide_materials()

func is_playing() -> bool:
	return _playing

func _apply_guide_materials() -> void:
	for material in _materials:
		material.set_shader_parameter("randomized_start",false)
		material.set_shader_parameter("single_pass",true)
		material.set_shader_parameter("pulse_interval",0.0)
		material.set_shader_parameter("guide_opacity",1.0 if _playing else 0.0)
		material.set_shader_parameter("time_override",_clock)

func _update_materials() -> void:
	super._update_materials()
	_apply_guide_materials()

func rebuild() -> void:
	super.rebuild()
	_apply_guide_materials()

func _process(delta: float) -> void:
	if not _playing: return
	_clock += maxf(0.0,delta)
	for material in _materials: material.set_shader_parameter("time_override",_clock)
	if _clock >= travel_duration+trail_duration+0.1:
		stop()
		finished.emit()
