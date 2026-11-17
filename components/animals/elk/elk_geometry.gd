@tool
extends "res://components/scenery/concert/shared/concert_geometry.gd"
## Grounded, smooth silhouette with painted coat regions. Front is +Z.
## UV stores baked proportions, UV2.x the articulated part, UV2.y depth scale.
var morph := Vector3.ONE
var coat: Color
var mane: Color
var rump: Color
var bone: Color

func vertex(p: Vector3, n: Vector3, color: Color, kind: float = 0.0) -> void:
	s.set_normal((n / morph).normalized())
	s.set_color(color.srgb_to_linear())
	s.set_uv(Vector2(morph.x, morph.y))
	s.set_uv2(Vector2(kind, morph.z))
	s.add_vertex(p * morph)

func oval(center: Vector3, radii: Vector3, color: Color, kind: float = 0.0, rotation := Basis.IDENTITY, sides: int = 20) -> void:
	var mesh := SphereMesh.new()
	mesh.radius = 1.0
	mesh.height = 2.0
	mesh.radial_segments = sides
	mesh.rings = 10
	append(mesh, Transform3D(rotation*Basis.from_scale(radii), center), color, kind)

func curve(points: Array[Vector4], steps: int = 3) -> Array[Vector4]:
	var result: Array[Vector4] = []
	for i in range(points.size() - 1):
		var a := points[maxi(0,i-1)]
		var b := points[i]
		var c := points[i+1]
		var d := points[mini(points.size()-1,i+2)]
		for j in range(steps):
			var t := float(j) / float(steps)
			result.append(0.5 * (2.0*b + (-a+c)*t + (2.0*a-5.0*b+4.0*c-d)*t*t + (-a+3.0*b-3.0*c+d)*t*t*t))
	result.append(points[-1])
	return result

func xyz(p: Vector4) -> Vector3:
	return Vector3(p.x,p.y,p.z)

func sweep(points: Array[Vector4], color: Color, kind: float = 0.0, sides: int = 10, steps: int = 3, flatten: float = 1.0, tip_color: Color = Color.TRANSPARENT, coat_blend: bool = false) -> void:
	var path := curve(points,steps)
	var axes: Array[Vector3] = []
	var tangents: Array[Vector3] = []
	var previous := Vector3.RIGHT
	for i in range(path.size()):
		var tangent := (xyz(path[mini(i+1,path.size()-1)])-xyz(path[maxi(i-1,0)])).normalized()
		var axis := previous.slide(tangent).normalized()
		if axis.length_squared() < 0.1:
			axis = tangent.cross(Vector3.BACK).normalized()
		axes.append(axis)
		tangents.append(tangent)
		previous = axis
	for i in range(path.size()-1):
		for side in range(sides):
			for id: Vector2i in [Vector2i(i,side),Vector2i(i+1,side),Vector2i(i+1,side+1),Vector2i(i,side),Vector2i(i+1,side+1),Vector2i(i,side+1)]:
				var p: Vector4 = path[id.x]
				var angle := TAU * float(id.y) / float(sides)
				var x := axes[id.x]
				var y := tangents[id.x].cross(x).normalized()
				var radial := x*cos(angle)*flatten + y*sin(angle)
				var normal := (x*cos(angle)/flatten+y*sin(angle)).normalized()
				var paint := color
				var previous_radius: Vector4 = path[maxi(id.x-1,0)]
				var next_radius: Vector4 = path[mini(id.x+1,path.size()-1)]
				var slope := (next_radius.w-previous_radius.w)/maxf(0.001,xyz(next_radius).distance_to(xyz(previous_radius)))
				normal = (normal-tangents[id.x]*slope).normalized()
				if coat_blend:
					paint = mane.lerp(coat_at(xyz(p)),smoothstep(0.62,1.13,p.y))
				if tip_color.a > 0.0:
					paint = color.lerp(tip_color, pow(float(id.x)/float(path.size()-1),2.0)*0.75)
				vertex(xyz(p)+radial*maxf(0.001,p.w),normal,paint,kind)
	# End caps are hidden at limb joins; close them for clean isolated tips.
	for end: int in [0,path.size()-1]:
		var p := path[end]
		var normal := tangents[end] * (-1.0 if end == 0 else 1.0)
		for side in range(sides):
			vertex(xyz(p),normal,color,kind)
			for offset: int in [0,1]:
				var angle := TAU*float(side+offset)/float(sides)
				vertex(xyz(p)+(axes[end]*cos(angle)*flatten+tangents[end].cross(axes[end])*sin(angle))*maxf(0.001,p.w),normal,color,kind)

