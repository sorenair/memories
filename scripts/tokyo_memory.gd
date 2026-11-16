@tool
extends MemoryScene
## Safe requested routes share the authored curves and each hall's own anchors.
func _ready() -> void:
	for trail: PainterlyCurvedPath in [$Zones/Meiji/Scenery/ForestWalk,$Zones/Meiji/Scenery/ToAsakusa,$Zones/Sensoji/Scenery/TempleWalk,$Zones/Sensoji/Scenery/ToShibuya,$Zones/Shibuya/Scenery/CrossingRoute]:
		if not trail.curve.changed.is_connected(_update_routes): trail.curve.changed.connect(_update_routes)
	_update_routes()

func _update_routes() -> void:
	if not is_inside_tree(): return
	var meiji: PainterlyJapaneseHall = $Zones/Meiji/Scenery/WorshipHall
	var senso: PainterlyJapaneseHall = $Zones/Sensoji/Scenery/MainHall
	if not meiji.get_anchor(&"PrayerFront") or not senso.get_anchor(&"PrayerFront"): return
	$Zones/Meiji/Fragment.global_position = meiji.get_anchor(&"PrayerFront").global_position+Vector3.UP*0.04
	$Zones/Sensoji/Fragment.global_position = senso.get_anchor(&"PrayerFront").global_position+Vector3.UP*0.04
	var forest: PainterlyCurvedPath = $Zones/Meiji/Scenery/ForestWalk
	var first := forest.get_route_points()
	first.append($Zones/Meiji/Fragment.global_position+Vector3.UP*0.76)
	_assign($Environment/Guidance/IntoTheShrine,first)
	var second := PackedVector3Array([$Zones/Meiji/Fragment.global_position+Vector3.UP*0.76])
	second.append(meiji.get_anchor(&"Approach").global_position+Vector3.UP*0.76)
	second.append_array($Zones/Meiji/Scenery/ToAsakusa.get_route_points())
	second.append_array($Zones/Sensoji/Scenery/TempleWalk.get_route_points())
	second.append($Zones/Sensoji/Fragment.global_position+Vector3.UP*0.76)
	_assign($Environment/Guidance/ThroughTheLanternGate,second)
	var third := PackedVector3Array([$Zones/Sensoji/Fragment.global_position+Vector3.UP*0.76])
	third.append(senso.get_anchor(&"Approach").global_position+Vector3.UP*0.76)
	third.append_array($Zones/Sensoji/Scenery/ToShibuya.get_route_points())
	third.append_array($Zones/Shibuya/Scenery/CrossingRoute.get_route_points())
	third.append($Zones/Shibuya/Fragment.global_position+Vector3.UP*0.76)
	_assign($Environment/Guidance/AcrossTheCity,third)

func _assign(guide: FragmentBrushstrokeGuide,points: PackedVector3Array) -> void:
	var local := PackedVector3Array()
	for point in points: local.append(guide.to_local(point))
	guide.waypoints = local
