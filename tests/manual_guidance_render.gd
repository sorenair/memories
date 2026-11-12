extends SceneTree
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(value: bool,message: String) -> void:
	if not value:
		failures += 1
		push_error(message)
func resolve(node: Node) -> void:
	if node.has_method("get_recall_controller"):
		var effect: Node = node.get_recall_controller()
		if is_instance_valid(effect):
			effect.seek(1.0)
			effect.set_process(false)
	for child in node.get_children(true): resolve(child)
func snapshot(path: String = "") -> Image:
	await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	if not path.is_empty(): image.save_png(path)
	return image
func brightened_pixels(a: Image,b: Image) -> int:
	var count := 0
	for y in a.get_height():
		for x in a.get_width():
			var first := a.get_pixel(x,y)
			var second := b.get_pixel(x,y)
			# Translucent white picks up the warm pigment beneath it; it needn't clip to pure white.
			if second.r>0.75 and second.g>0.75 and second.b>0.75 and second.get_luminance()-first.get_luminance()>0.025: count += 1
	return count
func press(button: Control) -> void:
	var event := InputEventScreenTouch.new()
	event.index = 1
	event.position = button._origin
	event.pressed = true
	button._input(event)
	event.pressed = false
	button._input(event)
func run() -> void:
	root.always_on_top = true
	root.content_scale_size = Vector2i(1400,646)
	var world: Node3D = load("res://scenes/world/first_meeting_world.tscn").instantiate()
	root.add_child(world)
	await physics_frame
	await physics_frame
	resolve(world)
	await create_timer(0.25).timeout
	world.get_node("Controls/FPSLabel").hide()
	world.get_node("CameraRig").set_process(false)
	var guidance: Node = world.get_node("GuidanceController")
	var button: Control = world.get_node("Controls/InteractButton")
	var actor: MemoryExplorer = world.get_node("Explorer")
	var plain := await snapshot()
	check(guidance.active_guide == null,"The first rendered memory must have no automatic guide")
	press(button)
	var guide: FragmentBrushstrokeGuide = guidance.active_guide
	check(is_instance_valid(guide),"The actual HUD touch must create visible guidance")
	if not is_instance_valid(guide): quit(1); return
	guide.set_process(false)
	guide._process(guide.travel_duration*0.65)
	var painted := await snapshot("res://docs/previews/manual-guide-arrival.png")
	var pixels := brightened_pixels(plain,painted)
	check(pixels>120,"A requested painterly stroke must be readable at the normal gameplay camera scale")
	guide._process(guide.travel_duration+guide.trail_duration+0.2)
	guidance._physics_process(0)
	check(not guide.visible and not guide.is_processing(),"The visible hint must stop after one pass")
	# Reading changes the next destination but never automatically starts its route.
	var house: MemoryFragment = world.get_node("Memory/Zones/House/Fragment")
	actor.global_position = house.global_position
	actor.reset_physics_interpolation()
	check(house.try_activate(actor),"The actual house fragment must remain interactive")
	var ui: Control = world.get_node("Controls/FragmentInteraction")
	while not ui.current_note.is_empty(): ui.advance_note()
	await create_timer(0.8).timeout
	check(guidance.active_guide == null,"Closing the source note must not show the onward guide")
	actor.global_position = Vector3(7.0,0.04,6.15)
	actor.reset_physics_interpolation()
	world.get_node("CameraRig").global_position = actor.global_position
	press(button)
	guide = guidance.active_guide
	check(is_instance_valid(guide) and guidance.active_destination.name == &"ArcadeFragment","A fresh request must now point from the player to the arcade")
	guide.set_process(false)
	guide._process(minf(1.2,guide.travel_duration*0.3))
	await snapshot("res://docs/previews/manual-guide-onward.png")
	world.queue_free()
	await process_frame
	await process_frame
	await create_timer(0.35).timeout
	print("Manual guide GPU: ","PASS" if failures==0 else "FAIL"," | readable brightened pixels ",pixels)
	quit(failures)
