extends SceneTree
var failures: int=0
func _initialize() -> void:
	call_deferred("run")
func check(condition: bool,message: String) -> void:
	if not condition:
		push_error(message)
		failures+=1
func run() -> void:
	var world: Node3D=load("res://scenes/world/memory_world.tscn").instantiate()
	root.add_child(world)
	await process_frame
	await process_frame
	var rain: PainterlyRain=world.get_node("Memory/Environment/ClearingRain")
	check(rain._streaks.multimesh.instance_count==rain.drop_count,"Requested drops must share one batch")
	check(rain._splashes.multimesh.instance_count==rain.splash_count,"Requested impacts must share one batch")
	check(rain.get_children().is_empty(),"Generated weather must not serialize")
	check(not rain.is_processing() and not rain.is_physics_processing(),"Rain must require no frame callbacks")
	check(rain._streaks.multimesh.mesh.get_faces().size()/3==2,"Each drop must retain a two-triangle budget")
	var strokes:=rain._streaks
	rain.intensity=0.0
	check(not rain._streaks.visible and not rain._splashes.visible,"Zero intensity must hide both batches")
	rain.intensity=0.7
	rain.wind=Vector2(1,0.3)
	check(rain._streaks==strokes and rain._streaks.visible,"Motion edits must preserve geometry")
	var packed:=PackedScene.new()
	packed.pack(rain)
	var restored: PainterlyRain=packed.instantiate()
	restored.platform=NodePath()
	restored.water_bodies=[]
	root.add_child(restored)
	await process_frame
	await process_frame
	check(restored.drop_count==rain.drop_count and restored.wind==rain.wind,"Weather controls must survive saving")
	restored.free()
	rain.splash_count=0
	rain.rebuild()
	check(rain._splashes==null and rain._streaks!=null,"Impacts must be independently optional")
	rain.drop_count=0
	rain.rebuild()
	check(rain.get_children(true).is_empty(),"Zero count must remove both draw calls")
	world.free()
	print("Rain component checks: ","PASS" if failures==0 else "FAIL")
	quit(failures)
