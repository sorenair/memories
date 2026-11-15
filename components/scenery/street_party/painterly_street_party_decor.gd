@tool
class_name PainterlyStreetPartyDecor
extends PainterlyConservatoryPiece
## A sparse pennant cord or one authentic street marker, in the shared paint batch.
@export_enum("Pennant Strand", "Street Sign") var layout := 0:
	set(value):
		layout = clampi(value,0,1)
		_request_rebuild()
@export_range(2.0,12.0,0.25) var span := 6.0:
	set(value):
		span = clampf(value,2,12)
		_request_rebuild()
@export_range(1.5,5.0,0.1) var height := 2.5:
	set(value):
		height = clampf(value,1.5,5)
		_request_rebuild()
@export var accent_color := Color("b75d60"):
	set(value):
		accent_color = value
		_request_rebuild()
@export var street_name := "W MIFFLIN ST":
	set(value):
		street_name = value
		_request_rebuild()

func _build(b: RefCounted) -> void:
	if layout==1:
		b.rod(Vector3.ZERO,Vector3.UP*(height+0.35),0.045,Color("8a8c7c"),8)
		var center := Vector3(0,height,0)
		b.soft_box(center,Vector3(1.9,0.36,0.075),Color("647d6b"),0.025)
		b.text(street_name,center+Vector3(0,0,0.045),0.15,Color("f4eedb"))
		_box_collision("SignPost",Vector3.UP*height*0.5,Vector3(0.15,height,0.15))
		return
	var cord: Array[Vector3] = []
	for i in 41:
		var t := i/40.0
		cord.append(Vector3((t-0.5)*span,height-sin(t*PI)*0.34,0))
	b.tube(cord,0.013,Color("8a8373"),5)
	var count := int(span/0.52)
	for i in count:
		var t := float(i+1)/(count+1)
		var at := Vector3((t-0.5)*span,height-sin(t*PI)*0.34,-0.015)
		var color := accent_color if i%3 else Color("efe9d9")
		b.quad(at+Vector3(-0.18,0,0),at+Vector3(0.18,0,0),at+Vector3(0,-0.38,0.035),at+Vector3(0,-0.38,0.035),color)
