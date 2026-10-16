extends SceneTree
## Headless checks of custom shapes, shared settings, shoreline fields, and obstacles.
var failures: int = 0
func _initialize() -> void:
	call_deferred("run")
func check(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		failures += 1
func distance_at(water: PainterlyWater, point: Vector2) -> float:
	var data: Dictionary = water._shore_data
	var uv: Vector2 = (point - data.bounds.position) / data.bounds.size
	var image: Image = data.image
	return image.get_pixel(clampi(int(uv.x * image.get_width()), 0, image.get_width()-1), clampi(int(uv.y * image.get_height()), 0, image.get_height()-1)).r
func run() -> void:
	var world := Node3D.new()
	root.add_child(world)
	var water: PainterlyWater = load("res://components/scenery/water/painterly_water.tscn").instantiate()
	water.name = "Water"
	water.footprint = Vector2(6,5)
	water.pond_outline = load("res://components/scenery/water/examples/pond_outline.tres")
	world.add_child(water)
	var original: PackedVector3Array = water.get_node("PaintedWater").mesh.get_faces()
	var valid := true
	for index in range(0,original.size(),3):
		valid = valid and (original[index+1]-original[index]).cross(original[index+2]-original[index]).length_squared() > 0.00000001
	check(valid and original.size()/3 < 1600, "Custom pond must triangulate without collapsed faces and retain a mobile budget")
	check(water.excludes_ground_point(Vector3(-2,0,0)) and not water.excludes_ground_point(Vector3(5,0,5)), "Custom outline must drive ground exclusion")
	check(distance_at(water,Vector2(-2,0)) > 0 and distance_at(water,Vector2(5,5)) < 0, "Baked field must distinguish inside/outside the custom pond")
	# Shared resources update both materials without regenerating either mesh.
	var other: PainterlyWater = load("res://components/scenery/water/painterly_water.tscn").instantiate()
	world.add_child(other)
	var shared := WaterSettings.new()
	water.settings = shared
	other.settings = shared
	var first_mesh := water.get_node("PaintedWater").get_instance_id()
	var second_mesh := other.get_node("PaintedWater").get_instance_id()
	shared.normal_strength = 0.61
	check(water._water_material.get_shader_parameter("normal_strength") == 0.61 and other._water_material.get_shader_parameter("normal_strength") == 0.61, "Shared settings must update both water materials")
	check(first_mesh == water.get_node("PaintedWater").get_instance_id() and second_mesh == other.get_node("PaintedWater").get_instance_id(), "Appearance settings must not rebake geometry")
	water.behavior_preset = 2
	var packed := PackedScene.new()
	packed.pack(water)
	var restored: PainterlyWater = packed.instantiate()
	world.add_child(restored)
	check(restored.behavior_preset == 2 and restored.settings.flow_speed == water.settings.flow_speed and restored.pond_outline != null, "Behavior preset and authored outline must survive scene saving")
	restored.free()
	# Boulders and merged clusters have independent convex slices at water level.
	water.pond_outline = null
	water.rebuild()
	var rock: PainterlyBoulder = load("res://components/scenery/boulders/painterly_boulder.tscn").instantiate()
	rock.name = "Rock"
	rock.dimensions = Vector3(1,0.7,1)
	rock.shape_profile = 1
	rock.position = Vector3(0.8,0,0)
	world.add_child(rock)
	water.shore_obstacles = [NodePath("../Rock")]
	water.rebuild()
	check(water._obstacle_regions.size() == 1, "Solid boulder must register a water-plane section")
	check(distance_at(water,Vector2(0.8,0)) < 0 and distance_at(water,Vector2(-1,0)) > 0, "Obstacle must cut the shore field without filling the pond")
	var old_region := water._obstacle_regions[0].duplicate()
	rock.position.x += 0.6
	await process_frame
	await process_frame
	check(water._obstacle_regions[0] != old_region, "Moving a registered rock must refresh the field")
	rock.solid = false
	rock.rebuild()
	water.rebuild()
	check(water._obstacle_regions.size() == 1, "Decorative rocks must produce visual foam sections without physics collision")
	var cluster: PainterlyRockCluster = load("res://components/scenery/rock_clusters/painterly_rock_cluster.tscn").instantiate()
	cluster.name = "Cluster"
	cluster.rock_count = 3
	cluster.solid = false
	world.add_child(cluster)
	water.shore_obstacles = [NodePath("../Cluster")]
	water.rebuild()
	check(water._obstacle_regions.size() == 3, "Merged decorative clusters must retain separate rock sections")
	water.shore_obstacles = []
	water.shape = 1
	water.stream_path = load("res://components/scenery/water/examples/stream_curve.tres")
	water.stream_width_profile = load("res://components/scenery/water/examples/stream_width.tres")
	water.footprint = Vector2(1.8,10)
	water.rebuild()
	var data: Dictionary = water._shape_data
	check(data.widths[20] > data.widths[0] * 1.2, "Authored width profile must shape the stream")
	var near_start := WaterBodyGeometry.stream_flow(data.centers[4],data)
	var near_end := WaterBodyGeometry.stream_flow(data.centers[42],data)
	check(near_start.dot(near_end) < 0.9, "Flow must turn with the authored curve")
	var points: PackedVector3Array = water.get_node("PaintedWater").mesh.get_faces()
	valid = true
	for index in range(0,points.size(),3):
		valid = valid and points[index].is_finite() and (points[index+1]-points[index]).cross(points[index+2]-points[index]).length_squared() > 0.000000001
	check(valid, "Curved variable-width stream must have valid triangles")
	check(water.excludes_ground_point(Vector3(data.centers[24].x,0,data.centers[24].y)), "Stream geometry and grass exclusion must share the curve")
	water.cap_stream_ends = false
	water.rebuild()
	check(distance_at(water, data.centers[0]) > 0.3, "Open mouths must not become artificial foam shores")
	print("Water framework checks: ", "PASS" if failures == 0 else "FAIL")
	world.free()
	quit(failures)
