@tool
extends "res://components/scenery/concert/shared/concert_geometry.gd"
## Small ceremonial details reuse the library's chamfered painted prop geometry.

func flat_deck(center: Vector3, width: float, depth: float, thickness: float, color: Color, bevel: float = 0.12) -> void:
	var previous := frame
	frame=previous*Transform3D(Basis(Vector3.RIGHT,PI*0.5),center)
	soft_box(Vector3.ZERO,Vector3(width,depth,thickness),color,bevel)
	frame=previous

func book_seal(at: Vector3, radius: float) -> void:
	disc(at,radius,0.012,brass,Vector3.BACK,0,28)
	disc(at+Vector3.BACK*0.009,radius*0.84,0.008,accent,Vector3.BACK,0,28)
	for side: float in [-1.0,1.0]:
		quad(at+Vector3(side*radius*0.05,-radius*0.33,0.018),at+Vector3(side*radius*0.56,-radius*0.21,0.018),at+Vector3(side*radius*0.56,radius*0.38,0.018),at+Vector3(side*radius*0.05,radius*0.23,0.025),ivory)
	rod(at+Vector3(0,-radius*0.35,0.025),at+Vector3(0,radius*0.24,0.025),radius*0.025,brass,6)

func commencement_hardware(config: Dictionary) -> Dictionary:
	begin(config)
	var width: float = config.footprint.x
	var depth: float = config.footprint.y
	var h: float = config.deck_height
	# Soft gold swags frame the central ramp, leaving an open presentation deck.
	for side: float in [-1.0,1.0]:
		var start: float = config.ramp_width*0.5+0.13 if config.ramp_enabled else 0.10
		var end := width*0.5-0.17
		var previous := Vector3(side*start,h-0.075,depth*0.5+0.035)
		for i in range(1,25):
			var t := float(i)/24
			var p := Vector3(side*lerpf(start,end,t),h-0.075-sin(t*PI)*h*0.40,depth*0.5+0.035)
			rod(previous,p,0.012,brass,6)
			previous=p
	if config.banners_enabled:
		for side: float in [-1.0,1.0]:
			var at := Vector3(side*width*0.39,h,-depth*0.32)
			flat_deck(at+Vector3.UP*0.035,0.48,0.45,0.07,accent.darkened(0.1),0.06)
			rod(at+Vector3.UP*0.06,at+Vector3.UP*3.20,0.025,brass,10)
			ball(at+Vector3.UP*3.23,Vector3.ONE*0.105,brass)
			rod(at+Vector3(-0.46,3.12,0.02),at+Vector3(0.46,3.12,0.02),0.018,brass,8)
			collider(at+Vector3.UP*1.6,Vector3(0.16,3.2,0.16),"BannerPole")
	anchors["Lectern"] = Vector3(0,h+0.015,0.10)
	anchors["DiplomaTable"] = Vector3(width*0.28,h+0.015,-0.18)
	return finish()

func banners(config: Dictionary) -> Dictionary:
	begin(config)
	var top: float = config.deck_height+3.10
	var bottom := top-1.65
	for side: float in [-1.0,1.0]:
		var x: float = side*config.footprint.x*0.39
		var z: float = -config.footprint.y*0.32+0.045
		for column in range(12):
			var u0 := float(column)/12
			var u1 := float(column+1)/12
			var x0 := x+(u0-0.5)*0.81
			var x1 := x+(u1-0.5)*0.81
			var z0 := z+sin(u0*TAU*2.0)*0.025
			var z1 := z+sin(u1*TAU*2.0)*0.025
			var hem0 := bottom+absf(u0-0.5)*0.26
			var hem1 := bottom+absf(u1-0.5)*0.26
			for row in range(8):
				var a := float(row)/8
				var b := float(row+1)/8
				var color := accent.lightened(sin((u0+u1)*TAU*2)*0.045)
				quad(Vector3(x0,lerpf(top,hem0,b),z0),Vector3(x1,lerpf(top,hem1,b),z1),Vector3(x1,lerpf(top,hem1,a),z1),Vector3(x0,lerpf(top,hem0,a),z0),color)
			# A broad hem follows the pointed fabric edge.
			quad(Vector3(x0,hem0,z0+0.004),Vector3(x1,hem1,z1+0.004),Vector3(x1,hem1+0.045,z1+0.004),Vector3(x0,hem0+0.045,z0+0.004),brass)
		book_seal(Vector3(x,top-0.54,z+0.047),0.19)
	return finish()

