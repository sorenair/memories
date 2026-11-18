@tool
extends MemoryScene
## Editable paths drive crowd clearance and fragment guidance.
func _ready() -> void:
	for path: PainterlyCurvedPath in [$Environment/StreetWeave, $Environment/PorchWeave, $Environment/BarApproach]:
		if not path.curve.changed.is_connected(_update_routes): path.curve.changed.connect(_update_routes)
	_update_routes()

func porch_branch_ratio() -> float:
	var street: PainterlyCurvedPath = $Environment/StreetWeave
	var branch: PainterlyCurvedPath = $Environment/PorchWeave
	return street.curve.get_closest_offset(street.to_local(branch.to_global(branch.point_at(0))))/street.get_path_length()

func _update_routes() -> void:
	if not is_inside_tree(): return
	var street: PainterlyCurvedPath = $Environment/StreetWeave
	var branch: PainterlyCurvedPath = $Environment/PorchWeave
	var split := porch_branch_ratio()
	var porch := street.get_route_points(0,split)
	porch.append_array(branch.get_route_points())
	_assign($Environment/Guidance/ToThePorch,porch)
	var bar := branch.get_route_points(1,0)
	bar.append_array(street.get_route_points(split,1))
	var approach: PainterlyCurvedPath = $Environment/BarApproach
	var street_end := street.to_global(street.point_at(street.get_path_length()))
	var approach_length := approach.get_path_length()
	if approach_length > 0.0:
		var join_distance := approach.curve.get_closest_offset(approach.to_local(street_end))
		bar.append_array(approach.get_route_points(join_distance / approach_length))
	for point in [Vector3(2.4,0.76,-28.8),Vector3(2.4,0.76,-30.1)]:
		bar.append(to_global(point))
	_assign($Environment/Guidance/ToTheBar,bar)

func _assign(guide: FragmentBrushstrokeGuide,points: PackedVector3Array) -> void:
	var local := PackedVector3Array()
	for point in points: local.append(guide.to_local(point))
	guide.waypoints = local
