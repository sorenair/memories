extends SceneTree
const Taps := preload("res://tests/shared/component_taps.gd")
var failures := 0
var results: Array[int] = []
func _initialize() -> void:
	call_deferred("run")
func check(value: bool, message: String) -> void:
	if not value:
		failures+=1
		push_error(message)
func finish_run(machine: PainterlyPunchingBag) -> void:
	for i in range(500):
		if not machine.is_playing(): break
		machine._process(1.0/60.0)
	check(not machine.is_playing(),"PunchingBag run must finish")
func run() -> void:
	var world: Node3D=load("res://scenes/world/first_meeting_world.tscn").instantiate()
	root.add_child(world)
	current_scene=world
	await physics_frame
	await physics_frame
	var player: MemoryExplorer=world.get_node("Explorer")
	var controller: Node=world.get_node("InteractionController")
	var guidance: Node=world.get_node("GuidanceController")
	var button: Control=world.get_node("Controls/InteractButton")
	var house: MemoryFragment=world.get_node("Memory/Zones/House/Fragment")
	var machine: PainterlyPunchingBag=world.get_node("Memory/Zones/Arcade/Scenery/Machines/PunchingBag")
	var events: Dictionary={"requested":0,"performed":0,"started":0}
	controller.interaction_requested.connect(func(_target: Node3D,_actor: Node3D): events.requested+=1)
	controller.interaction_performed.connect(func(_target: Node3D,_actor: Node3D): events.performed+=1)
	machine.interaction_started.connect(func(): events.started+=1)
	machine.score_awarded.connect(func(score: int): results.append(score))
	check(controller.actor==player and button.input_gate==controller,"The inherited controller and button must use the current local explorer")
	check(machine.is_in_group(&"memory_interactables"),"The actual memory punching bag must register as an interactable")
	controller.refresh_target()
	check(not controller.is_available(machine) and not controller.request_interaction(machine),"The house arrival must be too far away to punch the bag")
	check(not machine.try_activate(player),"Direct activation must also enforce range")
	var front:=machine.get_anchor(&"Punch").position
	front.y=0
	var approach:=machine.to_global(front)
	player.global_position=approach
	player.reset_physics_interpolation()
	controller.refresh_target()
	button._process(0.5)
	check(controller.is_available(machine) and button.available and button._activity>0.99 and guidance.get_next_fragment()==house,"Approaching the punching bag must leave guidance available for the unfinished house fragment")
	player.global_position=machine.to_global(Vector3(0,0,-1.8*machine.prop_scale))
	controller.refresh_target()
	check(not controller.is_available(machine),"Standing behind the cabinet must not count as approaching the front controls")
	player.global_position=approach
	controller.refresh_target()
	Taps.press(controller,machine)
	player.global_position=approach+Vector3(5,0,0)
	Taps.release(controller)
	check(not machine.is_playing() and events.started==0,"Walking out of range while holding the action must cancel the launch")
	player.global_position=approach
	machine.hide()
	controller.refresh_target()
	check(not controller.is_available(machine) and not machine.try_activate(player),"Hidden machines must be unavailable")
	machine.show()
	player.set_physics_process(false)
	controller.refresh_target()
	check(not controller.is_available(machine) and not controller.request_interaction(machine),"Arrival/return movement locks must block machine")
	player.set_physics_process(true)
	controller.refresh_target()
	Taps.press(controller,machine)
	Taps.release(controller)
	check(machine.is_playing() and events.requested==1 and events.performed==1 and events.started==1,"A touch must go through the shared controller and start exactly one real machine run")
	check(not controller.is_available(machine),"The active machine must immediately become unavailable")
	button._process(0.5)
	check(button.available and button._activity>0.99 and guidance.get_next_fragment()==house,"A busy machine must not disable guidance to an unfinished fragment")
	check(not controller.request_interaction(machine) and not machine.try_activate(player),"Busy machines must reject repeated controller and direct requests")
	finish_run(machine)
	check(results.size()==1 and results[0]==machine.last_score,"The component tap must award exactly one real result")
	controller.refresh_target()
	button._process(0.5)
	check(controller.is_available(machine) and button.available and button._activity>0.99 and guidance.get_next_fragment()==house,"Completing the punching bag must restore component tapping while guidance remains independently available")
	Taps.click(controller,machine)
	check(machine.is_playing() and events.started==2 and events.performed==2,"Clicking the component must use the same gated controller path")
	finish_run(machine)
	check(results.size()==2,"Touch and mouse runs must both finish normally")
	machine.interaction_range=0.6
	player.global_position=approach+Vector3(0.8,0,0)
	controller.refresh_target()
	check(not controller.is_available(machine),"Changing the exported range must affect target availability")
	player.global_position=approach+Vector3(0.3,0,0)
	controller.refresh_target()
	check(controller.is_available(machine),"The configured range must be measured in world space from the scaled/rotated front approach")
	world.free()
	# Let the audio driver's pending buffers release the final result cue.
	await create_timer(0.35).timeout
	print("PunchingBag shared interaction: ","PASS" if failures==0 else "FAIL")
	quit(failures)
