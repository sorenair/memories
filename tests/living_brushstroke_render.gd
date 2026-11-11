extends SceneTree
## GPU verification on a neutral canvas; saves an example still in docs/.
var brush: LivingBrushstroke

func _initialize() -> void:
	call_deferred("run")

func snapshot() -> Image:
	await process_frame
	await RenderingServer.frame_post_draw
	return root.get_texture().get_image()

func changes(a: Image, b: Image) -> int:
	a.convert(Image.FORMAT_RGBA8)
	b.convert(Image.FORMAT_RGBA8)
	var first := a.get_data()
	var second := b.get_data()
	var total := 0
	for index in range(first.size()):
		if absi(int(first[index]) - int(second[index])) > 3:
			total += 1
	return total

func set_time(seconds: float) -> void:
	for material in brush._materials:
		material.set_shader_parameter("time_override", seconds)

func core_thickness(frame: Image, background: Image) -> int:
	frame.convert(Image.FORMAT_RGBA8)
	background.convert(Image.FORMAT_RGBA8)
	var data := frame.get_data()
	var blank := background.get_data()
	var top := PackedInt32Array()
	var bottom := PackedInt32Array()
	top.resize(frame.get_width())
	bottom.resize(frame.get_width())
	top.fill(frame.get_height())
	bottom.fill(-1)
	for y in range(frame.get_height()):
		for x in range(frame.get_width()):
			var index := (y * frame.get_width() + x) * 4
			# Measure the white pigment, excluding its faint surrounding halo.
			if int(data[index]) - int(blank[index]) > 46:
				top[x] = mini(top[x], y)
				bottom[x] = maxi(bottom[x], y)
	var thickness := 0
	for x in range(frame.get_width()):
		thickness = maxi(thickness, bottom[x] - top[x] + 1)
	return thickness

func run() -> void:
	root.always_on_top = true
	root.content_scale_size = Vector2i(1200, 700)
	var scene := Node3D.new()
	root.add_child(scene)
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color("748079")
	scene.add_child(environment)
	brush = load("res://components/guidance/brushstroke/living_brushstroke.tscn").instantiate()
	brush.stroke_seed = 0
	scene.add_child(brush)
	var camera := Camera3D.new()
	camera.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 3.5
	scene.add_child(camera)
	camera.position = Vector3(5, 6, 8)
	camera.look_at(Vector3(0, 0.6, -0.5))
	set_time(3.1)
	await create_timer(0.5).timeout
	var still_a := await snapshot()
	await create_timer(0.2).timeout
	var still_b := await snapshot()
	still_a.save_png("res://docs/living-brushstroke.png")
	set_time(3.6)
	var moved := await snapshot()
	moved.save_png("/tmp/living-brushstroke-later.png")
	set_time(9.0)
	var resting := await snapshot()
	brush.visible = false
	var hidden := await snapshot()
	brush.visible = true
	# Verify the live TIME clock and the exported still-pose control as well.
	set_time(-1.0)
	for material in brush._materials:
		material.set_shader_parameter("seed_phase", 0.25)
	brush.playback_speed = 0.0
	var paused_a := await snapshot()
	await create_timer(0.2).timeout
	var paused_b := await snapshot()
	brush.playback_speed = 1.0
	var live_a := await snapshot()
	await create_timer(0.3).timeout
	var live_b := await snapshot()
	# Check that the ribbon remains readable from a second camera angle.
	for material in brush._materials:
		material.set_shader_parameter("seed_phase", 0.0)
	set_time(3.1)
	camera.position = Vector3(-4, 3, 5)
	camera.look_at(Vector3(0, 0.7, -0.5))
	var side := await snapshot()
	side.save_png("/tmp/living-brushstroke-side.png")
	var frozen := changes(still_a, still_b)
	var moving := changes(still_a, moved)
	var visible_paint := changes(still_a, hidden)
	var quiet := changes(resting, hidden)
	var side_paint := changes(side, hidden)
	var paused := changes(paused_a, paused_b)
	var live := changes(live_a, live_b)
	# A straight route isolates shape evolution from path curvature or translation.
	brush.set_points(Vector3(-2, 0.8, 0), Vector3(2, 0.8, 0))
	brush.arc_height = 0.0
	brush.curve_bend = 0.0
	brush.motion_amount = 0.0
	brush.surface_wash_enabled = false
	camera.position = Vector3(0, 0.8, 8)
	camera.look_at(Vector3(0, 0.8, 0))
	brush.visible = false
	var blank := await snapshot()
	brush.visible = true
	set_time(brush.travel_duration * 0.12)
	var birth := await snapshot()
	set_time(brush.travel_duration * 0.52)
	var bloom := await snapshot()
	set_time(brush.travel_duration * 0.92)
	var release := await snapshot()
	birth.save_png("/tmp/brushstroke-birth.png")
	bloom.save_png("/tmp/brushstroke-bloom.png")
	release.save_png("/tmp/brushstroke-release.png")
	var birth_width := core_thickness(birth, blank)
	var bloom_width := core_thickness(bloom, blank)
	var release_width := core_thickness(release, blank)
	brush.evolution_strength = 0.0
	set_time(brush.travel_duration * 0.92)
	var constant := await snapshot()
	var evolution := changes(release, constant)
	brush.evolution_strength = 1.0
	brush.glow_strength = 0.0
	set_time(brush.travel_duration * 0.52)
	var unlit := await snapshot()
	var glow := changes(bloom, unlit)
	print("Brushstroke GPU | frozen: ", frozen, " | moving: ", moving,
		" | visible paint: ", visible_paint, " | quiet rest: ", quiet, " | side: ", side_paint,
		" | paused: ", paused, " | live motion: ", live)
	print("Brushstroke evolution | birth/bloom/release core width: ", birth_width, "/", bloom_width, "/", release_width,
		" | shape change: ", evolution, " | glow: ", glow)
	quit(0 if frozen == 0 and moving > 500 and visible_paint > 500 and quiet == 0 and side_paint > 500 and paused == 0 and live > 500
		and bloom_width > birth_width * 1.25 and bloom_width > release_width * 1.25 and evolution > 500 and glow > 500 else 1)
