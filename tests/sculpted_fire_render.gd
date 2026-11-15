extends SceneTree
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(value: bool, message: String) -> void:
	if not value:
		push_error(message)
		failures += 1
func snapshot(path: String = "") -> Image:
	await process_frame
	RenderingServer.force_draw(false)
	var result := root.get_texture().get_image()
	if not path.is_empty(): result.save_png(path)
	return result
func changes(a: Image, b: Image) -> int:
	var small_a := a.duplicate() as Image
	var small_b := b.duplicate() as Image
	small_a.resize(320, 320)
	small_b.resize(320, 320)
	var first := small_a.get_data()
	var second := small_b.get_data()
	var count := 0
	for index in first.size():
		if absi(int(first[index]) - int(second[index])) > 5: count += 1
	return count
func warm_pixels(frame: Image) -> int:
	var small := frame.duplicate() as Image
	small.resize(400, 400)
	var count := 0
	for y in small.get_height():
		for x in small.get_width():
			var color := small.get_pixel(x, y)
			# Include the pale cream core while excluding the warm-white floor.
			if color.r > 0.45 and color.r > color.b * 1.18 and color.g > color.b * 1.10: count += 1
	return count
func gpu_time() -> float:
	var samples: Array[float] = []
	for index in 40:
		await process_frame
		RenderingServer.force_draw(false)
		if index >= 16: samples.append(RenderingServer.viewport_get_measured_render_time_gpu(root.get_viewport_rid()))
	samples.sort()
	return samples[samples.size() / 2]
