extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func snapshot() -> Image:
	await process_frame
	await RenderingServer.frame_post_draw
	return root.get_texture().get_image()
func changes(a: Image,b: Image) -> int:
	a.convert(Image.FORMAT_RGBA8)
	b.convert(Image.FORMAT_RGBA8)
	var first:=a.get_data()
	var second:=b.get_data()
	var total:=0
	for i in range(first.size()):
		if absi(int(first[i])-int(second[i]))>4: total+=1
	return total
func run() -> void:
	root.always_on_top=true
	root.content_scale_size=Vector2i(1400,900)
	var stage:=Node3D.new()
	root.add_child(stage)
	var environment:=WorldEnvironment.new()
	environment.environment=Environment.new()
	environment.environment.background_mode=Environment.BG_COLOR
	environment.environment.background_color=Color("efede3")
	stage.add_child(environment)
	var machine: PainterlyPunchingBag=load("res://components/activities/arcade/punching_bag/painterly_punching_bag.tscn").instantiate()
	stage.add_child(machine)
	var camera:=Camera3D.new()
	camera.physics_interpolation_mode=Node.PHYSICS_INTERPOLATION_MODE_OFF
	camera.projection=Camera3D.PROJECTION_ORTHOGONAL
	camera.size=3.2
	stage.add_child(camera)
	camera.position=Vector3(5,6.5,8)
	camera.look_at(Vector3(0,1.0,0.1))
	await create_timer(0.4).timeout
	var idle:=await snapshot()
	machine._random.seed=173
	machine.start_interaction()
	machine.set_process(false)
	machine._process(0.27)
	var impact:=await snapshot()
	impact.save_png("res://docs/punching-bag-impact.png")
	machine._bag.hide()
	var hidden:=await snapshot()
	machine._bag.show()
	machine._process(0.45)
	var returning:=await snapshot()
	machine._process(4.0)
	var finished:=await snapshot()
	finished.save_png("res://docs/punching-bag-interaction.png")
	var movement:=changes(idle,impact)
	var leather:=changes(impact,hidden)
	var swing:=changes(impact,returning)
	var score:=changes(idle,finished)
	print("Punch render | impact: ",movement," | visible leather: ",leather," | swing: ",swing," | final display: ",score," | strength: ",machine.last_score)
	stage.free()
	# Confirm the same controller-driven effect in the actual memory.
	root.content_scale_size=Vector2i(1400,646)
	var world: Node3D=load("res://scenes/world/first_meeting_world.tscn").instantiate()
	root.add_child(world)
	world.get_node("Controls/FPSLabel").hide()
	var bag: PainterlyPunchingBag=world.get_node("Memory/Environment/Arcade/PunchingBag")
	var player: Node3D=world.get_node("Explorer")
	player.global_position=bag.get_anchor(&"Punch").global_position
	player.global_position.y=0.05
	player.reset_physics_interpolation()
	var rig: Node3D=world.get_node("CameraRig")
	rig.set_process(false)
	rig.global_position=player.global_position
	await create_timer(0.5).timeout
	bag._random.seed=173
	var controller: Node=world.get_node("InteractionController")
	var accepted: bool=controller.request_interaction(bag)
	bag.set_process(false)
	bag._process(0.27)
	await create_timer(0.25).timeout
	var in_memory:=await snapshot()
	in_memory.save_png("res://docs/punching-bag-memory.png")
	world.free()
	quit(0 if movement>500 and leather>500 and swing>500 and score>100 and accepted else 1)
