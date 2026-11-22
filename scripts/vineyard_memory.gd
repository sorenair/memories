@tool
extends MemoryScene
@export_range(0.1,0.8,0.01) var rows_fragment_ratio := 0.46:
	set(value):
		rows_fragment_ratio = value
		if is_node_ready(): _update_routes()
func _ready() -> void:
	var trail: Path3D = $Zones/Rows/Scenery/AisleRoute
	if not trail.curve_changed.is_connected(_update_routes):
		trail.curve_changed.connect(_update_routes)
	_update_routes()
func _update_routes() -> void:
	if not is_inside_tree(): return
	var trail: Path3D = $Zones/Rows/Scenery/AisleRoute
	var split := trail.curve.get_baked_length() * rows_fragment_ratio
	$Zones/Rows/Fragment.global_position = trail.to_global(trail.curve.sample_baked(split, true)) + Vector3.UP * 0.04
	_assign($Environment/Guidance/BetweenTheVines, _sample_route(trail, 0.0, split))
	var deck := _sample_route(trail, split, trail.curve.get_baked_length())
	for point in [Vector3(0,0.8,-12.5),Vector3(0,1.3,-13.7),Vector3(0,1.3,-15.35),Vector3(-1.5,1.3,-15.35)]:
		deck.append(to_global(point))
	_assign($Environment/Guidance/OntoTheDeck,deck)

func _sample_route(trail: Path3D, start: float, end: float) -> PackedVector3Array:
	var points := PackedVector3Array()
	var steps := maxi(1, ceili((end - start) / 0.8))
	for step in range(steps + 1):
		var distance := lerpf(start, end, float(step) / steps)
		points.append(trail.to_global(trail.curve.sample_baked(distance, true)) + Vector3.UP * 0.76)
	return points

func _assign(guide: FragmentBrushstrokeGuide,points: PackedVector3Array) -> void:
	var local := PackedVector3Array()
	for point in points: local.append(guide.to_local(point))
	guide.waypoints = local
