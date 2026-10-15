extends SceneTree
## Requires graphics: godot --path . --script tests/foliage_palettes.gd
var failures: int = 0
func _initialize() -> void:
	call_deferred("run")
func check(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		failures += 1
func run() -> void:
	for component_name in ["painterly_grass_patch", "painterly_tree", "painterly_bush"]:
		var component: Node3D = load("res://components/foliage/%s.tscn" % component_name).instantiate()
		root.add_child(component)
		component.set_process(false)
		var nodes: Array[Node] = component.get_children(true)
		var buffers: Array[PackedFloat32Array] = []
		for node in nodes:
			if node is MultiMeshInstance3D:
				buffers.append(node.multimesh.buffer.duplicate())
		check(component.palette_preset == 1, component_name + ": default selector must be Summer Meadow")
		for preset in range(1, 10):
			component.palette_preset = preset
			check(component.palette_preset == preset, "Selector must retain selected preset")
			for material in component._palette_materials:
				for uniform in material.shader.get_shader_uniform_list():
					if StringName(uniform.name) in FoliagePalettes.COLOR_KEYS:
						var color: Color = material.get_shader_parameter(uniform.name)
						check(color.is_equal_approx(component.palette.get(uniform.name)), "Every palette-bearing material must update immediately")
			check(component.get_children(true) == nodes, "Palette changes must not rebuild geometry nodes")
			var index := 0
			for node in nodes:
				if node is MultiMeshInstance3D:
					check(node.multimesh.buffer == buffers[index], "Palette changes must preserve placement and painterly distribution")
					index += 1
		component.palette_preset = 6
		var packed := PackedScene.new()
		check(packed.pack(component) == OK, "Component must pack successfully")
		var restored: Node3D = packed.instantiate()
		root.add_child(restored)
		check(restored.palette_preset == 6, "Selected preset must survive scene packing")
		check(restored.palette.leaf_color.is_equal_approx(component.palette.leaf_color), "Preset colors must survive scene packing")
		var original: Color = restored.palette.leaf_color
		component.palette.leaf_color = Color(0.8, 0.2, 0.5)
		check(component.palette_preset == 0, "Editing preset colors must switch to Custom")
		check(restored.palette.leaf_color.is_equal_approx(original), "Preset edits must not recolor another instance")
		var custom := PackedScene.new()
		check(custom.pack(component) == OK, "Custom palette must pack")
		var restored_custom: Node3D = custom.instantiate()
		root.add_child(restored_custom)
		check(restored_custom.palette_preset == 0, "Custom mode must survive scene packing")
		check(restored_custom.palette.leaf_color.is_equal_approx(component.palette.leaf_color), "Custom colors must survive scene packing")
		component.palette = load("res://components/foliage/palettes/dusk.tres")
		check(component.palette_preset == 0, "Direct resource assignment must select Custom")
		component.queue_free()
		restored.queue_free()
		restored_custom.queue_free()
		await process_frame
	print("Foliage palette checks: ", "PASS" if failures == 0 else "FAIL")
	quit(failures)
