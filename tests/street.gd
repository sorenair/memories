extends SceneTree
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(value: bool,message: String) -> void:
	if not value:
		failures += 1
		push_error(message)
func supported(at: Vector3) -> bool:
	var query := PhysicsRayQueryParameters3D.create(at+Vector3.UP*2,at-Vector3.UP*2)
	return not root.world_3d.direct_space_state.intersect_ray(query).is_empty()
func run() -> void:
	var street: PainterlyStreet = load("res://components/groundcover/street/painterly_street.tscn").instantiate()
	street.length = 14
	street.width = 8
	street.position = Vector3(2,0,3)
	street.rotation.y = 0.5
	root.add_child(street)
	for frame in 4: await physics_frame
	check(street.get_node("Asphalt").mesh.get_surface_count()==1,"Street must be one continuous surface")
	check(supported(street.to_global(Vector3(3,0,6))),"Configured width and length must support the full road")
	check(not supported(street.to_global(Vector3(0,0,8))),"Street collision must end at the configured length")
	check(street.excludes_ground_point(street.global_position),"Street must exclude planting through transformed asphalt")
	check(not street.excludes_ground_point(street.to_global(Vector3(4.2,0,0))),"Planting beyond the street edges must remain available")
	street.length = 28
	for frame in 4: await physics_frame
	check(supported(street.to_global(Vector3(0,0,12))),"Editing Length must update collision as well as the visible road")
	street.collision_enabled = false
	for frame in 4: await physics_frame
	check(not supported(street.global_position),"Scenic streets must support disabling their own collision")
	street.free()
	print("Street component: ","PASS" if failures==0 else "FAIL")
	quit(failures)
