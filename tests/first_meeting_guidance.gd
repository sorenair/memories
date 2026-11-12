extends SceneTree
const Taps := preload("res://tests/shared/component_taps.gd")
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)
func resolve(node: Node) -> void:
	if node.has_method("get_recall_controller"):
		var effect: Node = node.get_recall_controller()
		if is_instance_valid(effect):
			effect.seek(1.0)
			effect.set_process(false)
	for child in node.get_children(true): resolve(child)
func touch(button: Control, pressed: bool) -> void:
	var event := InputEventScreenTouch.new()
	event.index = 1
	event.position = button._origin
	event.pressed = pressed
	button._input(event)
func guides_idle(memory: Node) -> bool:
	for guide in memory.find_children("*","FragmentBrushstrokeGuide",true,false):
		if guide.visible or guide.is_processing() or guide.is_playing(): return false
	return true
func clear_curve(world: Node3D, guide: FragmentBrushstrokeGuide, actor: CharacterBody3D) -> void:
	var shape := CapsuleShape3D.new()
	shape.height = 1.3
	shape.radius = 0.28
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.collision_mask = 1
	query.exclude = [actor.get_rid()]
	for i in 193:
		var p := guide.to_global(guide.sample_path(float(i)/192.0))
		p.y = 0.72
		query.transform = Transform3D(Basis.IDENTITY,p)
		check(world.get_world_3d().direct_space_state.intersect_shape(query,4).is_empty(), "The requested curve must clear fully recalled scenery at "+str(p))
