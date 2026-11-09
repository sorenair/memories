class_name WaterRecall
extends Node
## An opaque pool grows from a small seed; existing white foam follows its moving rim.
signal finished
@export var patch: PainterlyWater
@export var origin: Node3D # Common study API; expansion uses an interior point of the water.
@export_range(0.5, 10.0, 0.1) var duration: float = 3.8
var progress: float = 0.0
var playing: bool = false
var auto_discover: bool = false
var _material: ShaderMaterial
var _center := Vector2.ZERO
var _outline_field: Texture2D
var _shore_enabled: bool = false

func _ready() -> void:
	reset()

func reset() -> void:
	playing = false
	bind_materials()
	seek(0.0)

func play() -> void:
	playing = progress < 1.0

func replay() -> void:
	reset()
	play()

func seek(value: float) -> void:
	progress = clampf(value, 0.0, 1.0)
	restore_state()

func bind_materials() -> void:
	_material = patch.get_node("PaintedWater").material_override
	# One extra static field only when rocks need stationary holes during expansion.
	var outer := patch._shore_data
	if not patch._obstacle_regions.is_empty():
		var none: Array[PackedVector2Array] = []
		outer = PainterlyWater.SHORE_FIELD.bake(patch._shape_data, none, patch.shape == 1, patch.cap_stream_ends, patch.flow_direction, [64, 96, 128][patch.shore_field_quality])
	_outline_field = outer.texture
	# Choose an interior, obstacle-free point even for offset/concave custom ponds.
	var image: Image = patch._shore_data.image
	var deepest := -INF
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			var distance := image.get_pixel(x, y).r
			if distance > deepest:
				deepest = distance
				_center = patch._shore_data.bounds.position + Vector2((x + 0.5) / image.get_width(), (y + 0.5) / image.get_height()) * patch._shore_data.bounds.size
	_material.set_shader_parameter("recall_outline_field", _outline_field)
	_material.set_shader_parameter("recall_center", _center)
	_shore_enabled = false

func restore_state() -> void:
	_material.set_shader_parameter("recall_progress", progress)
	# A tiny initial pool quickly resolves; a gentle ease slows the final shoreline.
	_material.set_shader_parameter("recall_scale", lerpf(0.025, 1.0, smoothstep(0.0, 1.0, progress)))
	_update_shore_collision()

func _explorer_inside() -> bool:
	for explorer in get_tree().get_nodes_in_group(&"explorers"):
		if explorer is Node3D:
			var point := patch.to_local(explorer.global_position)
			if absf(explorer.global_position.y - patch.global_position.y) < 1.5 and Geometry2D.is_point_in_polygon(Vector2(point.x, point.z), patch._shape_data.outline):
				return true
	return false

func _update_shore_collision() -> void:
	var body := patch.get_node_or_null("ShoreCollision")
	if not body:
		_shore_enabled = progress >= 1.0
		return
	# Do not leave an invisible full-size wall, or trap a player inside the final rim.
	_shore_enabled = progress >= 1.0 and not _explorer_inside()
	for collision in body.get_children():
		collision.set_deferred("disabled", not _shore_enabled)

func _process(delta: float) -> void:
	if auto_discover and not playing and progress == 0.0:
		if preload("res://components/effects/recall/component_recall.gd").explorer_near_outline(patch, patch._shape_data.outline):
			play()
	if playing:
		seek(progress + delta / duration)
		if progress >= 1.0:
			playing = false
			finished.emit()
	elif progress >= 1.0 and not _shore_enabled:
		_update_shore_collision()
