@tool
extends "res://components/scenery/concert/shared/concert_geometry.gd"
## Curved roof sheets, timber framing, open gates and scenic temple exteriors.
const TURNED = preload("res://components/scenery/conservatory/shared/turned_geometry.gd")
var roof_paint: Color

func begin(c: Dictionary) -> void:
	super.begin(c)
	roof_paint=c.roof_color

func flat_deck(center: Vector3,width: float,depth: float,thickness: float,color: Color,bevel: float=0.12) -> void:
	var previous := frame
	frame=previous*Transform3D(Basis(Vector3.RIGHT,PI*0.5),center)
	soft_box(Vector3.ZERO,Vector3(width,depth,thickness),color,bevel)
	frame=previous

func tapered_post(a: Vector3,b: Vector3,radius: float,color: Color) -> void:
	var mesh := CylinderMesh.new()
	mesh.bottom_radius=radius
	mesh.top_radius=radius*0.88
	mesh.height=a.distance_to(b)
	mesh.radial_segments=24
	var y := (b-a).normalized()
	var x := y.cross(Vector3.BACK).normalized()
	append(mesh,Transform3D(Basis(x,y,x.cross(y)),(a+b)*0.5),color,2)

func crest(at: Vector3,radius: float) -> void:
	var outline := PackedVector2Array()
	for i in range(64):
		var a := TAU*float(i)/64
		var r := radius*(0.88+0.12*cos(a*16))
		outline.append(Vector2(cos(a),sin(a))*r)
	profile(outline,at,0.015,brass)
	disc(at+Vector3.BACK*0.012,radius*0.24,0.01,brass.lightened(0.12),Vector3.BACK,0,16)

func roof_point(at: Vector3,size: Vector2,rise: float,lift: float,face: int,u: float,v: float) -> Vector3:
	var y := rise*pow(1-v,1.55)+lift*pow(v,6)*(0.5+0.5*pow(absf(u*2-1),4))
	if face<2:
		return at+Vector3((u-0.5)*size.x*lerpf(0.55,1,v),y,(-1.0 if face==0 else 1.0)*v*size.y*0.5)
	return at+Vector3((-1.0 if face==2 else 1.0)*lerpf(size.x*0.275,size.x*0.5,v),y,(u-0.5)*size.y*v)

func roof_normal(size: Vector2,rise: float,lift: float,face: int,u: float,v: float) -> Vector3:
	var du := roof_point(Vector3.ZERO,size,rise,lift,face,minf(1,u+0.001),v)-roof_point(Vector3.ZERO,size,rise,lift,face,maxf(0,u-0.001),v)
	var dv := roof_point(Vector3.ZERO,size,rise,lift,face,u,minf(1,v+0.001))-roof_point(Vector3.ZERO,size,rise,lift,face,u,maxf(0,v-0.001))
	var n := du.cross(dv).normalized()
	if n.length_squared()<0.1:
		n=Vector3.UP
	return -n if n.y<0 else n

func roof(at: Vector3,size: Vector2,rise: float,color: Color,lift: float=0.20) -> void:
	for face in range(4):
		for row in range(10):
			for column in range(12):
				var ids := [Vector2i(column,row),Vector2i(column+1,row),Vector2i(column+1,row+1),Vector2i(column,row+1)]
				var points: Array[Vector3]=[]
				var normals: Array[Vector3]=[]
				for id in ids:
					var u := float(id.x)/12
					var v := float(id.y)/10
					points.append(roof_point(at,size,rise,lift,face,u,v))
					normals.append(roof_normal(size,rise,lift,face,u,maxf(0.0001,v)))
				var painted := color.lightened(float(row%3-1)*0.012)
				for triangle in [[0,1,2],[0,2,3]]:
					if (points[triangle[1]]-points[triangle[0]]).cross(points[triangle[2]]-points[triangle[0]]).length_squared()<0.00000001:
						continue
					for id in triangle:
						vertex(points[id],normals[id],painted)
		# Thick, curved fascia joins the roof to its shaded underside.
		for column in range(24):
			var a := roof_point(at,size,rise,lift,face,float(column)/24,1)
			var b := roof_point(at,size,rise,lift,face,float(column+1)/24,1)
			quad(a,b,b-Vector3.UP*0.115,a-Vector3.UP*0.115,color.darkened(0.13))
	rod(at+Vector3(-size.x*0.285,rise+0.03,0),at+Vector3(size.x*0.285,rise+0.03,0),0.060,color.lightened(0.10),12)

