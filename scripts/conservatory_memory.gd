@tool
extends MemoryScene
## Keep fragment placement and requested guidance attached to the authored curve.
@export_range(0.1,0.9,0.01) var jungle_fragment_ratio := 0.62:
	set(value):
		jungle_fragment_ratio = value
		if is_node_ready(): _update_jungle_route()

func _ready() -> void:
	for path in [$Environment/GardenToJungle, $Zones/Jungle/Scenery/WindingPath, $Environment/ToBonsai]:
		if path.curve and not path.curve.changed.is_connected(_update_jungle_route):
			path.curve.changed.connect(_update_jungle_route)
	_update_jungle_route()

func _update_jungle_route() -> void:
	if not is_inside_tree(): return
	var trail: PainterlyCurvedPath = get_node("Zones/Jungle/Scenery/WindingPath")
	var fragment: MemoryFragment = get_node("Zones/Jungle/Fragment")
	fragment.global_position = trail.to_global(trail.point_at(trail.get_path_length()*jungle_fragment_ratio))+Vector3.UP*0.04
	var threshold: PainterlyCurvedPath = $Environment/GardenToJungle
	var approach := PackedVector3Array([to_global(Vector3(2.7, 0.76, -8.9))])
	approach.append_array(threshold.get_route_points())
	approach.append_array(trail.get_route_points(0.0,jungle_fragment_ratio))
	_assign_route(get_node("Environment/Guidance/IntoTheGreen"),approach)
	var departure := trail.get_route_points(jungle_fragment_ratio,1.0)
	var bonsai_approach: PainterlyCurvedPath = $Environment/ToBonsai
	departure.append_array(bonsai_approach.get_route_points())
	_assign_route(get_node("Environment/Guidance/ToSmallWorlds"),departure)

func _assign_route(guide: FragmentBrushstrokeGuide,world_points: PackedVector3Array) -> void:
	var local := PackedVector3Array()
	for point in world_points: local.append(guide.to_local(point))
	guide.waypoints = local
