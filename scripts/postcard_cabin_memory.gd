@tool
extends MemoryScene
## One snowy hike curve drives the first note and both requested guidance legs.
@export_range(0.1,0.9,0.01) var hike_fragment_ratio := 0.40:
	set(value):
		hike_fragment_ratio = value
		if is_node_ready(): _update_routes()

func _ready() -> void:
	var trail: PainterlyCurvedPath = get_node("Zones/Hike/Scenery/Trail")
	if trail.curve and not trail.curve.changed.is_connected(_update_routes):
		trail.curve.changed.connect(_update_routes)
	_update_routes()

func _update_routes() -> void:
	if not is_inside_tree(): return
	var trail: PainterlyCurvedPath = get_node("Zones/Hike/Scenery/Trail")
	get_node("Zones/Hike/Fragment").global_position = trail.to_global(trail.point_at(trail.get_path_length()*hike_fragment_ratio))+Vector3.UP*0.04
	_assign(get_node("Environment/Guidance/ThroughThePines"),trail.get_route_points(0.0,hike_fragment_ratio))
	var route := trail.get_route_points(hike_fragment_ratio,1.0)
	# Take the open west side of the two chairs and fire bowl.
	for point in [Vector3(4,0.76,-23.5),Vector3(4,0.76,-27.8),Vector3(4.8,0.76,-27.8)]:
		route.append(to_global(point))
	_assign(get_node("Environment/Guidance/ToTheFire"),route)

func _assign(guide: FragmentBrushstrokeGuide,points: PackedVector3Array) -> void:
	var local := PackedVector3Array()
	for point in points: local.append(guide.to_local(point))
	guide.waypoints = local
