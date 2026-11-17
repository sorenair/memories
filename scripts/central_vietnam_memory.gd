@tool
extends MemoryScene
## Authored jungle, field and courtyard curves drive walking and requested guidance.
func _ready() -> void:
	var approach: PainterlyCurvedPath = $Zones/MarbleMountains/Scenery/MountainRoute
	for trail: PainterlyCurvedPath in [approach,$Zones/MarbleMountains/Scenery/ToFields,$Zones/Rice/Scenery/BundWalk,$Zones/Rice/Scenery/ToHue,$Zones/Hue/Scenery/GateApproach]:
		if not trail.curve.changed.is_connected(_update_routes): trail.curve.changed.connect(_update_routes)
	_update_routes()
func _update_routes() -> void:
	if not is_inside_tree(): return
	var approach: PainterlyCurvedPath = $Zones/MarbleMountains/Scenery/MountainRoute
	var note: MemoryFragment = $Zones/MarbleMountains/Fragment
	var distance := approach.curve.get_closest_offset(approach.to_local(note.global_position))
	_assign($Environment/Guidance/MarbleMountainsMemory,_sample(approach,0,distance))
	var fields := _sample(approach,distance,approach.get_path_length())
	fields.append_array($Zones/MarbleMountains/Scenery/ToFields.get_route_points())
	fields.append_array($Zones/Rice/Scenery/BundWalk.get_route_points())
	fields.append($Zones/Rice/Fragment.global_position+Vector3.UP*0.76)
	_assign($Environment/Guidance/FieldsMemory,fields)
	var city := $Zones/Rice/Scenery/ToHue.get_route_points() as PackedVector3Array
	city.append_array($Zones/Hue/Scenery/GateApproach.get_route_points())
	city.append($Zones/Hue/Fragment.global_position+Vector3.UP*0.76)
	_assign($Environment/Guidance/ImperialMemory,city)
func _sample(trail: PainterlyCurvedPath,from: float,to: float) -> PackedVector3Array:
	var points := PackedVector3Array()
	var steps := maxi(1,ceili(absf(to-from)/0.4))
	for index in steps+1:
		var point := trail.to_global(trail.point_at(lerpf(from,to,float(index)/steps)))
		points.append(point+Vector3.UP*0.76)
	return points
func _assign(guide: FragmentBrushstrokeGuide,points: PackedVector3Array) -> void:
	var local := PackedVector3Array()
	for point in points: local.append(guide.to_local(point))
	guide.waypoints = local
