@tool
extends "res://components/vehicles/four_runner/four_runner_geometry.gd"
## Park shuttle exterior. Reuses the painted vehicle builder and bounded rounding.
## Local +Z is forward; root is the tire contact plane.
var length_z: float
var roof: Color
var glass: Color
var front_axle: float
var rear_axle: float

func flat_deck(center: Vector3, width: float, depth: float, thickness: float, color: Color, bevel: float = 0.12) -> void:
	# Compose with vehicle scale rather than replacing the builder transform.
	var previous := frame
	frame = previous*Transform3D(Basis(Vector3.RIGHT,PI*0.5),center)
	soft_box(Vector3.ZERO,Vector3(width,depth,thickness),color,bevel)
	frame = previous

func side_x(y: float) -> float:
	return 1.17-clampf((y-1.55)/0.92,0,1)*0.04

func side_panel(points: PackedVector2Array, side: float, color: Color, kind: float = 0.0, inset: float = 0.014) -> void:
	var ids := Geometry2D.triangulate_polygon(points)
	for id in ids:
		var p := points[id]
		vertex(Vector3(side*(side_x(p.y)+inset),p.y,p.x),Vector3(side,0.04,0).normalized(),color,kind)

func side_rect(z: float, y: float, width_z: float, height: float, side: float, color: Color, kind: float = 0.0, inset: float = 0.014) -> void:
	var points := PackedVector2Array([Vector2(z-width_z*0.5,y-height*0.5),Vector2(z+width_z*0.5,y-height*0.5),Vector2(z+width_z*0.5,y+height*0.5),Vector2(z-width_z*0.5,y+height*0.5)])
	side_panel(rounded_polygon(points),side,color,kind,inset)

func shell() -> void:
	var front := length_z*0.5
	# Actual notches through the side silhouette leave room around each tire.
	var outline := PackedVector2Array([Vector2(front-0.10,0.47)])
	for axle: float in [front_axle,rear_axle]:
		for i in range(13):
			var a := PI*float(i)/12.0
			outline.append(Vector2(axle+cos(a)*0.54,0.47+sin(a)*0.54))
	outline.append_array(PackedVector2Array([Vector2(-front+0.12,0.47),Vector2(-front,0.62),Vector2(-front,1.51),Vector2(front-0.015,1.51),Vector2(front+0.02,0.67)]))
	var shape := rounded_polygon(outline)
	var ids := Geometry2D.triangulate_polygon(shape)
	for side: float in [-1.0,1.0]:
		for id in ids:
			var p := shape[id]
			vertex(Vector3(side*1.17,p.y,p.x),Vector3.RIGHT*side,body)
	for i in range(shape.size()):
		var a := shape[i]
		var b := shape[(i+1)%shape.size()]
		quad(Vector3(-1.17,a.y,a.x),Vector3(1.17,a.y,a.x),Vector3(1.17,b.y,b.x),Vector3(-1.17,b.y,b.x),body)
	# Rounded roof shoulders with shared smooth normals; the side panes stay flat.
	var section := PackedVector2Array([Vector2(-1.15,1.40),Vector2(-1.17,1.55),Vector2(-1.13,2.47),Vector2(-1.10,2.64),Vector2(-1.0,2.76),Vector2(-0.83,2.80),Vector2(0.83,2.80),Vector2(1.0,2.76),Vector2(1.10,2.64),Vector2(1.13,2.47),Vector2(1.17,1.55),Vector2(1.15,1.40)])
	for i in range(section.size()):
		var j := (i+1)%section.size()
		for id: Vector2i in [Vector2i(i,0),Vector2i(j,0),Vector2i(j,1),Vector2i(i,0),Vector2i(j,1),Vector2i(i,1)]:
			var p := section[id.x]
			var tangent := (section[(id.x+1)%section.size()]-section[posmod(id.x-1,section.size())]).normalized()
			var z := -front+0.015 if id.y==0 else front-0.12*(p.y-1.40)
			var color := roof if p.y>2.57 else body
			vertex(Vector3(p.x,p.y,z),Vector3(-tangent.y,tangent.x,0),color)
	var cap_ids := Geometry2D.triangulate_polygon(section)
	for end: float in [-1.0,1.0]:
		for id in cap_ids:
			var p := section[id]
			var z := -front+0.015 if end<0 else front-0.12*(p.y-1.4)
			vertex(Vector3(p.x,p.y,z),Vector3(0,0.12 if end>0 else 0,end).normalized(),roof if p.y>2.57 else body)

