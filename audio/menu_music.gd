extends AudioStreamPlayer
## Shared playback for the title screen and Memory Lane.

@export var playlist: Array[AudioStream] = []

const FADE_IN_DURATION := 0.8
const SILENCE_GAIN := 0.0001

var _remaining: Array[AudioStream] = []
var _last_track: AudioStream
var _level_db: float
var _gain := 0.0
var _fade: Tween
var _fading_out := false

func _ready() -> void:
	_level_db = volume_db
	_set_gain(0.0)
	finished.connect(_play_next)

func enter_menu() -> void:
	var starting := not playing
	if playing:
		# Keep the current song and shuffle only the tracks left in this pass.
		_remaining.shuffle()
	else:
		_set_gain(0.0)
		_play_next()
	if playing and (starting or _fading_out):
		_fading_out = false
		_fade_to(1.0, FADE_IN_DURATION)

func fade_out(seconds: float) -> void:
	if playing:
		_fading_out = true
		_fade_to(0.0, seconds)

func leave_menu() -> void:
	if _fade:
		_fade.kill()
	stop()
	stream = null
	_remaining.clear()
	_fading_out = false
	_set_gain(0.0)

func _fade_to(target: float, seconds: float) -> void:
	if _fade:
		_fade.kill()
	_fade = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_fade.tween_method(_set_gain, _gain, target, seconds)

func _set_gain(value: float) -> void:
	_gain = value
	volume_db = _level_db + linear_to_db(maxf(value, SILENCE_GAIN))

func _play_next() -> void:
	if _remaining.is_empty():
		for track in playlist:
			if track != null and not _remaining.has(track):
				_remaining.append(track)
		_remaining.shuffle()
		# Avoid repeating the last song at the start of a new pass.
		if _remaining.size() > 1 and _remaining.back() == _last_track:
			_remaining.push_front(_remaining.pop_back())
	if _remaining.is_empty():
		return
	_last_track = _remaining.pop_back()
	stream = _one_shot(_last_track)
	play()

func _one_shot(track: AudioStream) -> AudioStream:
	# Let the playlist loop even if a source file was imported with looping enabled.
	if track is AudioStreamWAV and track.loop_mode != AudioStreamWAV.LOOP_DISABLED:
		var copy := track.duplicate() as AudioStreamWAV
		copy.loop_mode = AudioStreamWAV.LOOP_DISABLED
		return copy
	if track is AudioStreamMP3 and track.loop:
		var copy := track.duplicate() as AudioStreamMP3
		copy.loop = false
		return copy
	if track is AudioStreamOggVorbis and track.loop:
		var copy := track.duplicate() as AudioStreamOggVorbis
		copy.loop = false
		return copy
	return track
