@tool
extends "res://components/scenery/tokyo/shared/japanese_geometry.gd"
## Controls for the faceted coastal silhouettes, ordered to match the component.
enum KarstContour { WEATHERED, SPLIT_RIDGE, SPIRE, SHELVED_BLUFF }

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
	if c.landmark >= 2:
		match int(c.landmark):
			2: _moon_gate(w, d)
			3: _island_pavilion(w, d)
			4: _island_hall(w, d, c.roof_tiles_enabled)
		anchors["Approach"] = Vector3(0, 0, d * 0.5 + 1.0)
		return finish()
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

func _moon_gate(width: float, depth: float) -> void:
	var opening := width * 0.25
	var spring := 1.47
	var cornice := 2.40
	for side: float in [-1.0, 1.0]:
		var pier := Vector3(side * (width * 0.25 + opening * 0.5), spring * 0.5, 0)
		var pier_size := Vector3(width * 0.5 - opening, spring, depth)
		soft_box(pier, pier_size, body, 0.035)
		collider(pier, pier_size, "MoonGatePier")
		box(Vector3(pier.x, (cornice + spring) * 0.5, 0), Vector3(pier_size.x, cornice - spring, depth), body)
		box(Vector3(pier.x, 0.14, 0), Vector3(pier_size.x + 0.13, 0.28, depth + 0.10), body.darkened(0.13))
		soft_box(Vector3(pier.x, 1.08, depth * 0.5 + 0.012), Vector3(0.17, 1.33, 0.045), accent, 0.018)
		# Low glazed relief panels sit beside the portal.
		var relief := Vector3(side * (width * 0.5 + 0.29), 0.82, 0.02)
		soft_box(relief, Vector3(0.58, 1.64, depth * 0.68), body.darkened(0.08), 0.05)
		soft_box(relief + Vector3(0, 0.10, depth * 0.35), Vector3(0.39, 0.73, 0.024), accent.lerp(body, 0.54), 0.04)
		roof(Vector3(relief.x, 1.68, 0), Vector2(0.78, depth * 0.8), 0.24, roof_paint, 0.10)
	for step in 12:
		var a := PI * step / 12.0
		var b := PI * (step + 1) / 12.0
		var left := Vector2(cos(a) * opening, spring + sin(a) * opening * 0.67)
		var right := Vector2(cos(b) * opening, spring + sin(b) * opening * 0.67)
		profile(PackedVector2Array([left, right, Vector2(right.x, cornice), Vector2(left.x, cornice)]), Vector3.ZERO, depth * 0.5, body)
	# The upper wall frames a true round opening.
	var sill := 2.62
	var oculus := 0.28
	var window_center := Vector3(0, sill + oculus * 1.35, depth * 0.41)
	var rim: Array[Vector3] = []
	for course in 16:
		var a := TAU * course / 16.0
		var b := TAU * (course + 1) / 16.0
		var inside_a := Vector2(cos(a), sin(a)) * oculus
		var inside_b := Vector2(cos(b), sin(b)) * oculus
		var outside_a := inside_a / maxf(absf(cos(a)), absf(sin(a))) * 1.35
		var outside_b := inside_b / maxf(absf(cos(b)), absf(sin(b))) * 1.35
		profile(PackedVector2Array([inside_a, inside_b, outside_b, outside_a]),
			window_center, depth * 0.22, body.lightened(0.05))
		rim.append(window_center + Vector3(inside_a.x, inside_a.y, depth * 0.114))
	rim.append(rim[0])
	tube(rim, 0.029, body.darkened(0.23), 6)
	box(Vector3(0, 2.50, 0), Vector3(width - 0.30, 0.22, depth * 0.82), body)
	soft_box(Vector3(0, 2.46, depth * 0.48), Vector3(0.89, 0.19, 0.08), accent, 0.027)
	# Split eaves frame the moon window instead of crossing the opening.
	for side: float in [-1.0, 1.0]:
		roof(Vector3(side * width * 0.33, cornice, 0), Vector2(width * 0.39, depth + 0.25), 0.37, roof_paint, 0.14)
	roof(Vector3(0, 3.36, depth * 0.16), Vector2(width * 0.77, depth * 0.92), 0.48, roof_paint, 0.22)
	_temple_ridge(3.91, width * 0.22, depth * 0.16)

