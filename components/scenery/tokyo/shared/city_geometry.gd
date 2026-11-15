@tool
extends "res://components/scenery/tokyo/shared/japanese_geometry.gd"
## Batched modular facades, neon fittings and a walkable scramble crossing.

func floor_shape(c: Dictionary,index: int) -> Vector3:
	var factor := 1.0
	if c.profile==1:
		factor=1.0 if index<c.floors*0.30 else (0.83 if index<c.floors*0.72 else 0.64)
	elif c.profile==2:
		factor=1.0 if index<3 else 0.74
	return Vector3(c.footprint.x*factor,c.floor_height,c.footprint.y*(0.90 if c.profile==2 and index>=3 else factor))

func tower(c: Dictionary) -> Dictionary:
	begin(c)
	var h: float=c.floor_height
	var w: float=c.footprint.x
	var d: float=c.footprint.y
	var total: float=c.floors*h
	for floor_index in range(c.floors):
		var size := floor_shape(c,floor_index)
		var y := float(floor_index)*h
		var bevel := minf(size.x,size.z)*(0.17 if c.profile==2 else 0.025)
		flat_deck(Vector3(0,y+h*0.5,0),size.x,size.z,h,body.lightened(rng.randf_range(-0.025,0.025)),bevel)
		flat_deck(Vector3(0,y+h-0.045,0),size.x+0.035,size.z+0.035,0.09,roof_paint,bevel)
		for face in range(4):
			var span: float=(size.x if face<2 else size.z)-bevel*2-0.16
			var columns := maxi(2,floori(span/0.62))
			var previous := frame
			var rot := Basis(Vector3.UP,0 if face==0 else (PI if face==1 else (PI*0.5 if face==2 else -PI*0.5)))
			var origin := Vector3(0,y+h*0.51,size.z*0.5+0.008) if face<2 else Vector3((1 if face==2 else -1)*size.x*0.5, y+h*0.51,0)
			if face==1:
				origin.z=-size.z*0.5-0.008
			frame=Transform3D(rot,origin)
			for column in range(columns):
				var x := (float(column)+0.5)/columns*span-span*0.5
				var on: bool=rng.randf()<c.lit_fraction
				var color: Color=(ivory.lerp(accent,0.18) if rng.randf()<0.45 else accent) if on else Color("30464d")
				box(Vector3(x,0,0.005),Vector3(span/columns*0.70,h*0.58,0.015),color,3 if on else 0)
			frame=previous
	# Broad storefront windows and the door stay legible at explorer scale.
	for side: float in [-1.0,1.0]:
		soft_box(Vector3(side*w*0.27,0.65,d*0.5+0.05),Vector3(w*0.37,1.10,0.05),Color("35565d"),0.025)
	soft_box(Vector3(0,0.60,d*0.5+0.06),Vector3(0.68,1.20,0.07),Color("26393f"),0.025)
	box(Vector3(0.17,0.64,d*0.5+0.11),Vector3(0.025,0.20,0.025),brass)
	soft_box(Vector3(0,1.37,d*0.5+0.09),Vector3(w*0.88,0.23,0.08),accent,0.03,4)
	if not c.sign_text.is_empty():
		text(c.sign_text,Vector3(0,1.37,d*0.5+0.14),minf(0.18,w/maxf(c.sign_text.length(),1)*0.65),ivory)
	var top_size := floor_shape(c,c.floors-1)
	for side: float in [-1.0,1.0]:
		soft_box(Vector3(side*top_size.x*0.24,total+0.18,0),Vector3(top_size.x*0.25,0.36,top_size.z*0.38),roof_paint.lightened(0.05),0.04)
	rod(Vector3(0,total+0.2,-top_size.z*0.15),Vector3(0,total+1.2,-top_size.z*0.15),0.025,brass,8)
	# A tall sign ribbon changes the silhouette independently of the screen.
	soft_box(Vector3(w*0.5+0.14,total*0.43,d*0.25),Vector3(0.26,minf(total*0.46,6),0.40),accent,0.035,4)
	for side: float in [-1.0,1.0]:
		var y := total*0.43+side*minf(total*0.46,6)*0.35
		var local_size := floor_shape(c,clampi(floori(y/h),0,c.floors-1))
		rod(Vector3(local_size.x*0.5,y,d*0.25),Vector3(w*0.5+0.14,y,d*0.25),0.025,roof_paint,8)
	if c.screen_enabled:
		var screen: Vector2=c.screen_size
		soft_box(Vector3(0,c.screen_y,d*0.5+0.08),Vector3(screen.x+0.18,screen.y+0.18,0.18),roof_paint.darkened(0.2),0.065)
	collider(Vector3(0,total*0.5,0),Vector3(w,total,d),"TowerExterior")
	anchors={"Entrance":Vector3(0,0,d*0.5+0.75),"Roof":Vector3(0,total+0.4,0)}
	return finish()

func zebra(at: Vector3,angle: float,width: float,length: float) -> void:
	var previous := frame
	frame=Transform3D(Basis(Vector3.UP,angle),at)
	var count := maxi(3,floori(length/0.70))
	for i in range(count):
		flat_deck(Vector3(0,0.021,(float(i)+0.5)/count*length-length*0.5),width,length/count*0.47,0.008,ivory.lightened(rng.randf_range(-0.025,0.02)),0.055)
	frame=previous

func crossing(c: Dictionary) -> Dictionary:
	begin(c)
	var road: float=c.road_width
	var size: float=c.extent
	var offset := road*0.5+1.25
	zebra(Vector3(0,0,-offset),PI*0.5,2.2,road)
	zebra(Vector3(0,0,offset),PI*0.5,2.2,road)
	zebra(Vector3(-offset,0,0),0,2.2,road)
	zebra(Vector3(offset,0,0),0,2.2,road)
	if c.diagonal_enabled:
		zebra(Vector3.ZERO,PI*0.25,2.5,road*1.38)
	for x: float in [-1.0,1.0]:
		for z: float in [-1.0,1.0]:
			var p := Vector3(x*(road*0.5+1.8),0,z*(road*0.5+1.8))
			flat_deck(p+Vector3.UP*0.018,3.2,3.2,0.025,Color("a9b1ac"),0.35)
			if c.signals_enabled:
				var post := p+Vector3(-x*1.0,0,-z*1.0)
				rod(post,post+Vector3.UP*2.4,0.035,Color("5a6c70"),10)
				soft_box(post+Vector3(0,2.15,0),Vector3(0.26,0.47,0.17),ink,0.03)
				disc(post+Vector3(0,2.27,0.095),0.060,0.008,Color("789c8d"),Vector3.BACK,4,12)
				disc(post+Vector3(0,2.04,0.095),0.060,0.008,Color("bce5c4"),Vector3.BACK,4,12)
				collider(post+Vector3.UP*1.2,Vector3(0.10,2.4,0.10),"SignalPost")
	collider(Vector3(0,-0.006,0),Vector3(size,0.025,size),"CrossingFloor")
	anchors={"Center":Vector3(0,0.03,0),"NorthApproach":Vector3(0,0,size*0.5-0.5),"DiagonalApproach":Vector3(-road*0.5,0,-road*0.5)}
	return finish()