func front_gable(at: Vector3,width: float,depth: float,rise: float,color: Color) -> void:
	var curve: Array[Vector3]=[]
	for i in range(33):
		var x := float(i)/32*2-1
		curve.append(at+Vector3(x*width*0.5,rise*pow(1-absf(x),1.65)+0.17*pow(absf(x),6),depth*0.5))
	for i in range(32):
		quad(curve[i],curve[i+1],curve[i+1]+Vector3.FORWARD*depth,curve[i]+Vector3.FORWARD*depth,color)
		quad(curve[i]-Vector3.UP*0.11,curve[i+1]-Vector3.UP*0.11,curve[i+1],curve[i],brass)
		quad(curve[i]-Vector3.UP*0.20,curve[i+1]-Vector3.UP*0.20,curve[i+1]-Vector3.UP*0.11,curve[i]-Vector3.UP*0.11,body.lightened(0.08))
	var fill := PackedVector2Array()
	for p in curve:
		fill.append(Vector2(p.x,p.y-0.19))
	fill.append(Vector2(at.x+width*0.5,at.y-0.15))
	fill.append(Vector2(at.x-width*0.5,at.y-0.15))
	profile(fill,Vector3(0,0,at.z+depth*0.5-0.04),0.06,body.darkened(0.05))
	crest(at+Vector3(0,rise*0.49,depth*0.5+0.012),0.16)

func stair_flight(front: float,height: float,width: float,run: float,color: Color) -> void:
	var steps := maxi(3,ceili(height/0.11))
	for i in range(steps):
		var h := height*float(steps-i)/steps
		flat_deck(Vector3(0,h*0.5,front+run*(float(i)+0.5)/steps),width,run/steps+0.008,h,color.lightened(float(i%2)*0.012),0.015)
	var points := PackedVector3Array()
	for x in [-width*0.5,width*0.5]:
		points.append(Vector3(x,-0.02,front))
		points.append(Vector3(x,height+0.008,front))
		points.append(Vector3(x,-0.02,front+run))
	colliders.append({"name":"StairRamp","points":points})

func lantern(at: Vector3,height: float,radius: float,color: Color) -> void:
	var previous := frame
	frame=previous*Transform3D(Basis.IDENTITY,at-Vector3.UP*height*0.5)
	var profile: Array[Vector2]=[Vector2(0,height*0.04),Vector2(radius*0.70,height*0.04),Vector2(radius*0.94,height*0.16),Vector2(radius,height*0.40),Vector2(radius*0.99,height*0.64),Vector2(radius*0.90,height*0.86),Vector2(radius*0.68,height*0.96),Vector2(0,height*0.96)]
	TURNED.lathe(self,profile,color,5,32,0.025)
	for h in [height*0.04,height*0.96]:
		disc(Vector3(0,h,0),radius*0.76,height*0.055,ink,Vector3.UP,0,24)
		disc(Vector3(0,h+0.005,0),radius*0.77,height*0.018,brass,Vector3.UP,0,24)
	frame=previous

