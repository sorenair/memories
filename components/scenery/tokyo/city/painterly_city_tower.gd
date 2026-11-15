@tool
class_name PainterlyCityTower
extends PainterlyTokyoPiece
const CITY = preload("res://components/scenery/tokyo/shared/city_geometry.gd")
const DISPLAY = preload("res://components/scenery/concert/display/concert_display.gdshader")
const HALO = preload("res://components/scenery/concert/display/display_halo.gdshader")
@export_group("Tower Shape")
@export_enum("Slab","Setback Tower","Chamfered Corner") var profile: int = 0:
	set(value):
		profile=clampi(value,0,2)
		_request_rebuild()
@export var footprint := Vector2(4.8,4.2):
	set(value):
		footprint=value.clamp(Vector2(3,3),Vector2(10,8))
		_request_rebuild()
@export_range(4,32,1) var floors: int = 10:
	set(value):
		floors=clampi(value,4,32)
		_request_rebuild()
@export_range(1.1,2.2,0.05) var floor_height: float = 1.35:
	set(value):
		floor_height=clampf(value,1.1,2.2)
		_request_rebuild()
@export_range(0.0,1.0,0.05) var lit_fraction: float = 0.64:
	set(value):
		lit_fraction=clampf(value,0,1)
		_request_rebuild()
@export var sign_text: String = "TOKYO":
	set(value):
		sign_text=value.left(20)
		_request_rebuild()
@export_group("Billboard")
@export var screen_enabled: bool = true:
	set(value):
		screen_enabled=value
		_request_rebuild()
@export var halo_enabled: bool = true:
	set(value):
		halo_enabled=value
		_request_rebuild()
@export_range(0.0,2.0,0.05) var screen_speed: float = 0.65:
	set(value):
		screen_speed=clampf(value,0,2)
		_update_screen()
var _display_material: ShaderMaterial
var _time_override: float = -1.0

func screen_size() -> Vector2:
	return Vector2(footprint.x*0.86,minf(floors*floor_height*0.23,4.5))

func screen_y() -> float:
	return maxf(floor_height*2.5,floors*floor_height*0.20)

func _build_geometry() -> Dictionary:
	var c := _config()
	c.merge({"profile":profile,"footprint":footprint,"floors":floors,"floor_height":floor_height,"lit_fraction":lit_fraction,"screen_enabled":screen_enabled,"screen_size":screen_size(),"screen_y":screen_y(),"sign_text":sign_text})
	return CITY.new().tower(c)

func _build_details() -> void:
	_display_material=null
	if not screen_enabled:
		return
	_display_material=ShaderMaterial.new()
	_display_material.shader=DISPLAY
	_update_screen()
	var mesh := QuadMesh.new()
	mesh.size=screen_size()
	var panel := _add_visual("Billboard",mesh,_display_material)
	panel.position=Vector3(0,screen_y(),footprint.y*0.5+0.184)
	if halo_enabled:
		var halo := ShaderMaterial.new()
		halo.shader=HALO
		halo.set_shader_parameter("display_size",screen_size())
		halo.set_shader_parameter("halo_color",accent_color.lightened(0.15))
		halo.set_shader_parameter("brightness",0.7)
		var glow := QuadMesh.new()
		glow.size=screen_size()+Vector2.ONE
		var visual := _add_visual("BillboardHalo",glow,halo)
		visual.position=panel.position-Vector3.BACK*0.012

func _update_screen() -> void:
	if not _display_material:
		return
	var colors := [accent_color,Color("e3a0b5"),Color("9b9cd6"),Color("dfc788")]
	for i in range(4):
		_display_material.set_shader_parameter("color_"+["a","b","c","d"][i],colors[i])
	_display_material.set_shader_parameter("display_size",screen_size())
	_display_material.set_shader_parameter("pattern_mode",0)
	_display_material.set_shader_parameter("beat_bpm",45.0)
	_display_material.set_shader_parameter("beats_per_pattern",2.0)
	_display_material.set_shader_parameter("playback_speed",screen_speed)
	_display_material.set_shader_parameter("brightness",0.95)
	_display_material.set_shader_parameter("emission_strength",0.35)
	_display_material.set_shader_parameter("paint_amount",0.55)
	_display_material.set_shader_parameter("pattern_seed",float(prop_seed))
	_display_material.set_shader_parameter("animation_time",_time_override)

func seek_time(seconds: float) -> void:
	_time_override=seconds
	_update_screen()
