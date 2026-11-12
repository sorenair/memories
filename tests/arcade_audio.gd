extends SceneTree
## Check cues against real simulation/animation events, not arbitrary timers.
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func run() -> void:
	var world := load("res://scenes/world/first_meeting_world.tscn").instantiate() as Node3D
	root.add_child(world)
	await process_frame
	await process_frame
	var pinball: PainterlyPinball = world.get_node("Memory/Zones/Arcade/Scenery/Machines/Pinball")
	var bag: PainterlyPunchingBag = world.get_node("Memory/Zones/Arcade/Scenery/Machines/PunchingBag")
	for machine in [pinball, bag]:
		for cue: AudioStreamPlayer in machine._sounds.get_children():
			check(not cue.playing and cue.bus == &"SFX" and cue.stream.get_length() > 0.1,
				"Machines must start silent with valid SFX clips")
	check(pinball.start_interaction(), "Pinball must accept a launch")
	pinball.set_process(false)
	check(pinball._sounds.get_node("Launch").playing and not pinball._sounds.get_node("Bumper").playing,
		"Launching must play the spring cue before any bumper hit")
	check(not pinball.start_interaction(), "Busy pinball must reject duplicate launches")
	pinball._simulation.launch(42, pinball.play_duration, pinball.launch_speed)
	var hit_heard := false
	for frame in 1000:
		if not pinball.is_playing(): break
		var before: int = pinball._simulation.bumper_hits
		pinball._process(1.0 / 120.0)
		if pinball._simulation.bumper_hits > before:
			hit_heard = hit_heard or pinball._sounds.get_node("Bumper").playing
	check(hit_heard and not pinball.is_playing() and pinball._sounds.get_node("Result").playing,
		"Real bumper collisions and the completed score must trigger their cues")
	check(pinball._sounds.get_node("Bumper").max_polyphony == 2,
		"Rapid bumper collisions must have bounded overlap")

	check(bag.start_interaction(), "Punching bag must accept a punch")
	bag.set_process(false)
	bag._process(0.10)
	check(not bag._sounds.get_node("Impact").playing, "Impact must wait for the visual windup")
	bag._process(0.10)
	check(bag._sounds.get_node("Impact").playing, "Crossing the windup must play the thump")
	check(not bag.start_interaction(), "Busy bag must reject duplicate punches")
	await create_timer(0.6).timeout
	bag._process(0.02)
	check(not bag._sounds.get_node("Impact").playing, "Swing frames must not repeat the impact sound")
	bag._process(5.0)
	check(not bag.is_playing() and bag._sounds.get_node("Result").playing,
		"Finishing the swing must play the result cue")
	var audio: MemoryAudio = world.get_node("Memory").get_audio()
	check(world.get_node("Memory/Zones/House/Ambience").playing, "Machine cues must not interrupt memory ambience")
	for machine in [pinball, bag]:
		machine.start_interaction()
		var old: WeakRef = weakref(machine._sounds)
		machine.rebuild()
		check(old.get_ref() == null and not machine.is_playing(),
			"Regeneration must free active voices and cancel the interaction")
		for cue: AudioStreamPlayer in machine._sounds.get_children():
			check(not cue.playing, "Regenerated sound banks must start silent")
		machine.sound_volume_db = -20.0
		check(is_equal_approx(machine._sounds.get_node("Result").volume_db, -24.0),
			"Inspector volume changes must affect existing cues with their balance offsets")
	world.free()
	await create_timer(0.35).timeout
	print("Arcade sound timing / lifetime: ", "PASS" if failures == 0 else "FAIL")
	quit(failures)
