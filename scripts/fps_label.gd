extends Label
## Low-frequency debug text refresh; the label belongs to the game viewport.
var _elapsed: float = 0.0

func _ready() -> void:
	_update_text()

func _process(delta: float) -> void:
	_elapsed += delta
	if _elapsed >= 0.25:
		_elapsed = 0.0
		_update_text()

func _update_text() -> void:
	text = "%d FPS" % Engine.get_frames_per_second()