func torso() -> void:
	# A continuous barrel/chest, rather than visibly joined primitive spheres.
	var controls: Array[Vector4] = [Vector4(-1.04,1.13,0.015,0.07),Vector4(-0.90,1.14,0.24,0.32),Vector4(-0.60,1.15,0.32,0.38),Vector4(-0.17,1.13,0.34,0.36),Vector4(0.29,1.18,0.34,0.43),Vector4(0.58,1.18,0.26,0.36),Vector4(0.73,1.21,0.06,0.15)]
	var rings := curve(controls,3)
	for i in range(rings.size()-1):
		for side in range(24):
			for id: Vector2i in [Vector2i(i,side),Vector2i(i+1,side),Vector2i(i+1,side+1),Vector2i(i,side),Vector2i(i+1,side+1),Vector2i(i,side+1)]:
				var ring: Vector4 = rings[id.x]
				var angle := TAU*float(id.y)/24.0
				var p := Vector3(cos(angle)*ring.z,ring.y+sin(angle)*ring.w,ring.x)
				var before: Vector4 = rings[maxi(id.x-1,0)]
				var after: Vector4 = rings[mini(id.x+1,rings.size()-1)]
				var tangent := Vector3(cos(angle)*(after.z-before.z),after.y-before.y+sin(angle)*(after.w-before.w),after.x-before.x).normalized()
				var normal := Vector3(cos(angle)/maxf(0.01,ring.z),sin(angle)/maxf(0.01,ring.w),0)
				normal.z = -(normal.x*tangent.x+normal.y*tangent.y)/maxf(0.01,tangent.z)
				vertex(p,normal.normalized(),coat_at(p))

func coat_at(p: Vector3) -> Color:
	var color := coat.lerp(rump,smoothstep(0.59,0.98,-p.z)*smoothstep(0.78,1.16,p.y)*0.94)
	color = color.lerp(mane,smoothstep(-0.02,0.60,p.z)*0.97)
	return color.darkened((1.0-smoothstep(0.70,1.1,p.y))*0.06)

func antlers(young: bool, size: float, spread: float) -> void:
	for side: float in [-1.0,1.0]:
		var asymmetry := rng.randf_range(0.94,1.06)
		var beam: Array[Vector4]
		if young:
			beam = [Vector4(0.14,2.12,0.96,0.034),Vector4(0.24,2.35,0.86,0.026),Vector4(0.29,2.55,0.68,0.002)]
		else:
			beam = [Vector4(0.14,2.12,0.96,0.052),Vector4(0.26,2.40,0.78,0.048),Vector4(0.43,2.63,0.36,0.040),Vector4(0.54,2.77,-0.15,0.026),Vector4(0.58,2.90,-0.44,0.013),Vector4(0.55,3.00,-0.58,0.002)]
		var paths: Array = [beam]
		if not young:
			paths.append([Vector4(0.22,2.31,0.85,0.034),Vector4(0.28,2.44,1.07,0.021),Vector4(0.30,2.55,1.28,0.002)])
			paths.append([Vector4(0.35,2.53,0.59,0.032),Vector4(0.44,2.70,0.76,0.021),Vector4(0.47,2.88,0.94,0.002)])
			paths.append([Vector4(0.45,2.65,0.20,0.028),Vector4(0.53,2.85,0.29,0.018),Vector4(0.54,3.06,0.39,0.002)])
			paths.append([Vector4(0.53,2.73,-0.10,0.023),Vector4(0.62,2.93,-0.02,0.014),Vector4(0.65,3.10,0.02,0.002)])
		for raw: Array in paths:
			var path: Array[Vector4] = []
			for p: Vector4 in raw:
				path.append(Vector4(side*(0.14+(p.x-0.14)*spread*size),2.12+(p.y-2.12)*size*asymmetry,0.96+(p.z-0.96)*size,p.w*sqrt(size)))
			sweep(path,bone.darkened(0.18),2.0,8,3,1.0,bone.lightened(0.16))

