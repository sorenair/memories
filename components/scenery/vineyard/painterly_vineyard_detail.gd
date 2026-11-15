@tool
class_name PainterlyVineyardDetail
extends PainterlyConservatoryPiece
## A row's simple timber/wire support and grapes, or a deck's timber rail.
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
@export var grape_color := Color("766079"):
	set(value):
		grape_color = value
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
		b.soft_box(Vector3(0,0.83,z),Vector3(0.12,1.66,0.12),wood_color,0.02)
		_box_collision("Post",Vector3(0,0.83,z),Vector3(0.14,1.66,0.14))
	for y in [0.68,1.22,1.57]:
		b.rod(Vector3(0,y,-length*0.5),Vector3(0,y,length*0.5),0.012,wood_color.darkened(0.1),6)
	# Tiny restrained bunches, sharing one static batch; foliage is existing bushes.
	var count := maxi(2,roundi(length/2.7))
	for i in count:
		var z := lerpf(-length*0.46,length*0.46,float(i)/(count-1))
		var side := -1.0 if i%2 else 1.0
		var top := Vector3(side*0.46,1.10,z)
		b.rod(top+Vector3.UP*0.17,top,0.013,wood_color.darkened(0.2),6)
		for j in 7:
			var angle := j*2.4
			var p := top+Vector3(cos(angle)*0.065,-j*0.032,sin(angle)*0.055)
			b.ball(p,Vector3.ONE*(0.12-j*0.005),grape_color.lightened(b.rng.randf_range(-0.05,0.05)))