func hall(c: Dictionary) -> Dictionary:
	begin(c)
	var w: float=c.footprint.x
	var d: float=c.footprint.y
	var h: float=c.wall_height
	var floor_y := 0.45
	var front := d*0.5
	var porch := 1.25
	var meiji: bool=c.hall_style==0
	flat_deck(Vector3(0,floor_y*0.5,porch*0.5),w+0.7,d+porch+0.35,floor_y,Color("bcb6a5"),0.07)
	collider(Vector3(0,floor_y*0.5,porch*0.5),Vector3(w+0.7,floor_y,d+porch+0.35),"Veranda")
	box(Vector3(0,floor_y+h*0.48,-0.13),Vector3(w,h*0.96,d-0.2),body.darkened(0.23))
	collider(Vector3(0,floor_y+h*0.5,-0.15),Vector3(w,h,d-0.2),"ClosedHall")
	var bays := 7
	for bay in range(bays+1):
		var x := lerpf(-w*0.47,w*0.47,float(bay)/bays)
		tapered_post(Vector3(x,floor_y,front+porch*0.73),Vector3(x,floor_y+h,front+porch*0.73),0.105,body)
		# Keep the center prayer/approach bay open between actual post colliders.
		collider(Vector3(x,floor_y+h*0.5,front+porch*0.73),Vector3(0.20,h,0.20),"VerandaPost")
		if bay<bays:
			var mid := lerpf(-w*0.47,w*0.47,(float(bay)+0.5)/bays)
			soft_box(Vector3(mid,floor_y+h*0.49,front-0.015),Vector3(w*0.115,h*0.79,0.055),body.darkened(0.50),0.018)
			for slat in range(5):
				box(Vector3(mid+(slat-2)*w*0.019,floor_y+h*0.49,front+0.027),Vector3(0.025,h*0.77,0.026),body.lightened(0.025))
			if meiji:
				box(Vector3(mid,floor_y+h-0.39,front+porch*0.76),Vector3(w*0.125,0.52,0.025),Color("d8c687"))
	for y in [floor_y+h-0.03,floor_y+h-0.28]:
		soft_box(Vector3(0,y,front+porch*0.73),Vector3(w+0.35,0.17,0.23),body,0.025)
	for bay in range(13):
		var x := lerpf(-w*0.49,w*0.49,float(bay)/12)
		box(Vector3(x,floor_y+h+0.10,front+porch*0.6),Vector3(0.12,0.15,0.56),brass if meiji else ivory)
	var eave_y := floor_y+h+0.12
	roof(Vector3(0,eave_y,0.2),Vector2(w+1.65,d+porch+0.8),c.roof_rise,roof_paint,0.18)
	if meiji:
		front_gable(Vector3(0,eave_y-0.08,front+0.60),w*0.46,2.05,c.roof_rise*1.12,roof_paint)
		# A quiet sacred rope and folded white paper, without invented inscriptions.
		var rope: Array[Vector3]=[]
		for i in range(25):
			var t := float(i)/24
			rope.append(Vector3((t-0.5)*w*0.5,eave_y-0.38-sin(t*PI)*0.12,front+porch*0.83))
		tube(rope,0.025,brass,8)
		for x in [-w*0.18,-w*0.06,w*0.06,w*0.18]:
			var points := PackedVector2Array([Vector2(-0.04,0),Vector2(0.04,0),Vector2(0.01,-0.10),Vector2(0.10,-0.13),Vector2(0.025,-0.30),Vector2(-0.025,-0.23),Vector2(0.01,-0.15),Vector2(-0.075,-0.12)])
			profile(points,Vector3(x,eave_y-0.45,front+porch*0.85),0.008,ivory)
	else:
		# Senso-ji's broad high roof and vermilion/white bracket rhythm.
		soft_box(Vector3(0,eave_y-0.47,front+0.04),Vector3(w*0.96,0.17,0.20),ivory,0.015)
		soft_box(Vector3(0,eave_y-0.72,front+0.12),Vector3(0.50,0.88,0.10),body.darkened(0.55),0.025)
		crest(Vector3(0,eave_y-0.69,front+0.18),0.12)
	stair_flight(front+porch+0.18,floor_y,minf(3.1,w*0.43),1.55,Color("c6c0b1"))
	anchors={"Approach":Vector3(0,0,front+porch+2.35),"PrayerFront":Vector3(0,floor_y,front+porch*0.49)}
	return finish()

