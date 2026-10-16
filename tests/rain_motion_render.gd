extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func snapshot() -> Image:
	await RenderingServer.frame_post_draw
	var frame:=root.get_texture().get_image()
	frame.resize(400,400)
	return frame
func changes(a: Image,b: Image) -> int:
	var first:=a.get_data()
	var second:=b.get_data()
	var result:=0
	for index in range(first.size()):
		if absi(int(first[index])-int(second[index]))>3:
			result+=1
	return result
func run() -> void:
	root.content_scale_size=Vector2i(800,800)
	var scene:=Node3D.new()
	root.add_child(scene)
	var environment:=WorldEnvironment.new()
	environment.environment=Environment.new()
	environment.environment.background_mode=Environment.BG_COLOR
	environment.environment.background_color=Color("526760")
	scene.add_child(environment)
	var rain: PainterlyRain=load("res://components/weather/rain/painterly_rain.tscn").instantiate()
	rain.footprint=Vector2(8,8)
	rain.rain_height=5.0
	rain.drop_count=300
	rain.splash_count=70
	rain.fall_speed=0.0
	scene.add_child(rain)
	var camera:=Camera3D.new()
	camera.projection=Camera3D.PROJECTION_ORTHOGONAL
	camera.size=9.0
	scene.add_child(camera)
	camera.position=Vector3(8,10,8)
	camera.look_at(Vector3(0,1,0))
	await create_timer(0.3).timeout
	var still_a: Image=await snapshot()
	await create_timer(0.4).timeout
	var still_b: Image=await snapshot()
	rain.fall_speed=8.0
	await create_timer(0.1).timeout
	var moving_a: Image=await snapshot()
	await create_timer(0.4).timeout
	var moving_b: Image=await snapshot()
	rain._streaks.hide()
	await process_frame
	var splash_a: Image=await snapshot()
	await create_timer(0.3).timeout
	var splash_b: Image=await snapshot()
	rain.intensity=0.0
	var hidden_a: Image=await snapshot()
	await create_timer(0.3).timeout
	var hidden_b: Image=await snapshot()
	var still:=changes(still_a,still_b)
	var motion:=changes(moving_a,moving_b)
	var splash:=changes(splash_a,splash_b)
	var hidden:=changes(hidden_a,hidden_b)
	print("Rain render | frozen: ",still," | animated: ",motion," | impacts: ",splash," | disabled: ",hidden)
	quit(0 if still==0 and motion>100 and splash>100 and hidden==0 else 1)
