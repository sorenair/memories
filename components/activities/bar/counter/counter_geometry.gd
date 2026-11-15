@tool
extends "res://components/activities/bar/shared/bar_geometry.gd"
## Reuses the bar kit's rounded geometry, paint and collider/anchor contract.
func create_counter(config: Dictionary) -> Dictionary:
	begin(config)
	var length: float = config.length
	var depth: float = config.depth
	var height: float = config.height
	var count := mini(int(config.stool_count),maxi(1,floori(length/0.85)))
	soft_box(Vector3(0,(height-0.12)*0.5,0),Vector3(length-0.16,height-0.12,depth-0.12),body,0.045)
	flat_box(Vector3(0,height-0.055,0),Vector3(length,0.11,depth+0.10),accent,0.07)
	flat_box(Vector3(0,0.075,0),Vector3(length-0.10,0.15,depth-0.06),body.darkened(0.12),0.035)
	var panels := maxi(2,roundi(length/1.2))
	for i in panels:
		var x := (float(i)+0.5)/panels*length-length*0.5
		soft_box(Vector3(x,height*0.48,depth*0.5-0.045),Vector3(length/panels-0.16,height*0.60,0.035),body.lightened(0.035),0.025)
	rod(Vector3(-length*0.43,0.21,depth*0.5+0.18),Vector3(length*0.43,0.21,depth*0.5+0.18),0.025,brass,8)
	for side in [-1.0,1.0]:
		rod(Vector3(side*length*0.40,0.19,depth*0.5-0.03),Vector3(side*length*0.40,0.19,depth*0.5+0.18),0.025,brass,8)
	collider(Vector3(0,height*0.5,0),Vector3(length,height,depth+0.10),"Counter")
	var row := depth*0.5+0.65
	for i in count:
		var x := 0.0 if count==1 else lerpf(-length*0.34,length*0.34,float(i)/(count-1))
		var seat := Vector3(x,0.71,row)
		disc(seat,0.28,0.11,config.stool_color,Vector3.UP,0,32)
		disc(seat-Vector3.UP*0.065,0.245,0.035,body.darkened(0.08),Vector3.UP,0,24)
		for a in [-1.0,1.0]:
			for b in [-1.0,1.0]:
				rod(Vector3(x+a*0.22,0.045,row+b*0.22),Vector3(x+a*0.15,0.65,row+b*0.15),0.025,brass.darkened(0.12),8)
		var ring: Array[Vector3] = []
		for step in 25:
			var angle := TAU*step/24.0
			ring.append(Vector3(x+cos(angle)*0.21,0.28,row+sin(angle)*0.21))
		tube(ring,0.016,brass,6)
		collider(Vector3(x,0.38,row),Vector3(0.56,0.76,0.56),"Stool%d" % (i+1))
		anchors["Stool%d" % (i+1)] = Vector3(x,0,row+0.65)
	anchors["Approach"] = Vector3(0,0,row+1.0)
	return finish()
