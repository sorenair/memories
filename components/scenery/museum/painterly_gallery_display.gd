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
func _build(b: RefCounted) -> void:
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
		for index in [0,1,2,0,2,3]:
			b.s.set_uv(uvs[index])
			b.vertex(center+corners[index]+Vector3(0,0,0.12),Vector3.BACK,Color.WHITE,8.0)
		b.s.set_uv(Vector2.ZERO)
	_box_collision("Partition",Vector3(0,1.95,-0.2),Vector3(w+1.25,3.9,0.25))
