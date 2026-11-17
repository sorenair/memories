extends Control
## A fixed lock body with a hinged shackle expresses the LAN connection state.
const INK := Color("363634")
const HINGE := Vector2(23, 31)
const OPEN_ANGLE := deg_to_rad(-34.0)
const TRANSITION_DURATION := 0.45
var connected := false
var _pending := false
var _blend := 0.0
var _time := 0.0
var _transition: Tween
var _body := PackedVector2Array()
var _shackle := PackedVector2Array()

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	# Cache the body independently: it never participates in the state animation.
	for corner in range(4):
		var center: Vector2 = [Vector2(22.5, 34.5), Vector2(41.5, 34.5), Vector2(41.5, 45.5), Vector2(22.5, 45.5)][corner]
		for step in range(9):
			var angle := PI + corner * PI * 0.5 + step / 8.0 * PI * 0.5
			_body.append(center + Vector2(cos(angle), sin(angle)) * 3.5)
	_body.append(_body[0])
	_shackle.append(Vector2(41, 31))
	for step in range(33):
		var angle := -step / 32.0 * PI
		_shackle.append(Vector2(32, 22) + Vector2(cos(angle), sin(angle)) * 9.0)
	_shackle.append(HINGE)
	set_process(false)

func set_connection(value: bool, pending: bool = false) -> void:
	var changed := connected != value
	connected = value
	_pending = pending
	tooltip_text = "Connected to your partner" if connected else ("Connecting" if pending else "No partner connected")
	if changed:
		if _transition:
			_transition.kill()
		_transition = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		_transition.tween_method(_set_blend, _blend, 1.0 if connected else 0.0, TRANSITION_DURATION)
	set_process(_pending)
	queue_redraw()

func _set_blend(value: float) -> void:
	_blend = value
	queue_redraw()

func _process(delta: float) -> void:
	_time += delta
	queue_redraw()

func _shackle_points() -> PackedVector2Array:
	var points := PackedVector2Array()
	for point in _shackle:
		points.append(HINGE + (point - HINGE).rotated(OPEN_ANGLE * (1.0 - _blend)))
	return points

func _draw() -> void:
	var scale_factor := minf(size.x, size.y) / 64.0
	if scale_factor <= 0.0:
		return
	draw_set_transform((size - Vector2.ONE * 64.0 * scale_factor) * 0.5, 0.0, Vector2.ONE * scale_factor)
	var width := 1.6 / scale_factor
	var alpha := lerpf(0.5, 0.9, _blend)
	if _pending:
		alpha = 0.5 + sin(_time * 3.0) * 0.08
	var shackle := _shackle_points()
	draw_polyline(shackle, Color(INK, alpha), width, true)
	draw_circle(shackle[0], width * 0.5, Color(INK, alpha), true, -1, true)
	draw_polyline(_body, Color(INK, 0.62), width, true)
	draw_line(Vector2(32, 38.5), Vector2(32, 41.5), Color(INK, 0.55), 1.25 / scale_factor, true)
	draw_set_transform(Vector2.ZERO)
