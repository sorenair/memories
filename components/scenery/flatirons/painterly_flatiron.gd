@tool
class_name PainterlyFlatiron
extends PainterlyConcertComponent
## Inclined sandstone landmark with jagged shoulders and recessed fractures.
const BUILDER = preload("res://components/scenery/flatirons/flatiron_geometry.gd")
const STONE_PAINT = preload("res://components/scenery/flatirons/flatiron_paint.gdshader")
const STONE_PRESETS = PainterlyBoulder.PRESETS

@export_group("Flatiron Shape")
@export_enum("Classic Slab", "Split Crest", "Broken Ridge") var formation_type: int = 0:
	set(value):
		formation_type = clampi(value,0,2)
		_request_rebuild()
@export_range(3.0,35.0,0.5) var formation_width: float = 9.0:
	set(value):
		formation_width = clampf(value,3,35)
		_request_rebuild()
@export_range(4.0,60.0,0.5) var formation_height: float = 16.0:
	set(value):
		formation_height = clampf(value,4,60)
		_request_rebuild()
@export_range(0.6,8.0,0.1) var thickness: float = 3.2:
	set(value):
		thickness = clampf(value,0.6,8)
		_request_rebuild()
## Angle above horizontal. Crest rises toward local -Z; +Z is the front/toe.
@export_range(40.0,80.0,1.0) var slope_angle: float = 55.0:
	set(value):
		slope_angle = clampf(value,40,80)
		_request_rebuild()
@export_range(0.0,1.0,0.05) var jaggedness: float = 0.75:
	set(value):
		jaggedness = clampf(value,0,1)
		_request_rebuild()
@export_range(1,7,1) var fracture_count: int = 4:
	set(value):
		fracture_count = clampi(value,1,7)
		_request_rebuild()
@export_range(0.0,1.0,0.05) var burial: float = 0.35:
	set(value):
		burial = clampf(value,0,1)
		_request_rebuild()
@export_group("Stone Palette")
@export_enum("Custom", "Granite", "Sandstone", "Slate", "Terracotta", "Chalk", "Dream Violet") var palette_preset: int = 4:
	set(value):
		palette_preset = clampi(value,0,6)
		if palette_preset!=0:
			_applying_preset = true
			palette = STONE_PRESETS[palette_preset].duplicate() as StonePalette
			_applying_preset = false
		notify_property_list_changed()
@export var palette: StonePalette:
	set(value):
		if palette and palette.changed.is_connected(_on_palette_changed):
			palette.changed.disconnect(_on_palette_changed)
		palette = value
		if palette: palette.changed.connect(_on_palette_changed)
		if not _applying_preset: palette_preset = 0
		_apply_material()
@export_range(0.0,0.20,0.01) var plane_variation: float = 0.14:
	set(value):
		plane_variation = clampf(value,0,0.2)
		_apply_material()

var _applying_preset: bool = false

func _init() -> void:
	_applying_preset = true
	palette = STONE_PRESETS[4].duplicate() as StonePalette
	_applying_preset = false
	visibility_distance = 140.0

func _validate_property(property: Dictionary) -> void:
	if property.name in ["body_color","accent_color","trim_color","pigment_strength"]:
		property.usage = PROPERTY_USAGE_NONE
	if property.name=="palette" and palette_preset!=0:
		property.usage = property.usage & ~PROPERTY_USAGE_STORAGE

func _on_palette_changed() -> void:
	palette_preset = 0
	_apply_material()

func _config() -> Dictionary:
	return {"prop_seed":prop_seed,"formation_type":formation_type,"formation_width":formation_width,"formation_height":formation_height,"thickness":thickness,"slope_angle":slope_angle,"jaggedness":jaggedness,"fracture_count":fracture_count,"burial":burial}

func _build_geometry() -> Dictionary:
	return BUILDER.new().create(_config())

func _apply_material() -> void:
	if not _material: return
	_material.shader = STONE_PAINT
	var colors: StonePalette = palette if palette else STONE_PRESETS[4]
	for key in [&"base_color",&"shadow_color",&"mid_color",&"highlight_color"]:
		_material.set_shader_parameter(key,colors.get(key))
	_material.set_shader_parameter("plane_variation",plane_variation)

func _build_details() -> void:
	if contact_shadow_enabled:
		var shadow: MeshInstance3D = _generated_root.get_node("ContactShadow")
		shadow.mesh.size = Vector2(formation_width*1.15,thickness*1.9)
		shadow.position = Vector3(0,0.012,-thickness*0.45)