func _island_pavilion(width: float, depth: float) -> void:
	flat_deck(Vector3(0, 0.065, 0), width + 0.3, depth + 0.3, 0.13, brass)
	for x: float in [-width * 0.39, width * 0.39]:
		for z: float in [-depth * 0.38, depth * 0.38]:
			tapered_post(Vector3(x, 0.12, z), Vector3(x, 1.97, z), 0.075, accent)
			box(Vector3(x, 0.15, z), Vector3(0.23, 0.22, 0.23), body)
			collider(Vector3(x, 1.0, z), Vector3(0.21, 2.0, 0.21), "PavilionPost")
	roof(Vector3(0, 1.94, 0), Vector2(width + 0.62, depth + 0.63), 0.70, roof_paint, 0.25)
	_temple_ridge(2.66, width * 0.29, 0.0)

func _island_hall(width: float, depth: float, tiled: bool) -> void:
	var front := depth * 0.5
	flat_deck(Vector3(0, 0.115, 0.15), width + 0.68, depth + 0.75, 0.23, brass, 0.095)
	flat_deck(Vector3(0, 0.052, front + 0.57), width * 0.77, 0.42, 0.10, brass)
	box(Vector3(0, 1.23, -0.16), Vector3(width, 2.12, depth * 0.85), body)
	for bay in 3:
		var x := (bay - 1) * width * 0.29
		var face := depth * 0.425 - 0.135
		soft_box(Vector3(x, 1.08, face), Vector3(width * 0.255, 1.63, 0.06), accent.darkened(0.33), 0.035)
		for slat in 5:
			box(Vector3(x + (slat - 2) * width * 0.043, 1.23, face + 0.03), Vector3(0.035, 1.18, 0.03), accent)
		tapered_post(Vector3(x - width * 0.145, 0.23, front + 0.08), Vector3(x - width * 0.145, 2.22, front + 0.08), 0.08, accent)
	tapered_post(Vector3(width * 0.435, 0.23, front + 0.08), Vector3(width * 0.435, 2.22, front + 0.08), 0.08, accent)
	box(Vector3(0, 2.09, front + 0.08), Vector3(width * 0.90, 0.18, 0.15), accent)
	var roof_size := Vector2(width + 0.94, depth + 1.12)
	roof(Vector3(0, 2.22, 0), roof_size, 0.95, roof_paint, 0.30)
	if tiled:
		temple_roof_tiles(Vector3(0, 2.22, 0), roof_size, 0.95, 0.30, roof_paint)
	_temple_ridge(3.19, width * 0.32, 0.0)
	collider(Vector3(0, 1.17, -0.10), Vector3(width, 2.34, depth * 0.95), "TempleBody")

func _temple_ridge(height: float, half_width: float, z: float) -> void:
	rod(Vector3(-half_width, height, z), Vector3(half_width, height, z), 0.055, brass, 8)
	for side: float in [-1.0, 1.0]:
		tube([Vector3(side * half_width, height, z), Vector3(side * (half_width + 0.20), height + 0.08, z),
			Vector3(side * (half_width + 0.28), height + 0.25, z)], 0.048, brass, 8)

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

func faceted_karst(c: Dictionary) -> Dictionary:
	begin(c)
	var canopy := SphereMesh.new()
	canopy.radius = 0.5
	canopy.height = 1.0
	canopy.radial_segments = 9
	canopy.rings = 3
	var footprint: Vector2 = c.footprint
	var height: float = c.karst_height
	var peak_count: int = c.peaks
	var contour: int = c.contour
	var direction := Vector2.from_angle(rng.randf_range(0.0, TAU))
	for peak in range(1, peak_count):
		var side := direction.rotated(PI * (peak - 1) + rng.randf_range(-0.45, 0.45))
		var offset := side * footprint * rng.randf_range(0.23, 0.32)
		var shoulder_height := height * rng.randf_range(0.41, 0.73)
		var shoulder_size := footprint * Vector2(rng.randf_range(0.51, 0.67), rng.randf_range(0.52, 0.68))
		var shoulder_contour := KarstContour.WEATHERED
		if contour == KarstContour.SPLIT_RIDGE and peak == 1:
			offset = side * footprint * 0.41
			shoulder_height = height * 0.87
			shoulder_size = footprint * Vector2(0.54, 0.62)
			shoulder_contour = KarstContour.SPIRE
		_karst_mass(offset, shoulder_size, shoulder_height, side, canopy, false, shoulder_contour)
	var core_size := footprint if peak_count == 1 else footprint * 0.86
	_karst_mass(Vector2.ZERO, core_size, height, direction, canopy, true, contour)
	collider(Vector3(0, height * 0.45, 0), Vector3(footprint.x * 0.78, height * 0.9, footprint.y * 0.78), "Limestone")
	return finish()

