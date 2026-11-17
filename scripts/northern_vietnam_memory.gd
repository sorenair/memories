@tool
extends MemoryScene
## Requested hints follow authored land paths and the actual curved bridge deck.
func _ready() -> void:
	for trail: PainterlyCurvedPath in [$Zones/OldQuarter/Scenery/LaneRoute,$Zones/OldQuarter/Scenery/ToLake,$Zones/HoanKiem/Scenery/LakeWalk,$Zones/HoanKiem/Scenery/ToBay,$Zones/HaLong/Scenery/ShoreApproach]:
		if not trail.curve.changed.is_connected(_update_routes): trail.curve.changed.connect(_update_routes)
	_update_routes()

func _update_routes() -> void:
	if not is_inside_tree(): return
	var lane: PainterlyCurvedPath = $Zones/OldQuarter/Scenery/LaneRoute
	var note: MemoryFragment = $Zones/OldQuarter/Fragment
	var distance := lane.curve.get_closest_offset(lane.to_local(note.global_position))
	_assign($Environment/Guidance/StreetMemory,_sample(lane,0,distance))
	var lake := _sample(lane,distance,lane.get_path_length())
	lake.append_array($Zones/OldQuarter/Scenery/ToLake.get_route_points())
	lake.append_array($Zones/HoanKiem/Scenery/LakeWalk.get_route_points())
	var bridge: PainterlyRedBridge = $Zones/HoanKiem/Scenery/RedBridge
	var bridge_points := PackedVector3Array()
	for index in 41:
		var z := lerpf(bridge.bridge_length*0.5,-bridge.bridge_length*0.5,index/40.0)
		bridge_points.append(bridge.to_global(Vector3(0,bridge.surface_height(z)+0.76,z)))
	lake.append_array(bridge_points)
	lake.append($Zones/HoanKiem/Fragment.global_position+Vector3.UP*0.76)
	_assign($Environment/Guidance/LakeMemory,lake)
	var bay := PackedVector3Array([$Zones/HoanKiem/Fragment.global_position+Vector3.UP*0.76])
	bridge_points.reverse()
	bay.append_array(bridge_points)
	var bank: PackedVector3Array = $Zones/HoanKiem/Scenery/LakeWalk.get_route_points()
	bank.reverse()
	bay.append_array(bank)
	bay.append_array($Zones/HoanKiem/Scenery/ToBay.get_route_points())
	bay.append_array($Zones/HaLong/Scenery/ShoreApproach.get_route_points())
	var dock: PainterlyWoodenDock = $Zones/HaLong/Scenery/LookoutDock
	if not dock.get_anchor(&"Approach"): return
	bay.append(dock.get_anchor(&"Approach").global_position+Vector3.UP*0.76)
	bay.append(dock.get_anchor(&"ShoreJoin").global_position+Vector3.UP*0.76)
	bay.append($Zones/HaLong/Fragment.global_position+Vector3.UP*0.76)
	_assign($Environment/Guidance/BayMemory,bay)

func _sample(trail: PainterlyCurvedPath,from: float,to: float) -> PackedVector3Array:
	var points := PackedVector3Array()
	var steps := maxi(1,ceili(absf(to-from)/0.45))
	for index in steps+1:
		points.append(trail.to_global(trail.point_at(lerpf(from,to,float(index)/steps)))+Vector3.UP*0.76)
	return points

func _assign(guide: FragmentBrushstrokeGuide,points: PackedVector3Array) -> void:
	var local := PackedVector3Array()
	for point in points: local.append(guide.to_local(point))
	guide.waypoints = local
