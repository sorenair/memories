extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func snapshot() -> Image:
	await RenderingServer.frame_post_draw
	var result:=root.get_texture().get_image()
	result.resize(300,300)
	return result
func changes(a: Image,b: Image) -> int:
	var first:=a.get_data()
	var second:=b.get_data()
	var count:=0
	for index in range(first.size()):
		if absi(int(first[index])-int(second[index]))>3:count+=1
	return count
func run() -> void:
	root.content_scale_size=Vector2i(800,800)
	var scene:=Node3D.new()
	root.add_child(scene)
	var env:=WorldEnvironment.new()
	env.environment=Environment.new()
	env.environment.background_mode=Environment.BG_COLOR
	env.environment.background_color=Color("261c29")
	scene.add_child(env)
	var fire: PainterlyFire=load("res://components/vfx/fire/painterly_fire.tscn").instantiate()
	fire.animation_speed=0.0
	scene.add_child(fire)
	var camera:=Camera3D.new()
	camera.projection=Camera3D.PROJECTION_ORTHOGONAL
	camera.size=3.5
	scene.add_child(camera)
	camera.position=Vector3(4,2.4,5)
	camera.look_at(Vector3(0,1.2,0))
	await create_timer(0.3).timeout
	var a: Image=await snapshot()
	await create_timer(0.4).timeout
	var b: Image=await snapshot()
	fire.animation_speed=1.0
	await create_timer(0.1).timeout
	var c: Image=await snapshot()
	await create_timer(0.5).timeout
	var d: Image=await snapshot()
	fire.animation_speed=0.0
	camera.position=Vector3(-5,3,4)
	camera.look_at(Vector3(0,1.2,0))
	var angle: Image=await snapshot()
	fire.intensity=0.0
	var empty: Image=await snapshot()
	print("Fire render | frozen: ",changes(a,b)," | motion: ",changes(c,d)," | side visibility: ",changes(angle,empty))
	quit(0 if changes(a,b)==0 and changes(c,d)>500 and changes(angle,empty)>1000 else 1)