func run() -> void:
	var world: Node3D = load("res://scenes/world/first_meeting_world.tscn").instantiate()
	root.add_child(world)
	await physics_frame
	await physics_frame
	resolve(world)
	await physics_frame
	var actor: MemoryExplorer = world.get_node("Explorer")
	var memory: MemoryScene = world.get_node("Memory")
	var house: MemoryFragment = world.get_node("Memory/Zones/House/Fragment")
	var arcade: MemoryFragment = world.get_node("Memory/Zones/Arcade/Fragment")
	var guidance: Node = world.get_node("GuidanceController")
	var controller: Node = world.get_node("InteractionController")
	var button: Control = world.get_node("Controls/InteractButton")
	var ui: Control = world.get_node("Controls/FragmentInteraction")
	var events := {"hints":0,"components":0}
	guidance.guidance_started.connect(func(_fragment: MemoryFragment): events.hints += 1)
	controller.interaction_performed.connect(func(_target: Node3D,_actor: Node3D): events.components += 1)
	check(guides_idle(memory) and guidance.active_guide == null, "No guidance may start on scene entry")
	check(button.available and guidance.get_next_fragment() == house, "The HUD must offer the first authored unfinished fragment")
	var launch := actor.global_position+Vector3.UP*0.72
	touch(button,true)
	touch(button,false)
	var first: FragmentBrushstrokeGuide = guidance.active_guide
	check(is_instance_valid(first) and first.is_playing() and events.hints == 1 and events.components == 0, "HUD touch must launch a hint without activating a nearby component")
	if not is_instance_valid(first): world.queue_free(); quit(failures+1); return
	first.set_process(false)
	check(first.to_global(first.sample_path(0)).is_equal_approx(launch), "A hint must begin at the current player position")
	check(first.to_global(first.sample_path(1)).is_equal_approx(house.to_global(Vector3.UP*house.float_height)), "The hint must end at the next fragment")
	check(first._materials[0].get_shader_parameter("single_pass") and is_zero_approx(first._materials[0].get_shader_parameter("pulse_interval")), "Each request must be a finite pass, never a periodic route")
	var mesh := first._ribbon.mesh
	actor.global_position.x += 0.4
	first._process(0.25)
	check(first.to_global(first.sample_path(0)).is_equal_approx(launch) and first._ribbon.mesh == mesh, "Walking must not drag the launch point or rebuild ribbon geometry")
	var clock := first._clock
	guidance._physics_process(5.0)
	touch(button,true)
	touch(button,false)
	check(not button.available and not guidance.request_guidance() and events.hints == 1, "HUD and direct requests must stay locked for the entire pass, regardless of elapsed cooldown time")
	check(guidance.active_guide == first and is_equal_approx(first._clock,clock), "Rejected requests must not restart or replace the active brushstroke")
	first._process(first.travel_duration+first.trail_duration+0.09-first._clock)
	guidance._physics_process(0.0)
	check(first.is_playing() and not button.available, "The action must stay locked until the stroke finishes fading at the fragment")
	first._process(0.02)
	guidance._physics_process(0.0)
	check(guides_idle(memory) and guidance.active_guide == null and button.available, "A completed hint must stop frame work and make guidance available again")
	touch(button,true)
	touch(button,false)
	check(events.hints == 2 and first.to_global(first.sample_path(0)).is_equal_approx(actor.global_position+Vector3.UP*0.72), "After completion, a new hint must snapshot the player's new position")
	first.set_process(false)
	first._process(first.travel_duration+first.trail_duration+0.2)
	guidance._physics_process(0.0)
	# The first unfinished fragment stays first even after exploring the arcade early.
	actor.global_position = Vector3(15.0,0.04,0.0)
	actor.reset_physics_interpolation()
	check(guidance.request_guidance() and guidance.active_destination == house, "Story order must win over physical proximity")
	var returning: FragmentBrushstrokeGuide = guidance.active_guide
	clear_curve(world,returning,actor)
	check(returning._route_length > actor.global_position.distance_to(house.global_position)+1.0, "A return hint must go around the fence rather than through the yard")
	returning.stop()
	guidance._physics_process(0.0)
	# Direct component taps retain the new interaction contract.
	house.notes = ["First page","Last page"]
	actor.global_position = house.global_position
	actor.reset_physics_interpolation()
	Taps.press(controller,house)
	Taps.release(controller)
	check(events.components == 1 and not ui.current_note.is_empty(), "The fragment itself must remain directly tappable")
	check(guidance.get_next_fragment() == house and not guidance.request_guidance(), "Reading must block hints without advancing story order")
	ui.advance_note()
	check(guidance.get_next_fragment() == house, "Intermediate pages must not finish the fragment")
	ui.advance_note()
	await create_timer(0.75).timeout
	check(guides_idle(memory) and guidance.get_next_fragment() == arcade, "Closing a note may enable the next destination, but may never spawn a hint")
	var key := InputEventKey.new()
	key.physical_keycode = KEY_E
	key.pressed = true
	button._unhandled_key_input(key)
	check(is_instance_valid(guidance.active_guide) and guidance.active_destination == arcade and events.components == 1, "E must send guidance, never interact with a component")
	var onward: FragmentBrushstrokeGuide = guidance.active_guide
	clear_curve(world,onward,actor)
	# Locks and reading stop an existing request; releasing a lock cannot restart it.
	actor.set_physics_process(false)
	guidance._physics_process(0.0)
	check(not onward.is_playing() and not guidance.request_guidance(), "Arrival/return locks must gate and cancel hints")
	actor.set_physics_process(true)
	guidance._physics_process(0.0)
	check(guides_idle(memory), "Unlocking input must not automatically start guidance")
	actor.global_position = arcade.global_position
	actor.reset_physics_interpolation()
	arcade.once_per_visit = false
	Taps.click(controller,arcade)
	check(guidance.get_next_fragment() == arcade and not guidance.request_guidance(), "The final popup must own input until it closes")
	ui.advance_note()
	await create_timer(0.75).timeout
	guidance._physics_process(0.0)
	check(not arcade.collected and guidance.get_next_fragment() == null and not button.available and not guidance.request_guidance(), "Even repeatable fragments must count as finished for per-visit guidance")
	check(guides_idle(memory), "All read fragments must leave the memory quiet")
	# Empty/removed fragments must also leave a safe disabled action.
	house.free()
	arcade.free()
	guidance.refresh_fragments()
	check(not button.available and not guidance.request_guidance(), "A memory without fragments must disable guidance")
	world.queue_free()
	await process_frame
	await process_frame
	await create_timer(0.35).timeout
	print("First Meeting manual guidance: ","PASS" if failures == 0 else "FAIL")
	quit(failures)
