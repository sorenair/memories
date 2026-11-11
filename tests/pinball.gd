extends SceneTree
const SIMULATION = preload("res://components/activities/arcade/pinball/pinball_simulation.gd")
const LAYOUT = preload("res://components/activities/arcade/pinball/pinball_layout.gd")
var failures := 0
var awards: Array[int] = []
var starts := 0
var cancellations := 0
func _initialize() -> void:
	call_deferred("run")
func check(value: bool, message: String) -> void:
	if not value:
		push_error(message)
		failures += 1
func finish_run(machine: PainterlyPinball, delta: float = 1.0/60.0) -> void:
	for i in range(1500):
		if not machine.is_playing(): break
		machine._process(delta)
		if not machine._simulation.contains_ball(machine._simulation.position):
			check(false,"Animated ball must stay on the playfield, outside bumpers, guides, posts, slings, and flippers")
			break
	check(not machine.is_playing(),"Every interaction must finish within its bounded duration")
func run() -> void:
	var steps := [1.0/30.0,1.0/60.0,1.0/144.0,0.17]
	var speeds := [1.8,2.4,3.0]
	var hits := 0
	var runs := 0
	# Swept collisions must remain safe at ordinary and deliberately coarse frames.
	for seed_value in range(24):
		var sim: RefCounted = SIMULATION.new()
		sim.launch(seed_value,5.0,speeds[seed_value%3])
		var dt: float = steps[seed_value%4]
		var valid: bool = sim.contains_ball(sim.position)
		for i in range(1500):
			if not sim.running: break
			sim.advance(dt)
			valid = valid and sim.contains_ball(sim.position) and sim.position.is_finite()
		check(valid,"Collision containment must hold for seed "+str(seed_value)+" at frame delta "+str(dt))
		check(sim.reached_top,"A launch must travel from the lower chute into the upper field")
		check(not sim.running and sim.elapsed<=5.001,"Simulation must terminate safely")
		hits += sim.bumper_hits
		runs += 1
	check(hits>=runs,"Runs must visibly ricochet through the bumper field")
	# The decorative overhead orbit clears the actual sphere in three dimensions.
	check(0.055/sqrt(1.0+0.214*0.214)>2.0*LAYOUT.BALL_RADIUS+0.011,"The ball must fit below the raised orbit wire without intersecting it")
	var machine: PainterlyPinball=load("res://components/activities/arcade/pinball/painterly_pinball.tscn").instantiate()
	root.add_child(machine)
	machine.score_awarded.connect(func(score: int): awards.append(score))
	machine.interaction_started.connect(func(): starts+=1)
	machine.interaction_cancelled.connect(func(): cancellations+=1)
	check(not machine.is_playing() and not machine.is_processing(),"Loading a machine must not start an interaction or enable idle frame work")
	check(machine.is_in_group(&"memory_interactables"),"Runtime machines must register with the shared interaction controller")
	check(machine.get_node("Ball").physics_interpolation_mode==Node.PHYSICS_INTERPOLATION_MODE_OFF,"Render-frame ball motion must avoid double interpolation")
	var cabinet_mesh: Mesh=machine.get_node("Visual").mesh
	var ball_mesh: Mesh=machine.get_node("Ball").mesh
	check(machine.get_node("Ball").position.is_equal_approx(LAYOUT.ball_center(LAYOUT.HOME)),"Idle ball must sit in the bottom launch chute")
	machine.score_range=Vector2i(700,900)
	check(machine.start_interaction(),"A direct placeholder request must start a run")
	check(not machine.start_interaction() and starts==1,"Repeated requests during a run must not duplicate launches")
	finish_run(machine)
	check(awards.size()==1 and machine.last_score in range(700,901),"Completion must award exactly one score in the configured range")
	check(machine._score_material.get_shader_parameter("score")==machine.last_score,"The live cabinet display must show the awarded score")
	check(not machine.is_processing(),"Finishing must turn off frame callbacks")
	for i in range(6):
		machine.interaction_requested.emit()
		finish_run(machine,1.0/144.0)
	check(awards.size()==7 and starts==7,"The request signal must support repeatable, independent interactions")
	var unique := {}
	for score in awards: unique[score]=true
	check(unique.size()>1,"Repeated plays must generate varied random scores")
	check(machine.get_node("Visual").mesh==cabinet_mesh and machine.get_node("Ball").mesh==ball_mesh,"Playing and updating scores must not rebuild meshes")
	machine.prop_scale=1.35
	machine.position=Vector3(7,0,-3)
	machine.rotation.y=0.7
	machine.rebuild()
	machine.start_interaction()
	machine._process(0.3)
	var expected: Vector3=LAYOUT.ball_center(machine._simulation.position)*machine.prop_scale
	check(machine.get_node("Ball").position.is_equal_approx(expected),"Ball motion must follow the component's authored scale")
	check(machine.get_anchor(&"Ball").global_position.is_equal_approx(machine.get_node("Ball").global_position),"The Ball anchor must follow the moving ball after scaling and rotation")
	var count := awards.size()
	machine.rebuild()
	check(not machine.is_playing() and not machine.is_processing() and cancellations==1 and awards.size()==count,"Editing during play must cancel safely without awarding a second score")
	check(machine.start_interaction(),"A regenerated machine must remain playable")
	finish_run(machine)
	var scene:=PackedScene.new()
	machine.interaction_range=1.8
	machine.play_duration=3.2
	machine.launch_speed=2.1
	check(scene.pack(machine)==OK,"Interaction controls must save")
	var restored: PainterlyPinball=scene.instantiate()
	root.add_child(restored)
	check(is_equal_approx(restored.play_duration,3.2) and is_equal_approx(restored.launch_speed,2.1) and restored.score_range==machine.score_range and is_equal_approx(restored.interaction_range,1.8),"Exported controls must survive serialization")
	check(not restored.is_playing() and not restored.is_processing(),"Restored scenes must begin idle")
	restored.free()
	machine.free()
	print("Pinball interaction checks: ","PASS" if failures==0 else "FAIL"," | simulated runs: ",runs," | bumper hits: ",hits)
	quit(failures)
