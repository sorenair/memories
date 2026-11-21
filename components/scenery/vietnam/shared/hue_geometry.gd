@tool
extends "res://components/scenery/tokyo/shared/japanese_geometry.gd"
## Compressed imperial silhouettes. The central gate remains a real open passage.
func arch(center_x: float,radius: float,spring: float,depth: float,color: Color) -> void:
	for i in range(24):
		var x0 := -radius+2.0*radius*i/24.0
		var x1 := -radius+2.0*radius*(i+1)/24.0
		var y0 := spring+sqrt(maxf(0,radius*radius-x0*x0))
		var y1 := spring+sqrt(maxf(0,radius*radius-x1*x1))
		var a := Vector3(center_x+x0,y0,depth*0.5)
		var b := Vector3(center_x+x1,y1,depth*0.5)
		var c := Vector3(center_x+x1,3.12,depth*0.5)
		var d := Vector3(center_x+x0,3.12,depth*0.5)
		quad(a,b,c,d,color)
		quad(a-Vector3.BACK*depth,d-Vector3.BACK*depth,c-Vector3.BACK*depth,b-Vector3.BACK*depth,color.darkened(0.04))
		quad(a,a-Vector3.BACK*depth,b-Vector3.BACK*depth,b,color.darkened(0.14))
		# Convex blocks follow the arch soffit; no invisible rectangle in the opening.
		var points := PackedVector3Array()
		for z in [-depth*0.5,depth*0.5]:
			points.append(Vector3(center_x+x0,y0,z))
			points.append(Vector3(center_x+x1,y1,z))
			points.append(Vector3(center_x+x0,3.12,z))
			points.append(Vector3(center_x+x1,3.12,z))
		colliders.append({"name":"ArchStone","points":points})
		for sign_z in [-1.0,1.0]:
			rod(Vector3(center_x+x0,y0,sign_z*(depth*0.5+0.025)),Vector3(center_x+x1,y1,sign_z*(depth*0.5+0.025)),0.065,brass,8)

func gate(c: Dictionary) -> Dictionary:
	begin(c)
	var w: float = c.footprint.x
	var depth: float = c.footprint.y
	var outer := w*0.30
	var spans := [Vector2(-w*0.5,-outer-0.95),Vector2(-outer+0.95,-1.15),Vector2(1.15,outer-0.95),Vector2(outer+0.95,w*0.5)]
	for span: Vector2 in spans:
		var x := (span.x+span.y)*0.5
		var width := span.y-span.x
		soft_box(Vector3(x,1.56,0),Vector3(width,3.12,depth),body,0.035)
		collider(Vector3(x,1.56,0),Vector3(width,3.12,depth),"GatePier")
		for row in 6:
			var y := 0.31 + row * 0.43
			for side: float in [-1.0, 1.0]:
				box(Vector3(x, y, side * (depth * 0.5 + 0.009)), Vector3(width - 0.06, 0.025, 0.02), body.darkened(0.10))
				var joint := x + width * (0.18 if row % 2 == 0 else -0.15)
				box(Vector3(joint, y + 0.22, side * (depth * 0.5 + 0.010)), Vector3(0.025, 0.405, 0.021), body.darkened(0.08))
		for y in [0.15,0.40,2.82]:
			box(Vector3(x,y,depth*0.5+0.025),Vector3(width,0.055,0.045),brass.darkened(0.13))
	arch(0,1.15,1.72,depth,body)
	arch(-outer,0.95,1.60,depth,body)
	arch(outer,0.95,1.60,depth,body)
	flat_deck(Vector3(0,3.13,0),w+0.4,depth+0.4,0.20,brass,0.05)
	# Central golden double roof; lower green wings suggest the five-phoenix pavilion.
	for side in [-1.0,1.0]:
		var x: float = side*w*0.345
		for dx in [-w*0.105,w*0.105]:
			for z in [-depth*0.32,depth*0.32]:
				tapered_post(Vector3(x+dx,3.24,z),Vector3(x+dx,4.05,z),0.055,accent)
		_glazed_roof(Vector3(x,3.98,0),Vector2(w*0.34,depth+1.0),0.66,Color("6c8370"),0.17)
		box(Vector3(x,3.68,0),Vector3(w*0.29,0.72,depth*0.58),accent.darkened(0.13))
		box(Vector3(x, 3.34, depth * 0.40), Vector3(w * 0.30, 0.08, 0.08), brass)
		for railing in 9:
			var post := x + (railing - 4) * w * 0.034
			box(Vector3(post, 3.48, depth * 0.40), Vector3(0.043, 0.26, 0.075), accent)
	for x in [-w*0.17,0.0,w*0.17]:
		for z in [-depth*0.35,depth*0.35]:
			tapered_post(Vector3(x,3.24,z),Vector3(x,4.35,z),0.067,accent)
	box(Vector3(0,3.77,-depth*0.12),Vector3(w*0.34,1.0,depth*0.42),accent.darkened(0.20))
	_glazed_roof(Vector3(0,4.21,0),Vector2(w*0.51,depth+1.1),1.05,roof_paint,0.20)
	_glazed_roof(Vector3(0,5.03,0),Vector2(w*0.29,depth*0.83),0.77,roof_paint.lightened(0.08),0.16)
	_roof_crest(5.84, w * 0.085, 0.0)
	anchors["Passage"] = Vector3.ZERO
	anchors["Approach"] = Vector3(0,0,depth*0.5+2.0)
	return finish()

