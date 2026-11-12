extends SceneTree
## Real memory/band/cue integration, simultaneous playback, mixing, and scene cleanup.
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)

func short_tone() -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = 22050
	var data := PackedByteArray()
	data.resize(4410 * 2)
	for sample in 4410:
		data.encode_s16(sample * 2, roundi(sin(TAU * 330.0 * sample / stream.mix_rate) * 4000))
	stream.data = data
	return stream

func run() -> void:
	var mixer := root.get_node("AudioMixer")
	for channel in [&"Master", &"Memory", &"Music", &"Ambience", &"SFX", &"UI"]:
		check(AudioServer.get_bus_index(channel) >= 0, "Missing bus: " + channel)
	for channel in [&"Music", &"Ambience", &"SFX"]:
		check(AudioServer.get_bus_send(AudioServer.get_bus_index(channel)) == &"Memory",
			str(channel) + " must pass through the memory fade bus")
	check(AudioServer.get_bus_send(AudioServer.get_bus_index(&"UI")) == &"Master",
		"UI must be independent of the memory transition")
	check(AudioServer.get_bus_effect(0, 0) is AudioEffectHardLimiter, "Master must limit summed peaks")

	var original_music: float = mixer.get_level(&"Music")
	var original_sfx: float = mixer.get_level(&"SFX")
	mixer.set_level(&"Music", 0.4)
	mixer.set_level(&"SFX", 0.7)
	mixer.set_muted(&"Music", true)
	check(is_equal_approx(mixer.get_level(&"Music"), 0.4) and mixer.is_muted(&"Music"),
		"Muting must preserve the category level")
	check(not mixer.is_muted(&"SFX") and is_equal_approx(mixer.get_level(&"SFX"), 0.7),
		"Adjusting music must not affect effects")
	mixer.set_level(&"Music", 0.0)
	check(mixer.get_level(&"Music") == 0.0, "A zero volume must be silent without nonfinite gains")
	mixer.set_muted(&"Music", false)
	mixer.set_level(&"Music", original_music)
	mixer.set_level(&"SFX", original_sfx)

	var world := load("res://scenes/world/first_meeting_world.tscn").instantiate() as Node3D
	root.add_child(world)
	current_scene = world
	await process_frame
	await process_frame
	var soundscape: MemoryAudio = world.get_node("Memory").get_audio()
	var house: MemoryZone = world.get_node("Memory/Zones/House")
	check(house.ambience.playing and not soundscape.music.playing and not soundscape.ambience.playing,
		"First Meeting must start its wind bed and tolerate an empty music slot")
	check(soundscape.ambience.bus == &"Ambience" and soundscape.music.bus == &"Music",
		"The two continuous layers must have independent routing")
	var source := house.ambience_stream as AudioStreamWAV
	check(source.loop_mode == AudioStreamWAV.LOOP_DISABLED
		and house.ambience.stream.loop_mode == AudioStreamWAV.LOOP_FORWARD,
		"Looping must be configured on a private stream, not mutate the shared imported asset")
	var tone := short_tone()
	soundscape.play_music(tone, -18.0)
	soundscape.play_ambience(tone, -30.0)
	# Its stream is shorter than the wait, so this proves the bed actually loops.
	await create_timer(0.4).timeout
	check(soundscape.music.playing and soundscape.ambience.playing,
		"Music must loop alongside ambience beyond the clip's end")
	check(tone.loop_mode == AudioStreamWAV.LOOP_DISABLED, "Playing a bed must preserve caller-owned resources")

	var band: PainterlyMechanicalBand = world.get_node("Memory/Zones/Arcade/Scenery/Machines/MechanicalBand")
	for index in 4:
		check(band._sounds[index].bus == &"SFX", "The band's instruments must use the effects fader")
		band.play_instrument(index)
	band._process(0.09)
	band.set_process(false)
	for index in 4:
		check(band._sounds[index].playing, "All four band notes must overlap")

	var actor := world.get_node("Explorer") as MemoryExplorer
	actor.set_physics_process(false)
	var fragment := world.get_node("Memory/Zones/House/Fragment") as MemoryFragment
	actor.global_position = fragment.global_position + Vector3.RIGHT * 0.5
	check(fragment.try_activate(actor), "The house fragment must retain its interaction")
	var cue_count := 0
	for voice in soundscape._voices:
		if voice.playing and voice.bus == &"SFX":
			cue_count += 1
	check(cue_count == 1, "An accepted fragment must trigger one SFX cue")
	check(not fragment.try_activate(actor), "Duplicate interactions must not stack cues")

	var first := soundscape.play_sfx(band.SOUNDS[3], -12.0)
	var second := soundscape.play_sfx(band.SOUNDS[0], -16.0, 0.95)
	var ui := soundscape.play_ui(band.SOUNDS[1], -20.0)
	check(first != second and first.playing and second.playing and ui.playing and ui.bus == &"UI",
		"Different sound effects and UI cues must coexist without cutting each other off")
	check(soundscape.music.playing and soundscape.ambience.playing,
		"One-shots and band interactions must not interrupt the continuous beds")

	# Inspect actual mixed output rather than only checking player flags.
	var capture := AudioEffectCapture.new()
	AudioServer.add_bus_effect(0, capture)
	await create_timer(0.2).timeout
	var buffer := capture.get_buffer(capture.get_frames_available())
	var peak := 0.0
	for frame in buffer:
		peak = maxf(peak, maxf(absf(frame.x), absf(frame.y)))
	check(buffer.size() > 0 and peak > 0.0001 and peak <= 1.0,
		"Simultaneous layers must reach Master as non-silent, bounded mixed samples")
	AudioServer.remove_bus_effect(0, AudioServer.get_bus_effect_count(0) - 1)

	var count := soundscape.get_child_count()
	for index in soundscape.max_one_shots * 3:
		soundscape.play_sfx(band.SOUNDS[3], -15.0)
	check(soundscape.get_child_count() == count and soundscape._voices.size() == soundscape.max_one_shots,
		"Rapid cues must steal a voice, not create unbounded players")
	var music_level: float = mixer.get_level(&"Music")
	mixer.fade_memory_out(0.05)
	await create_timer(0.1).timeout
	check(AudioServer.get_bus_volume_db(AudioServer.get_bus_index(&"Memory")) <= -79.0,
		"Memory transition must fade music, ambience, and band audio together")
	check(is_equal_approx(mixer.get_level(&"Music"), music_level)
		and AudioServer.get_bus_volume_db(AudioServer.get_bus_index(&"UI")) == 0.0,
		"Transition fades must preserve user category levels and UI volume")

	# An interrupted exit fade must never silence a newly entered memory later.
	mixer.fade_memory_out(0.2)
	mixer.begin_memory(0.0)
	await create_timer(0.25).timeout
	check(is_zero_approx(AudioServer.get_bus_volume_db(AudioServer.get_bus_index(&"Memory"))),
		"Starting another memory must cancel stale fade tweens")
	soundscape.stop()
	check(not soundscape.music.playing and not soundscape.ambience.playing and not house.ambience.playing,
		"Explicit stop must stop both continuous layers")
	var old_audio: WeakRef = weakref(soundscape)
	mixer.set_level(&"Music", 0.35)
	world.get_node("Controls/FragmentInteraction").advance_note()
	actor.set_physics_process(true)
	world.get_node("Controls/ReturnToTimeline").return_to_timeline()
	await create_timer(0.65).timeout
	check(current_scene.scene_file_path == "res://UI/memory_lane/memory_lane.tscn"
		and old_audio.get_ref() == null, "Timeline return must free memory-owned audio")
	check(AudioServer.get_bus_volume_db(AudioServer.get_bus_index(&"Memory")) <= -79.0,
		"Real timeline navigation must complete its audio fade")

	change_scene_to_file("res://scenes/world/first_meeting_world.tscn")
	await process_frame
	await process_frame
	await create_timer(1.3).timeout
	check(current_scene.get_node("Memory/Zones/House/Ambience").playing
		and is_zero_approx(AudioServer.get_bus_volume_db(AudioServer.get_bus_index(&"Memory"))),
		"Re-entering First Meeting must restore the soundscape")
	check(is_equal_approx(mixer.get_level(&"Music"), 0.35), "Bus settings must survive scene changes")
	mixer.set_level(&"Music", original_music)
	current_scene.free()
	await create_timer(0.35).timeout
	print("Memory audio integration: ", "PASS" if failures == 0 else "FAIL")
	quit(failures)
