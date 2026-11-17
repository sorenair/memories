@tool
extends MemoryScene
## The supported field, summit and forest-bank paths also define requested hints.
func _ready() -> void:
	for path: PainterlyCurvedPath in [$Zones/Flatirons/Scenery/FieldWalk,$Zones/Flatirons/Scenery/ToSummit,$Zones/Summit/Scenery/SummitClimb,$Zones/Summit/Scenery/ToLake,$Zones/ForestLake/Scenery/LakeshoreWalk]:
		if not path.curve.changed.is_connected(_update_routes): path.curve.changed.connect(_update_routes)
	_update_routes()
func _update_routes() -> void:
	if not is_inside_tree(): return
	var first := $Zones/Flatirons/Scenery/FieldWalk.get_route_points() as PackedVector3Array
	first.append($Zones/Flatirons/Fragment.global_position+Vector3.UP*.76)
	_assign($Environment/Guidance/FieldMemory,first)
	var second := $Zones/Flatirons/Scenery/ToSummit.get_route_points() as PackedVector3Array
	second.append_array($Zones/Summit/Scenery/SummitClimb.get_route_points())
	second.append($Zones/Summit/Fragment.global_position+Vector3.UP*.76)
	_assign($Environment/Guidance/SummitMemory,second)
	var third := $Zones/Summit/Scenery/ToLake.get_route_points() as PackedVector3Array
	third.append_array($Zones/ForestLake/Scenery/LakeshoreWalk.get_route_points())
	third.append($Zones/ForestLake/Fragment.global_position+Vector3.UP*.76)
	_assign($Environment/Guidance/LakeMemory,third)
func _assign(guide: FragmentBrushstrokeGuide,points: PackedVector3Array) -> void:
	var local := PackedVector3Array()
	for point in points: local.append(guide.to_local(point))
	guide.waypoints = local
