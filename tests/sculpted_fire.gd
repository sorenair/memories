extends SceneTree
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(value: bool, message: String) -> void:
	if not value:
		push_error(message)
		failures += 1
func run() -> void:
	var fire := load("res://components/vfx/sculpted_fire/painterly_sculpted_fire.tscn").instantiate() as PainterlySculptedFire
	root.add_child(fire)
	check(fire.get_children().is_empty(), "Generated batches must remain internal")
	check(fire.get_children(true).size() == 6, "Six batches: flames, flamelets, smoke volume/fray, sparks, ground wash")
	check(not fire.is_processing() and not fire.is_physics_processing(), "Fire animation must run entirely on the GPU")
	var flame := fire.get_node("Flames") as MeshInstance3D
	check(flame.mesh.get_aabb().size.z > 1.0, "Flames must use a volume proxy")
	var mesh := flame.mesh
	var material := flame.material_override
	fire.fire_size = Vector2(1.6, 3.0)
	fire.wind = Vector2(-0.5, 0.4)
	fire.smoke_height = 4.0
	fire.smoke_turbulence = 0.9
	fire.smoke_definition = 0.95
	fire.body_fullness = 0.6
	fire.spark_burstiness = 0.8
	fire.spark_variation = 0.9
	fire.core_color = Color("e5ffce")
	check(flame.mesh == mesh and flame.material_override == material, "Size/wind/palette controls must preserve geometry/materials")
	check(material.get_shader_parameter("core_color") == fire.core_color, "Palette must reach the shader")
	check(fire.get_node("Sparks").material_override.get_shader_parameter("spark_variation") == fire.spark_variation, "Spark variation must update without rebuilding")
	check(flame.custom_aabb.has_point(Vector3(-1.0, 7.0, 1.0)), "Bounds must include smoke/spark rise and wind")
	fire.smoke_amount = 0.0
	fire.spark_amount = 0.0
	fire.glow_strength = 0.0
	check(not fire.get_node("Smoke").visible and not fire.get_node("SmokeFray").visible and not fire.get_node("Sparks").visible and not fire.get_node("GroundGlow").visible, "Zero smoke/sparks/glow must hide the associated draws")
	check(flame.visible, "Disabling secondary effects must preserve the main flame")
	fire.intensity = 0.0
	for child in fire.get_children(true):
		check(not child.visible, "Zero intensity must hide every batch")
	fire.intensity = 1.0
	fire.smoke_amount = 0.7
	fire.spark_amount = 0.5
	check(fire.get_node("Smoke") is MeshInstance3D and fire.get_node("Smoke").visible and fire.get_node("Sparks").multimesh.visible_instance_count == 32, "Smoke density and active spark pool must update without rebuilding")
	var packed := PackedScene.new()
	packed.pack(fire)
	var copy := packed.instantiate() as PainterlySculptedFire
	root.add_child(copy)
	check(copy.fire_size == fire.fire_size and copy.wind == fire.wind and copy.smoke_amount == fire.smoke_amount and copy.core_color == fire.core_color and copy.smoke_turbulence == fire.smoke_turbulence and copy.smoke_definition == fire.smoke_definition and copy.spark_burstiness == fire.spark_burstiness and copy.spark_variation == fire.spark_variation and copy.body_fullness == fire.body_fullness, "Export controls must survive scene persistence")
	check(copy.get_node("Flames").mesh == mesh and copy.get_node("Flames").material_override != material, "Instances must share geometry and keep independent materials")
	check(copy.get_node("Flames").material_override.get_shader_parameter("flow_noise") == material.get_shader_parameter("flow_noise"), "Instances must share the baked flow texture")
	copy.free()
	fire.recall_enabled = true
	var effect := fire.get_recall_controller()
	effect.set_process(false)
	check(effect.progress == 0.0, "Recall must start hidden")
	effect.seek(0.5)
	fire.fire_seed = 91
	fire.rebuild()
	check(fire.get_recall_controller() == effect and effect.progress == 0.5, "Rebuild must retain recall progress")
	for paint in fire.recall_materials(): check(is_equal_approx(paint.get_shader_parameter("recall_visibility"), 0.5), "Every rebuilt batch must retain recall visibility")
	fire.recall_enabled = false
	for paint in fire.recall_materials(): check(paint.get_shader_parameter("recall_visibility") == 1.0, "Disabling recall must restore all batches")
	# Multiple queued editor changes should remain safe when a component is removed.
	fire.free()
	await process_frame
	print("Sculpted fire component: ", "PASS" if failures == 0 else "FAIL")
	quit(failures)
