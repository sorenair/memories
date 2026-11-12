extends SceneTree
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func snapshot(path: String = "") -> Image:
	await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	if not path.is_empty(): image.save_png(path)
	return image

func changed_pixels(a: Image, b: Image) -> int:
	var count := 0
	for y in a.get_height():
		for x in a.get_width():
			var first := a.get_pixel(x,y)
			var second := b.get_pixel(x,y)
			if absf(first.r-second.r)+absf(first.g-second.g)+absf(first.b-second.b) > 0.12: count += 1
	return count

func run() -> void:
	root.always_on_top = true
	root.content_scale_size = Vector2i(1400,900)
	var stage := Node3D.new()
	root.add_child(stage)
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color("d9d9d2")
	stage.add_child(environment)
	var band: PainterlyMechanicalBand = load("res://components/activities/arcade/mechanical_band/painterly_mechanical_band.tscn").instantiate()
	stage.add_child(band)
	var actor := Node3D.new()
	stage.add_child(actor)
	actor.set_physics_process(true)
	var controller: Node = load("res://scripts/interaction/interaction_controller.gd").new()
	controller.actor = actor
	stage.add_child(controller)
	controller.set_physics_process(false)
	var camera := Camera3D.new()
	camera.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 4.3
	stage.add_child(camera)
	camera.position = Vector3(4,5.5,8)
	camera.look_at(Vector3(0,1.0,0.35))
	actor.position = Vector3(0,0,10)
	await create_timer(0.4).timeout
	var idle := await snapshot()
	actor.position = Vector3(band.get_button(0).position.x,0,2.15)
	controller.refresh_target()
	controller._outlines._process(0.5)
	var outlined := await snapshot("res://docs/previews/mechanical-band-outline.png")
	var outline_change := changed_pixels(idle,outlined)
	if outline_change < 40 or outline_change > 3000: failures += 1
	print("Band selected cap changed pixels: ",outline_change)
	controller.request_interaction(band.get_button(0))
	for i in range(1,4): band.play_instrument(i)
	band.set_process(false)
	band._process(0.075)
	var struck := await snapshot("res://docs/previews/mechanical-band-playing.png")
	var animation_change := changed_pixels(outlined,struck)
	if animation_change < 200: failures += 1
	print("Band moving mechanism changed pixels: ",animation_change)
	band._process(2.0)
	# Exercise the actual audio mixer, not only stream assignment.
	var capture := AudioEffectCapture.new()
	AudioServer.add_bus_effect(0, capture)
	var capture_index := AudioServer.get_bus_effect_count(0)-1
	for i in 4:
		for sound in band._sounds: sound.stop()
		capture.clear_buffer()
		band.play_instrument(i)
		band.set_process(false)
		band._process(0.09)
		await create_timer(0.18).timeout
		var frames := capture.get_buffer(capture.get_frames_available())
		var peak := 0.0
		for frame in frames: peak = maxf(peak, maxf(absf(frame.x), absf(frame.y)))
		print("Band audio mixer ",band.INSTRUMENTS[i]," peak: ",peak)
		if peak < 0.001: failures += 1
		band._process(2.0)
	AudioServer.remove_bus_effect(0, capture_index)
	# The same pass must outline full solid props without painting their interiors white.
	band.free()
	controller.refresh_target()
	controller._outlines._process(0.5)
	var pinball: PainterlyPinball = load("res://components/activities/arcade/pinball/painterly_pinball.tscn").instantiate()
	stage.add_child(pinball)
	camera.size = 2.6
	camera.look_at(Vector3(0,1,0))
	actor.position = Vector3(0,0,10)
	var plain := await snapshot("/tmp/interaction-pinball-plain.png")
	actor.position = Vector3(0,0,1.13)
	controller.refresh_target()
	controller._outlines._process(0.5)
	var bright := await snapshot("res://docs/previews/interaction-outline.png")
	var outline_pixels := changed_pixels(plain,bright)
	if outline_pixels < 300 or outline_pixels > 15000: failures += 1
	print("Pinball outlined pixels: ",outline_pixels)
	stage.free()
	# Actual authored scale, camera, controller, and HUD in First Meeting.
	root.content_scale_size = Vector2i(1400,646)
	var world: Node3D = load("res://scenes/world/first_meeting_world.tscn").instantiate()
	root.add_child(world)
	world.get_node("Controls/FPSLabel").hide()
	var live_band: PainterlyMechanicalBand = world.get_node("Memory/Zones/Arcade/Scenery/Machines/MechanicalBand")
	var player: Node3D = world.get_node("Explorer")
	player.global_position = live_band.to_global(Vector3(live_band.get_button(2).position.x,0,2.9)*live_band.prop_scale)
	player.reset_physics_interpolation()
	var rig: Node3D = world.get_node("CameraRig")
	rig.set_process(false)
	rig.global_position = player.global_position
	await create_timer(0.5).timeout
	await snapshot("res://docs/previews/mechanical-band-memory.png")
	var live_controller: Node = world.get_node("InteractionController")
	if live_controller.target != live_band.get_button(2): failures += 1
	world.free()
	print("Band / outline GPU checks: ", "PASS" if failures == 0 else "FAIL")
	quit(failures)
