extends "res://scripts/follow_camera.gd"
## A steady walk between a short block-party reveal and the bar vignette.
@export var walking_size := 4.7
@export var party_size := 8.2
@export var bar_size := 6.1

const WALKING_OFFSET := Vector3(0, 0.95, -0.9)
var _party_view := false
var _bar_view := false

func _ready() -> void:
	framing_offset = WALKING_OFFSET
	$Camera3D.size = walking_size
	super._ready()

func _process(delta: float) -> void:
	if is_instance_valid(target):
		var at := target.get_global_transform_interpolated().origin
		var party_radius := 3.6 if _party_view else 2.5
		var bar_radius := 2.85 if _bar_view else 1.75
		_party_view = absf(at.z + 1.0) < party_radius and absf(at.x) < party_radius
		_bar_view = Vector2(at.x - 2.4, at.z + 30.1).length_squared() < bar_radius * bar_radius
		var size := walking_size
		var offset := WALKING_OFFSET
		if _party_view:
			size = party_size
			offset = Vector3(-0.95, 1.55, -1.4) - at
		elif _bar_view:
			size = bar_size
			offset = Vector3(0, 1.12, -31.3) - at
		var blend := 1.0 - exp(-3.3 * delta)
		framing_offset = framing_offset.lerp(offset, blend)
		$Camera3D.size = lerpf($Camera3D.size, size, blend)
	super._process(delta)
