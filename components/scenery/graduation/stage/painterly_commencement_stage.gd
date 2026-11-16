@tool
class_name PainterlyCommencementStage
extends PainterlyStage
## The tested walkable concert deck, dressed for a quiet open-air ceremony.
const CEREMONY = preload("res://components/scenery/graduation/shared/ceremony_geometry.gd")
const FABRIC = preload("res://components/scenery/graduation/shared/ceremony_fabric.gdshader")
@export_group("Ceremony")
@export var banners_enabled: bool = true:
	set(value):
		banners_enabled=value
		_request_rebuild()
## When disabled, both banners keep the stage's Accent / Trim palette.
@export var individual_banner_colors := false:
	set(value):
		individual_banner_colors=value
		_request_rebuild()
@export var left_banner_color := Color("425963"):
	set(value):
		left_banner_color=value
		_request_rebuild()
@export var left_banner_trim := Color("cfb070"):
	set(value):
		left_banner_trim=value
		_request_rebuild()
@export var right_banner_color := Color("425963"):
	set(value):
		right_banner_color=value
		_request_rebuild()
@export var right_banner_trim := Color("cfb070"):
	set(value):
		right_banner_trim=value
		_request_rebuild()
@export_range(0.0,0.12,0.005) var banner_wind: float = 0.045:
	set(value):
		banner_wind=clampf(value,0,0.12)
		if _fabric_material:
			_fabric_material.set_shader_parameter("wind_strength",banner_wind)
var _fabric_material: ShaderMaterial

func _ceremony_config() -> Dictionary:
	var c := _config()
	c.merge({"footprint":footprint,"deck_height":deck_height,"ramp_enabled":ramp_enabled,"ramp_width":minf(ramp_width,footprint.x-0.3),"banners_enabled":banners_enabled})
	if individual_banner_colors:
		c.merge({"left_banner_color":left_banner_color,"left_banner_trim":left_banner_trim,"right_banner_color":right_banner_color,"right_banner_trim":right_banner_trim})
	return c

func _build_geometry() -> Dictionary:
	var data := super._build_geometry()
	var additions: Dictionary = CEREMONY.new().commencement_hardware(_ceremony_config())
	var s := SurfaceTool.new()
	s.begin(Mesh.PRIMITIVE_TRIANGLES)
	s.append_from(data.mesh,0,Transform3D.IDENTITY)
	s.append_from(additions.mesh,0,Transform3D.IDENTITY)
	s.index()
	data.mesh=s.commit()
	data.colliders.append_array(additions.colliders)
	data.anchors.merge(additions.anchors,true)
	return data

func _build_details() -> void:
	_fabric_material=null
	if banners_enabled:
		_fabric_material=ShaderMaterial.new()
		_fabric_material.shader=FABRIC
		_fabric_material.set_shader_parameter("banner_top",deck_height+3.10)
		_fabric_material.set_shader_parameter("wind_strength",banner_wind)
		var visual := _add_visual("CeremonyBanners",CEREMONY.new().banners(_ceremony_config()).mesh,_fabric_material)
		visual.custom_aabb=visual.mesh.get_aabb().grow(0.14)

func seek_time(seconds: float) -> void:
	if _fabric_material:
		_fabric_material.set_shader_parameter("animation_time",seconds)
