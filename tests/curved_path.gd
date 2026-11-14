extends SceneTree
## Verify ribbon support and exclusions on the actual bent, transformed geometry.
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(value: bool,message: String) -> void:
	if not value:
		failures += 1
		push_error(message)

func run() -> void:
	var path: PainterlyCurvedPath = load("res://components/groundcover/paving/painterly_curved_path.tscn").instantiate()
	path.position = Vector3(8,0.4,-3)
	path.rotation.y = 0.6
	path.curve = Curve3D.new()
	path.curve.bake_interval = 0.05
	path.curve.add_point(Vector3(0,0,6),Vector3.ZERO,Vector3(0,0,-2))
	path.curve.add_point(Vector3(2.5,0,2.8),Vector3(0.1,0,1.8),Vector3(-0.1,0,-1.8))
	path.curve.add_point(Vector3(-2.4,0,-0.6),Vector3(0,0,1.8),Vector3(0,0,-1.8))
	path.curve.add_point(Vector3(0.2,0,-4.5),Vector3(-2,0,0.2),Vector3(2,0,-0.2))
	path.curve.add_point(Vector3(6.6,0,-4.5),Vector3(-2.2,0,0),Vector3.ZERO)
	root.add_child(path)
	for frame in 3: await physics_frame
	var space := path.get_world_3d().direct_space_state
	var support := path.get_node("WalkingSurface")
	var length := path.get_path_length()
	check(length>20.0,"The authored curve must travel through the room rather than form an endpoint chord")
	for sample in range(1,80):
		var distance := length*sample/80.0
		var center := path.point_at(distance)
		var side := path._side_at(distance)
		for across: float in [-0.7,0.0,0.7]:
			var at := path.to_global(center+side*across)
			var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(at+Vector3.UP*0.25,at-Vector3.UP*0.25))
			check(not hit.is_empty() and hit.collider==support,"The real collider must continuously support the center and both passing lanes through every bend")
		if distance>1.0 and length-distance>1.0:
			check(path.excludes_ground_point(path.to_global(center)),"Foliage exclusion must follow the curved center under rotation and translation")
	var outside := path.to_global(Vector3(-7,0,5))
	check(not path.excludes_ground_point(outside),"The ribbon must not exclude the whole rectangular bounds")
	check(space.intersect_ray(PhysicsRayQueryParameters3D.create(outside+Vector3.UP, outside-Vector3.UP)).is_empty(),"The ribbon must not create a rectangular walking box across the void")
	var mesh: Mesh = path.get_node("PaintedRibbon").mesh
	var colors: PackedColorArray = mesh.surface_get_arrays(0)[Mesh.ARRAY_COLOR]
	path.rebuild()
	check(path.get_node("PaintedRibbon").mesh.surface_get_arrays(0)[Mesh.ARRAY_COLOR]==colors,"Regeneration must keep seeded pigment stable")
	path.curve.set_point_position(1,Vector3(3.1,0,2.8))
	await process_frame
	await process_frame
	check(path.get_node("PaintedRibbon").mesh!=mesh and path.get_node("WalkingSurface").get_child_count()==1,"Editing curve handles must rebuild one mesh and replace the continuous collider")
	var packed := PackedScene.new()
	check(packed.pack(path)==OK,"A curved path must serialize as reusable authoring parameters")
	var restored: PainterlyCurvedPath = packed.instantiate()
	check(restored.curve.point_count==5 and restored.get_children().is_empty(),"The authored curve must persist while generated geometry stays out of scenes")
	restored.free()
	path.curve = Curve3D.new()
	await process_frame
	await process_frame
	check(not path.has_node("PaintedRibbon") and not path.has_node("WalkingSurface"),"Clearing the curve must remove stale geometry and collision")
	path.free()
	await process_frame
	print("Curved path component: ","PASS" if failures==0 else "FAIL")
	quit(failures)
