extends Node
## Global category levels live on the buses and survive scene changes.
## Playback belongs to the memory, so leaving it cannot leave orphaned sounds.

const CHANNELS: Array[StringName] = [&"Master", &"Music", &"Ambience", &"SFX", &"UI"]
const SILENCE_DB := -80.0
var _memory_gain := 1.0
var _fade: Tween

func set_level(channel: StringName, level: float) -> void:
	if channel not in CHANNELS or not is_finite(level):
		return
	var index := AudioServer.get_bus_index(channel)
	if index >= 0:
		AudioServer.set_bus_volume_db(index, linear_to_db(maxf(clampf(level, 0.0, 1.0), 0.0001)))

func get_level(channel: StringName) -> float:
	var index := AudioServer.get_bus_index(channel) if channel in CHANNELS else -1
	if index < 0 or AudioServer.get_bus_volume_db(index) <= SILENCE_DB:
		return 0.0
	return db_to_linear(AudioServer.get_bus_volume_db(index))

func set_muted(channel: StringName, muted: bool) -> void:
	var index := AudioServer.get_bus_index(channel) if channel in CHANNELS else -1
	if index >= 0:
		AudioServer.set_bus_mute(index, muted)

func is_muted(channel: StringName) -> bool:
	var index := AudioServer.get_bus_index(channel) if channel in CHANNELS else -1
	return index >= 0 and AudioServer.is_bus_mute(index)

func begin_memory(seconds: float = 1.2) -> void:
	_cancel_fade()
	_set_memory_gain(0.0)
	resume_memory(seconds)

func resume_memory(seconds: float = 0.15) -> void:
	_fade_memory(1.0, seconds)

func fade_memory_out(seconds: float = 0.45) -> void:
	_fade_memory(0.0, seconds)

func _fade_memory(target: float, seconds: float) -> void:
	_cancel_fade()
	if seconds <= 0.0:
		_set_memory_gain(target)
		return
	_fade = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_fade.tween_method(_set_memory_gain, _memory_gain, target, seconds)

func _cancel_fade() -> void:
	if _fade != null and _fade.is_valid():
		_fade.kill()

func _set_memory_gain(value: float) -> void:
	_memory_gain = value
	var index := AudioServer.get_bus_index(&"Memory")
	if index >= 0:
		AudioServer.set_bus_volume_db(index, linear_to_db(maxf(value, 0.0001)))
