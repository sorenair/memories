extends SceneTree
const Taps := preload("res://tests/shared/component_taps.gd")
var failures := 0
var played: Array[StringName] = []

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)

func run() -> void:
	var world: Node3D = load("res://scenes/world/first_meeting_world.tscn").instantiate()
	root.add_child(world)
	await physics_frame
	await physics_frame
	var band: PainterlyMechanicalBand = world.get_node("Memory/Zones/Arcade/Scenery/Machines/MechanicalBand")
	var actor: Node3D = world.get_node("Explorer")
	var controller: Node = world.get_node("InteractionController")
	var outlines: Node = controller.get_node("Outlines")
	band.instrument_played.connect(func(id: StringName): played.append(id))
	check(not band.is_in_group(&"memory_interactables"), "The whole band must never be an interaction/outline target")
	check(not band.is_processing(), "The band must have no idle frame callback")
	for i in 4:
		var button := band.get_button(i)
		check(button.is_in_group(&"memory_interactables"), "Every individual cap must register with the controller")
		actor.global_position = Vector3(0.1, 0.04, 6.4)
		check(not button.try_activate(actor), "Buttons must reject actors at the house arrival")
		actor.global_position = band.to_global(Vector3(button.position.x, 0, 2.15)*band.prop_scale)
		actor.reset_physics_interpolation()
		controller.refresh_target()
		outlines._process(0.5)
		check(controller.target == button, "Walking along the console must select the corresponding cap: "+str(i))
		check(outlines._entries.size() == 1 and outlines._entries.has(button.get_instance_id()), "Only the selected cap must retain an outline")
		var entry: Dictionary = outlines._entries[button.get_instance_id()]
		check(entry.parts.size() == 1 and entry.parts[0].source.get_ref() == button.cap, "The cap alone must be outlined, excluding the console and instruments")
		check(is_equal_approx(entry.amount, 1.0), "The outline must smoothly reach full visibility")
		# Tap/click the actual instrument cap, not the reserved HUD circle.
		if i%2 == 0:
			Taps.press(controller, button)
			Taps.release(controller)
		else:
			Taps.click(controller, button)
		check(played.size() == i+1 and played[-1] == band.INSTRUMENTS[i], "The shared action must play the selected instrument exactly once")
		check(not button.try_activate(actor), "A mechanism must reject retriggering during its own short action")
		band.set_process(false)
		band._process(0.09)
		check(button.cap.position.y < -0.02, "The physical cap must depress when pressed")
		check(band._sounds[i].playing, "The strike must start actual audio playback")
		var part: Node3D = band._parts[[&"GuitarPick", &"KickBeater", &"SnareStick", &"PianoAction"][i]]
		check(not part.rotation.is_zero_approx() or not part.position.is_equal_approx(part.get_meta(&"rest_position")), "The associated mechanism must visibly move")
		check(band._sounds[i].stream == band.SOUNDS[i] and band.SOUNDS[i].get_length() > 0.25, "Every instrument must have its own valid audio clip")
		band._process(2.0)
		check(not band.is_processing() and button.cap.position.is_zero_approx(), "Completed actions must settle exactly and stop frame callbacks")
		check(part.rotation.is_zero_approx() and part.position.is_equal_approx(part.get_meta(&"rest_position")), "The mechanism must return to its authored rest pose")
		controller.refresh_target()
	# Overlap different instruments, but never stack duplicate animations.
	check(band.play_instrument(0) and band.play_instrument(3) and not band.play_instrument(0), "Independent instruments must support overlapping notes with bounded retriggers")
	band.rebuild()
	check(not band.is_processing() and not band._playing.has(true), "Regeneration must cancel old mechanisms and audio safely")
	actor.global_position = band.to_global(Vector3(0,0,-2))
	controller.refresh_target()
	outlines._process(0.5)
	var has_cap_outline := false
	for i in 4:
		has_cap_outline = has_cap_outline or outlines._entries.has(band.get_button(i).get_instance_id())
	check(not band.get_button(0).can_interact(actor) and not has_cap_outline,
		"Leaving the controls must remove every cap outline, even if the nearby arcade fragment is available")
	# Existing solid targets use the same feedback and exclude transparent score/shadows.
	var pinball: PainterlyPinball = world.get_node("Memory/Zones/Arcade/Scenery/Machines/Pinball")
	actor.global_position = pinball.get_anchor(&"Play").global_position
	actor.global_position.y = 0.04
	controller.refresh_target()
	outlines._process(0.07)
	var entry: Dictionary = outlines._entries[pinball.get_instance_id()]
	check(entry.amount > 0.0 and entry.amount < 1.0 and entry.parts.size() == 2, "Pinball must fade in with its cabinet and live ball, without screen/shadow cards")
	actor.set_physics_process(false)
	controller.refresh_target()
	outlines._process(0.5)
	check(outlines._entries.is_empty() and not outlines.is_processing(), "Movement/modal gates must fade all feedback and leave no idle callbacks")
	actor.set_physics_process(true)
	# Rebuild a selected target: the old weak references must not leave stale outlines.
	controller.refresh_target()
	pinball.rebuild()
	controller.refresh_target()
	outlines._process(0.5)
	check(outlines._entries[pinball.get_instance_id()].parts[0].source.get_ref() == pinball.get_node("Visual"), "Regeneration must refresh the proxy on the new geometry")
	# Transparent orbs use their own undulating contour, never a rectangular hull.
	var fragment: MemoryFragment = load("res://components/interactables/fragments/memory_fragment.tscn").instantiate()
	fragment.position = Vector3(100,0,100)
	world.add_child(fragment)
	actor.global_position = fragment.global_position + Vector3.RIGHT
	controller.refresh_target()
	outlines._process(0.5)
	var orb_entry: Dictionary = outlines._entries[fragment.get_instance_id()]
	check(orb_entry.custom and orb_entry.parts.is_empty() and is_equal_approx(fragment._material.get_shader_parameter("interaction_outline"),1.0), "Fragment feedback must follow the orb shader's contour")
	check(controller.request_interaction(fragment), "Outlined fragments must retain their existing note interaction")
	outlines._process(0.5)
	check(is_zero_approx(fragment._material.get_shader_parameter("interaction_outline")), "Opening a modal note must fade the fragment outline")
	world.free()
	# Allow several of the headless Dummy driver's larger buffers to release voices.
	await create_timer(0.35).timeout
	print("Band / interaction outline checks: ", "PASS" if failures == 0 else "FAIL")
	quit(failures)
