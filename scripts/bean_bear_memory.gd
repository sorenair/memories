@tool
extends MemoryScene
## Guidance follows the very same curves as the supported hiking route.
func _ready() -> void:
	for trail: PainterlyCurvedPath in [$Zones/Trailhead/Scenery/ForestTrail,$Zones/Overlook/Scenery/OverlookClimb,$Zones/Overlook/Scenery/ToCamp,$Zones/Campsite/Scenery/CampWalk]:
		if not trail.curve.changed.is_connected(_update_routes): trail.curve.changed.connect(_update_routes)
	_update_routes()
func _update_routes() -> void:
	if not is_inside_tree(): return
	var forest: PainterlyCurvedPath = $Zones/Trailhead/Scenery/ForestTrail
	var note_distance := forest.curve.get_closest_offset(forest.to_local($Zones/Trailhead/Fragment.global_position))
	var ratio := note_distance/forest.get_path_length()
	var first := forest.get_route_points(0,ratio)
	first.append($Zones/Trailhead/Fragment.global_position+Vector3.UP*0.76)
	_assign($Environment/Guidance/ForestMemory,first)
	var second := forest.get_route_points(ratio,1)
	second.append_array($Zones/Overlook/Scenery/OverlookClimb.get_route_points())
	second.append($Zones/Overlook/Fragment.global_position+Vector3.UP*0.76)
	_assign($Environment/Guidance/LakesMemory,second)
	var third := $Zones/Overlook/Scenery/ToCamp.get_route_points() as PackedVector3Array
	third.append_array($Zones/Campsite/Scenery/CampWalk.get_route_points())
	third.append($Zones/Campsite/Fragment.global_position+Vector3.UP*0.76)
	_assign($Environment/Guidance/CampMemory,third)
func _assign(guide: FragmentBrushstrokeGuide,points: PackedVector3Array) -> void:
	var local := PackedVector3Array()
	for point in points: local.append(guide.to_local(point))
	guide.waypoints = local
