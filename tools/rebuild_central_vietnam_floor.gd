extends SceneTree
## Rebuild the single finite outline after editing the Central Vietnam paths.
func _initialize(): call_deferred("run")
func run():
	var memory=load("res://scenes/memories/central_vietnam.tscn").instantiate()
	root.add_child(memory)
	await process_frame
	var shapes: Array[PackedVector2Array]=[]
	# One solid mountain clearing, connected to the original fields and court.
	var mountains=PackedVector2Array()
	for i in 96:
		var a=TAU*i/96.0
		mountains.append(Vector2(cos(a)*16.5,sin(a)*15.0+13))
	shapes.append(mountains)
	var trail: PainterlyCurvedPath=memory.get_node("Zones/MarbleMountains/Scenery/ToFields")
	var line=PackedVector2Array()
	for point in trail.get_route_points(0,1,0.4): line.append(Vector2(point.x,point.z))
	shapes.append_array(Geometry2D.offset_polyline(line,2.25,Geometry2D.JOIN_ROUND,Geometry2D.END_ROUND))
	shapes.append(PackedVector2Array([Vector2(12,-29),Vector2(43,-29),Vector2(43,0),Vector2(12,0)]))
	trail=memory.get_node("Zones/Rice/Scenery/ToHue")
	line=PackedVector2Array()
	for point in trail.get_route_points(0,1,0.4): line.append(Vector2(point.x,point.z))
	shapes.append_array(Geometry2D.offset_polyline(line,2.25,Geometry2D.JOIN_ROUND,Geometry2D.END_ROUND))
	shapes.append(PackedVector2Array([Vector2(40,-59),Vector2(68,-59),Vector2(68,-21),Vector2(40,-21)]))
	var merged: PackedVector2Array=shapes[0]
	for i in range(1,shapes.size()):
		var result=Geometry2D.merge_polygons(merged,shapes[i])
		assert(result.size()==1,"Connected floor must remain a single outline without holes")
		merged=result[0]
	var curve=Curve2D.new()
	for point in merged: curve.add_point(point)
	var error=ResourceSaver.save(curve,"res://scenes/memories/central_vietnam/walk_outline.tres")
	print("Central Vietnam floor: ",merged.size()," points, saved ",error)
	memory.free()
	quit(error)
