@tool
class_name FoliagePalettes
extends RefCounted
## One preset order shared by grass, trees, and bushes. Custom preserves supplied resources.
const COLOR_KEYS = [&"root_color", &"shade_color", &"leaf_color", &"sun_color"]
const PRESETS = [
	null,
	preload("res://components/foliage/palettes/meadow.tres"),
	preload("res://components/foliage/palettes/spring.tres"),
	preload("res://components/foliage/palettes/autumn_gold.tres"),
	preload("res://components/foliage/palettes/autumn_red.tres"),
	preload("res://components/foliage/palettes/winter_frost.tres"),
	preload("res://components/foliage/palettes/dream_lavender.tres"),
	preload("res://components/foliage/palettes/dream_blue.tres"),
	preload("res://components/foliage/palettes/dream_rose.tres"),
	preload("res://components/foliage/palettes/dusk.tres"),
 ]

static func create_preset(index: int) -> GrassPalette:
	if index <= 0 or index >= PRESETS.size():
		return null
	# Preset edits stay local. Assign a custom resource explicitly to share edits.
	return PRESETS[index].duplicate() as GrassPalette

static func apply(material: ShaderMaterial, colors: GrassPalette) -> void:
	if not material or not colors:
		return
	# Bark uses only root_color; leaves and washes use all four gradient colors.
	for uniform in material.shader.get_shader_uniform_list():
		if StringName(uniform.name) in COLOR_KEYS:
			material.set_shader_parameter(uniform.name, colors.get(uniform.name))
