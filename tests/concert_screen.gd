extends SceneTree
## Editable screen instances, mounted variants, persistence and recall lifecycle.
var failures := 0
const SCREEN = preload("res://components/scenery/concert/display/painterly_concert_screen.tscn")

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)

func run() -> void:
	var screen: PainterlyConcertScreen = SCREEN.instantiate()
	root.add_child(screen)
	var sibling: PainterlyConcertScreen = SCREEN.instantiate()
	root.add_child(sibling)
	check(not screen.is_processing() and not screen.is_physics_processing(), "Screen sequencing and animation must run without CPU frame callbacks")
	var generated := screen._generated_root
	var panel: MeshInstance3D = generated.get_node("DisplayFace")
	check(panel.mesh is QuadMesh and panel.mesh.get_faces().size() == 6, "The animated canvas must remain one two-triangle surface")
	check(generated.has_node("Collision/ScreenCase") and screen._collision_data.size() == 5, "Free-standing screen must have panel and support collision")
	check(screen.get_anchor(&"DisplayCenter").position.is_equal_approx(panel.position), "Placement anchor must follow the luminous panel center")
	screen.palette = 2
	screen.pattern_mode = 5
	screen.beat_bpm = 144
	screen.beats_per_pattern = 0.5
	screen.brightness = 1.3
	screen.seek_time(7.25)
	check(screen._generated_root == generated, "Live visual edits must not rebuild display geometry")
	check(screen._display_material != sibling._display_material, "Screen instances must not share editable uniforms")
	check(screen._display_material.get_shader_parameter("color_a") == screen.PALETTES[2][0], "Palette selection must update the display")
	check(sibling._display_material.get_shader_parameter("pattern_mode") == 0, "Editing one screen must not alter its sibling")
	check(screen._display_material.get_shader_parameter("animation_time") == 7.25, "An authored clock must drive the display deterministically")
	screen.palette = 4
	screen.custom_colors = PackedColorArray([Color.CORAL])
	check(screen._display_material.get_shader_parameter("color_a") == Color.CORAL and screen._display_material.get_shader_parameter("color_d") == screen.PALETTES[0][3], "Incomplete custom palettes must retain valid fallback colors")
	screen.custom_colors = PackedColorArray()
	check(screen._display_material.get_shader_parameter("color_a") == screen.PALETTES[0][0], "An empty custom palette must remain usable")
	screen.display_size = Vector2(7.5, 3.0)
	screen.bottom_height = 1.2
	screen.supports_enabled = false
	screen.halo_enabled = false
	screen.rebuild()
	panel = screen._generated_root.get_node("DisplayFace")
	check(panel.mesh.size == Vector2(7.5, 3.0) and is_equal_approx(panel.position.y, 2.7), "Resizing must update the canvas and its mounting height")
	check(screen._collision_data.size() == 1 and not screen._generated_root.has_node("SoftGlow"), "Wall-mounted variant must remove stand solids and optional glow")
	check(screen._display_material.get_shader_parameter("animation_time") == 7.25, "Shape rebuilds must preserve a supplied animation clock")
	var packed := PackedScene.new()
	check(packed.pack(screen) == OK, "An authored screen must pack successfully")
	var restored: PainterlyConcertScreen = packed.instantiate()
	root.add_child(restored)
	check(restored.display_size == Vector2(7.5, 3) and restored.pattern_mode == 5 and restored.palette == 4, "Dimension and sequence exports must survive scene serialization")
	check(restored.get_child_count(true) == 1, "Only one internal generated hierarchy may exist after loading")
	screen.halo_enabled = true
	screen.rebuild()
	screen.recall_enabled = true
	var recall: Node = screen.get_recall_controller()
	recall.set_process(false)
	recall.seek(0.4)
	check(screen._display_material.get_shader_parameter("assembly_progress") < 1.0 and screen._halo_material.get_shader_parameter("assembly_progress") < 1.0, "Canvas and glow must participate in the existing hardware recall")
	screen.rebuild()
	check(screen.get_recall_controller() == recall and is_equal_approx(recall.progress, 0.4), "Screen regeneration must preserve recall state")
	check(screen._generated_root.has_node("Collision/ScreenCase"), "Recall must preserve safe solid collision")
	screen.recall_enabled = false
	check(screen._display_material.get_shader_parameter("assembly_progress") == 1.0 and screen._halo_material.get_shader_parameter("assembly_progress") == 1.0, "Disabling recall must restore both luminous layers")
	screen.seek_time(-1)
	check(screen._display_material.get_shader_parameter("animation_time") == -1.0, "Negative authored time must restore the normal GPU clock")
	screen.collision_enabled = false
	screen.rebuild()
	check(not screen._generated_root.has_node("Collision"), "Disabling collision must remove all old screen solids")
	print("Concert screen component checks: ", "PASS" if failures == 0 else "FAIL")
	screen.free()
	sibling.free()
	restored.free()
	await process_frame
	quit(failures)
