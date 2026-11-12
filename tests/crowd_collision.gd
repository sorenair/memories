extends SceneTree
## Actual physics checks: per-person hits, scaled capsules, rebuild cleanup, and explorer movement.
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)

func settle() -> void:
	await physics_frame
	await physics_frame
	await process_frame

func run() -> void:
	var stage := Node3D.new()
	root.add_child(stage)
	var ground := StaticBody3D.new()
	var floor_shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(30, 0.5, 30)
	floor_shape.shape = box
	floor_shape.position.y = -0.25
	ground.add_child(floor_shape)
	stage.add_child(ground)
	var crowd: PainterlyCrowd = load("res://components/characters/crowd/painterly_crowd.tscn").instantiate()
	crowd.position = Vector3(2, 0, -1)
	crowd.rotation.y = 0.37
	stage.add_child(crowd)
	await settle()
	var space := stage.get_world_3d().direct_space_state
	# Vertical rays distinguish individuals even though one static body owns a chunk.
	for index in range(crowd.generated_count):
		var center := crowd.to_global(crowd._placements[index].origin)
		var query := PhysicsRayQueryParameters3D.create(center + Vector3.UP * 3, center + Vector3.UP * 0.25, 1)
		var hit := space.intersect_ray(query)
		check(not hit.is_empty(), "Each rendered person must have a ray-hittable capsule")
		if not hit.is_empty():
			check(crowd.person_index_from_hit(hit.collider, hit.shape) == index, "Physics hits must resolve the exact person's index")
		var capsule := crowd._hitbox_shapes[index].shape as CapsuleShape3D
		var person_scale := crowd._placements[index].basis.get_scale()
		check(is_equal_approx(capsule.radius, crowd.hitbox_radius * person_scale.x), "Hitbox radius must follow individual build and scale")
		check(is_equal_approx(capsule.height, crowd.hitbox_height * person_scale.y), "Hitbox height must follow individual stature")
	var old_center := crowd.to_global(crowd._placements[0].origin)
	crowd.collision_enabled = false
	await process_frame
	await settle()
	var old_hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(old_center + Vector3.UP * 3, old_center + Vector3.UP * 0.25, 1))
	check(old_hit.is_empty(), "Turning off hitboxes must remove the old physics shapes")
	# Isolate a single crowd member and drive the actual explorer against its capsule.
	crowd.position = Vector3.ZERO
	crowd.rotation = Vector3.ZERO
	crowd.count = 1
	crowd.footprint = Vector2(0.4, 0.4)
	crowd.collision_enabled = true
	crowd.rebuild()
	var actor: MemoryExplorer = load("res://scenes/player/explorer.tscn").instantiate()
	actor.position = Vector3(0, 0.03, 1.5)
	stage.add_child(actor)
	actor.set_physics_process(false)
	await settle()
	for frame in range(90):
		await physics_frame
		actor.velocity = Vector3(0, -1, -2)
		actor.move_and_slide()
	var radius: float = crowd._hitbox_shapes[0].shape.radius
	check(actor.position.z > radius + 0.25 - 0.02, "Held forward movement must stop against the person")
	check(actor.position.z < 0.8, "The explorer must actually approach before contact")
	for frame in range(45):
		await physics_frame
		actor.velocity = Vector3(2, -1, 0)
		actor.move_and_slide()
	check(actor.position.x > 1.0, "The explorer must be able to move around the person's capsule")
	for frame in range(70):
		await physics_frame
		actor.velocity = Vector3(0, -1, -2)
		actor.move_and_slide()
	check(actor.position.z < -0.8, "Passing beside a person must remain possible")
	crowd.count = 0
	await process_frame
	await settle()
	check(space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(0, 3, 0), Vector3(0, 0.25, 0), 1)).is_empty(), "Reducing the count must remove stale obstacles")
	print("Crowd physics: ", "PASS" if failures == 0 else "FAIL")
	stage.free()
	await process_frame
	quit(failures)
