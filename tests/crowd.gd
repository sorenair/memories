extends SceneTree
## Structural coverage for seeded placement, batch reuse, exclusions, and Inspector edits.
const CROWD = preload("res://components/characters/crowd/painterly_crowd.tscn")
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)

func run() -> void:
	var crowd: PainterlyCrowd = CROWD.instantiate()
	root.add_child(crowd)
	check(crowd.generated_count == crowd.count, "The default crowd must fit every requested person")
	var original: Array[Transform3D] = crowd._placements.duplicate()
	var original_appearances := crowd._appearances.duplicate()
	var original_data := crowd._instance_data.duplicate()
	var original_poses := crowd._pose_indices.duplicate()
	var shared_mesh: Mesh = crowd.GEOMETRY.get_body(0)
	crowd.rebuild()
	check(crowd._placements == original, "Identical seeds/settings must reproduce all poses")
	check(crowd._appearances == original_appearances and crowd._instance_data == original_data, "Seeds must reproduce independent identities and GPU proportions")
	check(crowd._pose_indices == original_poses, "Seeds must preserve independent standing poses")
	check(crowd.GEOMETRY.get_body(0) == shared_mesh, "Rebuilds must reuse shared body geometry")
	var bodies := {}
	var heads := {}
	var pairings := {}
	for appearance in crowd._appearances:
		bodies[appearance.x] = true
		heads[appearance.y] = true
		pairings[appearance] = true
	check(bodies.size() == 8 and heads.size() == 8, "A default crowd must use the full silhouette and hairstyle vocabulary")
	check(pairings.size() >= 14, "Heads and outfits must mix independently rather than producing eight fixed characters")
	var poses := {}
	for index in range(crowd.generated_count):
		poses[crowd._pose_indices[index]] = true
		check(floori(crowd._instance_data[index].a * 12.0) == crowd._pose_indices[index], "Packed GPU pose ids must match the generated stance")
	check(poses.size() == 12, "Everyday Mix must distribute all twelve standing poses before repeating")
	check(crowd._hitbox_shapes.size() == crowd.generated_count, "Every person must have an individual collision capsule")
	check(not crowd.is_processing(), "Crowd idle motion must not require a per-frame CPU callback")
	for a in range(original.size()):
		for b in range(a):
			check(original[a].origin.distance_to(original[b].origin) + 0.0001 >= crowd.spacing, "Loose placement must respect center spacing")
	crowd.crowd_seed += 1
	await process_frame
	check(crowd._placements != original, "Changing the seed must change placement or appearance")
	crowd.layout = 1
	crowd.count = 40
	crowd.footprint = Vector2(5, 4)
	crowd.empty_areas = [Rect2(-0.4, -3, 0.8, 6)]
	await process_frame
	check(crowd.generated_count == 40, "A sufficiently large layout must fill its requested count")
	for pose in crowd._placements:
		check(absf(pose.origin.x) > 0.4 + 0.25 * crowd.person_scale * (1.0 + crowd.build_variation), "An authored aisle must remain clear of bodies")
	var sibling: PainterlyCrowd = CROWD.instantiate()
	root.add_child(sibling)
	crowd.palette = 4
	crowd.clothing_colors = PackedColorArray([Color.RED])
	check(sibling._material != crowd._material, "Editing one crowd palette must not recolor its siblings")
	check(crowd._material.get_shader_parameter("clothing_a") == Color.RED, "Custom clothing must apply live")
	crowd.motion_strength = 0.0
	check(is_zero_approx(crowd._material.get_shader_parameter("motion_strength")), "Zero strength must disable motion")
	for child in crowd._generated.get_children():
		var batch := child as MultiMeshInstance3D
		check(batch != null, "Generated people must be batches, never per-person nodes")
	# The headless dummy renderer does not retain GPU instance transforms; use the
	# generator's authored poses rather than reading them back from RenderingServer.
	for index in range(crowd.generated_count):
		var pose := crowd._placements[index]
		var appearance := crowd._appearances[index]
		for part in range(2):
			var mesh: Mesh = crowd.GEOMETRY.get_body(appearance.x) if part == 0 else crowd.GEOMETRY.get_head(appearance.y)
			var prefix := "Bodies_" if part == 0 else "Heads_"
			var bounds := pose * mesh.get_aabb()
			var enclosed := false
			for batch: MultiMeshInstance3D in crowd._generated.get_children():
				if batch.name.begins_with(prefix) and batch.custom_aabb.encloses(bounds):
					enclosed = true
					break
			check(enclosed, "Culling bounds must contain every head/body plus deformation margin")
	var saved := PackedScene.new()
	check(saved.pack(crowd) == OK, "Crowd parameters must pack into an ordinary reusable scene")
	var restored: PainterlyCrowd = saved.instantiate()
	root.add_child(restored)
	check(restored._placements == crowd._placements, "Scene reload must reconstruct identical people and empty aisles")
	check(restored._appearances == crowd._appearances, "Scene reload must preserve all mixed identities")
	check(restored._pose_indices == crowd._pose_indices and restored._hitbox_shapes.size() == restored.generated_count, "Scene reload must preserve poses and reconstruct hitboxes")
	check(restored.clothing_colors == crowd.clothing_colors and restored.palette == 4, "Scene reload must preserve custom colors")
	restored.free()
	var stats := crowd.get_statistics()
	check(stats.batches < stats.people, "Figures must share draw batches")
	crowd.pose_mix = 1
	await process_frame
	for stance in crowd._pose_indices:
		check(crowd.POSE_MIXES[1].has(stance), "Quiet pose mix must omit the social gestures")
	crowd.collision_enabled = false
	await process_frame
	check(crowd._hitbox_shapes.is_empty() and not is_instance_valid(crowd._hitboxes), "Disabling collisions must remove all previous obstacles")
	crowd.collision_enabled = true
	await process_frame
	check(crowd._hitbox_shapes.size() == crowd.generated_count, "Re-enabling collision must recreate every capsule once")
	crowd.count = 0
	await process_frame
	check(crowd.generated_count == 0 and crowd._generated.get_child_count() == 0, "An empty crowd must leave no stale geometry")
	check(crowd._hitbox_shapes.is_empty() and not is_instance_valid(crowd._hitboxes), "An empty crowd must leave no invisible colliders")
	crowd.count = 1000
	crowd.footprint = Vector2(0.4, 0.4)
	crowd.empty_areas = []
	await process_frame
	check(crowd.generated_count <= 1 and not crowd._get_configuration_warnings().is_empty(), "Overfull footprints must cap safely and explain capacity")
	print("Standing crowd: ", "PASS" if failures == 0 else "FAIL", " | 40-person sample: ", stats)
	crowd.free()
	sibling.free()
	quit(failures)
