extends "res://UI/main_menu/menu_icon_button.gd"
## Two-circle infinity and circular Recall, drawn as crisp vectors at the UI's current scale.
enum Action { ENTER, RECALL }
@export var action: Action = Action.ENTER

const INK := Color("363634")
var _idle_time := 0.0
var _motion_progress := 0.0
var _motion_amount := 0.0
var _engagement := 0.0

func _process(delta: float) -> void:
	super._process(delta)
	var engaged := not disabled and (is_hovered() or has_focus() or is_pressed() or _pointer >= 0)
	_engagement = lerpf(_engagement, 1.0 if engaged else 0.0, 1.0 - exp(-delta * 12.0))
	if not disabled and modulate.a > 0.98:
		_idle_time += delta
		var phase := fmod(maxf(_idle_time - (0.25 if action == Action.ENTER else 0.8), 0.0), 5.6)
		_motion_progress = clampf(phase / 2.2, 0.0, 1.0)
		_motion_amount = pow(sin(_motion_progress * PI), 2.0)

func _draw() -> void:
	var design_size := Vector2(96, 64) if action == Action.ENTER else Vector2(64, 64)
	var icon_scale := minf(symbol_size.x / design_size.x, symbol_size.y / design_size.y)
	draw_set_transform((size - design_size * icon_scale) * 0.5, 0.0, Vector2.ONE * icon_scale)
	var color := Color(INK, _ink_alpha)
	# Enlarging a symbol should not make its stroke heavier than the other controls.
	var width := 1.8 / icon_scale
	if action == Action.ENTER:
		_draw_entry(color, width)
	else:
		_draw_recall(color, width)
	draw_set_transform(Vector2.ZERO)

func _entry_shape() -> Dictionary:
	return {
		"center": Vector2(48, 32 - _motion_amount * 0.5),
		"radius": 20.0 + _motion_amount * 0.35,
		"separation": 20.0 - _motion_amount * 1.25 - _engagement * 0.5,
		"alpha": minf(_ink_alpha + _motion_amount * 0.05, 1.0),
	}

func _draw_entry(color: Color, width: float) -> void:
	var shape := _entry_shape()
	color.a = shape.alpha
	draw_polyline(infinity_outline(shape.center, shape.radius, shape.separation), color, width, true)

func get_entry_pose() -> Dictionary:
	# Preserve the exact live circles when the persistent transition takes ownership.
	var shape := _entry_shape()
	var icon_scale := minf(symbol_size.x / 96.0, symbol_size.y / 64.0)
	var origin := (size - Vector2(96, 64) * icon_scale) * 0.5
	return {
		"center": get_global_transform() * (origin + shape.center * icon_scale),
		"radius": shape.radius * icon_scale,
		"separation": shape.separation * icon_scale,
		"width": 1.8,
		"alpha": shape.alpha * modulate.a,
	}

static func infinity_outline(center: Vector2, radius: float, half_separation: float) -> PackedVector2Array:
	# Only the outside arcs remain as the circles overlap, producing one clean merged contour.
	var separation := clampf(half_separation, 0.0, radius)
	var intersection := acos(separation / radius)
	var points := PackedVector2Array()
	for step in range(65):
		var angle := lerpf(-intersection, -TAU + intersection, step / 64.0)
		points.append(center - Vector2(separation, 0) + Vector2(cos(angle), sin(angle)) * radius)
	for step in range(1, 65):
		var angle := lerpf(PI - intersection, -PI + intersection, step / 64.0)
		points.append(center + Vector2(separation, 0) + Vector2(cos(angle), sin(angle)) * radius)
	return points

func _draw_recall(color: Color, width: float) -> void:
	var turn := deg_to_rad(_engagement * 5.0 + _motion_amount * 3.0)
	for path in recall_strokes(turn):
		_stroke(path, color, width)

static func recall_strokes(turn: float = 0.0) -> Array[PackedVector2Array]:
	var loop := PackedVector2Array()
	for step in range(65):
		var angle := deg_to_rad(-155.0 - step / 64.0 * 270.0) - turn
		loop.append(Vector2(32, 32) + Vector2(cos(angle), sin(angle)) * 20.0)
	# End the curved tail before the head, then connect with a short tangent stem.
	# This keeps the inner wing clear of the curve instead of drawing them over each other.
	var angle := deg_to_rad(-425.0) - turn
	var direction := Vector2(sin(angle), -cos(angle))
	var normal := direction.orthogonal()
	var tip := loop[-1] + direction * 8.5
	loop.append(tip)
	var head := PackedVector2Array([tip - direction * 6.5 + normal * 4.5, tip, tip - direction * 6.5 - normal * 4.5])
	return [loop, head]

func _stroke(points: PackedVector2Array, color: Color, width: float = 1.6) -> void:
	draw_polyline(points, color, width, true)
	draw_circle(points[0], width * 0.5, color, true, -1, true)
	draw_circle(points[-1], width * 0.5, color, true, -1, true)

