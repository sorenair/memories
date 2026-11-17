@tool
extends "res://components/scenery/tokyo/shared/japanese_geometry.gd"

func house(c: Dictionary) -> Dictionary:
	begin(c)
	var w: float = c.footprint.x
	var d: float = c.footprint.y
	var h: float = c.floors*c.floor_height
	var f := d*0.5
	soft_box(Vector3(0,h*0.5,0),Vector3(w,h,d),body,0.065)
	box(Vector3(0,0.12,f+0.04),Vector3(w+0.08,0.24,0.14),brass)
	# Open-looking shop front is inset paint on a solid scenic building.
	box(Vector3(0,0.89,f+0.013),Vector3(w*0.79,1.55,0.035),ink)
	for side in [-1.0,1.0]:
		box(Vector3(side*w*0.45,0.95,f+0.05),Vector3(0.12,1.9,0.14),brass)
	box(Vector3(0,1.74,f+0.06),Vector3(w*0.92,0.20,0.14),accent)
	for level in range(1,c.floors):
		var y: float = level*c.floor_height
		box(Vector3(0,y+0.05,f+0.045),Vector3(w+0.09,0.14,0.19),brass)
		for side in [-1.0,1.0]:
			var x: float = side*w*0.23
			box(Vector3(x,y+0.91,f+0.025),Vector3(w*0.28,1.12,0.04),ink.lightened(0.10))
			for shutter in [-1.0,1.0]:
				var sx: float = x+shutter*w*0.19
				soft_box(Vector3(sx,y+0.91,f+0.075),Vector3(w*0.105,1.16,0.10),accent,0.02)
				for slat in range(4):
					box(Vector3(sx,y+0.55+slat*0.23,f+0.132),Vector3(w*0.085,0.045,0.018),accent.lightened(0.13))
		if c.balconies_enabled:
			flat_deck(Vector3(0,y+0.10,f+0.26),w*0.87,0.72,0.12,brass,0.04)
			for iy in [0.29,0.79]:
				rod(Vector3(-w*0.41,y+iy,f+0.56),Vector3(w*0.41,y+iy,f+0.56),0.025,accent,8)
			for index in range(8):
				var x := lerpf(-w*0.41,w*0.41,index/7.0)
				rod(Vector3(x,y+0.19,f+0.56),Vector3(x,y+0.79,f+0.56),0.018,accent,6)
			# Small built-in planters give the terraces a lived-in silhouette.
			for side in [-1.0,1.0]:
				box(Vector3(side*w*0.32,y+0.26,f+0.32),Vector3(0.32,0.27,0.28),roof_paint)
				ball(Vector3(side*w*0.32,y+0.49,f+0.32),Vector3(0.52,0.36,0.45),Color("738562"),2)
	if c.awning_enabled:
		for index in range(6):
			var x := (index/6.0-0.5)*w+w/12.0
			box(Vector3(x,1.91,f+0.48),Vector3(w/6.0+0.005,0.07,0.94),accent if index%2==0 else ivory,0,Basis(Vector3.RIGHT,0.16))
	if c.profile==1:
		roof(Vector3(0,h+0.07,0),Vector2(w+0.35,d+0.35),0.95,roof_paint,0.03)
	else:
		flat_deck(Vector3(0,h+0.06,0),w+0.15,d+0.15,0.16,brass,0.04)
		for side in [-1.0,1.0]:
			box(Vector3(side*(w*0.5-0.06),h+0.29,0),Vector3(0.12,0.47,d),body)
		box(Vector3(0,h+0.29,f-0.04),Vector3(w,0.47,0.12),body)
		if c.profile==2:
			box(Vector3(-w*0.18,h+0.61,-d*0.15),Vector3(w*0.6,0.85,d*0.6),body.lightened(0.05))
	collider(Vector3(0,h*0.5,0),Vector3(w,h,d),"Building")
	anchors["Approach"] = Vector3(0,0,f+1.1)
	return finish()

func bridge_y(z: float,length: float,rise: float) -> float:
	return 0.06+rise*sin(clampf((z+length*0.5)/length,0,1)*PI)

