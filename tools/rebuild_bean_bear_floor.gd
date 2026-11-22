extends SceneTree
## One finite, connected floor; no internal safety rim at a path or zone join.
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var memory := load("res://scenes/memories/bean_bear.tscn").instantiate() as MemoryScene
	root.add_child(memory)
	await process_frame
	var shapes: Array[PackedVector2Array] = []
	shapes.append(PackedVector2Array([Vector2(-6.8,24),Vector2(4.8,24),Vector2(4.8,32.3),Vector2(-6.8,32.3)]))
	for name in ["Trailhead/Scenery/ForestTrail","Trailhead/Scenery/BoulderFork",
		"Overlook/Scenery/OverlookClimb","Overlook/Scenery/LookoutSpur","Overlook/Scenery/ToCamp",
		"Campsite/Scenery/CampWalk","Campsite/Scenery/ShoreSpur"]:
		var trail: PainterlyCurvedPath = memory.get_node("Zones/"+name)
		var line := PackedVector2Array()
		for point in trail.get_route_points(0,1,0.4): line.append(Vector2(point.x,point.z))
		shapes.append_array(Geometry2D.offset_polyline(line,2.6,Geometry2D.JOIN_ROUND,Geometry2D.END_ROUND))
	shapes.append(PackedVector2Array([Vector2(17.5,-13.5),Vector2(30.5,-13.5),Vector2(30.5,-2.5),Vector2(17.5,-2.5)]))
	var camp := PackedVector2Array()
	for index in 80:
		var a := TAU*index/80.0
		camp.append(Vector2(25.5+cos(a)*6.7,-24.8+sin(a)*7.2))
	shapes.append(camp)
	var merged := shapes[0]
	for index in range(1,shapes.size()):
		var result := Geometry2D.merge_polygons(merged,shapes[index])
		if result.is_empty():
			push_error("Bean and Bear floor outline could not be merged")
			quit(1)
			return
		merged = result[0]
		for polygon in result:
			if _area(polygon)>_area(merged): merged=polygon
	var curve := Curve2D.new()
	for point in merged: curve.add_point(point)
	var error := ResourceSaver.save(curve,"res://scenes/memories/bean_bear/walk_outline.tres")
	print("Bean and Bear floor: ",merged.size()," points, saved ",error)
	memory.free()
	quit(error)
func _area(polygon: PackedVector2Array) -> float:
	var area := 0.0
	for index in polygon.size(): area += polygon[index].cross(polygon[(index+1)%polygon.size()])
	return absf(area)*0.5
