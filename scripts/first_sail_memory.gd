@tool
extends MemoryScene
## Shore, real access ramp and pier form one guidance route to the landing.
func _ready() -> void:
	var path: PainterlyCurvedPath = $Zones/Lakeside/Scenery/ShorePath
	if not path.curve.changed.is_connected(_update_route): path.curve.changed.connect(_update_route)
	var dock: PainterlyWoodenDock = $Zones/Lakeside/Scenery/Dock
	if not dock.ground_exclusion_changed.is_connected(_update_route): dock.ground_exclusion_changed.connect(_update_route)
	_update_route()
func _update_route() -> void:
	if not is_inside_tree(): return
	var dock: PainterlyWoodenDock = $Zones/Lakeside/Scenery/Dock
	var points := $Zones/Lakeside/Scenery/ShorePath.get_route_points() as PackedVector3Array
	var shore_z := dock.dock_length*0.5
	points.append(dock.to_global(Vector3(0,0.03,shore_z+dock.ramp_length))+Vector3.UP*0.76)
	points.append(dock.to_global(Vector3(0,dock.deck_height,shore_z))+Vector3.UP*0.76)
	points.append(dock.to_global(Vector3(0,dock.deck_height,0))+Vector3.UP*0.76)
	points.append(dock.get_anchor(&"DeckEnd").global_position+Vector3.UP*0.76)
	points.append($Zones/Lakeside/Fragment.global_position+Vector3.UP*0.76)
	var guide: FragmentBrushstrokeGuide = $Environment/Guidance/DockMemory
	var local := PackedVector3Array()
	for point in points: local.append(guide.to_local(point))
	guide.waypoints = local
