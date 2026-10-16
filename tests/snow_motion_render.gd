extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func snapshot() -> Image:
	await RenderingServer.frame_post_draw
	var result:=root.get_texture().get_image()
	result.resize(400,400)
	return result
func changes(a: Image,b: Image) -> int:
	var x:=a.get_data()
	var y:=b.get_data()
	var count:=0
	for index in range(x.size()):
		if absi(int(x[index])-int(y[index]))>3:count+=1
	return count
func run() -> void:
	root.always_on_top=true
	root.content_scale_size=Vector2i(800,800)
	var scene:=Node3D.new()
	root.add_child(scene)
	var env:=WorldEnvironment.new()
	env.environment=Environment.new()
	env.environment.background_mode=Environment.BG_COLOR
	env.environment.background_color=Color("526760")
	scene.add_child(env)
	var snow: PainterlySnow=load("res://components/weather/snow/painterly_snow.tscn").instantiate()
	snow.footprint=Vector2(8,8)
	snow.snow_height=5.0
	snow.flake_count=300
	snow.fall_speed=0.0
	scene.add_child(snow)
	var camera:=Camera3D.new()
	camera.projection=Camera3D.PROJECTION_ORTHOGONAL
	camera.size=9.0
	scene.add_child(camera)
	camera.position=Vector3(8,10,8)
	camera.look_at(Vector3(0,1,0))
	await create_timer(0.3).timeout
	var a: Image=await snapshot()
	await create_timer(0.4).timeout
	var b: Image=await snapshot()
	snow.fall_speed=0.65
	await create_timer(0.1).timeout
	var c: Image=await snapshot()
	await create_timer(0.7).timeout
	var d: Image=await snapshot()
	snow.intensity=0.0
	var hidden_a: Image=await snapshot()
	await create_timer(0.3).timeout
	var hidden_b: Image=await snapshot()
	print("Snow render | frozen: ",changes(a,b)," | motion: ",changes(c,d)," | visible: ",changes(d,hidden_a)," | disabled: ",changes(hidden_a,hidden_b))
	quit(0 if changes(a,b)==0 and changes(c,d)>100 and changes(d,hidden_a)>100 and changes(hidden_a,hidden_b)==0 else 1)