func run() -> void:
	physics_interpolation = false
	root.size = Vector2i(1000, 1000)
	root.content_scale_size = Vector2i(1000, 1000)
	var scene := Node3D.new()
	root.add_child(scene)
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color("1b202a")
	scene.add_child(environment)
	var floor_mesh := MeshInstance3D.new()
	floor_mesh.mesh = PlaneMesh.new()
	floor_mesh.mesh.size = Vector2(200, 200)
	var paint := StandardMaterial3D.new()
	paint.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	paint.albedo_color = Color("1b202a")
	floor_mesh.material_override = paint
	scene.add_child(floor_mesh)
	var fire := load("res://components/vfx/sculpted_fire/painterly_sculpted_fire.tscn").instantiate() as PainterlySculptedFire
	scene.add_child(fire)
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 5.6
	scene.add_child(camera)
	camera.position = Vector3(5, 3.0, 7)
	camera.look_at(Vector3(0, 1.95, 0))
	# Secondary effects must not disguise a broken or missing main flame shader.
	fire.smoke_amount = 0.0
	fire.spark_amount = 0.0
	fire.glow_strength = 0.0
	fire.get_node("Flamelets").hide()
	for time in [0.0, 0.6, 1.25, 2.0, 3.0, 4.0, 5.0]:
		fire.set_preview_time(time)
		fire.get_node("Flamelets").hide()
		var isolated := await snapshot("/tmp/sculpted-fire-core-%.2f.png" % time)
		var coverage := warm_pixels(isolated)
		check(coverage > 1500 and coverage < 18000, "The continuous flame must retain a warm, bounded body at time %.2f (%d pixels)" % [time, coverage])
	fire.set_preview_time(1.25)
	fire.body_fullness = 0.0
	fire.get_node("Flamelets").hide()
	var lean_frame := await snapshot("/tmp/sculpted-fire-fullness-0.png")
	var lower_region := Rect2i(0, 680, 1000, 220)
	var lean_body := warm_pixels(lean_frame.get_region(lower_region))
	fire.body_fullness = 1.0
	fire.get_node("Flamelets").hide()
	var full_frame := await snapshot("/tmp/sculpted-fire-fullness-1.png")
	var full_body := warm_pixels(full_frame.get_region(lower_region))
	check(full_body > lean_body * 1.10 and changes(lean_frame,full_frame)>500, "Body Fullness must visibly fill the lower flame (%d vs %d pixels)" % [full_body,lean_body])
	fire.body_fullness = 0.72
	# Orthographic size and shape must remain fixed when the camera dollies
	# along its view axis. Perspective-style rays inside a proxy fail this.
	fire.set_preview_time(1.25)
	fire.get_node("Flamelets").hide()
	var ortho_far := await snapshot()
	var camera_target := Vector3(0,1.95,0)
	var far_position := camera.position
	camera.position = camera_target+(far_position-camera_target)*0.55
	camera.look_at(camera_target)
	var ortho_near := await snapshot()
	var far_coverage := warm_pixels(ortho_far)
	var near_coverage := warm_pixels(ortho_near)
	check(absf(float(far_coverage-near_coverage))/maxf(far_coverage,1)<0.02, "Orthographic camera distance must not change the flame silhouette")
	camera.position = far_position
	camera.look_at(camera_target)
	var curl_change := 0
	# Bursts can be between attacks at any single instant. Compare the control
	# over a cycle, while requiring a visible core throughout.
	for time in [0.0, 0.3, 0.6, 1.25]:
		fire.set_preview_time(time)
		fire.curl_amount = 0.0
		fire.get_node("Flamelets").hide()
		var gentle := await snapshot("/tmp/sculpted-fire-curl-0-%.2f.png" % time)
		fire.curl_amount = 1.0
		fire.get_node("Flamelets").hide()
		var rolled := await snapshot("/tmp/sculpted-fire-curl-1-%.2f.png" % time)
		check(warm_pixels(rolled) > 1500, "Strong curls must retain their bright core")
		curl_change = maxi(curl_change, changes(gentle, rolled))
	check(curl_change > 500, "Curl Amount must visibly change the roll over a burst cycle")
	fire.curl_amount = 0.8
	# Verify that custom depth places ordinary scenery in front of and behind
	# the actual flame, without exposing the enclosing proxy's box.
	camera.position = Vector3(0, 1.1, 7)
	camera.look_at(Vector3(0, 0.9, 0))
	fire.set_preview_time(1.25)
	fire.get_node("Flamelets").hide()
	var clear_core := await snapshot()
	var blocker := MeshInstance3D.new()
	blocker.mesh = BoxMesh.new()
	blocker.mesh.size = Vector3(2, 2.6, 0.12)
	var blocker_paint := StandardMaterial3D.new()
	blocker_paint.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	blocker_paint.albedo_color = Color("304957")
	blocker.material_override = blocker_paint
	scene.add_child(blocker)
	blocker.position = Vector3(0, 1.2, 1.2)
	var covered := await snapshot("/tmp/sculpted-fire-occluded.png")
	check(warm_pixels(covered) < warm_pixels(clear_core) / 10, "Foreground scenery must occlude the volume")
	blocker.position.z = -1.2
	var behind := await snapshot()
	check(warm_pixels(behind) > warm_pixels(clear_core) * 0.85, "Background scenery must stay behind the flame surface")
	blocker.free()
	camera.projection = Camera3D.PROJECTION_PERSPECTIVE
	camera.position = Vector3(3.0, 1.9, 4.3)
	camera.look_at(Vector3(0, 1.0, 0))
	check(warm_pixels(await snapshot("/tmp/sculpted-fire-perspective.png")) > 1500, "The volume must also work with perspective projection")
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.position = Vector3(5, 3.0, 7)
	camera.look_at(Vector3(0, 1.95, 0))
	fire.smoke_amount = 0.65
	fire.spark_amount = 0.65
	fire.glow_strength = 0.55
	fire.get_node("Flamelets").show()
	fire.set_preview_time(1.25)
	await process_frame
	await snapshot("res://docs/previews/sculpted-fire-dark.png")
	fire.animation_speed = 0.0
	var frozen_a := await snapshot()
	await create_timer(0.2).timeout
	var frozen_b := await snapshot()
	check(changes(frozen_a, frozen_b) == 0, "Animation Speed zero must freeze every layer")
	fire.animation_speed = 1.0
	fire.set_preview_time(0.6)
	var moving_a := await snapshot()
	fire.set_preview_time(1.3)
	var moving_b := await snapshot()
	check(changes(moving_a, moving_b) > 900, "Fire, smoke and sparks must visibly animate")
	# Inspect smoke on its own: an animated flame must not disguise a missing
	# plume or a density control that does nothing.
	camera.size = 3.4
	camera.look_at(Vector3(0, 1.75, 0))
	fire.set_preview_time(1.3)
	fire.smoke_amount = 0.25
	for id in ["Flames", "Flamelets", "Sparks", "GroundGlow"]: fire.get_node(id).hide()
	var thin_smoke := await snapshot()
	fire.smoke_amount = 0.9
	for id in ["Flames", "Flamelets", "Sparks", "GroundGlow"]: fire.get_node(id).hide()
	var dense_smoke := await snapshot()
	fire.smoke_amount = 0.0
	for id in ["Flames", "Flamelets", "Sparks", "GroundGlow"]: fire.get_node(id).hide()
	var no_smoke := await snapshot()
	check(changes(dense_smoke, no_smoke) > 1000 and changes(thin_smoke, dense_smoke) > 300, "Smoke density must visibly control the plume")
	fire.smoke_amount = 0.65
	for id in ["Flames", "Flamelets", "Sparks", "GroundGlow"]: fire.get_node(id).hide()
	var smoke_a := await snapshot("res://docs/previews/sculpted-fire-smoke.png")
	fire.set_preview_time(2.5)
	for id in ["Flames", "Flamelets", "Sparks", "GroundGlow"]: fire.get_node(id).hide()
	var smoke_b := await snapshot()
	check(changes(smoke_a, smoke_b) > 500, "Smoke must visibly billow and disperse independently")
	fire.set_preview_time(1.3)
	camera.size = 5.6
	camera.look_at(Vector3(0, 1.95, 0))
	paint.albedo_color = Color("efede2")
	environment.environment.background_color = paint.albedo_color
	await snapshot("res://docs/previews/sculpted-fire-light.png")
	for angle in [0, 90, 180, 270]:
		var theta := deg_to_rad(float(angle))
		camera.position = Vector3(cos(theta) * 7, 3.7, sin(theta) * 7)
		camera.look_at(Vector3(0, 1.95, 0))
		var visible_fire := await snapshot("/tmp/sculpted-fire-angle-%s.png" % angle)
		fire.intensity = 0.0
		var empty := await snapshot()
		check(changes(visible_fire, empty) > 1800, "Fire must retain a volumetric silhouette at angle %s" % angle)
		fire.intensity = 1.0
	# Recall and strong wind must also work in the solid shader, without smoke
	# or sparks supplying the pixels that make a broken main flame look valid.
	camera.position = Vector3(5, 3.0, 7)
	camera.look_at(Vector3(0, 1.95, 0))
	var solid_material: ShaderMaterial = fire.get_node("Flames").material_override
	var recalled_coverage: Array[int] = []
	for progress in [0.0, 0.35, 1.0]:
		for id in ["Flamelets", "Smoke", "SmokeFray", "Sparks", "GroundGlow"]: fire.get_node(id).hide()
		solid_material.set_shader_parameter("recall_visibility", progress)
		recalled_coverage.append(warm_pixels(await snapshot()))
	check(recalled_coverage[0] == 0 and recalled_coverage[1] > 30 and recalled_coverage[2] > recalled_coverage[1] * 2, "The solid flame must grow continuously from hidden through partial recall")
	solid_material.set_shader_parameter("recall_visibility", 1.0)
	for strong_wind in [Vector2(-2, 2), Vector2(2, -2)]:
		fire.wind = strong_wind
		fire.intensity = 0.2
		for id in ["Flamelets", "Smoke", "SmokeFray", "Sparks", "GroundGlow"]: fire.get_node(id).hide()
		check(warm_pixels(await snapshot()) > 100, "Low-intensity solid flame must survive maximum wind")
	fire.wind = Vector2(0.16, 0.04)
	fire.intensity = 1.0
	if "--profile" in OS.get_cmdline_user_args():
		RenderingServer.viewport_set_measure_render_time(root.get_viewport_rid(), true)
		var full_time: float = await gpu_time()
		fire.hide()
		var empty_time: float = await gpu_time()
		fire.show()
		if full_time > 0.0:
			print("Fire GPU viewport ms | full: %.3f | empty: %.3f" % [full_time, empty_time])
		else:
			print("GPU timestamps unavailable on this rendering device")
	# A short deterministic engine animation, suitable for a preview GIF.
	if "--animation" in OS.get_cmdline_user_args():
		paint.albedo_color = Color("1b202a")
		environment.environment.background_color = paint.albedo_color
		camera.position = Vector3(5, 3.0, 7)
		camera.look_at(Vector3(0, 1.95, 0))
		for index in 96:
			fire.set_preview_time(1.25 + float(index) / 24.0)
			await snapshot("/tmp/sculpted-fire-frame-%03d.png" % index)
		if "--detail" in OS.get_cmdline_user_args():
			fire.smoke_amount = 0.0
			camera.size = 2.8
			camera.look_at(Vector3(0, 0.95, 0))
			for index in 96:
				fire.set_preview_time(1.25 + float(index) / 24.0)
				await snapshot("/tmp/sculpted-fire-detail-%03d.png" % index)
		if "--smoke" in OS.get_cmdline_user_args():
			fire.smoke_amount = 0.65
			camera.size = 3.4
			camera.look_at(Vector3(0, 1.75, 0))
			for index in 96:
				fire.set_preview_time(1.25 + float(index) / 24.0)
				for id in ["Flames", "Flamelets", "Sparks", "GroundGlow"]: fire.get_node(id).hide()
				await snapshot("/tmp/sculpted-fire-smoke-%03d.png" % index)
	scene.free()
	var stage: Node3D = load("res://tests/scenes/sculpted_fire_test.tscn").instantiate()
	root.add_child(stage)
	await process_frame
	await process_frame
	check(stage.subject is PainterlySculptedFire, "The F6 study must load the new fire on the generic stage")
	await snapshot("/tmp/sculpted-fire-stage.png")
	stage.free()
	await process_frame
	RenderingServer.force_draw(false)
	await process_frame
	print("Sculpted fire render: ", "PASS" if failures == 0 else "FAIL")
	quit(failures)
