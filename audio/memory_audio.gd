class_name MemoryAudio
extends Node
## Shared soundtrack/cues and local-explorer mixing of the memory's zone ambience.

@export_group("Music")
@export var music_stream: AudioStream
@export_range(-60.0, 0.0, 0.5, "suffix:dB") var music_volume_db := -14.0
@export var music_loop := true
@export_group("Global Ambience (Optional)")
@export var ambience_stream: AudioStream
@export_range(-60.0, 0.0, 0.5, "suffix:dB") var ambience_volume_db := -18.0
@export var ambience_loop := true
@export_group("Memory Cues")
@export var fragment_sound: AudioStream
@export_range(-60.0, 0.0, 0.5, "suffix:dB") var fragment_volume_db := -14.0
@export_group("Playback")
@export var autoplay := true
@export_range(0.0, 4.0, 0.05, "suffix:s") var fade_in_seconds := 1.2
@export_range(1, 16, 1) var max_one_shots := 8

@onready var music: AudioStreamPlayer = $Music
@onready var ambience: AudioStreamPlayer = $Ambience
var _voices: Array[AudioStreamPlayer] = []
var _voice_order: Array[int] = []
var _serial := 0
var _zones: Array[MemoryZone] = []
var _listener: Node3D
var _zone_audio_enabled := false

func _ready() -> void:
	set_process(false)
	for index in max_one_shots:
		var voice := AudioStreamPlayer.new()
		voice.name = "OneShot%d" % index
		voice.bus = &"SFX"
		add_child(voice)
		_voices.append(voice)
		_voice_order.append(0)
	# All sibling components must finish registering before we bind their cues.
	call_deferred("_start_when_ready")

func _start_when_ready() -> void:
	_zones.assign(get_parent().get_zones())
	for zone in _zones:
		zone.prepare_audio()
	set_process(is_instance_valid(_listener) and not _zones.is_empty())
	for fragment in get_tree().get_nodes_in_group(&"memory_fragments"):
		if get_parent().is_ancestor_of(fragment):
			fragment.activated.connect(_on_fragment_activated)
	if autoplay:
		start()

func start() -> void:
	_zone_audio_enabled = true
	get_node("/root/AudioMixer").begin_memory(fade_in_seconds)
	play_music(music_stream, music_volume_db, music_loop)
	play_ambience(ambience_stream, ambience_volume_db, ambience_loop)

## The real explorer is the listener, rather than the elevated orthographic camera.
func set_listener(actor: Node3D) -> void:
	_listener = actor
	set_process(is_instance_valid(_listener) and not _zones.is_empty())
	if not is_instance_valid(_listener):
		for zone in _zones:
			if is_instance_valid(zone):
				zone.stop_audio()

func _process(delta: float) -> void:
	if not is_instance_valid(_listener):
		set_listener(null)
		return
	if not _zone_audio_enabled:
		return
	var weights: Array[float] = []
	var total := 0.0
	for zone in _zones:
		var weight := 0.0
		if is_instance_valid(zone) and zone.is_visible_in_tree() and zone.can_process() and zone.ambience.stream != null:
			weight = zone.get_ambience_weight(_listener.global_position)
		weights.append(weight)
		total += weight
	# Overlapping bounds blend beds without doubling their combined gain.
	for index in _zones.size():
		if is_instance_valid(_zones[index]):
			_zones[index].update_ambience(weights[index] / maxf(1.0, total), delta)

func play_music(stream: AudioStream, volume_db: float = -14.0, loop: bool = true) -> void:
	_play_bed(music, stream, volume_db, loop)

func play_ambience(stream: AudioStream, volume_db: float = -18.0, loop: bool = true) -> void:
	_play_bed(ambience, stream, volume_db, loop)

func play_sfx(stream: AudioStream, volume_db: float = 0.0, pitch: float = 1.0) -> AudioStreamPlayer:
	return _play_one_shot(stream, &"SFX", volume_db, pitch)

func play_ui(stream: AudioStream, volume_db: float = 0.0) -> AudioStreamPlayer:
	return _play_one_shot(stream, &"UI", volume_db, 1.0)

func stop() -> void:
	_zone_audio_enabled = false
	for zone in _zones:
		if is_instance_valid(zone):
			zone.stop_audio()
	music.stop()
	ambience.stop()
	for voice in _voices:
		voice.stop()

func _play_bed(player: AudioStreamPlayer, stream: AudioStream, volume_db: float, loop: bool) -> void:
	player.stop()
	player.stream = _prepare_stream(stream, loop)
	player.volume_db = volume_db
	if player.stream != null:
		player.play()

func _play_one_shot(stream: AudioStream, bus: StringName, volume_db: float, pitch: float) -> AudioStreamPlayer:
	if stream == null or _voices.is_empty() or not is_finite(pitch) or pitch <= 0.0:
		return null
	var index := 0
	for candidate in _voices.size():
		if not _voices[candidate].playing:
			index = candidate
			break
		if _voice_order[candidate] < _voice_order[index]:
			index = candidate
	var voice := _voices[index]
	voice.stop()
	voice.bus = bus
	voice.stream = _prepare_stream(stream, false)
	voice.volume_db = volume_db
	voice.pitch_scale = clampf(pitch, 0.25, 4.0)
	_serial += 1
	_voice_order[index] = _serial
	voice.play()
	return voice

func _on_fragment_activated(_fragment: MemoryFragment) -> void:
	play_sfx(fragment_sound, fragment_volume_db)

static func _prepare_stream(stream: AudioStream, loop: bool) -> AudioStream:
	if stream == null:
		return null
	# Never change imported shared resources: one clip may be a bed and a cue.
	var result := stream.duplicate() as AudioStream
	if result is AudioStreamWAV:
		if loop:
			if result.loop_end <= result.loop_begin:
				result.loop_begin = 0
				result.loop_end = roundi(result.get_length() * result.mix_rate)
			result.loop_mode = AudioStreamWAV.LOOP_FORWARD
		else:
			result.loop_mode = AudioStreamWAV.LOOP_DISABLED
	elif result is AudioStreamOggVorbis or result is AudioStreamMP3:
		result.loop = loop
	return result
