@tool
class_name PainterlyConcertScreen
extends PainterlyConcertComponent
## A modular emissive VJ display. All graphics and sequencing run on the GPU.
const DISPLAY = preload("res://components/scenery/concert/display/concert_display.gdshader")
const HALO = preload("res://components/scenery/concert/display/display_halo.gdshader")
const PALETTES := [
	[Color("ee9576"), Color("68d6cb"), Color("a58bed"), Color("f2c977")],
	[Color("f28a62"), Color("e5c666"), Color("bd6785"), Color("72b8af")],
	[Color("76dcea"), Color("a883ed"), Color("df82ba"), Color("a7cbe9")],
	[Color("eebcae"), Color("addbd0"), Color("c2b6e7"), Color("eddaa5")]
]

@export_group("Display Shape")
@export var display_size := Vector2(5.4, 2.6):
	set(value):
		display_size = value.clamp(Vector2(1.2, 0.8), Vector2(16, 8))
		_request_rebuild()
## Bottom of the luminous canvas above the component's ground-level root.
@export_range(0.25, 4.0, 0.05) var bottom_height: float = 0.45:
	set(value):
		bottom_height = clampf(value, 0.25, 4)
		_request_rebuild()
@export var supports_enabled: bool = true:
	set(value):
		supports_enabled = value
		_request_rebuild()

@export_group("Visual Sequence")
@export_enum("Auto Mix", "Liquid Pigment", "Kaleidoscope", "Brush Bars", "Paper Prisms", "Orbiting Halos", "Painted Sunburst") var pattern_mode: int = 0:
	set(value):
		pattern_mode = clampi(value, 0, 6)
		_update_display()
@export_range(0.0, 180.0, 1.0) var beat_bpm: float = 120.0:
	set(value):
		beat_bpm = clampf(value, 0, 180)
		_update_display()
## One beat gives two graphics per second at 120 BPM. Zero BPM holds the family.
@export_range(0.5, 8.0, 0.5) var beats_per_pattern: float = 1.0:
	set(value):
		beats_per_pattern = clampf(value, 0.5, 8)
		_update_display()
## Zero freezes the full image, including the automatic sequence and liquid motion.
@export_range(0.0, 3.0, 0.05) var playback_speed: float = 1.0:
	set(value):
		playback_speed = clampf(value, 0, 3)
		_update_display()
@export_range(0.02, 0.4, 0.01) var transition_duration: float = 0.12:
	set(value):
		transition_duration = clampf(value, 0.02, 0.4)
		_update_display()

@export_group("Screen Pigment and Light")
@export_enum("Aurora", "Ember", "Electric", "Dream Pastel", "Custom") var palette: int = 0:
	set(value):
		palette = clampi(value, 0, 4)
		_update_display()
@export var custom_colors := PackedColorArray([Color("ee9576"), Color("68d6cb"), Color("a58bed"), Color("f2c977")]):
	set(value):
		custom_colors = value
		_update_display()
@export var ink_color := Color("20243a"):
	set(value):
		ink_color = value
		_update_display()
@export_range(0.0, 2.0, 0.05) var brightness: float = 1.1:
	set(value):
		brightness = clampf(value, 0, 2)
		_update_display()
@export_range(0.0, 2.0, 0.05) var emission_strength: float = 0.55:
	set(value):
		emission_strength = clampf(value, 0, 2)
		_update_display()
@export_range(0.0, 1.0, 0.05) var paint_amount: float = 0.38:
	set(value):
		paint_amount = clampf(value, 0, 1)
		_update_display()
@export var halo_enabled: bool = true:
	set(value):
		halo_enabled = value
		_request_rebuild()

var _display_material: ShaderMaterial
var _halo_material: ShaderMaterial
var _time_override: float = -1.0

func _build_geometry() -> Dictionary:
	var config := _config()
	config.display_size = display_size
	config.bottom_height = bottom_height
	config.supports_enabled = supports_enabled
	return GEOMETRY.new().display(config)

func _build_details() -> void:
	_display_material = ShaderMaterial.new()
	_display_material.shader = DISPLAY
	var face := QuadMesh.new()
	face.size = display_size
	var panel := _add_visual("DisplayFace", face, _display_material)
	panel.position = Vector3(0, bottom_height + display_size.y * 0.5, 0.112)
	_halo_material = null
	if halo_enabled:
		_halo_material = ShaderMaterial.new()
		_halo_material.shader = HALO
		var glow := QuadMesh.new()
		glow.size = display_size + Vector2.ONE
		var halo := _add_visual("SoftGlow", glow, _halo_material)
		halo.position = Vector3(0, bottom_height + display_size.y * 0.5, -0.13)
	_update_display()

func _update_display() -> void:
	if not _display_material:
		return
	var colors: Array = PALETTES[palette] if palette < 4 else Array(custom_colors)
	for index in range(4):
		var color: Color = colors[index] if index < colors.size() else PALETTES[0][index]
		_display_material.set_shader_parameter("color_" + ["a", "b", "c", "d"][index], color)
	for key in ["display_size", "pattern_mode", "beat_bpm", "beats_per_pattern", "playback_speed", "transition_duration", "brightness", "emission_strength", "paint_amount", "ink_color"]:
		_display_material.set_shader_parameter(key, get(key))
	_display_material.set_shader_parameter("pattern_seed", float(prop_seed))
	_display_material.set_shader_parameter("animation_time", _time_override)
	if _halo_material:
		_halo_material.set_shader_parameter("display_size", display_size)
		_halo_material.set_shader_parameter("brightness", brightness)
		var color: Color = colors[2] if colors.size() > 2 else PALETTES[0][2]
		_halo_material.set_shader_parameter("halo_color", color.lightened(0.24))

## Drives graphics from a supplied visual clock, e.g. an authored music cue or preview.
## A negative value returns to the normal GPU clock. This does not add a process callback.
func seek_time(seconds: float) -> void:
	_time_override = seconds
	_update_display()
