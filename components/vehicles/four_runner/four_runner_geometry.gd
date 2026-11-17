@tool
extends "res://components/scenery/concert/shared/concert_geometry.gd"
## Stylized 2018 five-door 4Runner exterior. Front is +Z; ground root.

func ellipse(at: Vector3, size: Vector2, color: Color, rotation := Basis.IDENTITY) -> void:
	var points: Array[Vector3] = []
	for i in range(17):
		var a := TAU * i / 16.0
		points.append(at + rotation * Vector3(cos(a) * size.x, sin(a) * size.y, 0))
	tube(points, 0.006, color, 4)

func badge(at: Vector3, rotation := Basis.IDENTITY) -> void:
	ellipse(at, Vector2(0.072, 0.047), accent, rotation)
	ellipse(at, Vector2(0.027, 0.044), accent, rotation)
	ellipse(at + rotation * Vector3(0, 0.012, 0.002), Vector2(0.063, 0.020), accent, rotation)

func section(z: float, height: float, top_width: float) -> Array[Vector3]:
	return [Vector3(-0.94, 1.14, z), Vector3(-0.96, 1.22, z), Vector3(-top_width, height - 0.05, z), Vector3(-top_width + 0.07, height, z), Vector3(top_width - 0.07, height, z), Vector3(top_width, height - 0.05, z), Vector3(0.96, 1.22, z), Vector3(0.94, 1.14, z)]

func cabin() -> void:
	var rings := [section(-2.20, 1.48, 0.84), section(-1.91, 1.80, 0.79), section(0.36, 1.80, 0.79), section(1.04, 1.23, 0.91)]
	for row in range(rings.size() - 1):
		for i in range(8):
			var j := (i + 1) % 8
			quad(rings[row][i], rings[row][j], rings[row + 1][j], rings[row + 1][i], body)
	quad(rings[0][0], rings[0][1], rings[0][6], rings[0][7], body)
	quad(rings[0][1], rings[0][2], rings[0][5], rings[0][6], body)
	quad(rings[0][2], rings[0][3], rings[0][4], rings[0][5], body)

func side_glass(points: PackedVector2Array, side: float, glass: Color) -> void:
	# Coordinates are longitudinal Z / height. Follow the tapered cabin side.
	var ids := Geometry2D.triangulate_polygon(points)
	for i in ids:
		var p := points[i]
		var x := lerpf(0.96, 0.79, clampf((p.y - 1.22) / 0.53, 0, 1)) + 0.012
		vertex(Vector3(side * x, p.y, p.x), Vector3(side, 0.25, 0).normalized(), glass, 1)

func front_panel(points: PackedVector2Array, z: float, color: Color, kind: float = 0.0) -> void:
	profile(points, Vector3(0, 0, z), 0.015, color, kind)

func rounded_polygon(points: PackedVector2Array) -> PackedVector2Array:
	# Bounded corner rounding avoids Catmull overshoot on the long body panels.
	var result := PackedVector2Array()
	for i in range(points.size()):
		var p := points[i]
		var before := points[posmod(i - 1, points.size())]
		var after := points[(i + 1) % points.size()]
		var a := p.move_toward(before, minf(0.04, p.distance_to(before) * 0.2))
		var b := p.move_toward(after, minf(0.04, p.distance_to(after) * 0.2))
		for j in range(4):
			var t := j / 3.0
			result.append(a * (1 - t) * (1 - t) + p * 2 * t * (1 - t) + b * t * t)
	return result

func wheel(at: Vector3, side: float) -> void:
	var axis := Vector3.RIGHT * side
	disc(at, 0.39, 0.25, Color("303b3b"), axis, 0, 40)
	var face := at + axis * 0.132
	disc(face, 0.282, 0.025, Color("4b5654"), axis, 0, 32)
	disc(face + axis * 0.016, 0.231, 0.025, accent, axis, 0, 32)
	disc(face + axis * 0.032, 0.182, 0.012, Color("59635f"), axis, 0, 24)
	for i in range(6):
		var a := TAU * i / 6.0
		var direction := Vector3(0, cos(a), sin(a))
		rod(face + axis * 0.042 + direction * 0.065, face + axis * 0.042 + direction * 0.215, 0.028, accent.lightened(0.04), 8)
	disc(face + axis * 0.047, 0.074, 0.020, accent.lightened(0.08), axis, 0, 20)
	# Broad sidewall rings keep the wheels round without a noisy tread texture.
	var previous := frame
	for sign_x: float in [-1.0, 1.0]:
		var outline: Array[Vector3] = []
		for i in range(33):
			var a := TAU * i / 32.0
			outline.append(at + Vector3(sign_x * 0.11, cos(a) * 0.365, sin(a) * 0.365))
		tube(outline, 0.014, Color("354040"), 4)
	frame = previous

