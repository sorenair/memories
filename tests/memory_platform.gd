extends SceneTree
var failures: int = 0
func _initialize() -> void:
	call_deferred("run")
func check(condition: bool,message: String) -> void:
	if not condition:
		push_error(message)
		failures+=1
func run() -> void:
	var world: Node3D =load("res://scenes/world/memory_world.tscn").instantiate()
	root.add_child(world)
	var platform: MemoryPlatform=world.get_node("Memory/Environment/MemoryPlatform")
	var player: CharacterBody3D=world.get_node("Explorer")
	check(not world.get_node("DreamSurface").visible and world.get_node("Ground/CollisionShape3D").disabled,"Platform memories must disable infinite ground")
	check(platform.contains_ground_point(world.get_node("Memory/Exit").global_position,0.8),"Exit must remain reachable on the platform")
	check(platform.contains_ground_point(player.global_position,1.0),"Entry must have generous platform clearance")
	check(platform.contains_ground_point(player.global_position+world.recalled_spawn_offset,1.0),"Recall landing must stay inside the platform")
	for frame in range(5):
		await physics_frame
	check(player.is_on_floor(),"Platform top must support the explorer")
	var body:=platform.get_node("PlatformCollision")
	check(body.get_child_count()==platform.outline_detail+1,"Every rim segment must have collision")
	var mesh: Mesh=platform.get_node("PlatformSurface").mesh
	var faces:=mesh.get_faces()
	var valid:=true
	for index in range(0,faces.size(),3):
		valid=valid and faces[index].is_finite() and (faces[index+1]-faces[index]).cross(faces[index+2]-faces[index]).length_squared()>0.000000001
	check(valid and faces.size()/3<1500,"Platform must have valid low-budget geometry")
	var original:=faces.duplicate()
	platform.rebuild()
	check(platform.get_node("PlatformSurface").mesh.get_faces()==original,"Seeded platform geometry must be repeatable")
	# Attempt escape at four rim faces; normal CharacterBody motion must stop inside.
	player.movement_camera=null
	for direction in [Vector2.RIGHT,Vector2.LEFT,Vector2.UP,Vector2.DOWN]:
		var center:=Vector3(0,0,1)
		var start:=center+Vector3(direction.x*9.5,0,direction.y*12.5)
		player.global_position=start
		player.velocity=Vector3.ZERO
		player.reset_physics_interpolation()
		var action: StringName
		if direction==Vector2.RIGHT: action=&"move_right"
		elif direction==Vector2.LEFT: action=&"move_left"
		elif direction==Vector2.UP: action=&"move_forward"
		else: action=&"move_back"
		Input.action_press(action)
		for frame in range(150):
			await physics_frame
		Input.action_release(action)
		check(platform.contains_ground_point(player.global_position,0.2) and player.is_on_floor(),"Rim must keep walking players on the platform")
		check(Vector2(player.velocity.x,player.velocity.z).length()<0.15,"Rim must physically stop outward movement")
	var visual:=platform.get_node("PlatformSurface")
	platform.side_color=Color("e2dfd5")
	check(platform.get_node("PlatformSurface")==visual,"Color edits must not regenerate geometry")
	var packed:=PackedScene.new()
	packed.pack(platform)
	var restored: MemoryPlatform=packed.instantiate()
	root.add_child(restored)
	check(restored.footprint==platform.footprint and restored.platform_seed==platform.platform_seed,"Platform controls must survive saving")
	restored.free()
	# Custom concave outlines use the same top, floor, and containment polygon.
	var custom := Curve2D.new()
	for point in [Vector2(-3,-3),Vector2(3,-3),Vector2(3,3),Vector2(0,1),Vector2(-3,3)]:
		custom.add_point(point)
	platform.custom_outline = custom
	platform.rebuild()
	check(platform.contains_ground_point(platform.to_global(Vector3(0,0,0))) and not platform.contains_ground_point(platform.to_global(Vector3(0,0,2.8))),"Custom concave outline must preserve its inlet")
	var ray := PhysicsRayQueryParameters3D.create(platform.to_global(Vector3(0,2,0)),platform.to_global(Vector3(0,-2,0)))
	await physics_frame
	check(not platform.get_world_3d().direct_space_state.intersect_ray(ray).is_empty(),"Custom platform floor must support downward collision")
	platform.custom_outline = null
	platform.rebuild()
	check(not world._landing_supported(Vector3(3000,0,3000)),"Recall must reject an unsupported offset into the void")
	# Infinite ground remains available for the original blank-void template.
	world.free()
	var blank: Node3D =load("res://scenes/world/memory_world.tscn").instantiate()
	var old: Node=blank.get_node("Memory")
	blank.remove_child(old)
	old.free()
	var memory: Node3D =load("res://scenes/memories/blank_void.tscn").instantiate()
	memory.name="Memory"
	blank.add_child(memory)
	root.add_child(blank)
	check(blank.get_node("DreamSurface").visible and not blank.get_node("Ground/CollisionShape3D").disabled,"Unbounded templates must retain their fallback ground")
	blank.free()
	print("Memory platform checks: ","PASS" if failures==0 else "FAIL"," | triangles: ",original.size()/3)
	quit(failures)
