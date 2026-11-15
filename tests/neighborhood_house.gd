extends SceneTree
## Cover reusable massing, editor changes and collision beyond the authored memory.
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(value: bool,message: String) -> void:
	if not value:
		failures += 1
		push_error(message)
func run() -> void:
	var house: PainterlyNeighborhoodHouse = load("res://components/buildings/neighborhood/painterly_neighborhood_house.tscn").instantiate()
	root.add_child(house)
	var triangles := []
	for profile in 4:
		house.profile = profile
		house.storeys = 2
		house.rebuild()
		var visual: MeshInstance3D = house.get_node("Exterior")
		var mesh := visual.mesh
		var points: PackedVector3Array = mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
		triangles.append(points.size()/3)
		check(mesh.get_surface_count()==1 and points.size()/3<15000,"All neighborhood profiles must remain one compact painted surface")
		var finite := true
		for p in points: finite = finite and p.is_finite()
		check(finite,"Roof and porch geometry must remain finite for every profile")
		house.rebuild()
		check(house.get_node("Exterior").mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]==points,"Each profile must rebuild deterministically")
		if profile>0:
			check(mesh.get_aabb().end.y>house.foundation_height+house.wall_height*2,"Gabled roof must sit above both storeys")
			var deck := Vector3(0,0,house.footprint.y*0.5+1.2)
			check(house.excludes_ground_point(deck),"The porch must remove groundcover underneath its deck")
			house.porch_enabled = false
			house.rebuild()
			check(not house.excludes_ground_point(deck),"Removing a porch must restore the former garden footprint")
			house.porch_enabled = true
	# Check a three-storey edited house with the real CharacterBody stair contract.
	house.profile = 1
	house.storeys = 3
	house.footprint = Vector2(5,4)
	house.foundation_height = 0.7
	house.porch_depth = 2.2
	house.step_count = 5
	house.rebuild()
	var floor := StaticBody3D.new()
	var plane := CollisionShape3D.new()
	plane.shape = WorldBoundaryShape3D.new()
	floor.add_child(plane)
	root.add_child(floor)
	var player := CharacterBody3D.new()
	player.floor_snap_length = 0.25
	var collider := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.25
	capsule.height = 1.35
	collider.shape = capsule
	collider.position.y = 0.675
	player.add_child(collider)
	root.add_child(player)
	player.position = house.get_node("Approach").position+Vector3.UP*0.05
	var climbed := 0.0
	for tick in 200:
		await physics_frame
		player.velocity = Vector3(0,-3,-2)
		player.move_and_slide()
		climbed = maxf(climbed,player.position.y)
	check(climbed>0.65,"Edited deep porch and stairs must support a real character")
	check(player.position.z>house.footprint.y*0.5+0.20,"Closed house must stop the explorer after crossing its porch")
	house.rotation.y = 0.7
	house.position.x = 4
	check(house.excludes_ground_point(house.to_global(Vector3.ZERO)),"Neighborhood exclusions must follow transforms")
	house.collision_enabled = false
	house.rebuild()
	check(not house.has_node("BuildingCollision"),"Distant scenic houses must support disabling physics")
	house.free()
	player.free()
	floor.free()
	print("Neighborhood house: ","PASS" if failures==0 else "FAIL"," | profile triangles: ",triangles)
	quit(failures)
