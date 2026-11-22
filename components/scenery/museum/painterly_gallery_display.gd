@tool
class_name PainterlyGalleryDisplay
extends PainterlyStadiumPiece
## A framed artwork on an incomplete gallery partition, or a simple gallery bench.
@export_enum("Painting Partition", "Bench") var display_type: int = 0:
	set(value):
		display_type = clampi(value,0,1)
		_request_rebuild()
@export var artwork: Texture2D:
	set(value):
		artwork = value
		_request_rebuild()
@export var canvas_size := Vector2(2.3,1.8):
	set(value):
		canvas_size = value.max(Vector2.ONE*0.3)
		_request_rebuild()
@export var wall_color := Color("d7d0c1"):
	set(value):
		wall_color = value
		_request_rebuild()
## Optional animated pigment that spills out of an interactive canvas.
const BRUSHSTROKES = preload("res://components/scenery/museum/canvas_brushstrokes.gd")
@export var animate_artwork_on_tap := false
@export_range(1.0, 5.0, 0.1) var interaction_range := 3.2
var _canvas: MeshInstance3D
var _brushstrokes: MultiMeshInstance3D
var _light_study: Tween

func _ready() -> void:
	super._ready()
	if not Engine.is_editor_hint() and animate_artwork_on_tap:
		add_to_group(&"memory_interactables")

func get_interaction_outline_meshes() -> Array[MeshInstance3D]:
	return [_canvas] if is_instance_valid(_canvas) else []

func set_interaction_outline(amount: float, _selected: bool) -> void:
	if is_instance_valid(_canvas):
		_material.set_shader_parameter("artwork_tap_outline", amount)

func can_interact(actor: Node3D) -> bool:
	if not is_instance_valid(_brushstrokes) or not is_instance_valid(actor) or not is_instance_valid(_canvas):
		return false
	if _light_study and _light_study.is_running():
		return false
	var offset := to_local(actor.global_position)
	return offset.z > 0.15 and global_position.distance_squared_to(actor.global_position) <= interaction_range ** 2 \
		and (not recall_enabled or (_recall != null and _recall.progress >= 1.0))

func try_activate(actor: Node3D) -> bool:
	if not can_interact(actor):
		return false
	return play_shared_interaction(0)

func play_shared_interaction(_seed_value: int) -> bool:
	if not is_instance_valid(_brushstrokes) or not is_instance_valid(_canvas) or (_light_study != null and _light_study.is_running()):
		return false
	_light_study = create_tween()
	_light_study.tween_method(_set_light_study, 0.0, 1.0, 4.4)
	return true

func _set_light_study(phase: float) -> void:
	_material.set_shader_parameter("artwork_light_phase", phase)
	_brushstrokes.seek(phase)

func _build(b: RefCounted) -> void:
	_canvas = null
	_brushstrokes = null
	if _light_study and _light_study.is_running():
		_light_study.kill()
	var wood := Color("7b6957")
	if display_type==1:
		b.soft_box(Vector3(0,0.53,0),Vector3(2.6,0.16,0.7),wood,0.045,1.0)
		for x in [-0.95,0.95]: b.box(Vector3(x,0.24,0),Vector3(0.15,0.48,0.5),wood.darkened(0.08),1.0)
		_box_collision("GalleryBench",Vector3(0,0.35,0),Vector3(2.65,0.7,0.75))
		return
	var w := canvas_size.x
	var h := canvas_size.y
	var center := Vector3(0,2.0,0)
	var frame := Color("ab9567")
	b.soft_box(Vector3(0,1.95,-0.22),Vector3(w+1.25,3.9,0.18),wall_color,0.08,1.0)
	b.box(Vector3(0,0.12,-0.08),Vector3(w+1.3,0.24,0.07),wall_color.darkened(0.035),1.0)
	b.box(center+Vector3(0,0,-0.04),Vector3(w+0.25,h+0.25,0.14),wood,1.0)
	for side in [-1.0,1.0]:
		b.box(center+Vector3(side*(w*0.5+0.065),0,0.06),Vector3(0.13,h+0.26,0.1),frame,1.0)
		b.box(center+Vector3(0,side*(h*0.5+0.065),0.06),Vector3(w,0.13,0.1),frame,1.0)
	if artwork:
		_material.set_shader_parameter("artwork_texture",artwork)
		var corners := [Vector3(-w/2,h/2,0),Vector3(w/2,h/2,0),Vector3(w/2,-h/2,0),Vector3(-w/2,-h/2,0)]
		var uvs := [Vector2(0,0),Vector2(1,0),Vector2(1,1),Vector2(0,1)]
		var canvas_builder := b
		if animate_artwork_on_tap:
			canvas_builder = GEOMETRY.new()
			canvas_builder.s = SurfaceTool.new()
			canvas_builder.s.begin(Mesh.PRIMITIVE_TRIANGLES)
		for index in [0,1,2,0,2,3]:
			canvas_builder.s.set_uv(uvs[index])
			canvas_builder.vertex(center+corners[index]+Vector3(0,0,0.12),Vector3.BACK,Color.WHITE,8.0)
		canvas_builder.s.set_uv(Vector2.ZERO)
		if animate_artwork_on_tap:
			_canvas = MeshInstance3D.new()
			_canvas.name = "InteractiveCanvas"
			_canvas.mesh = canvas_builder.s.commit()
			_canvas.material_override = _material
			_canvas.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			_generated(_canvas)
			if not Engine.is_editor_hint():
				_brushstrokes = BRUSHSTROKES.new()
				_brushstrokes.name = "CanvasBrushstrokes"
				_brushstrokes.position = center
				_brushstrokes.setup(canvas_size)
				_generated(_brushstrokes)
	_box_collision("Partition",Vector3(0,1.95,-0.2),Vector3(w+1.25,3.9,0.25))
