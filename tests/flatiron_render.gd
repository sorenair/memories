extends "res://tests/elk_render.gd"
func run() -> void:
	root.content_scale_size = Vector2i(1600,1000)
	var stage: Node3D = load("res://tests/scenes/flatiron_test.tscn").instantiate()
	root.add_child(stage)
	current_scene = stage
	await process_frame
	await process_frame
	for id in ["Explorer","Partner"]:
		var actor: MemoryExplorer = stage.get_node(id)
		actor.set_physics_process(false)
		actor.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
		actor.animation_player.pause()
		actor.reset_physics_interpolation()
	stage.get_node("Controls").hide()
	await shot("res://docs/previews/flatiron-forms.png")
	var setup: Node3D = stage.subject
	var rock: PainterlyFlatiron = setup.get_node("Classic")
	for component in setup.get_children(): component.visible = component==rock
	var actor: MemoryExplorer = stage.get_node("Explorer")
	actor.position = rock.position+Vector3(-1.5,0.03,2.6)
	actor.reset_physics_interpolation()
	var partner: MemoryExplorer = stage.get_node("Partner")
	partner.position = rock.position+Vector3(-0.35,0.03,2.6)
	partner.reset_physics_interpolation()
	var camera: Camera3D = stage.get_node("Camera3D")
	camera.size = 25.0
	camera.position = rock.position+Vector3(13,12,32)
	camera.look_at(rock.position+Vector3(0,8.0,-4.5))
	var first := await shot("res://docs/previews/flatiron-detail.png")
	rock.recall_enabled = true
	var recall: Node = rock.get_recall_controller()
	recall.set_process(false)
	recall.seek(0)
	check(changes(first,await shot())>10000,"Flatiron recall must visibly hide the rock")
	recall.seek(1)
	check(changes(first,await shot())<10,"Completed recall must restore the full stone material")
	rock.recall_enabled = false
	# A side view verifies real thickness and the backward incline.
	camera.position = rock.position+Vector3(28,12,10)
	camera.look_at(rock.position+Vector3(0,8.0,-4.2))
	await shot("res://docs/previews/flatiron-side.png")
	print("Flatiron Mobile render: ","PASS" if failures==0 else "FAIL")
	stage.free()
	await process_frame
	quit(failures)
