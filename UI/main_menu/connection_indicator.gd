extends Control
## Two quiet rings come together when the partner is connected.
const INK := Color("363634")
var connected := false
var _pending := false
var _blend := 0.0
var _time := 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	set_process(false)

func set_connection(value: bool, pending: bool = false) -> void:
	connected = value
	_pending = pending
	tooltip_text = "Connected to your partner" if connected else ("Connecting" if pending else "No partner connected")
	set_process(true)
	queue_redraw()

func _process(delta: float) -> void:
	_time += delta
	_blend = move_toward(_blend, 1.0 if connected else 0.0, delta * 5.0)
	queue_redraw()
	if not _pending and is_equal_approx(_blend, 1.0 if connected else 0.0):
		set_process(false)

func _draw() -> void:
	var center := size * 0.5
	var scale_factor := minf(size.x, size.y) / 64.0
	var separation := lerpf(12.0, 6.0, _blend) * scale_factor
	var radius := 9.0 * scale_factor
	var alpha := lerpf(0.28, 0.9, _blend)
	if _pending:
		alpha = 0.38 + sin(_time * 3.0) * 0.08
	var color := Color(INK, alpha)
	draw_arc(center - Vector2(separation, 0), radius, 0, TAU, 64, color, 1.8, true)
	draw_arc(center + Vector2(separation, 0), radius, 0, TAU, 64, color, 1.8, true)
