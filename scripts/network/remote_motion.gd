extends RefCounted
## Buffered playback in the sender's time domain; clocks need not be synchronized.

const DELAY := 0.10
const MAX_SAMPLES := 32

class Snapshot:
	var time: float
	var position: Vector3
	var heading: float
	var walking: bool

	func _init(at: float, point: Vector3, yaw: float, moving: bool) -> void:
		time = at
		position = point
		heading = yaw
		walking = moving

var _samples: Array[Snapshot] = []
var _playhead := 0.0
var _playing := false

func push(time: float, position: Vector3, heading: float, walking: bool) -> void:
	if not _samples.is_empty() and time <= _samples.back().time:
		return
	_samples.append(Snapshot.new(time, position, heading, walking))
	if _samples.size() > MAX_SAMPLES:
		_samples.pop_front()

func apply(delta: float, explorer: MemoryExplorer) -> void:
	if _samples.is_empty():
		return
	var latest := _samples.back() as Snapshot
	if not _playing:
		var first := _samples[0]
		explorer.global_position = first.position
		explorer.visual.rotation.y = first.heading
		explorer.show()
		# Fill the buffer before advancing so a late packet doesn't immediately cause a stall.
		if latest.time - first.time < DELAY - 0.001:
			return
		_playhead = latest.time - DELAY
		_playing = true
	else:
		var buffered := latest.time - _playhead
		# Small rate adjustments keep the buffer topped up without correcting the position by snapping.
		var speed := clampf(1.0 + (buffered - DELAY) * 1.5, 0.90, 1.10)
		_playhead = minf(latest.time, _playhead + delta * speed)
	while _samples.size() > 1 and _samples[1].time <= _playhead:
		_samples.pop_front()
	var from := _samples[0]
	var to := _samples[1] if _samples.size() > 1 else from
	var weight := clampf(inverse_lerp(from.time, to.time, _playhead), 0.0, 1.0) if from != to else 0.0
	explorer.global_position = from.position.lerp(to.position, weight)
	explorer.visual.rotation.y = lerp_angle(from.heading, to.heading, weight)
	# Stop animating if the buffer runs dry, rather than walking in place during a dropout.
	explorer.set_walking(from.walking and _samples.size() > 1)