func bridge(c: Dictionary) -> Dictionary:
	begin(c)
	var length: float = c.bridge_length
	var half: float = c.bridge_width*0.5
	var count := maxi(16,ceili(length/0.35))
	for i in range(count):
		var a := -length*0.5+length*i/count
		var b := -length*0.5+length*(i+1)/count
		var ya := bridge_y(a,length,c.arch_rise)
		var yb := bridge_y(b,length,c.arch_rise)
		quad(Vector3(-half,ya,a),Vector3(-half,yb,b),Vector3(half,yb,b),Vector3(half,ya,a),body.lightened(rng.randf_range(-0.035,0.035)))
		for side in [-1.0,1.0]:
			quad(Vector3(side*half,ya-0.13,a),Vector3(side*half,yb-0.13,b),Vector3(side*half,yb,b),Vector3(side*half,ya,a),accent)
			for rail_y in [0.37,0.80]:
				rod(Vector3(side*(half-0.06),ya+rail_y,a),Vector3(side*(half-0.06),yb+rail_y,b),0.034,accent,8)
		var points := PackedVector3Array()
		for x in [-half,half]:
			points.append(Vector3(x,ya,a))
			points.append(Vector3(x,yb,b))
			points.append(Vector3(x,-0.3,a))
			points.append(Vector3(x,-0.3,b))
		colliders.append({"name":"BridgeRamp%d"%i,"points":points})
	for i in range(ceili(length/0.85)+1):
		var z := lerpf(-length*0.5,length*0.5,float(i)/ceili(length/0.85))
		var y := bridge_y(z,length,c.arch_rise)
		for side in [-1.0,1.0]:
			rod(Vector3(side*(half-0.06),y-0.38,z),Vector3(side*(half-0.06),y+0.89,z),0.055,accent,10)
			collider(Vector3(side*half,y+0.42,z),Vector3(0.12,0.95,0.20),"RailPost")
	for side in [-1.0,1.0]:
		collider(Vector3(side*half,0.8,0),Vector3(0.11,1.7,length),"Guardrail")
	anchors["Shore"] = Vector3(0,0.06,length*0.5)
	anchors["Island"] = Vector3(0,0.06,-length*0.5)
	return finish()

func temple(c: Dictionary) -> Dictionary:
	begin(c)
	var w: float = c.footprint.x
	var d: float = c.footprint.y
	if c.landmark==1:
		for level in range(3):
			var shrink := pow(0.77,level)
			var y := level*1.06
			box(Vector3(0,y+0.48,0),Vector3(w*shrink,0.96,d*shrink),body)
			for side in [-1.0,0.0,1.0]:
				var x: float = side*w*shrink*0.29
				soft_box(Vector3(x,y+0.45,d*shrink*0.5+0.015),Vector3(w*shrink*0.17,0.56,0.025),ink.lightened(0.18),0.10)
			roof(Vector3(0,y+0.95,0),Vector2(w*shrink+0.30,d*shrink+0.30),0.32,roof_paint,0.09)
		collider(Vector3(0,1.6,0),Vector3(w,3.2,d),"Tower")
	else:
		flat_deck(Vector3(0,0.06,0),w+0.6,d+0.7,0.12,brass,0.08)
		box(Vector3(0,1.12,-0.25),Vector3(w*0.90,2.12,d*0.75),body)
		for x in [-w*0.40,0.0,w*0.40]:
			tapered_post(Vector3(x,0.12,d*0.43),Vector3(x,2.34,d*0.43),0.085,accent)
		# Put the door panels outside the body, including at wider footprints.
		var facade_z := -0.25+d*0.375+0.035
		for x in [-w*0.27,0.0,w*0.27]:
			box(Vector3(x,1.11,facade_z),Vector3(w*0.24,1.78,0.05),accent.darkened(0.27))
			box(Vector3(x,1.98,facade_z+0.03),Vector3(w*0.24,0.075,0.045),brass)
		roof(Vector3(0,2.20,0),Vector2(w+1.0,d+1.0),0.97,roof_paint,0.22)
		roof(Vector3(0,2.83,-0.05),Vector2(w*0.68,d*0.62),0.66,roof_paint.darkened(0.04),0.15)
		if c.get("roof_tiles_enabled",false):
			temple_roof_tiles(Vector3(0,2.20,0),Vector2(w+1,d+1),0.97,0.22,roof_paint)
			temple_roof_tiles(Vector3(0,2.83,-0.05),Vector2(w*0.68,d*0.62),0.66,0.15,roof_paint.darkened(0.04))
		# Restrained long ridge and curled ends; no Japanese gate/lantern asset.
		rod(Vector3(-w*0.30,3.51,-0.05),Vector3(w*0.30,3.51,-0.05),0.047,brass,10)
		for side in [-1.0,1.0]:
			tube([Vector3(side*w*0.30,3.51,-0.05),Vector3(side*w*0.40,3.55,-0.05),Vector3(side*w*0.43,3.74,-0.05)],0.04,brass,8)
		collider(Vector3(0,1.15,-0.25),Vector3(w*0.9,2.3,d*0.75),"TempleBody")
	anchors["Approach"] = Vector3(0,0,d*0.5+1.0)
	return finish()