func bus_wheel(at: Vector3, side: float) -> void:
	var axis := Vector3.RIGHT*side
	disc(at,0.445,0.28,Color("34403e"),axis,0,40)
	var face := at+axis*0.147
	disc(face,0.320,0.022,Color("53605a"),axis,0,32)
	disc(face+axis*0.014,0.266,0.022,Color("b4bdb4"),axis,0,32)
	for i in range(6):
		var a := TAU*float(i)/6.0
		var radial := Vector3(0,cos(a),sin(a))
		disc(face+axis*0.030+radial*0.194,0.033,0.009,Color("4a5853"),axis,0,12)
	disc(face+axis*0.041,0.113,0.045,Color("a0aca5"),axis,0,24)
	for i in range(6):
		var a := TAU*float(i)/6.0
		var radial := Vector3(0,cos(a),sin(a))
		disc(face+axis*0.067+radial*0.065,0.014,0.010,Color("dae0d3"),axis,0,8)

func mountain_band(side: float, start: float, end: float) -> void:
	var span := end-start
	var far := PackedVector2Array([Vector2(start,1.065),Vector2(start,1.20),Vector2(start+span*0.14,1.38),Vector2(start+span*0.25,1.21),Vector2(start+span*0.38,1.43),Vector2(start+span*0.55,1.20),Vector2(start+span*0.70,1.36),Vector2(start+span*0.85,1.20),Vector2(end,1.35),Vector2(end,1.065)])
	side_panel(far,side,roof.lerp(accent,0.24),0,0.018)
	var near := PackedVector2Array([Vector2(start,1.055),Vector2(start,1.14),Vector2(start+span*0.11,1.26),Vector2(start+span*0.31,1.11),Vector2(start+span*0.49,1.31),Vector2(start+span*0.61,1.16),Vector2(start+span*0.80,1.29),Vector2(end,1.13),Vector2(end,1.055)])
	side_panel(near,side,accent,0,0.023)

func sides(c: Dictionary) -> void:
	var front := length_z*0.5
	var start := -front+0.22
	var end := front-1.20
	var pitch: float = (end-start)/float(c.passenger_bays)
	for side: float in [-1.0,1.0]:
		side_rect(0,1.995,length_z-0.30,1.15,side,brass,0,0.008)
		for i in range(c.passenger_bays):
			var z := start+(float(i)+0.5)*pitch
			side_rect(z,2.005,pitch-0.10,0.94,side,glass.lightened(rng.randf_range(-0.025,0.025)),1,0.020)
			# A single large painted reflection, rather than transparent seats/interior.
			var glint := PackedVector2Array([Vector2(z-pitch*0.35,2.38),Vector2(z+pitch*0.30,2.38),Vector2(z+pitch*0.12,2.13),Vector2(z-pitch*0.35,1.94)])
			side_panel(glint,side,glass.lightened(0.075),1,0.024)
		if c.mountain_graphic_enabled: mountain_band(side,start,end)
		for axle: float in [front_axle,rear_axle]:
			bus_wheel(Vector3(side*1.065,0.447,axle),side)
			var points: Array[Vector3] = []
			for i in range(17):
				var a := PI*float(i)/16.0
				points.append(Vector3(side*1.184,0.47+sin(a)*0.56,axle+cos(a)*0.56))
			tube(points,0.021,body.darkened(0.13),8)
			box(Vector3(side*1.08,0.36,axle-0.48),Vector3(0.17,0.25,0.035),brass)
		# Long lower rub rail, interrupted at the real wheel arches.
		for segment: Vector2 in [Vector2(-front+0.12,rear_axle-0.58),Vector2(rear_axle+0.58,front_axle-0.58),Vector2(front_axle+0.58,front-0.12)]:
			if segment.y>segment.x:
				box(Vector3(side*1.181,0.73,(segment.x+segment.y)*0.5),Vector3(0.024,0.048,segment.y-segment.x),brass)
		for z: float in [-front+0.21,front-0.18]:
			side_rect(z,1.18,0.10,0.06,side,Color("d8aa60"),0,0.026)
		# Wide mirrors on restrained dark arms, with opaque painted glass.
		rod(Vector3(side*1.09,2.46,front-0.32),Vector3(side*1.47,2.35,front-0.05),0.025,brass,10)
		soft_box(Vector3(side*1.48,2.19,front-0.01),Vector3(0.16,0.36,0.20),brass,0.045)
		box(Vector3(side*1.48,2.19,front-0.116),Vector3(0.12,0.29,0.012),glass,1)
	# Curbside folding entry door; closed scenic exterior, no hidden room.
	var door_z := front-0.63
	side_rect(door_z,1.44,0.91,2.05,1.0,brass,0,0.031)
	for offset: float in [-0.218,0.218]:
		side_rect(door_z+offset,1.66,0.39,1.47,1.0,glass.darkened(0.05),1,0.039)
		side_rect(door_z+offset,0.685,0.39,0.35,1.0,body.darkened(0.12),0,0.040)
	side_rect(door_z,0.91,0.82,0.035,1.0,roof,0,0.043)
	# Driver's separate sliding window, opposite the entry door.
	side_rect(door_z,2.005,0.81,0.94,-1.0,glass,1,0.021)
	side_rect(door_z,1.96,0.020,0.88,-1.0,brass,0,0.027)
	box(Vector3(-1.187,1.24,door_z),Vector3(0.03,0.04,0.15),brass)

