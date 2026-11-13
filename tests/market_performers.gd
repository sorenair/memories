extends SceneTree
## Verify real arm/instrument mesh clearance through a complete playing cycle.
const STAGE = preload("res://components/scenery/christmas_market/painterly_market_stage.tscn")
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)

func crosses(start: Vector3, end: Vector3, faces: PackedVector3Array) -> bool:
	var line_bounds := AABB(start,Vector3.ZERO).expand(end).grow(0.001)
	for i in range(0,faces.size(),3):
		var a := faces[i]
		var b := faces[i+1]
		var c := faces[i+2]
		var triangle_bounds := AABB(a,Vector3.ZERO).expand(b).expand(c).grow(0.001)
		if line_bounds.intersects(triangle_bounds) and Geometry3D.segment_intersects_triangle(start,end,a,b,c)!=null:
			return true
	return false

func run() -> void:
	var stage: PainterlyMarketStage = STAGE.instantiate()
	root.add_child(stage)
	stage.set_process(false)
	stage.performance_strength = 1.0
	check(stage._musicians.size()==3 and stage._rigs.size()==3,"The stage must have three complete musician rigs")
	var instruments: Array[PackedVector3Array] = []
	for actor in stage._musicians:
		instruments.append(actor.get_node("Instrument").mesh.get_faces())
		check(actor.get_node("LeftArm").get_child_count()==3 and actor.get_node("RightArm").get_child_count()==3,
			"Each musician must have exactly two connected arms and hands")
	# Test the maximum animation setting, not just the quieter scene default.
	for frame in 32:
		stage._apply_performance(frame/32.0*0.625)
		for musician in stage._musicians.size():
			var actor := stage._musicians[musician]
			var rig := stage._rigs[musician]
			for side in 2:
				var arm: Dictionary = rig.arms[side]
				var upper_end: Vector3 = arm.upper.transform*(Vector3.UP*stage.UPPER_LENGTH)
				var wrist: Vector3 = arm.fore.transform*(Vector3.UP*stage.FORE_LENGTH)
				check(upper_end.distance_to(arm.fore.position)<0.0001,"Elbows must remain attached throughout playing")
				check(wrist.distance_to(arm.hand.position)<0.0001,"Playing hands must remain attached to their forearms")
				for part in 2:
					var bone: MeshInstance3D = arm.upper if part==0 else arm.fore
					var length: float = stage.UPPER_LENGTH if part==0 else stage.FORE_LENGTH
					# Fingers intentionally contact strings/necks. The sleeves should
					# stay outside the solid instrument, including their visible width.
					var end_y := length if part==0 else length-0.075
					var radius := 0.057 if part==0 else 0.040
					for offset in [Vector3.ZERO,Vector3.RIGHT*radius,Vector3.LEFT*radius,Vector3.FORWARD*radius,Vector3.BACK*radius]:
						var a: Vector3 = bone.transform*(Vector3.UP*0.005+offset)
						var b: Vector3 = bone.transform*(Vector3.UP*end_y+offset)
						check(not crosses(a,b,instruments[musician]),"%s %s sleeve crosses the instrument at phase %d" % [actor.name,bone.get_parent().name+"/"+bone.name,frame])
			if musician==1:
				check(rig.bow.position.distance_to(rig.arms[1].hand.position+Vector3(0,0,-0.005))<0.0001,"The bow grip must follow the right hand without rotating through the violin")
	if "--capture" in OS.get_cmdline_user_args():
		root.content_scale_size = Vector2i(1600,900)
		var environment := WorldEnvironment.new()
		environment.environment = Environment.new()
		environment.environment.background_mode = Environment.BG_COLOR
		environment.environment.background_color = Color(0.94,0.935,0.89)
		root.add_child(environment)
		var camera := Camera3D.new()
		camera.projection = Camera3D.PROJECTION_ORTHOGONAL
		camera.size = 3.4
		camera.position = Vector3(4.5,4.6,6.5)
		root.add_child(camera)
		camera.look_at(Vector3(0,1.25,0.15))
		for frame in 4:
			stage._apply_performance(frame*0.15625)
			await process_frame
			await RenderingServer.frame_post_draw
			var path := "res://docs/previews/christmas-market-performers.png" if frame==0 else "/tmp/market-performers-%d.png" % frame
			root.get_texture().get_image().save_png(path)
	stage.free()
	await process_frame
	print("Market performer articulation: ","PASS" if failures==0 else "FAIL (%d)" % failures)
	quit(failures)
