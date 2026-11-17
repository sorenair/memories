@tool
extends MemoryScene
## One route per fragment, derived from the same beach, cliff, dune and city paths.
func _ready() -> void:
	var beach: PainterlySandPatch = $Zones/BaiMon/Scenery/CrescentSand
	var dunes: PainterlySandPatch = $Zones/Dunes/Scenery/DuneSand
	$Entry.global_position.y = beach.get_surface_height($Entry.global_position)+0.045
	$Zones/Dunes/Fragment.global_position.y = dunes.get_surface_height($Zones/Dunes/Fragment.global_position)+0.045
	for item: Node3D in $Zones/Dunes/Scenery.get_children():
		if str(item.name).begins_with("DuneScrub") or str(item.name).begins_with("DuneGrass") or str(item.name).begins_with("DuneRock"):
			item.global_position.y = dunes.get_surface_height(item.global_position)
	for trail: PainterlyCurvedPath in [$Zones/BaiMon/Scenery/BeachRoute,$Zones/BaiMon/Scenery/HeadlandWalk,$Zones/BaiMon/Scenery/ToDunes,$Zones/Dunes/Scenery/DuneRoute,$Zones/Dunes/Scenery/ToSaigon,$Zones/Saigon/Scenery/CityRoute]:
		if not trail.curve.changed.is_connected(_update_routes): trail.curve.changed.connect(_update_routes)
	_update_routes()
func _update_routes() -> void:
	if not is_inside_tree(): return
	var beach: PainterlyCurvedPath = $Zones/BaiMon/Scenery/BeachRoute
	var dune_path: PainterlyCurvedPath = $Zones/Dunes/Scenery/DuneRoute
	var first := _sample(beach,0,beach.get_path_length(),$Zones/BaiMon/Scenery/CrescentSand)
	first.append_array($Zones/BaiMon/Scenery/HeadlandWalk.get_route_points())
	first.append($Zones/BaiMon/Fragment.global_position+Vector3.UP*0.76)
	_assign($Environment/Guidance/LighthouseMemory,first)
	var distance := dune_path.curve.get_closest_offset(dune_path.to_local($Zones/Dunes/Fragment.global_position))
	var second := $Zones/BaiMon/Scenery/ToDunes.get_route_points() as PackedVector3Array
	second.append_array(_sample(dune_path,0,distance,$Zones/Dunes/Scenery/DuneSand))
	second.append($Zones/Dunes/Fragment.global_position+Vector3.UP*0.76)
	_assign($Environment/Guidance/DunesMemory,second)
	var third := _sample(dune_path,distance,dune_path.get_path_length(),$Zones/Dunes/Scenery/DuneSand)
	third.append_array($Zones/Dunes/Scenery/ToSaigon.get_route_points())
	third.append_array($Zones/Saigon/Scenery/CityRoute.get_route_points())
	third.append($Zones/Saigon/Fragment.global_position+Vector3.UP*0.76)
	_assign($Environment/Guidance/CityMemory,third)
func _sample(trail: PainterlyCurvedPath,from: float,to: float,sand: PainterlySandPatch) -> PackedVector3Array:
	var points := PackedVector3Array()
	var steps := maxi(1,ceili(absf(to-from)/0.4))
	for index in steps+1:
		var point := trail.to_global(trail.point_at(lerpf(from,to,float(index)/steps)))
		point.y = sand.get_surface_height(point)
		points.append(point+Vector3.UP*0.76)
	return points
func _assign(guide: FragmentBrushstrokeGuide,points: PackedVector3Array) -> void:
	var local := PackedVector3Array()
	for point in points: local.append(guide.to_local(point))
	guide.waypoints = local
