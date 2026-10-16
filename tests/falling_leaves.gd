extends SceneTree
var failures: int=0
func _initialize() -> void:
	call_deferred("run")
func check(condition: bool,message: String) -> void:
	if not condition:
		push_error(message)
		failures+=1
func run() -> void:
	var tree: PainterlyTree=load("res://components/foliage/painterly_tree.tscn").instantiate()
	# Isolate the no-emission baseline from editable component scene defaults.
	tree.falling_leaf_count = 0
	root.add_child(tree)
	check(not tree.has_node("FallingLeaves"),"Default trees must have no falling-leaf draw call")
	var canopy:=tree.get_node("Canopy")
	tree.falling_leaf_count=12
	var leaves: MultiMeshInstance3D=tree.get_node("FallingLeaves")
	check(leaves.multimesh.instance_count==12 and leaves.multimesh.mesh.get_faces().size()/3==10,"Count must allocate one cheap leaf batch")
	check(tree.get_node("Canopy")==canopy,"Count must preserve approved canopy geometry")
	tree.falling_leaf_rate=0.0
	check(not leaves.visible,"Zero rate must disable emission")
	tree.falling_leaf_rate=0.65
	check(leaves.visible and tree.get_node("FallingLeaves")==leaves,"Rate changes must preserve the batch")
	tree.palette_preset=6
	check(tree._falling_material.get_shader_parameter("leaf_color")==tree.palette.leaf_color,"Falling leaves must follow palette selection")
	var packed:=PackedScene.new()
	packed.pack(tree)
	var restored: PainterlyTree=packed.instantiate()
	root.add_child(restored)
	check(restored.falling_leaf_count==12 and restored.falling_leaf_rate==0.65 and restored.has_node("FallingLeaves"),"Leaf settings must survive saving")
	restored.free()
	for kind in range(6):
		tree.tree_type=kind
		tree.rebuild()
		check(tree.has_node("FallingLeaves") and tree._falling_material.get_shader_parameter("max_height")>0.4,"All tree variants must supply canopy origins")
	tree.leaf_sprays_per_cluster=0
	tree.rebuild()
	check(not tree.has_node("FallingLeaves"),"Bare trees must not emit leaves")
	tree.free()
	print("Falling leaf checks: ","PASS" if failures==0 else "FAIL")
	quit(failures)
