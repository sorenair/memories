@tool
extends MemoryScene
@export_range(0.1,0.8,0.01) var rows_fragment_ratio := 0.46:
	set(value):
		rows_fragment_ratio = value
		if is_node_ready(): _update_routes()
func _ready() -> void:
	var trail: PainterlyCurvedPath = $Zones/Rows/Scenery/Trail
	if not trail.curve.changed.is_connected(_update_routes): trail.curve.changed.connect(_update_routes)
	_update_routes()
func _update_routes() -> void:
	if not is_inside_tree(): return
	var trail: PainterlyCurvedPath = $Zones/Rows/Scenery/Trail
	$Zones/Rows/Fragment.global_position = trail.to_global(trail.point_at(trail.get_path_length()*rows_fragment_ratio))+Vector3.UP*0.04
	_assign($Environment/Guidance/BetweenTheVines,trail.get_route_points(0,rows_fragment_ratio))
	var deck := trail.get_route_points(rows_fragment_ratio,1)
	for point in [Vector3(0,0.8,-12.5),Vector3(0,1.3,-13.7),Vector3(0,1.3,-15.35),Vector3(-1.5,1.3,-15.35)]:
		deck.append(to_global(point))
	_assign($Environment/Guidance/OntoTheDeck,deck)
func _assign(guide: FragmentBrushstrokeGuide,points: PackedVector3Array) -> void:
	var local := PackedVector3Array()
	for point in points: local.append(guide.to_local(point))
	guide.waypoints = local
