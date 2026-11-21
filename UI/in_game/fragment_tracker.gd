extends Control
## One mark per fragment, filled in collection order during the current visit.
const CONTRAST_SHADER := preload("res://UI/in_game/glyph_contrast.gdshader")
const INK := Color(1.0, 1.0, 1.0)

@export var timeline_button: Control

var _total := 0
var _collected: Dictionary = {}
var _fill := 0.0
var _fill_tween: Tween

func _ready() -> void:
	var contrast_material := ShaderMaterial.new()
	contrast_material.shader = CONTRAST_SHADER
	material = contrast_material
	resized.connect(queue_redraw)
	if timeline_button:
		timeline_button.resized.connect(queue_redraw)

func track_memory(memory: MemoryScene) -> void:
	# Guidance can list a subset, but every fragment in the memory counts here.
	for fragment: MemoryFragment in memory.find_children("*", "MemoryFragment", true, false):
		_total += 1
		fragment.activated.connect(_on_fragment_collected)
		if fragment.collected:
			_collected[fragment.get_instance_id()] = true
	_set_fill(float(_collected.size()))

func _on_fragment_collected(fragment: MemoryFragment) -> void:
	var id := fragment.get_instance_id()
	if _collected.has(id):
		return
	_collected[id] = true
	if _fill_tween:
		_fill_tween.kill()
	_fill_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_fill_tween.tween_method(_set_fill, _fill, float(_collected.size()), 0.32)

func _set_fill(value: float) -> void:
	_fill = value
	queue_redraw()

func _draw() -> void:
	if _total == 0:
		return
	var scale_factor := clampf(minf(size.x, size.y) / 720.0, 0.85, 1.0)
	var padding := 52.0 * scale_factor
	var step := 40.0 * scale_factor
	var radius := 13.0 * scale_factor
	var top_row := timeline_button.position.y + timeline_button.size.y * 0.5 if timeline_button else 84.0
	var columns := maxi(1, int((size.x * 0.48 - padding) / step))
	for index in _total:
		var row := floorf(float(index) / columns)
		var center := Vector2(padding + (index % columns) * step, top_row + row * step)
		var progress := clampf(_fill - index, 0.0, 1.0)
		draw_arc(center, radius, 0.0, TAU, 48, Color(INK, 0.78 * (1.0 - progress)), 2.6 * scale_factor, true)
		if progress > 0.0:
			draw_circle(center, radius * lerpf(0.45, 1.0, progress), Color(INK, 0.9 * progress), true, -1, true)