func car(c: Dictionary) -> Dictionary:
	begin(c)
	var glass := Color("596e73")
	var outline := PackedVector2Array()
	# Side silhouette with actual arch cutouts through the lower body.
	outline.append(Vector2(2.31, 0.55))
	for center: float in [-1.40, 1.40]:
		for p in [Vector2(-0.48,0.55), Vector2(-0.40,0.80), Vector2(-0.30,0.88), Vector2(0.30,0.88), Vector2(0.40,0.80), Vector2(0.48,0.55)]:
			outline.append(Vector2(-(center + p.x), p.y))
	outline.append_array(PackedVector2Array([Vector2(-2.28,0.55), Vector2(-2.36,0.68), Vector2(-2.32,1.07), Vector2(-2.20,1.19), Vector2(2.18,1.19), Vector2(2.32,1.08)]))
	var previous := frame
	frame = Transform3D(Basis(Vector3.UP, PI * 0.5), Vector3.ZERO)
	profile(rounded_polygon(outline), Vector3.ZERO, 1.90, body)
	frame = previous
	soft_box(Vector3(0, 0.48, 0), Vector3(1.62, 0.12, 3.80), brass.darkened(0.15), 0.04)
	cabin()
	# Hood with shallow pressed shoulders and a modest rearward rise.
	quad(Vector3(-0.86,1.18,2.24), Vector3(0.86,1.18,2.24), Vector3(0.92,1.27,1.03), Vector3(-0.92,1.27,1.03), body.lightened(0.035))
	quad(Vector3(-0.86,1.18,2.24), Vector3(-0.92,1.27,1.03), Vector3(-0.67,1.31,1.03), Vector3(-0.66,1.22,2.08), body)
	quad(Vector3(0.86,1.18,2.24), Vector3(0.66,1.22,2.08), Vector3(0.67,1.31,1.03), Vector3(0.92,1.27,1.03), body)
	quad(Vector3(-0.66,1.22,2.08), Vector3(-0.67,1.31,1.03), Vector3(0.67,1.31,1.03), Vector3(0.66,1.22,2.08), body.lightened(0.015))
	for side: float in [-1.0, 1.0]:
		side_glass(PackedVector2Array([Vector2(0.84,1.29),Vector2(0.28,1.71),Vector2(-0.06,1.71),Vector2(-0.06,1.29)]), side, glass)
		side_glass(PackedVector2Array([Vector2(-0.19,1.29),Vector2(-0.19,1.71),Vector2(-0.91,1.71),Vector2(-0.91,1.29)]), side, glass.darkened(0.05))
		side_glass(PackedVector2Array([Vector2(-1.04,1.29),Vector2(-1.04,1.71),Vector2(-1.76,1.71),Vector2(-2.04,1.38),Vector2(-2.04,1.29)]), side, glass.darkened(0.10))
		for z: float in [0.41, -0.73]:
			soft_box(Vector3(side * 0.965, 1.075, z), Vector3(0.035,0.055,0.18), brass, 0.015)
		for z: float in [-0.14, 0.94]:
			rod(Vector3(side * 0.956,0.63,z), Vector3(side * 0.956,1.19,z), 0.006, body.darkened(0.18), 6)
		soft_box(Vector3(side * 1.01,0.42,-0.15), Vector3(0.13,0.09,2.20), brass, 0.035)
		rod(Vector3(side * 0.90,1.28,0.71), Vector3(side * 1.08,1.31,0.73), 0.028, brass, 10)
		soft_box(Vector3(side * 1.10,1.33,0.75), Vector3(0.19,0.14,0.22), body, 0.035)
		box(Vector3(side * 1.10,1.33,0.635), Vector3(0.14,0.10,0.008), glass, 1)
		for z: float in [-1.40, 1.40]:
			wheel(Vector3(side * 0.84, 0.395, z), side)
			var arch := [Vector2(-0.48,0.57),Vector2(-0.40,0.80),Vector2(-0.30,0.90),Vector2(0.30,0.90),Vector2(0.40,0.80),Vector2(0.48,0.57)]
			for i in range(arch.size()-1):
				var a: Vector2 = arch[i]
				var b: Vector2 = arch[i+1]
				quad(Vector3(side*0.982,a.y,z+a.x),Vector3(side*0.982,b.y,z+b.x),Vector3(side*0.976,b.y+0.07,z+b.x),Vector3(side*0.976,a.y+0.07,z+a.x),body.darkened(0.08))
	# Windshield follows the sloping front cabin face; no transparent interior pass.
	var wind: Array[Vector3] = []
	for xy: Vector2 in [Vector2(-0.79,1.31),Vector2(0.79,1.31),Vector2(0.70,1.72),Vector2(-0.70,1.72)]:
		wind.append(Vector3(xy.x,xy.y,0.36+(1.80-xy.y)*0.68/0.57+0.012))
	quad(wind[0],wind[1],wind[2],wind[3],glass,1)
	for x: float in [-0.34, 0.34]:
		rod(Vector3(x-0.18,1.30,0.99),Vector3(x+0.20,1.33,0.98),0.009,brass,6)
	# 2018's stepped front fascia: upper slot, deep lower grille and fog pockets.
	front_panel(PackedVector2Array([Vector2(-0.48,1.04),Vector2(0.48,1.04),Vector2(0.39,1.16),Vector2(-0.39,1.16)]),2.405,brass.darkened(0.2))
	front_panel(PackedVector2Array([Vector2(-0.54,0.64),Vector2(0.54,0.64),Vector2(0.50,0.94),Vector2(-0.50,0.94)]),2.410,brass.darkened(0.25))
	for y: float in [0.70,0.78,0.86]:
		box(Vector3(0,y,2.430),Vector3(0.98,0.013,0.015),brass.lightened(0.03))
	for i in range(11):
		var x := -0.44 + i * 0.088
		rod(Vector3(x,0.66,2.430),Vector3(x+0.055,0.91,2.430),0.006,brass.lightened(0.05),6)
	soft_box(Vector3(0,0.99,2.415),Vector3(1.03,0.12,0.065),body,0.025)
	badge(Vector3(0,1.09,2.430))
	soft_box(Vector3(0,0.56,2.30),Vector3(1.74,0.15,0.18),body.darkened(0.10),0.05)
	for side: float in [-1.0,1.0]:
		var lamp := PackedVector2Array([Vector2(side*0.50,1.03),Vector2(side*0.88,1.04),Vector2(side*0.91,1.18),Vector2(side*0.48,1.17)])
		front_panel(lamp,2.405,Color("cdd3bf"),4)
		disc(Vector3(side*0.65,1.105,2.424),0.045,0.010,brass,Vector3.BACK,0,20)
		disc(Vector3(side*0.65,1.105,2.433),0.029,0.006,Color("d0d8c7"),Vector3.BACK,4,20)
		quad(Vector3(side*0.966,1.05,2.26),Vector3(side*0.966,1.05,2.06),Vector3(side*0.966,1.16,2.03),Vector3(side*0.966,1.17,2.30),Color("c5ccbc"),4)
		box(Vector3(side*0.87,1.11,2.418),Vector3(0.05,0.08,0.014),Color("d6a158"))
		soft_box(Vector3(side*0.76,0.77,2.395),Vector3(0.22,0.25,0.035),brass,0.04)
		disc(Vector3(side*0.76,0.79,2.420),0.064,0.012,Color("b8c1b4"),Vector3.BACK,4,20)
	# Rear hatch, spoiler, stacked lamps and a blank plate rather than invented ID.
	quad(Vector3(-0.79,1.37,-2.212),Vector3(-0.75,1.48,-2.212),Vector3(0.75,1.48,-2.212),Vector3(0.79,1.37,-2.212),glass.darkened(0.12),1)
	quad(Vector3(-0.75,1.48,-2.212),Vector3(-0.69,1.71,-2.004),Vector3(0.69,1.71,-2.004),Vector3(0.75,1.48,-2.212),glass.darkened(0.12),1)
	soft_box(Vector3(0,1.80,-1.99),Vector3(1.62,0.07,0.34),body,0.025)
	box(Vector3(0,1.788,-2.164),Vector3(0.38,0.028,0.018),Color("b86755"))
	for side: float in [-1.0,1.0]:
		soft_box(Vector3(side*0.825,1.17,-2.39),Vector3(0.20,0.40,0.065),Color("984f47"),0.04)
		box(Vector3(side*0.825,1.27,-2.428),Vector3(0.17,0.075,0.015),Color("c9c9b7"))
	soft_box(Vector3(0,0.57,-2.31),Vector3(1.80,0.16,0.18),body.darkened(0.08),0.04)
	soft_box(Vector3(0,0.93,-2.405),Vector3(0.39,0.19,0.028),accent.darkened(0.10),0.025)
	badge(Vector3(0,1.18,-2.43),Basis(Vector3.UP,PI))
	text("4RUNNER",Vector3(0,1.07,-2.43),0.058,accent,Basis(Vector3.UP,PI))
	soft_box(Vector3(0,0.37,-2.34),Vector3(0.13,0.11,0.18),brass,0.015)
	if c.roof_rack_enabled:
		for side: float in [-1.0,1.0]:
			for z: float in [-1.62,0.16]:
				box(Vector3(side*0.66,1.83,z),Vector3(0.09,0.11,0.14),brass)
			rod(Vector3(side*0.66,1.89,-1.68),Vector3(side*0.66,1.89,0.22),0.026,accent,10)
		for z: float in [-1.23,-0.10]:
			rod(Vector3(-0.67,1.90,z),Vector3(0.67,1.90,z),0.022,brass,10)
	collider(Vector3(0,1.02,0),Vector3(2.04,1.55,4.75),"ParkedVehicle")
	anchors={"Front":Vector3(0,0,3.0),"Rear":Vector3(0,0,-3.0),"DriverDoor":Vector3(-1.45,0,0.15),"PassengerDoor":Vector3(1.45,0,0.15),"Roof":Vector3(0,1.95,-0.75)}
	return finish()
