@tool
extends MemoryScene
## Each hint follows the very same winding route as the actual walking surface.
func _ready() -> void:
	for path: PainterlyCurvedPath in [$Zones/Trail/Scenery/ForestTrail,$Zones/Trail/Scenery/LookoutClimb,$Zones/Trail/Scenery/ToLighthouse,$Zones/Lighthouse/Scenery/ShoreWalk,$Zones/Lighthouse/Scenery/AroundLighthouse,$Zones/Lighthouse/Scenery/ToGarden,$Zones/Garden/Scenery/GardenWalk]:
		if not path.curve.changed.is_connected(_update_routes): path.curve.changed.connect(_update_routes)
	_update_routes()
func _update_routes() -> void:
	if not is_inside_tree(): return
	var first := $Zones/Trail/Scenery/ForestTrail.get_route_points() as PackedVector3Array
	first.append_array($Zones/Trail/Scenery/LookoutClimb.get_route_points())
	first.append($Zones/Trail/Fragment.global_position+Vector3.UP*.76)
	_assign($Environment/Guidance/LookoutMemory,first)
	var second := $Zones/Trail/Scenery/ToLighthouse.get_route_points() as PackedVector3Array
	second.append_array($Zones/Lighthouse/Scenery/ShoreWalk.get_route_points())
	second.append($Zones/Lighthouse/Fragment.global_position+Vector3.UP*.76)
	_assign($Environment/Guidance/LighthouseMemory,second)
	var third := $Zones/Lighthouse/Scenery/AroundLighthouse.get_route_points() as PackedVector3Array
	third.append_array($Zones/Lighthouse/Scenery/ToGarden.get_route_points())
	third.append_array($Zones/Garden/Scenery/GardenWalk.get_route_points())
	third.append($Zones/Garden/Fragment.global_position+Vector3.UP*.76)
	_assign($Environment/Guidance/GardenMemory,third)
func _assign(guide: FragmentBrushstrokeGuide,points: PackedVector3Array) -> void:
	var local := PackedVector3Array()
	for point in points: local.append(guide.to_local(point))
	guide.waypoints = local
