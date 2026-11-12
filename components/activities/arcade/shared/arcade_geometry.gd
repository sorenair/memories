@tool
extends RefCounted
const PINBALL = preload("res://components/activities/arcade/pinball/pinball_layout.gd")
## Small opaque, vertex-painted mechanical props. Front is local +Z.
var s: SurfaceTool
var frame := Transform3D.IDENTITY
var rng := RandomNumberGenerator.new()
var ink := Color("343b40")
var body: Color
var accent: Color
var brass: Color
var ivory: Color
var wood := Color("725546")
var colliders: Array[Dictionary] = []
var anchors: Dictionary = {}
var parts: Dictionary = {}
var _part_stack: Array = []
var _outline_tool: SurfaceTool
var _record_outline := false

# Keep moving pieces in small opaque batches; the rest stays in the original mesh.
func begin_part(id: StringName, pivot: Vector3) -> void:
	_part_stack.append([s, frame])
	if not parts.has(id):
		var tool := SurfaceTool.new()
		tool.begin(Mesh.PRIMITIVE_TRIANGLES)
		parts[id] = {"tool":tool, "pivot":pivot}
	s = parts[id].tool
	frame = Transform3D(Basis.IDENTITY, -pivot) * frame

func end_part() -> void:
	var previous: Array = _part_stack.pop_back()
	s = previous[0]
	frame = previous[1]

func vertex(p: Vector3, n: Vector3, color: Color, kind: float = 0.0) -> void:
	s.set_normal((frame.basis.inverse().transposed() * n).normalized())
	s.set_color(color.srgb_to_linear())
	s.set_uv2(Vector2(kind, 0.0))
	s.add_vertex(frame * p)
	if _record_outline and _outline_tool:
		_outline_tool.set_normal((frame.basis.inverse().transposed() * n).normalized())
		_outline_tool.add_vertex(frame * p)

func quad(a: Vector3, b: Vector3, c: Vector3, d: Vector3, color: Color, kind: float = 0.0) -> void:
	var n := (b-a).cross(c-a).normalized()
	for p in [a,b,c,a,c,d]: vertex(p,n,color,kind)

