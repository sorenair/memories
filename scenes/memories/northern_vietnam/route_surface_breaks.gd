@tool
extends Node3D
## Paint selected spans of one authored route using the existing surface component.
## The hidden source retains uninterrupted support, exclusions and hint sampling.
@export var source_path: NodePath:
	set(value):
		source_path = value
		_queue_rebuild()
@export var visible_spans := PackedVector2Array([Vector2(0,0.42),Vector2(0.57,1)]):
	set(value):
		visible_spans = value
		_queue_rebuild()
const SURFACE = preload("res://components/groundcover/paths/painterly_surface_path.tscn")
var _queued := false
var _source: PainterlySurfacePath
var _segments: Array[PainterlySurfacePath] = []
func _ready() -> void:
	_rebuild.call_deferred()
func _queue_rebuild() -> void:
	if is_inside_tree() and not _queued:
		_queued = true
		_rebuild.call_deferred()
func _rebuild() -> void:
	_queued = false
	if is_instance_valid(_source) and _source.ground_exclusion_changed.is_connected(_queue_rebuild):
		_source.ground_exclusion_changed.disconnect(_queue_rebuild)
	_source = get_node_or_null(source_path) as PainterlySurfacePath
	for segment in _segments:
		if is_instance_valid(segment): segment.free()
	_segments.clear()
	if not _source or not _source.curve or _source.curve.point_count<2: return
	_source.ground_exclusion_changed.connect(_queue_rebuild)
	var length := _source.get_path_length()
	for span in visible_spans:
		var start := clampf(span.x,0,1)*length
		var end := clampf(span.y,0,1)*length
		if end-start<0.15: continue
		var segment: PainterlySurfacePath = SURFACE.instantiate()
		segment.name = "PaintedSpan%d" % (_segments.size()+1)
		for key in ["surface_style","path_width","paving_seed","paving_color","shoulder_color","stone_color","width_variation","crown_height","detail_density","stone_size","joint_width","edge_softness","irregularity","breakup_size","sample_spacing"]:
			segment.set(key,_source.get(key))
		segment.end_fade = Vector2(0.9,0.9)
		segment.collision_enabled = false
		var curve := Curve3D.new()
		var steps := maxi(2,ceili((end-start)/0.3))
		for index in steps+1:
			curve.add_point(to_local(_source.to_global(_source.point_at(lerpf(start,end,float(index)/steps)))))
		segment.curve = curve
		add_child(segment,false,Node.INTERNAL_MODE_BACK)
		_segments.append(segment)