func palace(c: Dictionary) -> Dictionary:
	begin(c)
	var w: float = c.footprint.x
	var d: float = c.footprint.y
	flat_deck(Vector3(0,0.10,0.15),w+1.25,d+1.10,0.20,brass,0.10)
	flat_deck(Vector3(0,0.055,d*0.56),w*0.66,0.75,0.11,body.lerp(brass, 0.66),0.06)
	box(Vector3(0,1.37,-d*0.14),Vector3(w*0.91,2.5,d*0.65),body)
	for i in range(7):
		var x := lerpf(-w*0.44,w*0.44,i/6.0)
		tapered_post(Vector3(x,0.20,d*0.43),Vector3(x,2.89,d*0.43),0.085,accent)
		if i<6:
			var bay := x + w * 0.073
			box(Vector3(bay,1.37,d*0.19),Vector3(w*0.125,2.05,0.05),accent.darkened(0.36))
			for slat in range(-2, 3):
				box(Vector3(bay + slat * w * 0.016, 1.64, d * 0.19 + 0.036),
					Vector3(0.039, 1.36, 0.031), accent.lightened(0.09))
			box(Vector3(bay, 2.11, d * 0.19 + 0.051), Vector3(w * 0.115, 0.098, 0.042), brass)
	box(Vector3(0,2.69,d*0.43),Vector3(w*0.94,0.18,0.17),accent)
	_glazed_roof(Vector3(0,2.73,0),Vector2(w+1.25,d+1.2),1.12,roof_paint,0.22)
	_glazed_roof(Vector3(0,3.58,-0.14),Vector2(w*0.69,d*0.64),0.93,roof_paint.lightened(0.05),0.18)
	_roof_crest(4.58, w * 0.23, -0.14)
	for side: float in [-1.0, 1.0]:
		for index in 4:
			var x := side * lerpf(w * 0.34, w * 0.50, index / 3.0)
			soft_box(Vector3(x, 0.25, d * 0.50), Vector3(0.15, 0.48, 0.16), brass, 0.022)
		box(Vector3(side * w * 0.42, 0.46, d * 0.50), Vector3(w * 0.17, 0.094, 0.12), brass)
	collider(Vector3(0,1.40,-d*0.14),Vector3(w*0.91,2.8,d*0.65),"PalaceBody")
	for x in [-w*0.44,0.0,w*0.44]: collider(Vector3(x,1.4,d*0.43),Vector3(0.18,2.8,0.18),"Pillar")
	anchors["Approach"] = Vector3(0,0,d*0.5+1.3)
	return finish()

func _glazed_roof(at: Vector3, size: Vector2, rise: float, color: Color, lift: float) -> void:
	roof(at, size, rise, color, lift)
	for face in 4:
		for course in 3:
			var distance := 0.70 + course * 0.10
			for index in 12:
				for corner: Vector2 in [Vector2(0, 0), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0), Vector2(0, 1), Vector2(1, 1)]:
					var u := (index + corner.x) / 12.0
					var v := distance + corner.y * 0.017
					var normal := roof_normal(size, rise, lift, face, u, v)
					vertex(roof_point(at, size, rise, lift, face, u, v) + normal * 0.018, normal, color.darkened(0.12))

func _roof_crest(height: float, half_width: float, z: float) -> void:
	var ceramic := brass.lerp(Color("eee0ad"), 0.53)
	rod(Vector3(-half_width, height, z), Vector3(half_width, height, z), 0.045, ceramic, 8)
	for side: float in [-1.0, 1.0]:
		tube([Vector3(side * half_width, height, z),
			Vector3(side * (half_width + 0.23), height + 0.08, z),
			Vector3(side * (half_width + 0.36), height + 0.27, z)], 0.052, ceramic, 8)
	disc(Vector3(0, height + 0.105, z), 0.097, 0.068, ceramic, Vector3.BACK, 0, 12)
