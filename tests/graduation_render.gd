extends SceneTree
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(value: bool,message: String) -> void:
	if not value:
		failures+=1
		push_error(message)

func snapshot(path: String="") -> Image:
	await process_frame
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	if not path.is_empty():
		img.save_png(path)
	return img

func changes(a: Image,b: Image) -> int:
	var x := a.get_data()
	var y := b.get_data()
	var count := 0
	for i in range(0,x.size(),4):
		if absi(int(x[i])-int(y[i]))+absi(int(x[i+1])-int(y[i+1]))+absi(int(x[i+2])-int(y[i+2]))>18:
			count+=1
	return count

func run() -> void:
	root.content_scale_size=Vector2i(1600,1000)
	var study: Node3D=load("res://tests/scenes/graduation_test.tscn").instantiate()
	root.add_child(study)
	current_scene=study
	await process_frame
	await process_frame
	var setup: Node3D=study.subject
	var actor: MemoryExplorer=study.get_node("Explorer")
	actor.set_physics_process(false)
	actor.physics_interpolation_mode=Node.PHYSICS_INTERPOLATION_MODE_OFF
	actor.animation_player.pause()
	actor.reset_physics_interpolation()
	for name in ["SeatedGraduates","Presenter","WaitingGraduates"]:
		setup.get_node(name)._material.set_shader_parameter("preview_time",0.0)
	for name in ["FrontFlowersLeft","FrontFlowersRight","BackFlowersLeft","BackFlowersRight"]:
		setup.get_node(name).wind_strength=0
		setup.get_node(name).react_to_explorers=false
	var deck: PainterlyCommencementStage=setup.get_node("CommencementStage")
	deck.seek_time(0)
	study.get_node("Controls").hide()
	await create_timer(0.5).timeout
	await snapshot("res://docs/previews/graduation-overview.png")
	var camera: Camera3D=study.get_node("Camera3D")
	camera.size=7.6
	camera.position=Vector3(8,7,10)
	camera.look_at(Vector3(0,1.7,-0.2))
	var first := await snapshot("res://docs/previews/graduation-stage.png")
	deck.seek_time(3.2)
	var moving := changes(first,await snapshot())
	check(moving>40,"Ceremony banners must visibly move in the actual Mobile renderer")
	deck.banner_wind=0
	var frozen := await snapshot()
	deck.seek_time(11)
	check(changes(frozen,await snapshot())<15,"Zero banner wind must hold a stable frame")
	camera.size=4.1
	camera.position=Vector3(6,4.5,1.6)
	camera.look_at(Vector3(1.85,0.83,4.8))
	actor.global_position=Vector3(0.25,0.02,4.6)
	actor.reset_physics_interpolation()
	var people: PainterlyGraduateCrowd=setup.get_node("SeatedGraduates")
	var seated := await snapshot("res://docs/previews/graduation-graduates.png")
	people._material.set_shader_parameter("preview_time",3.3)
	check(changes(seated,await snapshot())>40,"Seated graduates must retain subtle independent idle motion")
	people.motion_strength=0
	var still := await snapshot()
	people._material.set_shader_parameter("preview_time",8.1)
	check(changes(still,await snapshot())<15,"Zero graduate motion must hold the seated poses still")
	camera.size=3.4
	camera.position=Vector3(5,4.0,5)
	camera.look_at(Vector3(0.6,1.1,-0.1))
	await snapshot("res://docs/previews/graduation-details.png")
	print("Graduation Mobile render: ","PASS" if failures==0 else "FAIL"," | banner pixels: ",moving)
	study.free()
	await process_frame
	quit(failures)