func elk(config: Dictionary) -> Dictionary:
	begin(config)
	var type: int = config.elk_type
	var base_size: float = [1.0,0.90,0.61,0.87][type]
	morph = Vector3(rng.randf_range(0.94,1.08),rng.randf_range(0.97,1.06),rng.randf_range(0.95,1.08))*base_size*config.elk_size
	if type == 1: morph.x *= 0.87
	if type == 2: morph.z *= 0.87
	coat = body.lightened(rng.randf_range(-0.05,0.06))
	mane = accent.lightened(rng.randf_range(-0.035,0.05))
	if type == 1 or type == 2: mane = mane.lerp(coat,0.36)
	rump = brass
	bone = config.antler_color
	torso()
	# Slender articulated legs, thicker at shoulder/haunch; hooves stay planted.
	for side: float in [-1.0,1.0]:
		var stance := rng.randf_range(-0.055,0.055)
		for front: bool in [false,true]:
			var x := side*(0.225 if front else 0.23)
			var path: Array[Vector4]
			if front:
				path = [Vector4(x*0.83,1.44,0.37,0.035),Vector4(x,1.13,0.43,0.105),Vector4(x,0.82,0.46,0.075),Vector4(x+side*0.015,0.47,0.57+stance,0.053),Vector4(x+side*0.025,0.085,0.59+stance,0.038)]
			else:
				path = [Vector4(x*0.78,1.40,-0.63,0.03),Vector4(x,1.11,-0.64,0.13),Vector4(x,0.76,-0.44,0.088),Vector4(x+side*0.025,0.37,-0.78+stance,0.051),Vector4(x+side*0.035,0.085,-0.68+stance,0.036)]
			# Bury the upper joint and blend the haunch/chest pigment into the coat.
			sweep(path,mane,0,10,3,1.0,Color.TRANSPARENT,true)
			var foot := xyz(path[-1])
			for toe: float in [-1.0,1.0]:
				oval(Vector3(foot.x+toe*0.021,0.047,foot.z+0.025),Vector3(0.021,0.047,0.065),Color("49443b"),0,Basis.IDENTITY,12)
	# A broad, tapered mane grows naturally out of the shoulder.
	var neck_width: float = 1.0 if type == 0 else 0.80
	sweep([Vector4(0,1.11,0.34,0.18),Vector4(0,1.25,0.48,0.31),Vector4(0,1.43,0.55,0.29),Vector4(0,1.72,0.76,0.22),Vector4(0,1.98,1.03,0.145)],mane,1,20,4,neck_width)
	oval(Vector3(0,1.99,1.12),Vector3(0.16,0.18,0.265),mane,2)
	sweep([Vector4(0,2.01,1.15,0.135),Vector4(0,1.93,1.35,0.112),Vector4(0,1.87,1.51,0.088)],mane.lightened(0.05),2,16,3,1.0)
	oval(Vector3(0,1.858,1.55),Vector3(0.098,0.072,0.078),Color("3e3a33"),2)
	for side: float in [-1.0,1.0]:
		oval(Vector3(side*0.147,2.015,1.22),Vector3(0.019,0.023,0.029),Color("292e2b"),2,Basis.IDENTITY,12)
		oval(Vector3(side*0.161,2.022,1.228),Vector3(0.005,0.006,0.007),Color("d0c3a3"),2,Basis.IDENTITY,8)
		var ear_root := Vector3(side*0.13,2.075,1.035)
		var ear_tip := Vector3(side*0.47,2.22,0.90)
		var direction := (ear_tip-ear_root).normalized()
		var ear_basis := Basis(Quaternion(Vector3.UP,direction))
		var ear_center := ear_root.lerp(ear_tip,0.53)
		var part := 3.0 if side < 0 else 4.0
		oval(ear_center,Vector3(0.095,0.225,0.045),mane,part,ear_basis,16)
		oval(ear_center+Vector3(0,0,0.031),Vector3(0.061,0.17,0.017),coat.lerp(rump,0.32),part,ear_basis,16)
	sweep([Vector4(0,1.29,-0.97,0.062),Vector4(0,1.13,-1.12,0.053),Vector4(0,1.01,-1.12,0.018)],mane,5,10,3)
	if type == 0 or type == 3:
		antlers(type == 3,config.antler_size,config.antler_spread)
	colliders.append({"name":"Body", "center":Vector3(0,0.78,-0.08)*morph,"size":Vector3(0.78,1.55,1.95)*morph})
	anchors["Approach"] = Vector3(0,0,2.45)*morph
	anchors["Shoulder"] = Vector3(0,1.50,0.35)*morph
	anchors["Head"] = Vector3(0,1.99,1.12)*morph
	var data := finish()
	data.morph = morph
	# Includes antler tips, lowering/yawing heads and idle ear/tail excursions.
	data.bounds = AABB(Vector3(-1.90,-0.03,-1.65)*morph,Vector3(3.8,4.0,5.30)*morph)
	return data