func temple_roof_tiles(at: Vector3,size: Vector2,rise: float,lift: float,color: Color) -> void:
	# A quiet rhythm of broad pigment tiles; shallow relief avoids a glossy roof.
	for face in 4:
		for row in 8:
			for column in 16:
				var u0 := (column+0.025)/16.0
				var u1 := (column+0.975)/16.0
				var v0 := (row+0.025)/8.0
				var v1 := (row+0.975)/8.0
				var corners := [Vector2(u0,v0),Vector2(u1,v0),Vector2(u1,v1),Vector2(u0,v1)]
				var paint := color.lightened(0.018*sin(row*1.8)+0.008*sin(column*2.3+face))
				for triangle in [[0,1,2],[0,2,3]]:
					for index in triangle:
						var uv: Vector2 = corners[index]
						var normal := roof_normal(size,rise,lift,face,uv.x,uv.y)
						var point := roof_point(at,size,rise,lift,face,uv.x,uv.y)
						vertex(point+normal*0.012,normal,paint)

func karst(c: Dictionary) -> Dictionary:
	begin(c)
	var w: float = c.footprint.x
	var d: float = c.footprint.y
	var h: float = c.karst_height
	var phase := rng.randf()*TAU
	var rings: Array[PackedVector3Array] = []
	const SIDES := 28
	const LEVELS := 12
	for j in range(LEVELS+1):
		var t := float(j)/LEVELS
		var ring := PackedVector3Array()
		var taper := 0.90+0.10*sin(t*PI)-0.53*pow(t,7)
		for i in range(SIDES):
			var a := TAU*i/SIDES
			var flutes := 1.0+0.10*sin(a*7+phase)+0.06*sin(a*11-phase)
			var ledges := 1.0+0.035*sin(t*31+a*2)
			var top := h*(0.90+0.045*sin(a*c.peaks+phase)+0.025*sin(a*5+phase))
			ring.append(Vector3(cos(a)*w*0.5*taper*flutes*ledges+sin(t*2+phase)*w*0.08,t*top-0.13,sin(a)*d*0.5*taper*flutes*ledges))
		rings.append(ring)
	for j in range(LEVELS):
		for i in range(SIDES):
			var next := (i+1)%SIDES
			var cliff := body.lightened(0.07*sin(i*1.7+phase)+0.025*sin(j*1.9))
			if j>7 and sin(i*1.3+phase)+float(j)/LEVELS>0.5: cliff = accent.darkened((11-j)*0.012)
			quad(rings[j][i],rings[j+1][i],rings[j+1][next],rings[j][next],cliff)
	var center := Vector3(0,h*0.94,0)
	for i in range(SIDES):
		var a: Vector3 = rings[LEVELS][i]
		var b: Vector3 = rings[LEVELS][(i+1)%SIDES]
		var n := (a-center).cross(b-center).normalized()
		if n.y<0: n=-n
		for p in [center,a,b]: vertex(p,n,accent)
	# Overlapping crown masses and ledge growth break the outline without nodes.
	for i in range(24):
		var a := rng.randf()*TAU
		var radius := rng.randf_range(0.10,0.95)
		var at := Vector3(cos(a)*w*0.30*radius,h*(0.87+0.055*(1.0-radius)),sin(a)*d*0.30*radius)
		ball(at,Vector3(w*rng.randf_range(0.19,0.32),h*0.055,d*rng.randf_range(0.21,0.35)),accent.lightened(rng.randf_range(-0.05,0.06)),3)
	for i in range(10):
		var angle := rng.randi_range(0,SIDES-1)
		var at := rings[rng.randi_range(7,10)][angle]
		ball(at,Vector3(w*0.15,h*0.038,d*0.16),accent.darkened(0.03),2)

	collider(Vector3(0,h*0.45,0),Vector3(w*0.78,h*0.9,d*0.78),"Limestone")
	return finish()