func torii(c: Dictionary) -> Dictionary:
	begin(c)
	var w: float=c.opening_width
	var h: float=c.gate_height
	for side: float in [-1.0,1.0]:
		var low := Vector3(side*w*0.5,0.07,0)
		var high := Vector3(side*(w*0.5-0.12),h-0.12,0)
		tapered_post(low,high,0.21,body)
		disc(Vector3(side*w*0.5,0.055,0),0.29,0.11,Color("b4ada0"),Vector3.UP,0,24)
		collider(Vector3(side*(w*0.5-0.05),h*0.5,0),Vector3(0.46,h,0.45),"TimberPost")
	var beam_width := w*1.47
	for layer in range(2):
		for i in range(32):
			var x0 := (float(i)/32-0.5)*beam_width
			var x1 := (float(i+1)/32-0.5)*beam_width
			var y0 := h+pow(absf(x0)/(beam_width*0.5),4)*0.24+float(layer)*0.22
			var y1 := h+pow(absf(x1)/(beam_width*0.5),4)*0.24+float(layer)*0.22
			var color := body.darkened(0.15) if layer==1 else body.lightened(0.025)
			for z: float in [-0.22,0.22]:
				quad(Vector3(x0,y0-0.13,z),Vector3(x1,y1-0.13,z),Vector3(x1,y1+0.10,z),Vector3(x0,y0+0.10,z),color)
			quad(Vector3(x0,y0+0.10,-0.22),Vector3(x1,y1+0.10,-0.22),Vector3(x1,y1+0.10,0.22),Vector3(x0,y0+0.10,0.22),color)
			quad(Vector3(x0,y0-0.13,0.22),Vector3(x1,y1-0.13,0.22),Vector3(x1,y1-0.13,-0.22),Vector3(x0,y0-0.13,-0.22),color)
		for side: float in [-1.0,1.0]:
			var x := side*beam_width*0.5
			var y := h+0.24+float(layer)*0.22
			quad(Vector3(x,y-0.13,-0.22),Vector3(x,y+0.10,-0.22),Vector3(x,y+0.10,0.22),Vector3(x,y-0.13,0.22),body.darkened(0.10 if layer==1 else 0))
	soft_box(Vector3(0,h*0.77,0),Vector3(w*1.25,0.28,0.31),body,0.025)
	soft_box(Vector3(0,h*0.875,0),Vector3(0.20,h*0.26,0.25),body,0.015)
	for x in [-w*0.48,0,w*0.48]:
		crest(Vector3(x,h+0.005,0.234),0.12)
	collider(Vector3(0,h*0.78,0),Vector3(w*1.25,0.28,0.32),"TieBeam")
	anchors={"Passage":Vector3.ZERO,"Approach":Vector3(0,0,1.25)}
	return finish()

