extends SceneTree
var failures := 0
func _initialize() -> void:
	call_deferred("run")
func check(value: bool,message: String) -> void:
	if not value:
		failures+=1
		push_error(message)
func shot(path: String="") -> Image:
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
		if absi(int(x[i])-int(y[i]))+absi(int(x[i+1])-int(y[i+1]))+absi(int(x[i+2])-int(y[i+2]))>24:
			count+=1
	return count
func freeze_actor(stage: Node3D) -> void:
	var actor: MemoryExplorer=stage.get_node("Explorer")
	actor.set_physics_process(false)
	actor.physics_interpolation_mode=Node.PHYSICS_INTERPOLATION_MODE_OFF
	actor.animation_player.pause()
	actor.reset_physics_interpolation()
	stage.get_node("Controls").hide()
func run() -> void:
	root.content_scale_size=Vector2i(1600,1000)
	var study: Node3D=load("res://tests/scenes/tokyo_temples_test.tscn").instantiate()
	root.add_child(study)
	current_scene=study
	await process_frame
	await process_frame
	freeze_actor(study)
	var setup: Node3D=study.subject
	for name in ["MeijiTreeLeft","MeijiTreeRight"]:
		setup.get_node(name).wind_strength=0
		setup.get_node(name).react_to_explorers=false
	await create_timer(0.4).timeout
	await shot("res://docs/previews/tokyo-temples-overview.png")
	for name in ["SensoHall","HozomonGate","Pagoda"]:
		setup.get_node(name).hide()
	var camera: Camera3D=study.get_node("Camera3D")
	camera.size=12
	camera.position=Vector3(-2,8,15)
	camera.look_at(Vector3(-10,2.8,1.2))
	await shot("res://docs/previews/tokyo-meiji.png")
	setup.get_node("MeijiTorii").hide()
	camera.size=9.2
	camera.position=Vector3(-4,5.4,10)
	camera.look_at(Vector3(-10,2.7,1.6))
	study.get_node("Explorer").position=Vector3(-10,0.03,6.5)
	study.get_node("Explorer").reset_physics_interpolation()
	await shot("res://docs/previews/tokyo-meiji-hall.png")
	for name in ["MeijiHall","MeijiTreeLeft","MeijiTreeRight"]:
		setup.get_node(name).hide()
	setup.get_node("SensoHall").show()
	setup.get_node("Pagoda").show()
	camera.size=14.5
	camera.position=Vector3(22,11,18)
	camera.look_at(Vector3(11.5,4.8,1.9))
	setup.get_node("HozomonGate").hide()
	await shot("res://docs/previews/tokyo-sensoji.png")
	setup.get_node("HozomonGate").show()
	setup.get_node("SensoHall").hide()
	setup.get_node("Pagoda").hide()
	camera.size=10.5
	camera.position=Vector3(14,6.8,20)
	camera.look_at(Vector3(8,3.9,10))
	study.get_node("Explorer").position=Vector3(8,0.03,12)
	study.get_node("Explorer").reset_physics_interpolation()
	await shot("res://docs/previews/tokyo-hozomon.png")
	study.free()
	await process_frame
	study=load("res://tests/scenes/tokyo_city_test.tscn").instantiate()
	root.add_child(study)
	current_scene=study
	await process_frame
	await process_frame
	freeze_actor(study)
	setup=study.subject
	setup.get_node("Crowd")._material.set_shader_parameter("preview_time",0.0)
	for name in ["BackLeftTower","BackRightTower","SideLeftTower","SideRightTower","LowCornerTower"]:
		setup.get_node(name).seek_time(1.1)
	await create_timer(0.4).timeout
	await shot("res://docs/previews/tokyo-shibuya-overview.png")
	camera=study.get_node("Camera3D")
	camera.size=9
	camera.position=Vector3(7,9,15)
	camera.look_at(Vector3(0,1.2,0))
	var before := await shot("res://docs/previews/tokyo-shibuya-street.png")
	for name in ["BackLeftTower","BackRightTower","SideLeftTower","SideRightTower","LowCornerTower"]:
		setup.get_node(name).seek_time(4.3)
	var movement := changes(before,await shot())
	check(movement>300,"City billboards must visibly animate in the real Mobile renderer")
	for name in ["BackLeftTower","BackRightTower","SideLeftTower","SideRightTower","LowCornerTower"]:
		setup.get_node(name).screen_speed=0
	var frozen := await shot()
	for name in ["BackLeftTower","BackRightTower","SideLeftTower","SideRightTower","LowCornerTower"]:
		setup.get_node(name).seek_time(8.8)
	check(changes(frozen,await shot())<20,"Zero billboard speed must produce stable city frames")
	print("Tokyo Mobile render: ","PASS" if failures==0 else "FAIL"," | animated pixels: ",movement)
	study.free()
	await process_frame
	quit(failures)