func windshield_z(y: float) -> float:
	return length_z*0.5-0.12*(y-1.40)+0.022

func front_quad(a: Vector2, b: Vector2, d: Vector2, e: Vector2, color: Color, kind: float = 0.0, offset: float = 0.0) -> void:
	quad(Vector3(a.x,a.y,windshield_z(a.y)+offset),Vector3(b.x,b.y,windshield_z(b.y)+offset),Vector3(d.x,d.y,windshield_z(d.y)+offset),Vector3(e.x,e.y,windshield_z(e.y)+offset),color,kind)

func front_and_rear(c: Dictionary) -> void:
	var front := length_z*0.5
	front_quad(Vector2(-1.045,1.44),Vector2(1.045,1.44),Vector2(0.965,2.60),Vector2(-0.965,2.60),brass)
	front_quad(Vector2(-0.98,1.51),Vector2(0.98,1.51),Vector2(0.90,2.36),Vector2(-0.90,2.36),glass,1,0.005)
	front_quad(Vector2(-0.88,2.28),Vector2(0.87,2.28),Vector2(0.86,2.34),Vector2(-0.55,2.34),glass.lightened(0.12),1,0.008)
	front_quad(Vector2(-0.93,1.56),Vector2(-0.74,1.56),Vector2(-0.22,2.30),Vector2(-0.43,2.30),glass.lightened(0.065),1,0.009)
	front_quad(Vector2(-0.017,1.50),Vector2(0.017,1.50),Vector2(0.017,2.37),Vector2(-0.017,2.37),brass,0,0.012)
	# Sign geometry is constrained to the display; blank text removes lettering.
	var route: String = c.destination_text.strip_edges().substr(0,24)
	if not route.is_empty():
		var width_at_unit := ThemeDB.fallback_font.get_string_size(route,HORIZONTAL_ALIGNMENT_LEFT,-1,48).x/48.0
		var sign_height := minf(0.115,1.62/maxf(0.001,width_at_unit))
		text(route,Vector3(0,2.475,windshield_z(2.475)+0.015),sign_height,roof,Basis(Vector3.RIGHT,-atan(0.12)))
	for x: float in [-0.45,0.45]:
		rod(Vector3(x-0.25,1.55,windshield_z(1.55)+0.018),Vector3(x+0.14,1.65,windshield_z(1.65)+0.018),0.010,brass,6)
	soft_box(Vector3(0,0.90,front+0.042),Vector3(1.24,0.30,0.045),brass,0.05)
	for y: float in [0.82,0.90,0.98]:
		box(Vector3(0,y,front+0.069),Vector3(1.10,0.018,0.014),body.lightened(0.10))
	soft_box(Vector3(0,0.51,front+0.01),Vector3(2.24,0.18,0.18),brass,0.06)
	for side: float in [-1.0,1.0]:
		soft_box(Vector3(side*0.86,1.075,front+0.025),Vector3(0.37,0.30,0.05),roof,0.05)
		disc(Vector3(side*0.87,1.09,front+0.061),0.115,0.025,brass,Vector3.BACK,0,28)
		disc(Vector3(side*0.87,1.09,front+0.079),0.087,0.013,Color("ecdfb6"),Vector3.BACK,4,28)
		box(Vector3(side*0.87,1.29,front+0.044),Vector3(0.23,0.055,0.025),Color("d8ab61"))
	soft_box(Vector3(0,0.63,front+0.115),Vector3(0.36,0.14,0.018),roof,0.018)
	# Rear window, engine louvers, stacked lamps and a quiet blank plate.
	soft_box(Vector3(0,2.08,-front-0.008),Vector3(1.79,0.95,0.028),brass,0.08)
	soft_box(Vector3(0,2.08,-front-0.025),Vector3(1.64,0.80,0.014),glass.darkened(0.08),0.055,1)
	soft_box(Vector3(0,1.01,-front-0.018),Vector3(1.54,0.49,0.028),body.darkened(0.11),0.045)
	for i in range(5):
		box(Vector3(0,0.86+float(i)*0.074,-front-0.037),Vector3(1.35,0.020,0.012),brass)
	for side: float in [-1.0,1.0]:
		soft_box(Vector3(side*0.975,1.17,-front-0.016),Vector3(0.22,0.61,0.04),brass,0.05)
		for i in range(3):
			disc(Vector3(side*0.975,0.98+float(i)*0.18,-front-0.045),0.072,0.014,Color("ad6558") if i!=1 else Color("d9c9a7"),Vector3.FORWARD,0,20)
	soft_box(Vector3(0,0.51,-front-0.01),Vector3(2.25,0.18,0.18),brass,0.05)
	soft_box(Vector3(0,0.65,-front-0.10),Vector3(0.38,0.14,0.018),roof,0.018)

