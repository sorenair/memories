extends SceneTree
var failures: int=0
func _initialize() -> void:
	call_deferred("run")
func check(condition: bool,message: String) -> void:
	if not condition:
		push_error(message)
		failures+=1
func run() -> void:
	var snow: PainterlySnow=load("res://components/weather/snow/painterly_snow.tscn").instantiate()
	root.add_child(snow)
	check(snow._flakes.multimesh.instance_count==snow.flake_count,"Count must control a single flake batch")
	check(snow.get_children().is_empty() and snow.get_children(true).size()==1,"Generated flakes must remain internal")
	check(not snow.is_processing() and not snow.is_physics_processing(),"Snow must not require frame callbacks")
	check(snow._flakes.multimesh.mesh.get_faces().size()/3==2,"Flakes must retain two triangles each")
	var batch:=snow._flakes
	snow.intensity=0.0
	check(not batch.visible,"Zero intensity must hide snow")
	snow.intensity=0.7
	snow.wind=Vector2(1,0.4)
	snow.flutter=0.8
	snow.snow_height=12.0
	snow.flake_size=Vector2(0.08,0.03)
	check(snow._flakes==batch and batch.visible,"Motion and size edits must preserve the batch")
	check(snow.flake_size==Vector2(0.03,0.08),"Size range must remain ordered")
	check(batch.custom_aabb.has_point(Vector3(snow.footprint.x*0.5+1.5,12,0)),"Bounds must cover volume and drift")
	var packed:=PackedScene.new()
	packed.pack(snow)
	var restored: PainterlySnow=packed.instantiate()
	root.add_child(restored)
	check(restored.flake_count==snow.flake_count and restored.wind==snow.wind and restored.flake_size==snow.flake_size,"Snow controls must survive saving")
	restored.free()
	snow.flake_count=0
	snow.rebuild()
	check(snow.get_children(true).is_empty(),"Zero count must remove the draw call")
	snow.free()
	print("Snow component checks: ","PASS" if failures==0 else "FAIL")
	quit(failures)