func gate(c: Dictionary) -> Dictionary:
	begin(c)
	var w: float=c.gate_width
	var h: float=c.gate_height
	var d := w*0.27
	for x in [-w*0.43,-w*0.17,w*0.17,w*0.43]:
		for z in [-d*0.30,d*0.30]:
			tapered_post(Vector3(x,0.06,z),Vector3(x,h*0.54,z),0.14,body)
			collider(Vector3(x,h*0.27,z),Vector3(0.28,h*0.54,0.28),"GatePost")
			box(Vector3(x,h*0.51,z),Vector3(0.34,0.18,0.42),ivory)
	for side: float in [-1.0,1.0]:
		soft_box(Vector3(side*w*0.37,h*0.24,0),Vector3(w*0.15,h*0.40,d*0.55),body.darkened(0.43),0.035)
		collider(Vector3(side*w*0.37,h*0.24,0),Vector3(w*0.15,h*0.48,d*0.55),"GuardianBay")
		for slat in range(7):
			var x := side*w*0.37+(float(slat)-3)*w*0.018
			box(Vector3(x,h*0.20,d*0.28+0.012),Vector3(0.038,h*0.30,0.045),body.lightened(0.10))
		for y in [h*0.06,h*0.13,h*0.34]:
			box(Vector3(side*w*0.37,y,d*0.28+0.03),Vector3(w*0.15,0.055,0.07),ivory if y<h*0.10 else body)
	for y in [h*0.46,h*0.52]:
		box(Vector3(0,y,0),Vector3(w,0.19,d*0.75),body)
		box(Vector3(0,y-0.11,d*0.39),Vector3(w*0.93,0.09,0.08),ivory)
	roof(Vector3(0,h*0.53,0),Vector2(w*1.12,d*1.35),h*0.17,roof_paint,0.22)
	box(Vector3(0,h*0.74,0),Vector3(w*0.76,h*0.25,d*0.72),ivory)
	for x in range(9):
		var at := lerpf(-w*0.39,w*0.39,float(x)/8)
		box(Vector3(at,h*0.74,d*0.38),Vector3(0.12,h*0.26,0.14),body)
	for y in [h*0.65,h*0.69]:
		box(Vector3(0,y,d*0.46),Vector3(w*0.84,0.09,0.10),body)
	roof(Vector3(0,h*0.87,0),Vector2(w,d*1.13),h*0.19,roof_paint,0.20)
	rod(Vector3(0,h*0.51,0),Vector3(0,h*0.43,0),0.020,ink,8)
	lantern(Vector3(0,h*0.365,0),h*0.20,w*0.057,Color("c85540"))
	for side: float in [-1.0,1.0]:
		lantern(Vector3(side*w*0.215,h*0.365,0),h*0.17,w*0.041,Color("827958"))
	anchors={"Passage":Vector3.ZERO,"Approach":Vector3(0,0,d*0.5+1.25)}
	return finish()

func pagoda(c: Dictionary) -> Dictionary:
	begin(c)
	var width: float=c.base_width
	var height: float=c.tower_height
	var pitch := height*0.155
	flat_deck(Vector3(0,0.18,0),width*0.87,width*0.87,0.36,Color("b8b4a8"),0.08)
	for tier in range(5):
		var span := width*pow(0.85,tier)
		var y := 0.36+float(tier)*pitch
		var wall := pitch*0.67
		box(Vector3(0,y+wall*0.5,0),Vector3(span*0.57,wall,span*0.57),ivory)
		for side: float in [-1.0,1.0]:
			for column in range(5):
				var x := lerpf(-span*0.30,span*0.30,float(column)/4)
				box(Vector3(x,y+wall*0.5,side*span*0.30),Vector3(0.075,wall,0.095),body)
				box(Vector3(side*span*0.30,y+wall*0.5,x),Vector3(0.095,wall,0.075),body)
			for level in [0.13,0.27]:
				box(Vector3(0,y+pitch*level,side*span*0.36),Vector3(span*0.80,0.06,0.06),body)
				box(Vector3(side*span*0.36,y+pitch*level,0),Vector3(0.06,0.06,span*0.80),body)
			box(Vector3(0,y+wall-0.06,side*span*0.32),Vector3(span*0.70,0.09,0.16),body)
		roof(Vector3(0,y+wall,0),Vector2.ONE*span,pitch*0.30,roof_paint,0.14)
	var top := 0.36+pitch*5
	rod(Vector3(0,top,0),Vector3(0,height,0),0.035,brass,12)
	for ring in range(9):
		var t := float(ring)/8
		disc(Vector3(0,lerpf(top+0.1,height-0.25,t),0),lerpf(0.22,0.065,t),0.035,brass,Vector3.UP,0,24)
	ball(Vector3(0,height+0.05,0),Vector3.ONE*0.16,brass)
	collider(Vector3(0,height*0.5,0),Vector3(width*0.68,height,width*0.68),"PagodaBody")
	anchors={"Approach":Vector3(0,0,width*0.60+0.9)}
	return finish()
