@tool
class_name PainterlyLimestoneKarst
extends PainterlyVietnamPiece
## Seeded limestone scenery with rounded peaks or faceted coastal cliffs.
signal scenery_changed

@export_enum("Rounded Peaks", "Faceted Cliffs") var formation_profile := 0:
	set(value):
		formation_profile = clampi(value, 0, 1)
		_request_rebuild()
## Only used by the Faceted Cliffs profile.
@export_enum("Weathered", "Split Ridge", "Spire", "Shelved Bluff") var contour: int = BUILDER.KarstContour.WEATHERED:
	set(value):
		contour = value
		_request_rebuild()
@export var footprint := Vector2(5.5,4.4):
	set(value):
		footprint = value.clamp(Vector2(2,2),Vector2(15,12))
		_request_rebuild()
@export_range(3.0,22.0,0.5) var karst_height := 9.0:
	set(value):
		karst_height = clampf(value,3,22)
		_request_rebuild()
@export_range(1,3,1) var peaks := 2:
	set(value):
		peaks = clampi(value,1,3)
		_request_rebuild()

func _ready() -> void:
	ground_exclusion_changed.connect(scenery_changed.emit)
	super._ready()

func _build_geometry() -> Dictionary:
	var c := _config()
	c.merge({"footprint":footprint,"karst_height":karst_height,"peaks":peaks,"contour":contour})
	var builder := BUILDER.new()
	if formation_profile == 1:
		return builder.faceted_karst(c)
	return builder.karst(c)