func lectern(config: Dictionary) -> Dictionary:
	begin(config)
	var h: float = config.lectern_height
	var w: float = config.lectern_width
	flat_deck(Vector3(0,0.045,0),w*1.10,0.51,0.09,body.darkened(0.08),0.07)
	var panel := PackedVector2Array([Vector2(-w*0.38,0.11),Vector2(w*0.38,0.11),Vector2(w*0.44,h-0.16),Vector2(-w*0.44,h-0.16)])
	profile(panel,Vector3(0,0,0),0.32,body)
	soft_box(Vector3(0,h*0.48,0.169),Vector3(w*0.68,h*0.57,0.018),accent,0.035)
	book_seal(Vector3(0,h*0.57,0.184),w*0.19)
	var previous := frame
	frame = Transform3D(Basis(Vector3.RIGHT,0.17),Vector3(0,h-0.075,0))
	flat_deck(Vector3.ZERO,w*1.16,0.52,0.065,body.lightened(0.07),0.035)
	# Two pale note sheets sit on the sloped reading surface.
	box(Vector3(-0.035,0.037,0),Vector3(w*0.46,0.007,0.29),ivory)
	box(Vector3(-0.005,0.042,0.012),Vector3(w*0.46,0.005,0.29),ivory.lightened(0.05))
	frame = previous
	soft_box(Vector3(0,h-0.11,0.26),Vector3(w*1.05,0.045,0.027),brass,0.009)
	var mic: Array[Vector3] = [Vector3(-w*0.34,h-0.01,-0.10),Vector3(-w*0.34,h+0.25,-0.10),Vector3(-w*0.17,h+0.32,0.01),Vector3(-0.02,h+0.28,0.07)]
	tube(mic,0.011,ink,8)
	ball(mic[-1]+Vector3(0.018,-0.005,0.014),Vector3(0.085,0.041,0.052),ink)
	collider(Vector3(0,h*0.5,0),Vector3(w*1.12,h,0.53),"Lectern")
	anchors = {"Speaker":Vector3(0,0,-0.72),"Microphone":mic[-1]}
	return finish()

func diploma_table(config: Dictionary) -> Dictionary:
	begin(config)
	var w: float = config.table_width
	var h := 0.74
	for x: float in [-w*0.40,w*0.40]:
		for z: float in [-0.23,0.23]:
			rod(Vector3(x,0.04,z),Vector3(x,h-0.04,z),0.035,body,8)
	flat_deck(Vector3(0,h,0),w,0.70,0.07,ivory,0.045)
	# Long softly pleated front panel, with a quiet gold hem.
	for i in range(18):
		var x0 := -w*0.5+w*float(i)/18
		var x1 := -w*0.5+w*float(i+1)/18
		var z0 := 0.36+sin(float(i)*PI*0.5)*0.018
		var z1 := 0.36+sin(float(i+1)*PI*0.5)*0.018
		quad(Vector3(x0,0.15,z0),Vector3(x1,0.15,z1),Vector3(x1,h+0.03,z1),Vector3(x0,h+0.03,z0),accent.lightened(float(i%3)*0.018))
		quad(Vector3(x0,0.15,z0+0.003),Vector3(x1,0.15,z1+0.003),Vector3(x1,0.18,z1+0.003),Vector3(x0,0.18,z0+0.003),brass)
	var columns := maxi(1,ceili(float(config.diploma_count)/3))
	for i in range(config.diploma_count):
		var x := 0.0 if columns==1 else lerpf(-w*0.38,w*0.38,float(i%columns)/float(columns-1))
		var row := i/columns
		var at := Vector3(x,h+0.071+float(row%2)*0.003,-0.22+float(row)*0.20)
		disc(at,0.028,0.165,ivory,Vector3.FORWARD,0,16)
		disc(at,0.031,0.025,brass,Vector3.FORWARD,0,16)
		ball(at+Vector3(0,0.032,0),Vector3(0.045,0.012,0.038),accent)
	collider(Vector3(0,h*0.5,0),Vector3(w,h+0.12,0.73),"PresentationTable")
	anchors = {"Presentation":Vector3(0,h+0.12,0.30),"Approach":Vector3(0,0,0.95)}
	return finish()

func folding_chair(config: Dictionary) -> Dictionary:
	begin(config)
	# Light crossed frames, soft padded seat and rounded rectangular back.
	for side: float in [-1.0,1.0]:
		rod(Vector3(side*0.215,0.035,-0.25),Vector3(side*0.215,0.47,0.19),0.018,brass,8)
		rod(Vector3(side*0.215,0.035,0.25),Vector3(side*0.215,0.87,-0.23),0.018,brass,8)
		disc(Vector3(side*0.218,0.37,0.07),0.027,0.008,body,Vector3.RIGHT,0,10)
		for z: float in [-0.25,0.25]:
			ball(Vector3(side*0.215,0.03,z),Vector3(0.052,0.035,0.065),body.darkened(0.15))
	flat_deck(Vector3(0,0.415,0.005),0.47,0.44,0.05,body,0.045)
	soft_box(Vector3(0,0.745,-0.221),Vector3(0.47,0.245,0.055),body,0.055)
	rod(Vector3(-0.21,0.26,-0.04),Vector3(0.21,0.26,-0.04),0.013,brass,8)
	return finish()
