@tool
class_name PainterlyFestiveLights
extends PainterlyStadiumPiece
## Warm festoon strands or a tree's spiral of lights, ornaments and a star.
const DETAILS = preload("res://components/scenery/christmas_market/market_geometry.gd")
@export_enum("Festoon", "Tree Trimming") var layout := 0:
	set(value):
		layout = clampi(value,0,1)
		_request_rebuild()
@export_range(2.0,16.0,0.25) var span := 6.5:
	set(value):
		span = value
		_request_rebuild()
@export_range(1.5,6.0,0.1) var height := 3.6:
	set(value):
		height = value
		_request_rebuild()
@export_range(0.05,1.0,0.05) var sag := 0.45:
	set(value):
		sag = value
		_request_rebuild()
@export var poles := true:
	set(value):
		poles = value
		_request_rebuild()
@export var tree_radius := 1.05:
	set(value):
		tree_radius = value
		_request_rebuild()

func _build(b: RefCounted) -> void:
	if layout==0: _festoon(b)
	else: _tree(b)

func _festoon(b: RefCounted) -> void:
	var cord: Array[Vector3] = []
	for i in 49:
		var t := i/48.0
		var p := Vector3((t-0.5)*span,height-sin(t*PI)*sag,0)
		cord.append(p)
		if i%3==0:
			b.rod(p,p-Vector3.UP*0.10,0.015,Color("766a51"),5)
			b.ball(p-Vector3.UP*0.15,Vector3(0.09,0.12,0.09),DETAILS.BULB,3.0)
	b.tube(cord,0.018,Color("777366"),6)
	if not poles: return
	for side in [-1.0,1.0]:
		var foot := Vector3(side*span*0.5,0,0)
		b.rod(foot,foot+Vector3.UP*(height+0.2),0.055,Color("8b755f"),8)
		b.ball(foot+Vector3.UP*(height+0.2),Vector3.ONE*0.15,Color("f0f0e5"),1.0)
		_box_collision("LightPole",foot+Vector3.UP*height*0.5,Vector3(0.18,height,0.18))

func _tree(b: RefCounted) -> void:
	var cord: Array[Vector3] = []
	for i in 145:
		var t := i/144.0
		var angle := t*TAU*4.3
		var radius := lerpf(tree_radius,0.07,t)
		var p := Vector3(cos(angle)*radius,lerpf(height*0.29,height-0.3,t),sin(angle)*radius)
		cord.append(p)
		if i%3==0: b.ball(p,Vector3.ONE*0.07,DETAILS.BULB,3.0)
		if i%9==0:
			b.ball(p-Vector3.UP*0.13,Vector3.ONE*0.13,Color("ab7063") if i%2 else DETAILS.GOLD,1.0)
	b.tube(cord,0.013,DETAILS.GOLD.darkened(0.09),6)
	b.star(Vector3(0,height+0.07,0),0.25,DETAILS.GOLD)
	# A few parcels at the base anchor the tree without encircling its path.
	for i in 3:
		var at := Vector3(-0.42+i*0.38,0.16,0.46+(i%2)*0.16)
		var size := Vector3(0.33,0.32+(i%2)*0.12,0.3)
		b.soft_box(at,size,Color("a97868") if i%2 else DETAILS.GREEN,0.025,1.0)
		b.box(at+Vector3.UP*(size.y*0.5+0.005),Vector3(0.045,0.01,size.z),DETAILS.GOLD,1.0)
		b.box(at+Vector3(0,0,size.z*0.5+0.005),Vector3(0.045,size.y,0.01),DETAILS.GOLD,1.0)
	_box_collision("TreeParcels",Vector3(0,0.23,0.5),Vector3(1.2,0.46,0.7))
