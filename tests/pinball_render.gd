extends SceneTree
## Render the callable interaction without wiring any game input.
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
func advance_to(machine: PainterlyPinball, seconds: float) -> void:
	while machine.is_playing() and machine._simulation.elapsed<seconds-0.000001:
		machine._process(minf(1.0/120.0,seconds-machine._simulation.elapsed))
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
	var machine: PainterlyPinball=load("res://components/activities/arcade/pinball/painterly_pinball.tscn").instantiate()
	stage.add_child(machine)
	var camera:=Camera3D.new()
	camera.physics_interpolation_mode=Node.PHYSICS_INTERPOLATION_MODE_OFF
	camera.projection=Camera3D.PROJECTION_ORTHOGONAL
	camera.size=1.8
	stage.add_child(camera)
	camera.position=Vector3(3.5,5.2,7)
	camera.look_at(Vector3(0,1.1,-0.02))
	machine._random.seed=173
	machine.start_interaction()
	# Freeze real-time advancement between deterministic captured samples.
	machine.set_process(false)
	await create_timer(0.3).timeout
	var first:=await snapshot()
	first.save_png("/tmp/pinball-launch.png")
	advance_to(machine,0.42)
	var upper:=await snapshot()
	upper.save_png("/tmp/pinball-upper.png")
	advance_to(machine,0.85)
	var bounce:=await snapshot()
	bounce.save_png("/tmp/pinball-bounce.png")
	machine.get_node("Ball").hide()
	var hidden:=await snapshot()
	machine.get_node("Ball").show()
	advance_to(machine,8.0)
	var score:=await snapshot()
	score.save_png("/tmp/pinball-score-close.png")
	camera.size=3.0
	camera.look_at(Vector3(0,0.9,0))
	var full:=await snapshot()
	full.save_png("res://docs/previews/pinball-interaction.png")
	var motion:=changes(first,upper)
	var visible:=changes(bounce,hidden)
	var scoring:=changes(bounce,score)
	print("Pinball render | launch movement: ",motion," | visible ball: ",visible," | score changes: ",scoring," | awarded: ",machine.last_score)
	quit(0 if motion>25 and visible>25 and scoring>50 and not machine.is_playing() else 1)
