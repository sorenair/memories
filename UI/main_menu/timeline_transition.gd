extends Control
## Two outlined circles meet, fill, and become the timeline's one selection point.
const LAYER_NAME := "TimelineThreadTransition"
const Symbols := preload("res://UI/main_menu/memory_action_button.gd")
const PAPER := Color("faf9f6")
const INK := Color("363634")
const DEPART_DURATION := 0.35
const ARRIVE_DURATION := 0.65
const MERGE_END := 0.62
const FILL_START := 0.64
const FILL_END := 0.84
const TIMELINE_REVEAL_START := 0.80
var progress := 0.0
var cover_alpha := 0.0
var _start_center_uv := Vector2.ZERO
var _start_radius := 20.0
var _start_separation := 20.0
var _stroke_width := 1.8
var _start_alpha := 0.72
var _timeline: WeakRef

func begin(pose: Dictionary) -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_start_center_uv = pose.center / size
	_start_radius = pose.radius
	_start_separation = pose.separation
	_stroke_width = pose.width
	_start_alpha = pose.alpha

func attach_timeline(timeline: Control) -> void:
	_timeline = weakref(timeline)
	var tween := create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "progress", 1.0, ARRIVE_DURATION).set_trans(Tween.TRANS_LINEAR)
	tween.tween_property(self, "cover_alpha", 0.0, 0.3)
	tween.chain().tween_callback(_complete)

func _complete() -> void:
	var timeline := _timeline.get_ref() as Control
	if is_instance_valid(timeline):
		timeline.complete_main_menu_transition()
	cancel()

func cancel() -> void:
	hide()
	get_parent().queue_free()

func _process(_delta: float) -> void:
	queue_redraw()

func center_position() -> Vector2:
	return (_start_center_uv * size).lerp(size * 0.5, smoothstep(0.0, MERGE_END, progress))

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(PAPER, cover_alpha))
	var center := center_position()
	var merge := smoothstep(0.0, MERGE_END, progress)
	var fill := smoothstep(FILL_START, FILL_END, progress)
	var mark_scale := clampf(minf(size.x / 1920.0, size.y / 886.0), 0.8, 1.2)
	var radius := lerpf(_start_radius, 14.0 * mark_scale, merge)
	var separation := _start_separation * (1.0 - merge)
	# Fill begins only after the circles have met at the screen's center.
	draw_circle(center, 23.0 * mark_scale, Color(0.88, 0.85, 0.80, 0.16 * fill), true, -1, true)
	draw_circle(center, 18.0 * mark_scale, Color(PAPER, fill), true, -1, true)
	draw_circle(center, radius, Color(INK, fill), true, -1, true)
	var outline_alpha := lerpf(_start_alpha, 0.85, merge) * (1.0 - smoothstep(0.85, 1.0, fill))
	draw_polyline(Symbols.infinity_outline(center, radius, separation), Color(INK, outline_alpha), _stroke_width, true)
