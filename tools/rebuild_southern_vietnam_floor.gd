extends SceneTree
## Merge a finite beach, headland, dune field and city around their authored routes.
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var memory := load("res://scenes/memories/southern_vietnam.tscn").instantiate() as MemoryScene
	root.add_child(memory)
	await process_frame
	var shapes: Array[PackedVector2Array] = []
	var beach := PackedVector2Array()
	for index in 81:
		var a := -1.95+3.9*index/80.0
		beach.append(Vector2(sin(a)*17,cos(a)*17+11))
	for index in 81:
		var a := 1.95-3.9*index/80.0
		beach.append(Vector2(sin(a)*8.2,cos(a)*8.2+11))
	shapes.append(beach)
	_add_path(shapes,memory.get_node("Zones/BaiMon/Scenery/HeadlandWalk"))
	shapes.append(PackedVector2Array([Vector2(6,-1),Vector2(20,-1),Vector2(20,14),Vector2(6,14)]))
	_add_path(shapes,memory.get_node("Zones/BaiMon/Scenery/ToDunes"))
	var dune_area := PackedVector2Array()
	for index in 80:
		var a := TAU*index/80.0
		dune_area.append(Vector2(40+cos(a)*17,-23+sin(a)*17))
	shapes.append(dune_area)
	_add_path(shapes,memory.get_node("Zones/Dunes/Scenery/ToSaigon"))
	shapes.append(PackedVector2Array([Vector2(51,-80),Vector2(84,-80),Vector2(84,-42),Vector2(51,-42)]))
	var merged := shapes[0]
	for index in range(1,shapes.size()):
		var result := Geometry2D.merge_polygons(merged,shapes[index])
		if result.is_empty():
			push_error("Southern Vietnam floor outline could not be merged")
			quit(1)
			return
		# The ascent loops around the headland. Keep the largest outer polygon;
		# its interior ground prevents an inner rim from cutting across that loop.
		merged = result[0]
		for polygon in result:
			if _area(polygon)>_area(merged): merged=polygon

	var curve := Curve2D.new()
	for point in merged: curve.add_point(point)
	var error := ResourceSaver.save(curve,"res://scenes/memories/southern_vietnam/walk_outline.tres")
	print("Southern Vietnam floor: ",merged.size()," points, saved ",error)
	memory.free()
	quit(error)
func _add_path(shapes: Array[PackedVector2Array],trail: PainterlyCurvedPath) -> void:
	var line := PackedVector2Array()
	for point in trail.get_route_points(0,1,0.4): line.append(Vector2(point.x,point.z))
	shapes.append_array(Geometry2D.offset_polyline(line,2.5,Geometry2D.JOIN_ROUND,Geometry2D.END_ROUND))

func _area(polygon: PackedVector2Array) -> float:
	var area := 0.0
	for index in polygon.size(): area += polygon[index].cross(polygon[(index+1)%polygon.size()])
	return absf(area)*0.5
