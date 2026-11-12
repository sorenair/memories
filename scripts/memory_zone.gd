class_name MemoryZone
extends Node3D
## A movable piece of a memory: scenery, one story fragment, and a local ambience bed.

@export var zone_id: StringName = &"zone"
@export var display_name := "A remembered place"
@export_group("Ambience")
@export var ambience_stream: AudioStream
@export_range(-60.0, 0.0, 0.5, "suffix:dB") var ambience_volume_db := -18.0
@export var ambience_loop := true
## Full-volume rectangle centered on the zone origin, in local X/Z meters.
@export var ambience_size := Vector2(12.0, 12.0)
## Outside the rectangle, weight falls smoothly to zero over this distance.
@export_range(0.1, 20.0, 0.1, "suffix:m") var ambience_blend_distance := 3.0
@export_range(0.1, 3.0, 0.05, "suffix:s") var ambience_response_seconds := 0.4

@onready var ambience: AudioStreamPlayer = $Ambience
var _gain := 0.0
var _in_range := false

func get_fragment() -> MemoryFragment:
	return get_node_or_null("Fragment") as MemoryFragment

func get_ambience_weight(world_position: Vector3) -> float:
	var point := to_local(world_position)
	var half_size := ambience_size.abs() * 0.5
	var outside := Vector2(maxf(absf(point.x) - half_size.x, 0.0),
		maxf(absf(point.z) - half_size.y, 0.0)).length()
	return 1.0 - smoothstep(0.0, maxf(0.1, ambience_blend_distance), outside)

func prepare_audio() -> void:
	stop_audio()
	ambience.stream = MemoryAudio._prepare_stream(ambience_stream, ambience_loop)
	ambience.volume_db = -80.0

func update_ambience(weight: float, delta: float) -> void:
	if ambience.stream == null:
		return
	_gain = lerpf(_gain, clampf(weight, 0.0, 1.0),
		1.0 - exp(-maxf(0.0, delta) / maxf(0.1, ambience_response_seconds)))
	if weight <= 0.0 and _gain < 0.001:
		stop_audio()
		return
	ambience.volume_db = ambience_volume_db + linear_to_db(maxf(_gain, 0.0001))
	if not _in_range and weight > 0.0:
		_in_range = true
		ambience.play()

func stop_audio() -> void:
	ambience.stop()
	_gain = 0.0
	_in_range = false
