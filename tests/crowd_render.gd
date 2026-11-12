extends SceneTree
## Renders the reusable preview and verifies that GPU idle motion changes its silhouettes.
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)

func snapshot(path: String = "") -> Image:
	await process_frame
	await RenderingServer.frame_post_draw
	var picture := root.get_texture().get_image()
	if not path.is_empty():
		picture.save_png(path)
	return picture

func pixel_changes(first: Image, second: Image) -> int:
	first.convert(Image.FORMAT_RGBA8)
	second.convert(Image.FORMAT_RGBA8)
	var a := first.get_data()
	var b := second.get_data()
	var changed := 0
	for index in range(0, a.size(), 4):
		if absi(int(a[index]) - int(b[index])) + absi(int(a[index + 1]) - int(b[index + 1])) + absi(int(a[index + 2]) - int(b[index + 2])) > 12:
			changed += 1
	return changed

func run() -> void:
	root.content_scale_size = Vector2i(1600, 1000)
	var stage: Node3D = load("res://scenes/previews/crowd_preview.tscn").instantiate()
	root.add_child(stage)
	await create_timer(0.3).timeout
	var crowds: Array[PainterlyCrowd] = [stage.get_node("Display/LooseGathering"), stage.get_node("Display/StandingAudience")]
	for crowd in crowds:
		check(crowd.generated_count == crowd.count, "Both preview configurations must contain their advertised counts")
		crowd._material.set_shader_parameter("preview_time", 0.0)
	# Freeze the real avatars so image differences isolate crowd motion.
	for actor: MemoryExplorer in [stage.get_node("Display/Soren"), stage.get_node("Display/Vivian")]:
		actor.animation_player.pause()
	var first := await snapshot()
	for crowd in crowds:
		crowd._material.set_shader_parameter("preview_time", 3.0)
	var second := await snapshot("res://docs/crowd-preview.png")
	var moving := pixel_changes(first, second)
	check(moving > 150, "GPU idle motion must be visible without moving the feet")
	for crowd in crowds:
		crowd.motion_strength = 0
	var still_a := await snapshot()
	for crowd in crowds:
		crowd._material.set_shader_parameter("preview_time", 8.0)
	var still_b := await snapshot()
	var still := pixel_changes(still_a, still_b)
	check(still < 15, "Zero motion strength must keep the crowd still as time advances")
	for crowd in crowds:
		crowd.pose_strength = 0
	var neutral := await snapshot()
	var posing := pixel_changes(still_b, neutral)
	check(posing > 1500, "Independent GPU poses must visibly change arms and stances on the shared meshes")
	for crowd in crowds:
		crowd.pose_strength = 1
		crowd.motion_strength = 0.45
	# Gameplay-scale detail showing the same figures with both actual explorers.
	stage.get_node("Display/StandingAudience").hide()
	var gathering: PainterlyCrowd = stage.get_node("Display/LooseGathering")
	gathering.position = Vector3(0.1, 0, -0.2)
	gathering.count = 12
	gathering.footprint = Vector2(3.7, 2.2)
	gathering.rebuild()
	stage.get_node("Camera3D").size = 3.5
	stage.get_node("Camera3D").position += Vector3(0.4, 0.1, 0.4)
	stage.get_node("Display/Soren").position.z = 1.5
	stage.get_node("Display/Vivian").position.z = 1.5
	stage.get_node("Captions/LooseCaption").hide()
	stage.get_node("Captions/AudienceCaption").hide()
	stage.get_node("Captions/ExplorerCaption").hide()
	stage.get_node("Captions/Subtitle").text = "Gameplay camera scale  /  both explorers beside the crowd"
	await snapshot("res://docs/crowd-detail.png")
	print("Crowd GPU: ", "PASS" if failures == 0 else "FAIL", " | animated pixels: ", moving, " | still pixels: ", still, " | pose pixels: ", posing)
	stage.free()
	await process_frame
	quit(failures)
