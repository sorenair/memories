extends SceneTree
## Optional actual-engine preview: godot --path . --script tests/render_water_preview.gd
func _initialize() -> void:
	call_deferred("capture")
func capture() -> void:
	root.content_scale_size = Vector2i(1600, 1100)
	var scene := Node3D.new()
	root.add_child(scene)
	var environment := WorldEnvironment.new()
	var settings := Environment.new()
	settings.background_mode = Environment.BG_COLOR
	settings.background_color = Color(0.94, 0.935, 0.89)
	environment.environment = settings
	scene.add_child(environment)
	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(200, 200)
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = settings.background_color
	plane.material = material
	ground.mesh = plane
	scene.add_child(ground)
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 17.0
	scene.add_child(camera)
	camera.position = Vector3(0, 16, 13)
	camera.look_at(Vector3.ZERO)
	var water: PainterlyWater = load("res://components/scenery/water/painterly_water.tscn").instantiate()
	water.footprint = Vector2(7.5, 6.0)
	water.irregularity = 0.08
	scene.add_child(water)
	camera.size = 9.2
	camera.position = Vector3(0, 10, 7)
	camera.look_at(Vector3.ZERO)
	await create_timer(0.8).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/water-preview.png")
	quit()
