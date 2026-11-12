extends SceneTree
var failures := 0

func _initialize() -> void: call_deferred("run")

func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)

func settle(audio: MemoryAudio) -> void:
	for frame in 400:
		audio._process(1.0 / 120.0)

func run() -> void:
	var world := load("res://scenes/world/first_meeting_world.tscn").instantiate() as Node3D
	root.add_child(world)
	await process_frame
	await process_frame
	var memory: MemoryScene = world.get_node("Memory")
	var zones := memory.get_zones()
	check(zones.size() == 2 and zones[0].zone_id == &"house" and zones[1].zone_id == &"arcade",
		"First Meeting must compose two ordered, identified zones")
	var house: MemoryZone = zones[0]
	var arcade: MemoryZone = zones[1]
	for zone in zones:
		check(zone.get_node("Scenery").get_child_count() > 0 and zone.get_fragment() != null
			and zone.ambience_stream != null and zone.ambience.bus == &"Ambience",
			"Every zone must own scenery, a fragment, and an ambience source")
		for grass: PainterlyGrassPatch in zone.find_children("*", "PainterlyGrassPatch", true, false):
			for path in grass.ground_exclusions:
				check(grass.get_node_or_null(path) != null, "Relocated groundcover exclusions must still resolve")
	check(memory.get_guidance_fragments() == [house.get_fragment(), arcade.get_fragment()],
		"Zone order must define default guidance order")
	memory.get_node("Zones").move_child(arcade, 0)
	check(memory.get_guidance_fragments()[0] == arcade.get_fragment(),
		"Reordering zones must reorder default guidance without editing NodePaths")
	memory.get_node("Zones").move_child(house, 0)
	var audio := memory.get_audio()
	var actor: MemoryExplorer = world.get_node("Explorer")
	actor.set_physics_process(false)
	audio.set_process(false)
	var spawn := actor.global_position
	settle(audio)
	check(house.ambience.playing and house._gain > 0.99 and not arcade.ambience.playing,
		"The sidewalk arrival must hear house wind, not distant arcade ambience")

	actor.global_position = Vector3(7.8, 0.04, 2.0)
	var previous := house._gain
	audio._process(1.0 / 60.0)
	check(absf(house._gain - previous) < 0.1 and house.ambience.playing and arcade.ambience.playing,
		"Entering the overlap must blend smoothly instead of hard switching")
	settle(audio)
	check(house._gain > 0.1 and arcade._gain > 0.1 and house._gain + arcade._gain <= 1.001,
		"Overlapping beds must use normalized gains to avoid a doubled mix")

	actor.global_position = Vector3(15.0, 0.04, 1.0)
	settle(audio)
	check(arcade.ambience.playing and arcade._gain > 0.99 and not house.ambience.playing,
		"At the machines, arcade ambience must replace house wind")
	actor.global_position = Vector3(100, 0, 100)
	settle(audio)
	check(not arcade.ambience.playing and not house.ambience.playing,
		"Outside all zone bounds, ambience players must fade out and stop")
	actor.global_position = spawn
	settle(audio)
	check(house.ambience.playing, "Returning to a zone must restart its ambience")
	audio.set_listener(null)
	check(not house.ambience.playing and not arcade.ambience.playing,
		"Removing the listener must stop zone audio safely")

	# A future authored zone moves and rotates its scenery, fragment, and bounds together.
	var template := load("res://scenes/memories/memory_zone.tscn").instantiate() as MemoryZone
	root.add_child(template)
	template.position = Vector3(40, 0, -20)
	template.rotation.y = 0.7
	template.ambience_size = Vector2(8, 4)
	check(template.get_fragment() != null and template.has_node("Scenery") and template.has_node("Ambience"),
		"The reusable zone scene must provide the complete standard structure")
	check(template.get_ambience_weight(template.to_global(Vector3(3, 0, 1))) == 1.0
		and template.get_ambience_weight(template.to_global(Vector3(20, 0, 0))) == 0.0,
		"Ambience bounds must respect a zone's transformed local coordinates")
	template.ambience_stream = preload("res://audio/samples/arcade_result.wav")
	template.ambience_loop = false
	template.prepare_audio()
	template.update_ambience(1.0, 0.2)
	await create_timer(0.7).timeout
	template.update_ambience(1.0, 0.2)
	check(not template.ambience.playing, "A non-looping zone clip must not restart every frame while inside")
	template.update_ambience(0.0, 5.0)
	template.update_ambience(1.0, 0.2)
	check(template.ambience.playing, "A non-looping clip may play again after leaving and re-entering")
	template.free()

	var starter := load("res://scenes/memories/memory_template.tscn").instantiate() as MemoryScene
	root.add_child(starter)
	check(starter.get_zones().size() == 1 and starter.get_guidance_fragments().size() == 1
		and starter.has_node("Environment/Platform") and starter.get_audio() != null,
		"A new memory starter must include one complete zone, shared audio, and supported ground")
	starter.free()

	# Existing non-zone memories retain their original fragment discovery and global bed API.
	var legacy := load("res://scenes/memories/foliage_demo.tscn").instantiate() as MemoryScene
	root.add_child(legacy)
	check(legacy.get_zones().is_empty() and legacy.get_guidance_fragments().size() == 2,
		"Seasonal Demo must retain its original two fragments without forced migration")
	legacy.free()
	world.free()
	await create_timer(0.35).timeout
	print("Memory zones / ambience blending: ", "PASS" if failures == 0 else "FAIL")
	quit(failures)