func append(mesh: Mesh, transform: Transform3D, color: Color, kind: float = 0.0) -> void:
	var arrays := mesh.surface_get_arrays(0)
	var points: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var ids: PackedInt32Array = arrays[Mesh.ARRAY_INDEX] if arrays[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
	if ids.is_empty():
		for i in range(points.size()): ids.append(i)
	var normal_basis := transform.basis.inverse().transposed()
	for i in ids:
		vertex(transform * points[i], normal_basis * normals[i], color, kind)

func box(center: Vector3, size: Vector3, color: Color, kind: float = 0.0, rotation := Basis.IDENTITY) -> void:
	var mesh := BoxMesh.new()
	mesh.size = size.max(Vector3.ONE * 0.001)
	append(mesh, Transform3D(rotation, center), color, kind)

func profile(points: PackedVector2Array, center: Vector3, depth: float, color: Color, kind: float = 0.0) -> void:
	var ids := Geometry2D.triangulate_polygon(points)
	for z in [-depth * 0.5, depth * 0.5]:
		var normal := Vector3(0,0,signf(z))
		for i in ids: vertex(center + Vector3(points[i].x, points[i].y, z), normal, color, kind)
	for i in range(points.size()):
		var a := points[i]
		var b := points[(i+1)%points.size()]
		quad(center+Vector3(a.x,a.y,-depth*0.5),center+Vector3(b.x,b.y,-depth*0.5),center+Vector3(b.x,b.y,depth*0.5),center+Vector3(a.x,a.y,depth*0.5),color.darkened(0.025),kind)

func smooth_outline(points: PackedVector2Array, closed: bool = true, steps: int = 3) -> PackedVector2Array:
	var result := PackedVector2Array()
	var count := points.size()
	for i in range(count if closed else count-1):
		var p0 := points[posmod(i-1,count)] if closed else points[maxi(0,i-1)]
		var p1 := points[i]
		var p2 := points[(i+1)%count]
		var p3 := points[(i+2)%count] if closed else points[mini(count-1,i+2)]
		for j in range(steps):
			var t := float(j)/steps
			result.append(0.5*((2.0*p1)+(-p0+p2)*t+(2.0*p0-5.0*p1+4.0*p2-p3)*t*t+(-p0+3.0*p1-3.0*p2+p3)*t*t*t))
	if not closed: result.append(points[count-1])
	return result

func soft_box(center: Vector3, size: Vector3, color: Color, bevel: float = 0.035, kind: float = 0.0) -> void:
	var x := size.x * 0.5
	var y := size.y * 0.5
	var b := minf(bevel, minf(x,y)*0.45)
	var outline := PackedVector2Array([Vector2(-x+b,-y),Vector2(x-b,-y),Vector2(x,-y+b),Vector2(x,y-b),Vector2(x-b,y),Vector2(-x+b,y),Vector2(-x,y-b),Vector2(-x,-y+b)])
	profile(outline,center,size.z,color,kind)

func rod(a: Vector3, b: Vector3, radius: float, color: Color, sides: int = 10) -> void:
	var direction := b-a
	if direction.length() < 0.0001: return
	var y := direction.normalized()
	var reference := Vector3.BACK if absf(y.dot(Vector3.BACK)) < 0.97 else Vector3.RIGHT
	var x := y.cross(reference).normalized()
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = direction.length()
	mesh.radial_segments = sides
	mesh.rings = 0
	append(mesh, Transform3D(Basis(x,y,x.cross(y)),(a+b)*0.5),color)

func tube(points: Array[Vector3], radius: float, color: Color, sides: int = 8) -> void:
	for i in range(points.size()-1): rod(points[i],points[i+1],radius,color,sides)

func disc(center: Vector3, radius: float, depth: float, color: Color, axis := Vector3.UP, kind: float = 0.0, sides: int = 24) -> void:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = depth
	mesh.radial_segments = sides
	mesh.rings = 0
	var y := axis.normalized()
	var reference := Vector3.BACK if absf(y.dot(Vector3.BACK)) < 0.97 else Vector3.RIGHT
	var x := y.cross(reference).normalized()
	append(mesh,Transform3D(Basis(x,y,x.cross(y)),center),color,kind)

func ball(center: Vector3, size: Vector3, color: Color, kind: float = 0.0) -> void:
	var mesh := SphereMesh.new()
	mesh.radius = 0.5
	mesh.height = 1.0
	mesh.radial_segments = 12
	mesh.rings = 6
	append(mesh,Transform3D(Basis.IDENTITY.scaled(size),center),color,kind)

func text(value: String, center: Vector3, height: float, color: Color, rotation := Basis.IDENTITY) -> void:
	var mesh := TextMesh.new()
	mesh.text = value
	mesh.font = ThemeDB.fallback_font
	mesh.font_size = 48
	mesh.pixel_size = height / 48.0
	mesh.depth = 0.0
	mesh.curve_step = 2.0
	append(mesh,Transform3D(rotation,center),color)

func star(center: Vector3, radius: float, color: Color, rotation: float = 0.0) -> void:
	var points := PackedVector2Array()
	for i in range(10):
		var angle := TAU * i / 10.0 + PI * 0.5 + rotation
		points.append(Vector2(cos(angle),sin(angle)) * radius * (1.0 if i%2==0 else 0.42))
	profile(points, center, 0.004, color)

func gear(center: Vector3, radius: float) -> void:
	var points := PackedVector2Array()
	for i in range(32):
		var angle := TAU * i / 32.0
		points.append(Vector2(cos(angle),sin(angle))*radius*(1.0 if i%4 in [1,2] else 0.80))
	profile(points,center,0.045,brass)
	disc(center+Vector3(0,0,0.027),radius*0.31,0.014,ink,Vector3.BACK)
	disc(center+Vector3(0,0,0.04),radius*0.13,0.015,ivory,Vector3.BACK,0,12)

func collider(center: Vector3, size: Vector3, name: String) -> void:
	colliders.append({"center":center,"size":size,"name":name})

func pinball() -> void:
	_record_outline = true
	# Legs, wedge cabinet, and sloping playfield: solid painted shapes, no glass pass.
	for x in [-0.36,0.36]:
		for z in [-0.57,0.57]:
			rod(Vector3(x*1.13,0.06,z*1.1),Vector3(x,0.83,z),0.033,brass)
			disc(Vector3(x*1.13,0.04,z*1.1),0.06,0.04,ink)
	var a:=Vector3(-0.43,0.80,0.70); var b:=Vector3(0.43,0.80,0.70)
	var c:=Vector3(0.43,1.10,-0.70); var d:=Vector3(-0.43,1.10,-0.70)
	quad(a,b,c,d,body)
	quad(a-Vector3(0,0.19,0),a,d,d-Vector3(0,0.19,0),body.darkened(0.1))
	quad(b,c,c-Vector3(0,0.19,0),b-Vector3(0,0.19,0),body)
	box(Vector3(0,0.73,0.69),Vector3(0.86,0.2,0.07),body)
	var y := func(z: float) -> float: return PINBALL.surface_y(z)
	quad(Vector3(-0.37,y.call(0.59),0.59),Vector3(0.37,y.call(0.59),0.59),Vector3(0.37,y.call(-0.61),-0.61),Vector3(-0.37,y.call(-0.61),-0.61),Color("647c74"))
	for x in [-0.405,0.405]:
		rod(Vector3(x,y.call(0.66)+0.02,0.66),Vector3(x,y.call(-0.66)+0.02,-0.66),0.027,ivory)
	for z in [-0.66,0.66]: rod(Vector3(-0.4,y.call(z)+0.02,z),Vector3(0.4,y.call(z)+0.02,z),0.024,brass)
	_record_outline = false
	# Bumpers, raised orbit, slingshots, and flippers. The live ball is separate.
	for point in PINBALL.BUMPERS:
		var p:=Vector3(point.x,y.call(point.y)+0.024,point.y)
		disc(p,PINBALL.BUMPER_RADIUS,0.04,brass)
		disc(p+Vector3.UP*0.035,0.081,0.038,accent)
		disc(p+Vector3.UP*0.059,0.045,0.012,ivory,Vector3.UP,2.0,16)
	var orbit: Array[Vector3] = []
	for i in range(18):
		var angle:=lerpf(-0.7,3.7,float(i)/17.0)
		var z: float = -0.15+sin(angle)*0.36
		orbit.append(Vector3(cos(angle)*0.29,y.call(z)+0.055,z))
	tube(orbit,0.011,brass)
	for z in [-0.48,0.08,0.28]:
		disc(Vector3(-0.17,y.call(z)+0.004,z),0.055,0.005,Color("9eaf8d"),Vector3.UP,0,12)
	for flipper in PINBALL.flippers():
		rod(PINBALL.on_surface(flipper.a,0.03),PINBALL.on_surface(flipper.b,0.03),flipper.radius,ivory)
	for center in PINBALL.slings():
		ball(PINBALL.on_surface(center,0.035),Vector3(PINBALL.SLING_RADIUS*2.0,0.055,(PINBALL.SLING_RADIUS+PINBALL.SLING_HALF_RUN)*2.0),accent)
	for point in PINBALL.posts():
		disc(PINBALL.on_surface(point,0.015),PINBALL.POST_RADIUS,0.014,ivory,Vector3.UP,2.0,8)
	# A narrow shooter lane and a banked guide send the launch into the upper field.
	rod(PINBALL.on_surface(PINBALL.GUIDE_A,0.025),PINBALL.on_surface(PINBALL.GUIDE_B,0.025),PINBALL.GUIDE_RADIUS,brass)
	rod(PINBALL.on_surface(PINBALL.DEFLECTOR_A,0.025),PINBALL.on_surface(PINBALL.DEFLECTOR_B,0.025),PINBALL.DEFLECTOR_RADIUS,ivory)
	_record_outline = true
	soft_box(Vector3(0,1.47,-0.72),Vector3(0.98,0.76,0.22),body,0.075)
	_record_outline = false
	soft_box(Vector3(0,1.49,-0.596),Vector3(0.86,0.62,0.026),brass,0.045)
	soft_box(Vector3(0,1.52,-0.575),Vector3(0.78,0.49,0.02),ivory,0.035)
	text("PINBALL",Vector3(0,1.58,-0.556),0.145,body)
	star(Vector3(-0.27,1.39,-0.552),0.067,accent)
	star(Vector3(0.27,1.71,-0.552),0.055,accent,0.2)
	soft_box(Vector3(0,1.31,-0.548),Vector3(0.58,0.105,0.016),ink,0.015)
	# An orbit graphic on each side and a coin door at the front.
	for side in [-1.0,1.0]:
		for i in range(4):
			var z: float = -0.38+i*0.21
			ball(Vector3(side*0.435,y.call(z)-0.095,z),Vector3(0.015,0.055,0.12),accent.lightened(i*0.035))
	soft_box(Vector3(0,0.715,0.738),Vector3(0.22,0.13,0.012),ink,0.018)
	box(Vector3(0,0.74,0.751),Vector3(0.095,0.012,0.005),brass)
	ball(Vector3(0.43,0.91,0.53),Vector3(0.047,0.06,0.07),accent)
	collider(Vector3(0,0.96,0),Vector3(0.98,1.92,1.52),"Cabinet")
	anchors = {"Play":Vector3(0,0.85,1.13),"Ball":PINBALL.ball_center(PINBALL.HOME)}

func punching_bag() -> void:
	_record_outline = true
	soft_box(Vector3(0,0.075,0.21),Vector3(0.93,0.15,1.12),ink,0.1)
	soft_box(Vector3(0,0.94,-0.28),Vector3(0.78,1.77,0.43),body,0.13)
	soft_box(Vector3(0,1.91,0.02),Vector3(0.94,0.5,1.03),body,0.09)
	_record_outline = false
	soft_box(Vector3(0,1.96,0.553),Vector3(0.82,0.30,0.035),ivory,0.05)
	text("STRIKE",Vector3(0,2.005,0.578),0.115,body)
	soft_box(Vector3(0,1.86,0.58),Vector3(0.47,0.105,0.02),ink,0.015)
	disc(Vector3(0,1.7,0.31),0.13,0.07,brass)
	rod(Vector3(0,1.71,0.31),Vector3(0,1.56,0.31),0.025,ink)
	soft_box(Vector3(0,0.6,-0.047),Vector3(0.48,0.46,0.025),ink,0.05)
	star(Vector3(0,0.64,-0.029),0.115,brass)
	box(Vector3(0,0.44,-0.022),Vector3(0.13,0.018,0.014),brass)
	for x in [-0.28,0.28]:
		rod(Vector3(x,0.17,0.65),Vector3(x,0.17,-0.12),0.012,brass)
	collider(Vector3(0,1.08,0.15),Vector3(0.98,2.16,1.16),"PunchCabinet")
	anchors = {"Punch":Vector3(0,1.25,0.99),"BagPivot":Vector3(0,1.57,0.31)}

func punching_bag_leather() -> void:
	# Smooth lathed leather pear, with broad hand-painted panels and stitched seam.
	var rings := smooth_outline(PackedVector2Array([Vector2(0.00,0.025),Vector2(0.06,0.09),Vector2(0.17,0.165),Vector2(0.30,0.20),Vector2(0.43,0.17),Vector2(0.56,0.095),Vector2(0.65,0.035)]),false)
	var bottom := Vector3(0,0.92,0.31)
	for j in range(rings.size()-1):
		for i in range(24):
			for uv in [Vector2(0,0),Vector2(1,0),Vector2(1,1),Vector2(0,0),Vector2(1,1),Vector2(0,1)]:
				var row:=j+int(uv.y)
				var angle: float = TAU*(i+uv.x)/24.0
				var r:=rings[row]
				var prev:=rings[maxi(0,row-1)]; var next:=rings[mini(rings.size()-1,row+1)]
				var slope:=-(next.y-prev.y)/maxf(0.001,next.x-prev.x)
				var normal:=Vector3(cos(angle),slope,sin(angle)).normalized()
				vertex(bottom+Vector3(cos(angle)*r.y,r.x,sin(angle)*r.y),normal,accent.darkened(0.07 if i/6%2 else 0.0))
	var seam: Array[Vector3] = []
	for r in rings:
		seam.append(bottom+Vector3(0,r.x,r.y+0.002))
	tube(seam,0.004,ivory.darkened(0.1),6)
	for j in range(6):
		var y:=1.07+j*0.042
		rod(Vector3(-0.012,y,0.49),Vector3(0.012,y+0.012,0.49),0.003,ivory,6)

func guitar() -> void:
	var old:=frame
	frame = frame * Transform3D(Basis(Vector3.BACK,-0.17),Vector3(-1.58,0.44,0))
	var outline:=PackedVector2Array([Vector2(-0.05,-0.34),Vector2(-0.24,-0.30),Vector2(-0.32,-0.17),Vector2(-0.31,-0.03),Vector2(-0.20,0.10),Vector2(-0.24,0.25),Vector2(-0.20,0.38),Vector2(-0.08,0.42),Vector2(0.08,0.42),Vector2(0.20,0.38),Vector2(0.24,0.25),Vector2(0.20,0.10),Vector2(0.31,-0.03),Vector2(0.32,-0.17),Vector2(0.24,-0.30),Vector2(0.05,-0.34)])
	outline = smooth_outline(outline)
	profile(outline,Vector3.ZERO,0.15,wood)
	profile(outline,Vector3(0,0,0.083),0.015,accent)
	disc(Vector3(0,0.15,0.101),0.105,0.01,brass,Vector3.BACK)
	disc(Vector3(0,0.15,0.109),0.084,0.012,ink,Vector3.BACK)
	soft_box(Vector3(0,0.68,0.015),Vector3(0.105,0.64,0.09),wood,0.015)
	soft_box(Vector3(0,1.07,0.015),Vector3(0.18,0.21,0.085),accent,0.027)
	box(Vector3(0,-0.10,0.112),Vector3(0.18,0.045,0.02),ink)
	for i in range(6):
		var x: float = (i-2.5)*0.010
		rod(Vector3(x,-0.10,0.13),Vector3(x,1.11,0.076),0.0018,ivory,5)
	for i in range(6):
		box(Vector3(0,0.43+i*0.081,0.067),Vector3(0.097,0.006,0.005),brass)
	for side in [-1.0,1.0]:
		for i in range(3): ball(Vector3(side*0.112,1.01+i*0.051,0.02),Vector3(0.038,0.025,0.04),brass)
	frame=old
	rod(Vector3(-1.58,0.18,-0.12),Vector3(-1.58,1.35,-0.12),0.033,brass)
	rod(Vector3(-1.98,0.18,0.26),Vector3(-1.98,0.67,0.26),0.028,brass)
	gear(Vector3(-1.98,0.55,0.28),0.145)
	begin_part(&"GuitarPick", Vector3(-1.98,0.59,0.32))
	rod(Vector3(-1.98,0.59,0.32),Vector3(-1.64,0.59,0.23),0.018,brass)
	ball(Vector3(-1.64,0.59,0.23),Vector3(0.10,0.065,0.04),ivory)
	end_part()

func drums() -> void:
	var kick:=Vector3(-0.43,0.56,0.14)
	disc(kick,0.355,0.43,accent,Vector3.BACK)
	for z in [-0.09,0.37]:
		disc(Vector3(-0.43,0.56,z),0.377,0.032,brass,Vector3.BACK)
	begin_part(&"KickHead", Vector3(-0.43,0.56,0.392))
	disc(Vector3(-0.43,0.56,0.392),0.335,0.02,ivory,Vector3.BACK)
	star(Vector3(-0.43,0.56,0.407),0.14,body)
	end_part()
	for i in range(8):
		var a:=TAU*i/8.0
		rod(Vector3(-0.43+cos(a)*0.363,0.56+sin(a)*0.363,-0.1),Vector3(-0.43+cos(a)*0.363,0.56+sin(a)*0.363,0.37),0.009,ink,6)
	for side in [-1.0,1.0]: rod(kick+Vector3(side*0.27,-0.12,0),kick+Vector3(side*0.37,-0.36,0.25),0.02,brass)
	soft_box(Vector3(-0.43,0.19,0.64),Vector3(0.13,0.03,0.28),ink,0.02)
	begin_part(&"KickBeater", Vector3(-0.43,0.20,0.63))
	rod(Vector3(-0.43,0.20,0.63),Vector3(-0.43,0.50,0.47),0.015,brass)
	ball(Vector3(-0.43,0.50,0.47),Vector3.ONE*0.105,ivory)
	end_part()
	var snare:=Vector3(0.43,0.83,0.06)
	rod(Vector3(0.43,0.2,0.06),snare,0.025,brass)
	for i in range(3):
		var a:=TAU*i/3.0
		rod(Vector3(0.43,0.22,0.06),Vector3(0.43+cos(a)*0.24,0.17,0.06+sin(a)*0.24),0.015,brass)
	disc(snare,0.24,0.18,body)
	for y in [0.73,0.93]: disc(Vector3(0.43,y,0.06),0.25,0.025,brass)
	begin_part(&"SnareHead", Vector3(0.43,0.947,0.06))
	disc(Vector3(0.43,0.947,0.06),0.226,0.012,ivory)
	end_part()
	for i in range(8):
		var a:=TAU*i/8.0
		rod(Vector3(0.43+cos(a)*0.244,0.75,0.06+sin(a)*0.244),Vector3(0.43+cos(a)*0.244,0.92,0.06+sin(a)*0.244),0.008,brass,6)
	rod(Vector3(0.7,0.2,-0.22),Vector3(0.7,1.22,-0.22),0.028,brass)
	gear(Vector3(0.7,1.15,-0.19),0.12)
	begin_part(&"SnareStick", Vector3(0.7,1.19,-0.14))
	rod(Vector3(0.7,1.19,-0.14),Vector3(0.43,1.04,0.08),0.018,wood)
	ball(Vector3(0.43,1.04,0.08),Vector3.ONE*0.08,ivory)
	end_part()

func piano() -> void:
	soft_box(Vector3(1.48,0.81,-0.12),Vector3(1.02,1.26,0.44),body,0.05)
	soft_box(Vector3(1.48,1.48,-0.12),Vector3(1.14,0.09,0.53),wood,0.025)
	soft_box(Vector3(1.48,1.18,0.116),Vector3(0.83,0.42,0.025),ink,0.025)
	for i in range(11):
		var x:=1.12+i*0.071
		rod(Vector3(x,1.01,0.136),Vector3(x,1.35-absf(i-5)*0.017,0.136),0.007,brass,6)
	box(Vector3(1.48,0.825,0.32),Vector3(1.12,0.08,0.48),wood)
	for i in range(14):
		var x:=1.48+(i-6.5)*0.069
		if i in [2,6,10]: begin_part(&"PianoAction", Vector3(1.48,0.88,0.33))
		box(Vector3(x,0.88,0.33),Vector3(0.065,0.065,0.37),ivory.lightened(rng.randf_range(-0.02,0.01)))
		if i in [2,6,10]: end_part()
		if i%7 in [0,1,3,4,5]: box(Vector3(x+0.0345,0.93,0.23),Vector3(0.04,0.07,0.22),ink)
	for x in [1.02,1.94]:
		rod(Vector3(x,0.2,0.43),Vector3(x,0.83,0.43),0.035,wood)
	begin_part(&"PianoAction", Vector3(1.48,0.88,0.33))
	for x in [1.2,1.46,1.72]:
		rod(Vector3(x,1.19,-0.03),Vector3(x,1.19,0.32),0.017,brass)
		rod(Vector3(x,1.19,0.32),Vector3(x,0.99,0.34),0.015,brass)
		ball(Vector3(x,0.99,0.34),Vector3(0.06,0.04,0.08),ivory)
	end_part()
	gear(Vector3(2.03,1.14,0.14),0.14)

func mechanical_band() -> void:
	soft_box(Vector3(0,0.09,0.12),Vector3(4.7,0.18,2.1),wood,0.10)
	box(Vector3(0,0.165,1.10),Vector3(4.52,0.028,0.025),brass)
	for i in range(13):
		box(Vector3(-2.16+i*0.36,0.183,0.08),Vector3(0.34,0.008,1.92),wood.lightened(rng.randf_range(-0.035,0.04)))
	for side in [-1.0,1.0]:
		rod(Vector3(side*2.16,0.18,-0.62),Vector3(side*2.16,2.08,-0.62),0.037,brass)
		gear(Vector3(side*2.16,0.56,-0.575),0.15)
	tube([Vector3(-2.16,2.08,-0.62),Vector3(-1.88,2.29,-0.62),Vector3(1.88,2.29,-0.62),Vector3(2.16,2.08,-0.62)],0.037,brass)
	soft_box(Vector3(0,2.16,-0.62),Vector3(3.48,0.39,0.10),body,0.085)
	soft_box(Vector3(0,2.16,-0.554),Vector3(3.30,0.27,0.025),ivory,0.065)
	text("MECHANICAL BAND",Vector3(0,2.118,-0.534),0.18,body)
	guitar()
	drums()
	piano()
	# Four independent caps, each a small interaction/animation target.
	for x in [-0.78,0.78]: rod(Vector3(x,0.04,1.42),Vector3(x,0.69,1.42),0.035,brass)
	soft_box(Vector3(0,0.70,1.43),Vector3(1.95,0.16,0.48),body,0.05)
	var colors: Array[Color] = [accent,Color("d49c61"),Color("8caaa0"),ivory]
	var labels := ["GUITAR","KICK","SNARE","PIANO"]
	var targets: Array[Vector3] = [Vector3(-1.58,0.6,0.2),Vector3(-0.43,0.56,0.42),Vector3(0.43,0.96,0.06),Vector3(1.48,0.93,0.35)]
	for i in range(4):
		var x: float = (i-1.5)*0.44
		disc(Vector3(x,0.797,1.43),0.107,0.025,brass)
		begin_part(StringName(labels[i].capitalize()+"Button"), Vector3(x,0.826,1.43))
		disc(Vector3(x,0.826,1.43),0.084,0.043,colors[i],Vector3.UP,2.0)
		end_part()
		text(labels[i],Vector3(x,0.667,1.677),0.057,ivory)
		var end: Vector3 = targets[i]
		tube([Vector3(x,0.66,1.26),Vector3(x,0.20,1.05),Vector3(end.x,0.20,0.85),Vector3(end.x,0.20,end.z)],0.012,ink,6)
		anchors[labels[i].capitalize()+"Button"] = Vector3(x,0.85,1.43)
		anchors[labels[i].capitalize()] = end
	collider(Vector3(0,1.05,0.05),Vector3(4.7,2.1,2.15),"Stage")
	collider(Vector3(0,0.42,1.43),Vector3(1.98,0.84,0.52),"Console")
	anchors["Play"] = Vector3(0,0.8,2.2)

func bar_corner() -> void:
	# Roofless cutaway: back/left walls frame the activities without hiding them.
	soft_box(Vector3(0,0.018,0),Vector3(10.8,0.036,8.2),Color("a79073"),0.08)
	for i in range(27):
		var c:=Color("b29a7d").lightened(rng.randf_range(-0.045,0.045))
		box(Vector3(-5.2+i*0.4,0.040,0),Vector3(0.388,0.016,8.1),c)
	soft_box(Vector3(0,1.26,-3.95),Vector3(10.8,2.52,0.22),Color("827a76"),0.05)
	soft_box(Vector3(-5.3,1.26,-1.65),Vector3(0.20,2.52,4.5),Color("827a76"),0.05)
	for x in [-5.2,-2.7,0.0,2.7,5.2]: box(Vector3(x,1.25,-3.81),Vector3(0.07,2.5,0.045),wood)
	box(Vector3(0,0.23,-3.80),Vector3(10.6,0.46,0.07),wood)
	box(Vector3(0,0.48,-3.75),Vector3(10.6,0.055,0.1),brass)
	soft_box(Vector3(0,2.15,-3.79),Vector3(2.8,0.54,0.12),wood,0.1)
	soft_box(Vector3(0,2.15,-3.712),Vector3(2.64,0.40,0.025),ivory,0.07)
	text("ARCADE",Vector3(0,2.095,-3.689),0.25,body)
	for side in [-1.0,1.0]:
		rod(Vector3(side*4.8,0.02,-3.5),Vector3(side*4.8,3.15,-3.5),0.05,wood)
	var wire: Array[Vector3] = []
	for i in range(25):
		var x:=lerpf(-4.8,4.8,float(i)/24.0)
		wire.append(Vector3(x,2.80+0.35*pow(x/4.8,2.0),-3.4))
	tube(wire,0.009,ink,6)
	for i in range(13):
		var x:=lerpf(-4.65,4.65,float(i)/12.0)
		var y:=2.80+0.35*pow(x/4.8,2.0)
		rod(Vector3(x,y,-3.4),Vector3(x,y-0.09,-3.4),0.015,ink,6)
		ball(Vector3(x,y-0.14,-3.4),Vector3(0.085,0.12,0.085),Color("ffe2ab"),2.0)
	# A tiny bar ledge, bottles, and two stools establish a bar rather than a fairground.
	soft_box(Vector3(-4.18,0.48,1.28),Vector3(1.3,0.96,1.85),body,0.07)
	soft_box(Vector3(-4.18,1.0,1.28),Vector3(1.48,0.13,2.04),wood,0.06)
	for i in range(3):
		var p:=Vector3(-4.4+i*0.24,1.12,0.7+i*0.25)
		ball(p+Vector3.UP*0.07,Vector3(0.12,0.22,0.12),Color("71847a").darkened(i*0.08))
		rod(p+Vector3.UP*0.12,p+Vector3.UP*0.30,0.025,Color("71847a").darkened(i*0.08))
		box(p+Vector3(0,0.07,0.062),Vector3(0.082,0.085,0.007),ivory)
	for z in [0.75,1.85]:
		disc(Vector3(-3.05,0.65,z),0.25,0.10,accent)
		for side in [-1.0,1.0]:
			rod(Vector3(-3.05+side*0.16,0.6,z),Vector3(-3.05+side*0.25,0.06,z),0.025,brass)
	collider(Vector3(0,0.024,0),Vector3(10.8,0.048,8.2),"Floor")
	collider(Vector3(0,1.26,-3.95),Vector3(10.8,2.52,0.24),"BackWall")
	collider(Vector3(-5.3,1.26,-1.65),Vector3(0.22,2.52,4.5),"SideWall")
	collider(Vector3(-4.18,0.52,1.28),Vector3(1.48,1.04,2.04),"Bar")
	for z in [0.75,1.85]: collider(Vector3(-3.05,0.34,z),Vector3(0.55,0.68,0.55),"Stool")

func create(kind: StringName, config: Dictionary) -> Dictionary:
	body = config.cabinet_color
	accent = config.accent_color
	brass = config.metal_color
	ivory = config.cream_color
	rng.seed = config.prop_seed
	s = SurfaceTool.new()
	s.begin(Mesh.PRIMITIVE_TRIANGLES)
	if kind in [&"pinball", &"punching_bag"]:
		_outline_tool = SurfaceTool.new()
		_outline_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	match kind:
		&"pinball": pinball()
		&"punching_bag": punching_bag()
		&"mechanical_band": mechanical_band()
		&"bar_corner": bar_corner()
	for part in parts.values():
		part["mesh"] = part.tool.commit()
		part.erase("tool")
	return {"mesh":s.commit(),"colliders":colliders,"anchors":anchors,"parts":parts,
		"outline_mesh":_outline_tool.commit() if _outline_tool else null}