func _karst_mass(center: Vector2, footprint: Vector2, height: float, lean: Vector2, canopy: SphereMesh, main: bool, contour: int) -> void:
	const SIDES := 10
	# Lower break, steep walls, stepped shoulders, then an oblique crown.
	var widths := [0.94, 1.0, 0.88, 0.87, 0.69, rng.randf_range(0.39, 0.58), 0.28]
	var levels := [0.0, 0.13, 0.34, 0.57, 0.71, 0.83, 0.94]
	var phase := rng.randf_range(0.0, TAU)
	var drift := lean * footprint * 0.18 * rng.randf_range(0.7, 1.25)
	match contour:
		KarstContour.SPLIT_RIDGE:
			widths = [1.0, 1.02, 0.83, 0.69, 0.60, 0.44, 0.25]
		KarstContour.SPIRE:
			widths = [0.91, 1.0, 0.76, 0.69, 0.55, 0.36, 0.19]
			levels = [0.0, 0.08, 0.24, 0.53, 0.73, 0.87, 0.95]
			drift *= 1.4
		KarstContour.SHELVED_BLUFF:
			widths = [1.0, 1.08, 0.89, 0.93, 0.63, 0.67, 0.43]
			levels = [0.0, 0.14, 0.40, 0.48, 0.69, 0.77, 0.91]
			drift *= 0.75
	var rings: Array[PackedVector3Array] = []
	var bearings := PackedVector2Array()
	var wall_heights := PackedFloat32Array()
	var face_tints := PackedFloat32Array()
	for side in SIDES:
		var angle := phase + TAU * (side + rng.randf_range(-0.21, 0.21)) / SIDES
		bearings.append(Vector2.from_angle(angle) * rng.randf_range(0.77, 1.19))
		wall_heights.append(rng.randf_range(-0.075, 0.065))
		face_tints.append(rng.randf_range(-0.075, 0.055))

	for level in levels.size():
		var t: float = levels[level]
		var level_center := center + drift * sin(t * PI)
		var ring := PackedVector3Array()
		for side in SIDES:
			var bearing := bearings[side]
			var shoulder := sin(float(side) * 1.8 + phase + t * 2.5)
			var width: float = widths[level] * (1.0 + shoulder * (0.07 + t * 0.19))
			if contour == KarstContour.SPIRE and level < 2:
				# A scalloped waterline reads as an undercut beneath the standing wall.
				width *= 1.0 - posmod(side + 2, SIDES) % 3 * 0.045
			var p := level_center + footprint * bearing * (width * 0.5)
			var y := (t + wall_heights[side] * smoothstep(0.02, 0.58, t)) * height
			y += height * shoulder * 0.028 * sin(t * PI)
			ring.append(Vector3(p.x, y - 0.28, p.y))
		rings.append(ring)

	var green_start := rng.randi_range(0, SIDES - 1)
	for level in range(rings.size() - 1):
		for side in SIDES:
			var next := (side + 1) % SIDES
			var a := rings[level][side]
			var b := rings[level][next]
			var c := rings[level + 1][next]
			var d := rings[level + 1][side]
			var tone := face_tints[side] + rng.randf_range(-0.018, 0.018)
			var stone := body.lightened(maxf(0.0, tone)).darkened(maxf(0.0, -tone))
			if level == 0:
				stone = stone.lerp(accent.darkened(0.2), 0.29)
			elif level >= 4:
				stone = stone.lerp(accent, 0.11)
			var green_side := posmod(side - green_start, SIDES)
			if level == 5 and green_side < 6:
				stone = stone.lerp(accent, 0.44 if green_side == 0 or green_side == 5 else 0.69)
			elif level == 4 and green_side < 5:
				stone = stone.lerp(accent, 0.52)
			elif level == 3 and green_side in [1, 2]:
				stone = stone.lerp(accent, 0.41)
			var outward := Vector3(bearings[side].x + bearings[next].x, 0.0, bearings[side].y + bearings[next].y)
			_karst_face(a, b, c, outward, stone)
			_karst_face(a, c, d, outward, stone.lerp(body, 0.18))
	var summit := Vector3(center.x, height * 0.97 - 0.28, center.y)
	var crown := rings.back() as PackedVector3Array
	for side in SIDES:
		var green_side := posmod(side - green_start, SIDES)
		var crown_tint := body.lerp(accent, 0.86 if green_side < 7 else 0.46)
		_karst_face(summit, crown[side], crown[(side + 1) % SIDES], Vector3.UP, crown_tint)
		var bottom := Vector3(center.x, -0.28, center.y)
		_karst_face(bottom, rings[0][side], rings[0][(side + 1) % SIDES], Vector3.DOWN, body.darkened(0.23))

	# Let the canopy spill from the ridge onto selected shoulders.
	for patch in (5 if main else 3):
		var side := (green_start + patch) % SIDES
		var next := (side + 1) % SIDES
		var ledge := rings[5][side].lerp(rings[5][next], 0.55)
		var rim := rings[6][side].lerp(rings[6][next], 0.55)
		var at := ledge.lerp(rim, rng.randf_range(0.58, 0.86))
		var tint := accent.lerp(Color(0.56, 0.64, 0.40), rng.randf_range(0.18, 0.38))
		var size := Vector3(footprint.x * 0.245, height * 0.105, footprint.y * 0.25)
		_karst_canopy(canopy, at.lerp(rim, 0.16), size, tint.darkened(0.10))
		_karst_canopy(canopy, rim.lerp(summit, 0.27), size * 0.89, tint.lightened(0.095))
		_karst_canopy(canopy, at.lerp(rings[6][next], 0.44), size * 0.72, tint)
		var shelf := rings[4][side].lerp(rings[4][next], 0.42)
		var fringe := shelf.lerp(ledge, 0.54 + 0.12 * cos(float(patch)))
		_karst_canopy(canopy, fringe, size * Vector3(0.98, 0.72, 0.94), tint.darkened(0.13))
		_karst_canopy(canopy, fringe.lerp(ledge, 0.42), size * 0.82, tint)
		if patch in [1, 2]:
			var lower_shelf := rings[3][side].lerp(rings[3][next], 0.52)
			var apron := shelf.lerp(lower_shelf, 0.36 + float(patch) * 0.18)
			_karst_canopy(canopy, shelf, size * Vector3(0.94, 0.78, 0.88), tint)
			_karst_canopy(canopy, apron, size * Vector3(0.77, 0.93, 0.74), tint.darkened(0.14))
			_karst_canopy(canopy, apron.lerp(rings[4][next], 0.24), size * 0.67, tint.lightened(0.07))

	# A second band wraps the crown, with its mass centered on the summit faces.
	for patch in (7 if main else 5):
		var side := (green_start + SIDES - patch) % SIDES
		var edge := crown[side].lerp(crown[(side + 1) % SIDES], 0.42)
		var lift := 0.25 + 0.17 * sin(float(side) + phase)
		var at := edge.lerp(summit, lift)
		var width := 0.20 + 0.025 * cos(float(side) * 2.0 + phase)
		var size := Vector3(footprint.x * width, height * 0.091, footprint.y * width)
		var tint := accent.lerp(Color(0.58, 0.67, 0.43), 0.26 + 0.11 * sin(float(side) + phase))
		_karst_canopy(canopy, at, size, tint)
		_karst_canopy(canopy, at.lerp(summit, 0.37), size * 0.63, tint.lightened(0.11))

func _karst_canopy(canopy: SphereMesh, at: Vector3, size: Vector3, tint: Color) -> void:
	# Sink the underside into the limestone so each crown follows the landform.
	var center := at + Vector3.UP * size.y * 0.11
	append(canopy, Transform3D(Basis.IDENTITY.scaled(size), center), tint, 2)

func _karst_face(a: Vector3, b: Vector3, c: Vector3, outward: Vector3, tint: Color) -> void:
	var normal := (b - a).cross(c - a).normalized()
	if normal.dot(outward) < 0.0:
		normal = -normal
		vertex(a, normal, tint)
		vertex(b, normal, tint)
		vertex(c, normal, tint)
	else:
		vertex(a, normal, tint)
		vertex(c, normal, tint)
		vertex(b, normal, tint)
