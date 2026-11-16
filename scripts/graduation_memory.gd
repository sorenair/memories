@tool
extends MemoryScene
## Requested hints follow the same curves and treads as the authored walking route.
func _ready() -> void:
	for trail: PainterlyCurvedPath in [$Zones/Arches/Scenery/CampusWalk,$Zones/Portico/Scenery/GardenWalk,$Zones/Ceremony/Scenery/Aisle]:
		if not trail.curve.changed.is_connected(_update_routes): trail.curve.changed.connect(_update_routes)
	_update_routes()

func _update_routes() -> void:
	if not is_inside_tree(): return
	var walk: PainterlyCurvedPath = $Zones/Arches/Scenery/CampusWalk
	var ratio := walk.curve.get_closest_offset(walk.curve.get_point_position(2))/walk.get_path_length()
	$Zones/Arches/Fragment.global_position = walk.to_global(walk.point_at(walk.get_path_length()*ratio))+Vector3.UP*0.04
	_assign($Environment/Guidance/ThroughTheArches,walk.get_route_points(0,ratio))
	var portico: PainterlyClassicalPortico = $Zones/Portico/Scenery/Portico
	$Zones/Portico/Fragment.position.y = portico.landing_height()+0.04
	var stairs := walk.get_route_points(ratio,1)
	stairs.append(portico.to_global(Vector3(0,0.76,portico.stair_front()+0.8)))
	var profile := portico.stair_profile()
	for point in profile:
		if point.x<0.85: break
		stairs.append(portico.to_global(Vector3(0,point.y+0.76,point.x)))
	stairs.append($Zones/Portico/Fragment.global_position+Vector3.UP*0.76)
	_assign($Environment/Guidance/UpTheSteps,stairs)
	var garden: PainterlyCurvedPath = $Zones/Portico/Scenery/GardenWalk
	var ceremony := PackedVector3Array([$Zones/Portico/Fragment.global_position+Vector3.UP*0.76])
	ceremony.append_array(garden.get_route_points())
	ceremony.append_array($Zones/Ceremony/Scenery/Aisle.get_route_points())
	var stage: PainterlyStage = $Zones/Ceremony/Scenery/Setup/CommencementStage
	for point in [Vector3(0,0.76,stage.footprint.y*0.5+stage.ramp_length),Vector3(0,stage.deck_height+0.76,stage.footprint.y*0.5),Vector3(0,stage.deck_height+0.76,0.9)]:
		ceremony.append(stage.to_global(point))
	ceremony.append($Zones/Ceremony/Fragment.global_position+Vector3.UP*0.76)
	_assign($Environment/Guidance/ToTheCeremony,ceremony)

func _assign(guide: FragmentBrushstrokeGuide,points: PackedVector3Array) -> void:
	var local := PackedVector3Array()
	for point in points: local.append(guide.to_local(point))
	guide.waypoints = local
