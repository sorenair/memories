extends SceneTree
## Finite support around the field, summit ascent/descent and lake-bank meadow.
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var memory := load("res://scenes/memories/colorado.tscn").instantiate() as MemoryScene
	root.add_child(memory)
	await process_frame
	var shapes: Array[PackedVector2Array] = []
	shapes.append(_oval(Vector2(0,20),Vector2(11.5,10.5)))
	for route in ["Flatirons/Scenery/FieldWalk","Flatirons/Scenery/ToSummit","Summit/Scenery/SummitClimb"]: _add_path(shapes,memory.get_node("Zones/"+route))
	shapes.append(PackedVector2Array([Vector2(22,-16),Vector2(36,-16),Vector2(36,-3),Vector2(22,-3)]))
	_add_path(shapes,memory.get_node("Zones/Summit/Scenery/ToLake"))
	var mountain := memory.get_node("Zones/Summit/Scenery/QuandaryTerrain") as Node3D
	var ridge_outline := PackedVector2Array()
	for local: Vector2 in mountain.get("outline"):
		var point := mountain.to_global(Vector3(local.x, 0.0, local.y))
		ridge_outline.append(Vector2(point.x, point.z))
	shapes.append(ridge_outline)
	_add_path(shapes,memory.get_node("Zones/ForestLake/Scenery/LakeshoreWalk"))
	shapes.append(PackedVector2Array([Vector2(56.3,-52),Vector2(70.5,-52),Vector2(70.5,-34),Vector2(55.5,-34)]))
	var merged := shapes[0]
	for i in range(1,shapes.size()):
		var result := Geometry2D.merge_polygons(merged,shapes[i])
		if result.is_empty():
			push_error("Colorado floor failed to merge")
			quit(1)
			return
		merged = result[0]
		for polygon in result:
			if _area(polygon)>_area(merged): merged=polygon
	var curve := Curve2D.new()
	for point in merged: curve.add_point(point)
	var error := ResourceSaver.save(curve,"res://scenes/memories/colorado/walk_outline.tres")
	print("Colorado floor: ",merged.size()," points, saved ",error)
	memory.free()
	quit(error)
func _oval(center: Vector2,radius: Vector2) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in 80:
		var a := TAU*i/80.0
		points.append(center+Vector2(cos(a),sin(a))*radius)
	return points
func _add_path(shapes: Array[PackedVector2Array],path: PainterlyCurvedPath) -> void:
	var line := PackedVector2Array()
	for p in path.get_route_points(0,1,.35): line.append(Vector2(p.x,p.z))
	shapes.append_array(Geometry2D.offset_polyline(line,2.65,Geometry2D.JOIN_ROUND,Geometry2D.END_ROUND))
func _area(points: PackedVector2Array) -> float:
	var area := 0.0
	for i in points.size(): area+=points[i].cross(points[(i+1)%points.size()])
	return absf(area)*.5
