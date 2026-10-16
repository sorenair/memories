extends SceneTree
var failures: int=0
func _initialize() -> void:
	call_deferred("run")
func check(condition: bool,message: String) -> void:
	if not condition:
		push_error(message)
		failures+=1
func run() -> void:
	var fire: PainterlyFire=load("res://components/vfx/fire/painterly_fire.tscn").instantiate()
	root.add_child(fire)
	check(fire.get_children().is_empty() and fire.get_children(true).size()==3,"Generated fire must remain three internal batches")
	check(fire.get_node("Embers").multimesh.instance_count==fire.ember_count,"Ember Count must control the pool")
	check(not fire.is_processing() and not fire.is_physics_processing(),"Animation must require no frame callbacks")
	var flame:=fire.get_node("Flame")
	fire.flame_size=Vector2(1.3,2.1)
	fire.core_color=Color("a3f5df")
	fire.intensity=0.0
	check(not flame.visible and not fire.get_node("Embers").visible,"Zero intensity must hide all fire")
	fire.intensity=1.0
	check(fire.get_node("Flame")==flame and flame.visible,"Size and palette changes must preserve geometry")
	check(flame.material_override.get_shader_parameter("core_color")==fire.core_color,"Palette edits must reach the flame")
	var bounds: AABB=flame.custom_aabb
	check(bounds.has_point(Vector3(0,fire.flame_size.y*2.1,0)),"Bounds must include the ember plume")
	var packed:=PackedScene.new()
	packed.pack(fire)
	var restored: PainterlyFire=packed.instantiate()
	root.add_child(restored)
	check(restored.flame_size==fire.flame_size and restored.core_color==fire.core_color and restored.ember_count==fire.ember_count,"Fire controls must survive saving")
	restored.free()
	fire.ember_count=0
	fire.rebuild()
	check(not fire.has_node("Embers") and fire.get_children(true).size()==2,"Zero embers must remove their draw call")
	fire.glow_strength=0.0
	check(not fire.get_node("GroundGlow").visible,"Zero glow must hide the ground wash")
	fire.free()
	print("Fire component checks: ","PASS" if failures==0 else "FAIL")
	quit(failures)
