extends SceneTree
## Render the isolated stands to check that shader motion is confined to the crowd.
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)
func snapshot() -> Image:
	await RenderingServer.frame_post_draw
	var result := root.get_texture().get_image()
	result.resize(500,375)
	return result
func changed(a: Image, b: Image, mask: PackedByteArray) -> Vector2i:
	var first := a.get_data()
	var second := b.get_data()
	var counts := Vector2i.ZERO
	var channels := first.size() / mask.size()
	for pixel in mask.size():
		var offset: int = pixel * channels
		if maxi(absi(first[offset]-second[offset]),maxi(absi(first[offset+1]-second[offset+1]),absi(first[offset+2]-second[offset+2]))) <= 4:
			continue
		counts.x += 1
		if mask[pixel] == 0: counts.y += 1
	return counts
func run() -> void:
	root.content_scale_size = Vector2i(1000,750)
	var scene := Node3D.new()
	root.add_child(scene)
	var stands := load("res://components/scenery/stadium/painterly_stadium_stands.tscn").instantiate() as PainterlyStadiumStands
	stands.minnesota_branding = true
	scene.add_child(stands)
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 22.0
	scene.add_child(camera)
	var focus := Vector3(-44,6,-48)
	camera.position = focus+Vector3(13,42,38)
	camera.look_at(focus)
	var visual := stands.get_node("Visual") as MeshInstance3D
	var mesh := visual.mesh
	var arrays := mesh.surface_get_arrays(0)
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var kinds: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV2]
	var uv: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
	var regions := {}
	for index in vertices.size():
		if not is_equal_approx(kinds[index].x,7.0): continue
		var seed := uv[index]
		var at := camera.unproject_position(stands.to_global(vertices[index]))*0.5
		if not regions.has(seed): regions[seed] = Rect2(at,Vector2.ZERO)
		var region: Rect2 = regions[seed]
		region = region.expand(at)
		regions[seed] = region.expand(camera.unproject_position(stands.to_global(vertices[index]+Vector3.UP*stands.crowd_bounce_height))*0.5)
	check(regions.size()>100, "Crowd figures must have independent baked phases and rates")
	var mask := PackedByteArray()
	mask.resize(500*375)
	for region: Rect2 in regions.values():
		var bounds := Rect2i(region.grow(3.0)).intersection(Rect2i(0,0,500,375))
		for y in range(bounds.position.y,bounds.end.y):
			for x in range(bounds.position.x,bounds.end.x): mask[y*500+x] = 1
	stands.crowd_bounce_height = 0.0
	await create_timer(0.2).timeout
	var rest: Image = await snapshot()
	await create_timer(0.3).timeout
	var still: Image = await snapshot()
	check(changed(rest,still,mask).x == 0, "Zero bounce must give a completely still stadium")
	stands.crowd_bounce_height = 0.14
	await create_timer(0.2).timeout
	var first: Image = await snapshot()
	await create_timer(0.65).timeout
	var second: Image = await snapshot()
	var motion := changed(first,second,mask)
	check(motion.x>100 and motion.y==0, "Rendered crowd must move while every pixel outside the crowd stays still: %s" % motion)
	check(visual.mesh==mesh and not stands.is_processing() and not stands.is_physics_processing()
		and stands.get_children(true).size()==3, "Crowd controls must preserve the single mesh and add no nodes or CPU animation callbacks")
	first.save_png("/tmp/stadium-crowd-motion-a.png")
	second.save_png("/tmp/stadium-crowd-motion-b.png")
	print("Stadium crowd motion: ", "PASS" if failures==0 else "FAIL", " | figures: ",regions.size()," | moving pixels: ",motion.x," | outside crowd: ",motion.y)
	scene.free()
	await create_timer(0.2).timeout
	quit(failures)
