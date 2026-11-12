@tool
extends Node
## Small component-owned cue bank, including for standalone Inspector previews.
## Bounded players route to the shared SFX bus and die with a rebuilt component.

var _offsets: Dictionary = {}

func add_cue(id: StringName, stream: AudioStream, offset_db: float = 0.0, polyphony: int = 1) -> void:
	var player := AudioStreamPlayer.new()
	player.name = id
	player.stream = stream
	player.bus = &"SFX"
	player.max_polyphony = polyphony
	add_child(player)
	_offsets[id] = offset_db

func set_volume_db(value: float) -> void:
	for id in _offsets:
		get_node(NodePath(id)).volume_db = value + _offsets[id]

func play(id: StringName, pitch: float = 1.0) -> void:
	var player := get_node(NodePath(id)) as AudioStreamPlayer
	player.pitch_scale = pitch
	player.play()
