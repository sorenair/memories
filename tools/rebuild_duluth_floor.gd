extends SceneTree
## One finite support boundary around the connected hiking, shore and garden routes.
const GARDEN_OUTLINE: Curve2D = preload("res://scenes/memories/duluth_autumn/garden_walk_outline.tres")

func _initialize() -> void: call_deferred("run")
func run() -> void:
	var memory := load("res://scenes/memories/duluth_autumn.tscn").instantiate() as MemoryScene
	root.add_child(memory)
	await process_frame
	var shapes: Array[PackedVector2Array] = []
	_add_path(shapes,memory.get_node("Zones/Trail/Scenery/ForestTrail"))
	_add_path(shapes,memory.get_node("Zones/Trail/Scenery/LookoutClimb"))
	var ridge: Node3D = memory.get_node("Zones/Trail/Scenery/RockLookout")
	var rock_ground := PackedVector2Array()
	for point: Vector2 in ridge.outline:
		var world := ridge.to_global(Vector3(point.x, 0.0, point.y))
		rock_ground.append(Vector2(world.x, world.z))
	shapes.append(rock_ground)
	_add_path(shapes,memory.get_node("Zones/Trail/Scenery/ToLighthouse"))
	var bank: PainterlySandPatch = memory.get_node("Zones/Lighthouse/Scenery/RockyBank")
	var land := PackedVector2Array()
	for i in bank.custom_outline.point_count:
		var p := bank.custom_outline.get_point_position(i)
		var world := bank.to_global(Vector3(p.x,0,p.y))
		land.append(Vector2(world.x,world.z))
	shapes.append(land)
	_add_path(shapes, memory.get_node("Zones/Lighthouse/Scenery/ShoreApproach"), 1.45)
	shapes.append(memory.get_node("Zones/Lighthouse/Scenery/Breakwater").get_walk_outline())
	_add_path(shapes, memory.get_node("Zones/Lighthouse/Scenery/ToGarden"), 1.95)
	for route in ["GardenWalk","GardenCircuit"]: _add_path(shapes,memory.get_node("Zones/Garden/Scenery/"+route))
	_add_path(shapes, memory.get_node("Zones/Garden/Scenery/TowerSpur"), 1.55)
	var garden_zone: Node3D = memory.get_node("Zones/Garden")
	var garden := PackedVector2Array()
	for i in GARDEN_OUTLINE.point_count:
		var point := GARDEN_OUTLINE.get_point_position(i)
		var world := garden_zone.to_global(Vector3(point.x, 0, point.y))
		garden.append(Vector2(world.x, world.z))
	shapes.append(garden)
	var merged := shapes[0]
	for i in range(1,shapes.size()):
		var result := Geometry2D.merge_polygons(merged,shapes[i])
		if result.is_empty():
			push_error("Duluth support outline failed to merge")
			quit(1)
			return
		merged = result[0]
		for p in result:
			if _area(p)>_area(merged): merged=p
	var curve := Curve2D.new()
	for p in merged: curve.add_point(p)
	var error := ResourceSaver.save(curve,"res://scenes/memories/duluth_autumn/walk_outline.tres")
	print("Duluth floor: ",merged.size()," points, saved ",error)
	memory.free()
	quit(error)
func _add_path(shapes: Array[PackedVector2Array],path: PainterlyCurvedPath, width := 2.65) -> void:
	var line := PackedVector2Array()
	for p in path.get_route_points(0,1,.35): line.append(Vector2(p.x,p.z))
	shapes.append_array(Geometry2D.offset_polyline(line,width,Geometry2D.JOIN_ROUND,Geometry2D.END_ROUND))
func _area(points: PackedVector2Array) -> float:
	var area := 0.0
	for i in points.size(): area+=points[i].cross(points[(i+1)%points.size()])
	return absf(area)*.5