func shuttle(c: Dictionary) -> Dictionary:
	begin(c)
	length_z = 5.90+float(c.passenger_bays-4)*0.85
	roof = c.roof_color
	glass = c.glass_color
	var scale_factor: float = c.vehicle_scale
	frame = Transform3D(Basis.from_scale(Vector3.ONE*scale_factor),Vector3.ZERO)
	front_axle = length_z*0.5-1.72
	rear_axle = -length_z*0.5+1.30
	soft_box(Vector3(0,0.48,0),Vector3(1.86,0.15,length_z-0.55),brass,0.05)
	shell()
	sides(c)
	front_and_rear(c)
	if c.roof_pod_enabled:
		flat_deck(Vector3(0,2.88,-0.55),1.32,1.85,0.19,roof.darkened(0.05),0.16)
		for z: float in [-0.96,-0.76,-0.56,-0.36,-0.16]:
			box(Vector3(0,2.982,z),Vector3(0.83,0.008,0.035),roof.darkened(0.22))
	flat_deck(Vector3(0,2.815,0.95),0.65,0.73,0.025,roof.lightened(0.035),0.08)
	collider(Vector3(0,1.39,0),Vector3(2.39,2.77,length_z+0.18),"ParkedShuttle")
	for info: Dictionary in colliders:
		info.center *= scale_factor
		info.size *= scale_factor
	anchors = {"Front":Vector3(0,0,length_z*0.5+0.9),"Rear":Vector3(0,0,-length_z*0.5-0.9),"Boarding":Vector3(1.75,0,length_z*0.5-0.63),"Door":Vector3(1.23,1.4,length_z*0.5-0.63),"Driver":Vector3(-1.6,0,length_z*0.5-0.63),"Roof":Vector3(0,3.0,-0.55)}
	for key in anchors: anchors[key] *= scale_factor
	var data := finish()
	data.length_z = length_z*scale_factor
	return data
