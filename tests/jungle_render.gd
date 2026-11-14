extends SceneTree
## Rendered botanical silhouettes, tip motion, response and a dense garden preview.
var failures := 0
const SCENES = [
	"res://components/foliage/jungle/painterly_palm.tscn",
	"res://components/foliage/jungle/painterly_palm.tscn",
	"res://components/foliage/jungle/painterly_tropical_broadleaf.tscn",
	"res://components/foliage/jungle/painterly_tropical_broadleaf.tscn",
	"res://components/foliage/jungle/painterly_tropical_broadleaf.tscn",
	"res://components/foliage/jungle/painterly_fern.tscn",
	"res://components/foliage/jungle/painterly_bamboo.tscn"
]

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)

func snapshot(path: String = "") -> Image:
	await process_frame
	await RenderingServer.frame_post_draw
	var result := root.get_texture().get_image()
	if not path.is_empty():
		result.save_png(path)
	return result

func changes(a: Image, b: Image) -> int:
	var first := a.get_data()
	var second := b.get_data()
	var changed := 0
	for index in range(0, first.size(), 4):
		if absi(int(first[index]) - int(second[index])) + absi(int(first[index + 1]) - int(second[index + 1])) + absi(int(first[index + 2]) - int(second[index + 2])) > 24:
			changed += 1
	return changed

func run() -> void:
	root.content_scale_size = Vector2i(1440, 900)
	var stage: Node3D = load("res://tests/scenes/jungle_test.tscn").instantiate()
	root.add_child(stage)
	await process_frame
	await process_frame
	var study: Node3D = stage.subject
	for child in study.get_children():
		if child is PainterlyJunglePlant:
			child.react_to_explorers = false
			child.seek_time(1.2)
		elif child is PainterlyBush:
			child.wind_strength = 0
			child.react_to_explorers = false
		elif child is PainterlyGrassPatch:
			child.wind_strength = 0
			child.react_to_explorer = false
	study.get_node("Fountain").seek_time(1.2)
	var actor: MemoryExplorer = stage.get_node("Explorer")
	actor.set_physics_process(false)
	actor.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	actor.reset_physics_interpolation()
	actor.animation_player.pause()
	stage.get_node("Controls").hide()
	await create_timer(0.3).timeout
	await snapshot("res://docs/previews/jungle-overview.png")
	var camera: Camera3D = stage.get_node("Camera3D")
	camera.size = 3.5
	camera.position = Vector3(5, 5, 10)
	camera.look_at(Vector3(0, 0.9, 1.35))
	await snapshot("res://docs/previews/jungle-walkway.png")
	study.hide()
	# Render every selectable silhouette against the same neutral floor.
	var sheet := Image.create(1200, 750, false, Image.FORMAT_RGBA8)
	sheet.fill(Color(0.94, 0.935, 0.89))
	var last: PainterlyJunglePlant
	for form in range(7):
		if is_instance_valid(last):
			last.free()
		last = load(SCENES[form]).instantiate()
		last.plant_form = form
		last.react_to_explorers = false
		root.add_child(last)
		last.seek_time(1.2)
		camera.size = 6.8 if form <= 1 else 3.5
		camera.position = Vector3(7, 7, 13)
		camera.look_at(Vector3(0, 1.90 if form <= 1 else (1.25 if form == 6 else 0.65), 0))
		actor.position = Vector3(-1.15, 0.02, 0.8)
		actor.reset_physics_interpolation()
		var frame := await snapshot("res://docs/previews/jungle-form-%d.png" % form)
		var tile := frame.duplicate() as Image
		tile.convert(Image.FORMAT_RGBA8)
		tile.resize(400, 250, Image.INTERPOLATE_LANCZOS)
		sheet.blit_rect(tile, Rect2i(0, 0, 400, 250), Vector2i((form % 3) * 400, (form / 3) * 250))
	sheet.save_png("res://docs/previews/jungle-plant-forms.png")
	last.free()
	var fern: PainterlyJunglePlant = load(SCENES[5]).instantiate()
	fern.react_to_explorers = false
	root.add_child(fern)
	fern.wind_strength = 0.12
	camera.size = 3.5
	camera.look_at(Vector3(0, 0.5, 0))
	fern.seek_time(0)
	var still := await snapshot()
	fern.seek_time(2)
	var moved := await snapshot()
	var motion := changes(still, moved)
	check(motion > 400, "Fronds must visibly sway at a real shader clock")
	fern.wind_strength = 0
	var held := await snapshot()
	fern.seek_time(8)
	check(changes(held, await snapshot()) < 15, "Zero wind and disabled response must produce a stable image")
	fern._canopy_material.set_shader_parameter("disturbance_strength", 0.3)
	fern._canopy_material.set_shader_parameter("disturbance_sources", PackedVector4Array([Vector4(0.25, 0, 0, 1), Vector4.ZERO]))
	check(changes(held, await snapshot()) > 400, "Nearby explorer disturbance must visibly bend the fronds")
	print("Jungle Mobile render: ", "PASS" if failures == 0 else "FAIL", " | moving fern pixels: ", motion)
	fern.free()
	stage.free()
	await process_frame
	quit(failures)
