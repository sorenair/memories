extends SceneTree
var failures := 0
var awards: Array[int] = []
var cancellations := 0
func _initialize() -> void:
	call_deferred("run")
func check(value: bool, message: String) -> void:
	if not value:
		failures+=1
		push_error(message)
func finish_run(machine: PainterlyPunchingBag, delta: float = 1.0/60.0) -> void:
	for i in range(1000):
		if not machine.is_playing(): break
		machine._process(delta)
	check(not machine.is_playing(),"A punch must complete within its configured duration")
func run() -> void:
	var machine: PainterlyPunchingBag=load("res://components/activities/arcade/punching_bag/painterly_punching_bag.tscn").instantiate()
	root.add_child(machine)
	machine.score_awarded.connect(func(score: int): awards.append(score))
	machine.interaction_cancelled.connect(func(): cancellations+=1)
	check(machine.is_in_group(&"memory_interactables") and not machine.is_processing() and not machine.is_playing(),"A loaded bag must register with the controller while remaining idle")
	check(machine._pivot.physics_interpolation_mode==Node.PHYSICS_INTERPOLATION_MODE_OFF,"Render-frame bag motion must avoid double interpolation")
	check(machine._score_material.get_shader_parameter("digit_count")==3,"Strength display must use three digits")
	var body: Mesh=machine.get_node("Visual").mesh
	var leather: Mesh=machine._bag.mesh
	check(body.get_faces().size()/3+leather.get_faces().size()/3<3500,"Cabinet and leather must retain a small combined geometry budget")
	machine.score_range=Vector2i(600,650)
	check(machine.start_interaction() and not machine.start_interaction(),"Only one punch may start at a time")
	machine._process(0.09)
	check(machine._pivot.rotation.length()>0.001 and not machine._impact.visible,"Anticipation should precede the impact")
	machine._process(0.17)
	check(machine._impact.visible and machine._bag.scale.y<1.0,"Impact must briefly produce painted feedback and squash the leather")
	check(machine._pivot.rotation.length()>0.05,"A hit must visibly deflect the bag")
	finish_run(machine)
	check(awards.size()==1 and machine.last_score>=600 and machine.last_score<=650,"A completed punch must award exactly one score in range")
	check(machine._pivot.rotation.is_equal_approx(Vector3.ZERO) and machine._bag.scale.is_equal_approx(Vector3.ONE) and not machine._impact.visible,"Completion must restore the resting shape and hide transient feedback")
	check(not machine.is_processing() and machine._score_material.get_shader_parameter("score")==machine.last_score,"Completion must stop frame work and retain the displayed result")
	for i in range(5):
		machine.interaction_requested.emit()
		finish_run(machine,1.0/144.0)
	check(awards.size()==6,"Repeated signal requests must produce independent completed punches")
	var unique := {}
	for score in awards: unique[score]=true
	check(unique.size()>1,"Strength results should vary between punches")
	check(machine.get_node("Visual").mesh==body and machine._bag.mesh==leather,"Punching and scoring must not rebuild geometry")
	# The animated leather must clear the actual cabinet column and overhead hood.
	var vertices: PackedVector3Array=leather.get_faces()
	var clear := true
	for direction in [-1.0,1.0]:
		machine.start_interaction()
		machine._direction=direction
		machine._amplitude=deg_to_rad(35.0)
		for frame in range(200):
			if not machine.is_playing(): break
			machine._process(1.0/60.0)
			var transform: Transform3D=machine._pivot.transform*machine._bag.transform
			for vertex in vertices:
				var point: Vector3=transform*vertex
				if not point.is_finite() or absf(point.x)>0.49 or point.y>1.66 or point.z< -0.065 or point.z>0.73:
					clear=false
		check(not machine.is_playing(),"Maximum-angle runs must finish")
	check(clear,"Leather must remain clear of the column and hood throughout maximum swings in both directions")
	machine._random.seed=421
	machine.start_interaction()
	machine._process(0.48)
	var single: Vector3=machine._pivot.rotation
	machine.rebuild()
	machine._random.seed=421
	machine.start_interaction()
	for i in range(24): machine._process(0.02)
	check(machine._pivot.rotation.is_equal_approx(single),"Swing pose must be independent of render-frame partitioning")
	var before:=awards.size()
	var cancelled:=cancellations
	machine.rebuild()
	check(not machine.is_playing() and not machine.is_processing() and awards.size()==before and cancellations==cancelled+1,"Regeneration during a punch must cancel safely without awarding points")
	machine.prop_scale=1.3
	machine.rotation.y=0.7
	machine.rebuild()
	check(machine._pivot.position.is_equal_approx(machine.PIVOT*1.3) and machine._pivot.scale.is_equal_approx(Vector3.ONE*1.3),"Bag pivot and motion must follow authored size")
	machine.start_interaction()
	finish_run(machine,0.25)
	machine.interaction_range=1.8
	machine.swing_duration=3.2
	machine.swing_angle=31
	var packed:=PackedScene.new()
	check(packed.pack(machine)==OK,"Interactive component must save")
	var restored: PainterlyPunchingBag=packed.instantiate()
	root.add_child(restored)
	check(is_equal_approx(restored.interaction_range,1.8) and is_equal_approx(restored.swing_duration,3.2) and is_equal_approx(restored.swing_angle,31) and restored.score_range==machine.score_range,"Interaction settings must survive saving/reloading")
	check(not restored.is_playing() and not restored.is_processing(),"Saved scenes must reload idle")
	restored.free()
	machine.free()
	print("Punching bag checks: ","PASS" if failures==0 else "FAIL")
	quit(failures)
