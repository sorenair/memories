extends SceneTree

var failures: int = 0


func _initialize() -> void:
	call_deferred("run")


func check(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		failures += 1


func check_path(brush: LivingBrushstroke, description: String) -> void:
	check(brush.sample_path(0.0).is_equal_approx(brush.start_point), description + ": start endpoint must be exact")
	check(brush.sample_path(1.0).is_equal_approx(brush.end_point), description + ": end endpoint must be exact")
	var bounds: AABB = brush._ribbon.custom_aabb.grow(0.001)
	for index in range(129):
		var point: Vector3 = brush.sample_path(float(index) / 128.0)
		check(point.is_finite(), description + ": path must remain finite")
		check(bounds.has_point(point), description + ": sampled curve must remain inside culling bounds")


func triangle_count(instance: MeshInstance3D) -> int:
	if instance.mesh == null:
		return 0
	return instance.mesh.get_faces().size() / 3


func check_white_palette(brush: LivingBrushstroke, description: String) -> void:
	for value in [brush.pigment_color, brush.edge_color, brush.highlight_color]:
		var color: Color = value
		var channel_spread: float = maxf(color.r, maxf(color.g, color.b)) - minf(color.r, minf(color.g, color.b))
		check(channel_spread < 0.015, description + ": the white palette must remain monochrome")
		check(color.get_luminance() > 0.65, description + ": the default pigment must stay on a bright white scale")


func check_halo_envelope(brush: LivingBrushstroke, description: String) -> void:
	# Conservative displacement budget: halo half-width 1.3 * bloom 1.26 *
	# ripple 1.12, plus .14-width sway, .12-width roll, and 1.35-motion drift.
	# This checks animated geometry clearance, beyond just the static centerline.
	var displacement: float = brush.stroke_width * 2.095 + brush.motion_amount * 1.35
	var bounds: AABB = brush._ribbon.custom_aabb.grow(0.001)
	for index in range(65):
		var center: Vector3 = brush.sample_path(float(index) / 64.0)
		for axis in [Vector3.UP, Vector3.DOWN, Vector3.LEFT, Vector3.RIGHT, Vector3.FORWARD, Vector3.BACK]:
			check(bounds.has_point(center + axis * displacement), description + ": bounds must cover the widest evolving halo")


func run() -> void:
	var scene: PackedScene = load("res://components/guidance/brushstroke/living_brushstroke.tscn")
	var brush: LivingBrushstroke = scene.instantiate()
	root.add_child(brush)
	check(brush._ribbon != null and brush._wash != null, "Both render surfaces must be generated")
	if brush._ribbon == null or brush._wash == null:
		brush.free()
		quit(failures)
		return
	check(brush.get_children().is_empty(), "Generated brushstroke surfaces must remain internal")
	check(not brush.is_processing() and not brush.is_physics_processing(), "Shader animation must not require frame callbacks")
	check(brush._ribbon.visible and brush._wash.visible, "The default stroke and optional surface wash must be visible")
	check_white_palette(brush, "Default brushstroke")
	check(brush.glow_strength > 0.0 and brush.evolution_strength > 0.0, "The default brushstroke must glow and evolve")
	check(triangle_count(brush._ribbon) > 0, "The ribbon must contain triangles")
	check(triangle_count(brush._ribbon) + triangle_count(brush._wash) < 2000, "The default component must stay below 2000 triangles")
	var original_triangle_count: int = triangle_count(brush._ribbon) + triangle_count(brush._wash)
	var original_ribbon_id: int = brush._ribbon.get_instance_id()
	var original_wash_id: int = brush._wash.get_instance_id()
	var original_ribbon_material: Material = brush._ribbon.material_override
	var original_wash_material: Material = brush._wash.material_override
	check_path(brush, "Default route")
	check_halo_envelope(brush, "Default route")

	var original_mesh: Mesh = brush._ribbon.mesh
	var original_wash_mesh: Mesh = brush._wash.mesh
	brush.set_points(Vector3(-4.2, 0.45, 1.7), Vector3(2.8, 1.25, -3.4))
	check_path(brush, "Updated route")
	brush.start_point = Vector3(-3.6, 0.6, 2.1)
	brush.end_point = Vector3(3.2, 1.1, -2.7)
	brush.arc_height = 0.71
	brush.curve_bend = -0.53
	brush.stroke_width = 0.57
	brush.motion_amount = 0.12
	check_path(brush, "Exported path controls")
	check(brush._ribbon.mesh == original_mesh and brush._wash.mesh == original_wash_mesh, "Editing route and width must preserve shared geometry")
	for instance in [brush._ribbon, brush._wash]:
		var material: ShaderMaterial = instance.material_override
		check(material.get_shader_parameter("start_point") == brush.start_point and material.get_shader_parameter("end_point") == brush.end_point, "Both layers must receive endpoint edits")
		check(is_equal_approx(material.get_shader_parameter("stroke_width"), brush.stroke_width), "Both layers must receive width edits")

	brush.pigment_color = Color(0.82, 0.71, 0.93, 1.0)
	brush.edge_color = Color(0.96, 0.88, 0.78, 1.0)
	brush.highlight_color = Color(1.0, 0.97, 0.89, 1.0)
	brush.opacity = 0.43
	brush.wash_opacity = 0.11
	brush.playback_speed = 0.72
	brush.travel_duration = 4.8
	brush.trail_duration = 1.7
	brush.rest_duration = 2.3
	brush.glow_strength = -1.0
	brush.evolution_strength = -1.0
	check(brush.glow_strength == 0.0 and brush.evolution_strength == 0.0, "Glow and evolution must reject negative strengths")
	brush.glow_strength = 4.0
	brush.evolution_strength = 4.0
	check(brush.glow_strength == 2.0 and brush.evolution_strength == 1.0, "Glow and evolution must stay inside their safe shader ranges")
	brush.glow_strength = 0.73
	brush.evolution_strength = 0.63
	check(brush._ribbon.mesh == original_mesh and brush._wash.mesh == original_wash_mesh, "Changing paint and timing must preserve geometry")
	check(brush._ribbon.get_instance_id() == original_ribbon_id and brush._wash.get_instance_id() == original_wash_id, "Glow and evolution edits must preserve both render surfaces")
	check(brush._ribbon.material_override == original_ribbon_material and brush._wash.material_override == original_wash_material, "Glow and evolution edits must update existing shader materials")
	check(brush.get_children(true).size() == 2 and triangle_count(brush._ribbon) + triangle_count(brush._wash) == original_triangle_count, "Glow must reuse the existing two surfaces and triangle budget")
	for instance in [brush._ribbon, brush._wash]:
		var material: ShaderMaterial = instance.material_override
		check(material.get_shader_parameter("pigment_color") == brush.pigment_color and material.get_shader_parameter("edge_color") == brush.edge_color and material.get_shader_parameter("highlight_color") == brush.highlight_color, "Both layers must receive palette edits")
		check(is_equal_approx(material.get_shader_parameter("opacity"), brush.opacity) and is_equal_approx(material.get_shader_parameter("playback_speed"), brush.playback_speed), "Both layers must receive animation and opacity edits")
		check(is_equal_approx(material.get_shader_parameter("glow_strength"), brush.glow_strength) and is_equal_approx(material.get_shader_parameter("evolution_strength"), brush.evolution_strength), "Both layers must receive glow and evolution edits")

	brush.surface_wash_enabled = false
	check(not brush._wash.visible and brush._ribbon.visible, "Disabling the wash must preserve the airborne stroke")
	brush.surface_wash_enabled = true
	check(brush._wash.visible, "The surface wash must be re-enableable")

	var packed: PackedScene = PackedScene.new()
	check(packed.pack(brush) == OK, "Brushstroke configuration must pack successfully")
	var restored: LivingBrushstroke = packed.instantiate()
	root.add_child(restored)
	check(restored.start_point.is_equal_approx(brush.start_point) and restored.end_point.is_equal_approx(brush.end_point), "Nondefault endpoints must survive saving")
	check(restored.pigment_color.is_equal_approx(brush.pigment_color) and restored.edge_color.is_equal_approx(brush.edge_color) and restored.highlight_color.is_equal_approx(brush.highlight_color), "Nondefault paint colors must survive saving")
	check(is_equal_approx(restored.opacity, brush.opacity) and is_equal_approx(restored.wash_opacity, brush.wash_opacity), "Opacity controls must survive saving")
	check(is_equal_approx(restored.glow_strength, brush.glow_strength) and is_equal_approx(restored.evolution_strength, brush.evolution_strength), "Glow and evolution controls must survive saving")
	check(restored.get_children().is_empty(), "Saved brushstrokes must regenerate internal surfaces")
	check_path(restored, "Restored route")
	restored.free()

	# The shader must use the same side-axis fallback as sample_path(). With a
	# narrow stroke, mismatched near-vertical fallbacks can escape these bounds.
	brush.stroke_width = 0.08
	brush.motion_amount = 0.0
	brush.curve_bend = 0.9
	brush.arc_height = 0.38
	brush.glow_strength = 2.0
	brush.evolution_strength = 1.0
	for horizontal_delta in [Vector3(0.01, 0.0, 0.0), Vector3(0.0, 0.0, 0.01), Vector3(0.0001, 0.0, 0.0001)]:
		brush.set_points(Vector3(0.2, 0.4, -0.3), Vector3(0.2, 10.4, -0.3) + horizontal_delta)
		check_path(brush, "Near-vertical narrow route")
		check_halo_envelope(brush, "Near-vertical narrow route")
		check(brush._ribbon.visible and not brush._wash.visible, "Near-vertical routes must hide the degenerate surface wash")

	brush.stroke_width = 0.9
	brush.motion_amount = 0.2
	brush.set_points(Vector3(1.0, 0.2, -2.0), Vector3(1.0, 3.2, -2.0))
	check_path(brush, "Vertical route")
	check_halo_envelope(brush, "Maximum-width vertical route")
	check(brush._ribbon.visible and not brush._wash.visible, "A vertical route must retain its ribbon and hide the degenerate ground wash")
	brush.set_points(Vector3(0.4, 0.9, -0.6), Vector3(0.4, 0.9, -0.6))
	check(not brush._ribbon.visible and not brush._wash.visible, "Coincident endpoints must hide both surfaces safely")
	check(brush.sample_path(0.5).is_finite(), "A coincident route must remain finite")
	brush.set_points(Vector3(-1.0, 0.4, 0.0), Vector3(2.0, 0.7, -1.0))
	check(brush._ribbon.visible and brush._wash.visible, "A usable route must recover after coincident endpoints")
	check_path(brush, "Recovered route")

	brush.detail = 48
	await process_frame
	await process_frame
	check(brush._ribbon.mesh != original_mesh, "Changing tessellation detail must rebuild geometry")
	check(triangle_count(brush._ribbon) > 0, "Rebuilt geometry must remain valid")
	brush.rebuild()
	check_path(brush, "Explicit rebuild")
	check(not brush.is_processing() and not brush.is_physics_processing(), "Runtime edits must not enable frame callbacks")
	var demo: Node3D = load("res://scenes/memories/foliage_demo.tscn").instantiate()
	var demo_brush: LivingBrushstroke = demo.get_node("Environment/SummerSpring/LivingBrushstroke")
	check(demo_brush != null, "The summer clearing must contain the reusable brushstroke")
	check_white_palette(demo_brush, "Demo brushstroke")
	check(demo_brush.start_point.distance_to(demo_brush.end_point) > 1.0, "Demo guidance must span a usable route")
	check(not demo.get_node("Environment/ClearingWisps").visible, "The existing hidden wisp route must remain hidden")
	demo.free()
	brush.free()
	print("Living brushstroke checks: ", "PASS" if failures == 0 else "FAIL")
	quit(failures)
