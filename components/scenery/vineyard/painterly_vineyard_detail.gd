@tool
class_name PainterlyVineyardDetail
extends PainterlyConservatoryPiece
## A row's simple timber/wire support, or a deck's timber rail.
@export_enum("Grape Trellis", "Timber Rail") var layout := 0:
	set(value):
		layout = clampi(value,0,1)
		_request_rebuild()
@export_range(1.0,24.0,0.25) var length := 18.0:
	set(value):
		length = clampf(value,1,24)
		_request_rebuild()
@export var wood_color := Color("95816a"):
	set(value):
		wood_color = value
		_request_rebuild()
func _build(b: RefCounted) -> void:
	if layout==1:
		var bays := maxi(1,ceili(length/1.9))
		for i in bays+1:
			var x := lerpf(-length*0.5,length*0.5,float(i)/bays)
			b.soft_box(Vector3(x,0.48,0),Vector3(0.11,0.96,0.11),wood_color,0.02)
		for y in [0.38,0.88]:
			b.soft_box(Vector3(0,y,0),Vector3(length+0.08,0.10,0.10),wood_color,0.025)
		_box_collision("Rail",Vector3(0,0.48,0),Vector3(length,0.96,0.14))
		return
	var bays := maxi(1,ceili(length/3.0))
	for i in bays+1:
		var z := lerpf(-length*0.5,length*0.5,float(i)/bays)
		b.soft_box(Vector3(0,0.98,z),Vector3(0.12,1.96,0.12),wood_color,0.02)
		_box_collision("Post",Vector3(0,0.98,z),Vector3(0.14,1.96,0.14))
	for y in [0.73,1.25,1.70]:
		b.rod(Vector3(0,y,-length*0.5),Vector3(0,y,length*0.5),0.012,wood_color.darkened(0.1),6)
