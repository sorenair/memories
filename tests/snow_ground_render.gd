extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func snapshot() -> Image:
	await RenderingServer.frame_post_draw
	var result:=root.get_texture().get_image()
	result.resize(400,300)
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
	root.content_scale_size=Vector2i(1000,750)
	var scene:=Node3D.new()
	root.add_child(scene)
	var env:=WorldEnvironment.new()
	env.environment=Environment.new()
	env.environment.background_mode=Environment.BG_COLOR
	env.environment.background_color=Color(0.94,0.935,0.89)
	scene.add_child(env)
	var patch: PainterlySnowPatch=load("res://components/groundcover/snow/painterly_snow_patch.tscn").instantiate()
	var custom := "--outline" in OS.get_cmdline_user_args()
	var offset := Vector3(3,0,2) if custom else Vector3.ZERO
	if custom:
		var outline := Curve2D.new()
		for point in [Vector2(-2.6,-1.8),Vector2(2.6,-1.8),Vector2(2.6,0.4),Vector2(0.5,0.4),Vector2(0.5,1.8),Vector2(-2.6,1.8)]:
			outline.add_point(point+Vector2(offset.x,offset.z))
		patch.custom_outline=outline
	patch.track_footprints=false
	patch.footprint_linger=0.6
	patch.footprint_fade_duration=0.5
	scene.add_child(patch)
	var camera:=Camera3D.new()
	camera.projection=Camera3D.PROJECTION_ORTHOGONAL
	camera.size=6.0
	scene.add_child(camera)
	camera.position=Vector3(5,7,6)+offset
	camera.look_at(offset)
	await create_timer(0.2).timeout
	var blank: Image=await snapshot()
	for index in range(7):
		patch.stamp_footprint(offset+Vector3(-1.2+index*0.38,0,0.1 if index%2==0 else -0.1),Vector3.RIGHT)
	patch._flush_field()
	var stamped: Image=await snapshot()
	await create_timer(0.3).timeout
	var lingering: Image=await snapshot()
	await create_timer(1.0).timeout
	var faded: Image=await snapshot()
	patch._clock=300.0
	patch.stamp_footprint(offset,Vector3.RIGHT)
	patch._flush_field()
	await physics_frame
	var late: Image=await snapshot()
	var visible:=changes(blank,stamped)
	var hold:=changes(stamped,lingering)
	var restored:=changes(blank,faded)
	var late_visible:=changes(blank,late)
	print("Snow ground render (", "outline" if custom else "oval", ") | prints: ",visible," | linger change: ",hold," | after fade: ",restored," | late timestamp: ",late_visible)
	quit(0 if visible>200 and hold==0 and restored==0 and late_visible>30 else 1)
