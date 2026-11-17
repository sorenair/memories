@tool
extends "res://components/animals/elk/elk_geometry.gd"
## Reuses the elk's smooth loft/sweep, vertex paint and articulated part encoding.
## A low shoulder hump, shaggy bib/beard and slim backward horns distinguish it.
var fluff: float = 0.75

func coat_at(p: Vector3) -> Color:
	var underside := (1.0-smoothstep(0.38,1.16,p.y))*0.23
	var warm := smoothstep(0.3,0.95,-p.z)*0.055
	return coat.lerp(accent,underside).lerp(Color("ddd5bf"),warm)

func torso() -> void:
	var controls: Array[Vector4] = [Vector4(-0.85,0.77,0.014,0.06),Vector4(-0.73,0.78,0.25,0.32),Vector4(-0.44,0.78,0.34,0.36),Vector4(-0.10,0.79,0.36,0.40),Vector4(0.21,0.85,0.36,0.44),Vector4(0.43,0.86,0.29,0.36),Vector4(0.59,0.90,0.08,0.14)]
	var rings := curve(controls,3)
	for i in range(rings.size()-1):
		for side in range(24):
			for id: Vector2i in [Vector2i(i,side),Vector2i(i+1,side),Vector2i(i+1,side+1),Vector2i(i,side),Vector2i(i+1,side+1),Vector2i(i,side+1)]:
				var r: Vector4 = rings[id.x]
				var angle := TAU*float(id.y)/24.0
				# Broad undulations, not individual fur strands or cotton-ball shells.
				var wave := 1.0+fluff*(0.028*sin(angle*5.0+r.x*8.0)+0.016*cos(angle*3.0-r.x*11.0))
				var p := Vector3(cos(angle)*r.z*wave,r.y+sin(angle)*r.w*wave,r.x)
				p.y -= fluff*0.035*(0.65+0.35*cos(r.x*17.0+angle*3.0))*(1.0-smoothstep(-0.8,-0.15,sin(angle)))
				var before: Vector4 = rings[maxi(id.x-1,0)]
				var after: Vector4 = rings[mini(id.x+1,rings.size()-1)]
				var tangent := Vector3(cos(angle)*(after.z-before.z),after.y-before.y+sin(angle)*(after.w-before.w),after.x-before.x).normalized()
				var n := Vector3(cos(angle)/maxf(0.01,r.z),sin(angle)/maxf(0.01,r.w),0)
				n.z = -(n.x*tangent.x+n.y*tangent.y)/maxf(0.01,tangent.z)
				vertex(p,n.normalized(),coat_at(p))

func lock(root: Vector3, end: Vector3, radius: float, part: float = 0.0) -> void:
	var center := root.lerp(end,0.54)+Vector3(0,0,0.013)
	sweep([Vector4(root.x,root.y,root.z,radius*1.20),Vector4(center.x,center.y,center.z,radius*0.83),Vector4(end.x,end.y,end.z,0.012)],coat_at(center),part,12,3,0.82)

func hoof(center: Vector3) -> void:
	# Rounded toes with a flat sole/top, rather than hovering spheres or sharp cubes.
	var mesh := SphereMesh.new()
	mesh.radius = 1.0
	mesh.height = 2.0
	mesh.radial_segments = 12
	mesh.rings = 8
	var a := mesh.surface_get_arrays(0)
	var radius := Vector3(0.029,0.070,0.075)
	for id: int in a[Mesh.ARRAY_INDEX]:
		var p: Vector3 = a[Mesh.ARRAY_VERTEX][id]*radius+center
		var n: Vector3 = (a[Mesh.ARRAY_NORMAL][id]/radius).normalized()
		if p.y < 0.004:
			p.y = 0.004
			n = Vector3.DOWN
		elif p.y > 0.115:
			p.y = 0.115
			n = Vector3.UP
		vertex(p,n,bone)

func goat(config: Dictionary) -> Dictionary:
	begin(config)
	fluff = config.fluffiness
	# Adult baseline is about one metre at the shoulder, below the elk's barrel.
	morph = Vector3(rng.randf_range(0.97,1.04),rng.randf_range(0.98,1.035),rng.randf_range(0.97,1.04))*0.85*config.goat_size
	coat = body.lightened(rng.randf_range(-0.012,0.012))
	mane = coat
	rump = coat
	bone = brass
	torso()
	# Broad shoulder/neck, tapering into a slim white face.
	sweep([Vector4(0,0.79,0.30,0.22),Vector4(0,1.02,0.44,0.30),Vector4(0,1.24,0.62,0.24),Vector4(0,1.43,0.84,0.13)],coat,1,20,4,0.90)
	# Short, woolly legs taper gradually to visible split hooves.
	for side: float in [-1.0,1.0]:
		for front: bool in [true,false]:
			var x := side*0.22
			var stance := rng.randf_range(-0.025,0.025)
			var path: Array[Vector4]
			if front:
				path = [Vector4(x*0.85,1.04,0.29,0.035),Vector4(x,0.79,0.34,0.14),Vector4(x+side*0.018,0.49,0.40,0.105),Vector4(x+side*0.026,0.105,0.43+stance,0.047)]
			else:
				path = [Vector4(x*0.85,0.99,-0.55,0.035),Vector4(x,0.75,-0.51,0.14),Vector4(x+side*0.012,0.48,-0.40,0.098),Vector4(x+side*0.025,0.29,-0.62,0.062),Vector4(x+side*0.03,0.105,-0.57+stance,0.045)]
			sweep(path,coat,0,12,3,1.0,Color.TRANSPARENT,true)
			var foot := xyz(path[-1])
			for toe: float in [-1.0,1.0]:
				hoof(Vector3(foot.x+toe*0.030,0.055,foot.z+0.028))
	# A small number of overlapping coat masses make a shaggy chest and belly.
	if fluff > 0.02:
		for side: float in [-1.0,1.0]:
			for i in range(4):
				var z := -0.59+float(i)*0.28
				lock(Vector3(side*0.20,0.63,z),Vector3(side*0.27,0.39-fluff*rng.randf_range(0.02,0.045),z-0.04),0.12*fluff)
			lock(Vector3(side*0.10,1.17,0.55),Vector3(side*0.10,0.79-fluff*0.04,0.67),0.14*fluff,1)
		lock(Vector3(0,1.07,0.52),Vector3(0,0.71-fluff*0.04,0.61),0.14*fluff,1)
	# Angular goat profile, with smooth normals rather than cylinder facets.
	oval(Vector3(0,1.405,0.915),Vector3(0.135,0.16,0.225),coat,2)
	sweep([Vector4(0,1.43,0.94,0.119),Vector4(0,1.34,1.105,0.094),Vector4(0,1.25,1.23,0.070)],coat,2,16,3,0.88)
	oval(Vector3(0,1.244,1.258),Vector3(0.066,0.039,0.042),bone,2,Basis.IDENTITY,16)
	# Long chin hair is one curved beard with two supporting painted locks.
	var beard_length := lerpf(0.17,0.29,fluff)
	lock(Vector3(0,1.31,1.085),Vector3(0,1.265-beard_length,1.09),0.083,2)
	for side: float in [-1.0,1.0]:
		oval(Vector3(side*0.125,1.419,1.015),Vector3(0.016,0.015,0.027),bone,2,Basis.IDENTITY,12)
		oval(Vector3(side*0.137,1.425,1.02),Vector3(0.0035,0.004,0.006),Color("efeee7"),2,Basis.IDENTITY,8)
		var root := Vector3(side*0.115,1.485,0.855)
		var tip := Vector3(side*0.335,1.56,0.80)
		var ear_basis := Basis(Quaternion(Vector3.UP,(tip-root).normalized()))
		var ear_center := root.lerp(tip,0.54)
		var part := 3.0 if side < 0 else 4.0
		oval(ear_center,Vector3(0.064,0.151,0.034),coat,part,ear_basis,16)
		oval(ear_center+Vector3(0,0,0.024),Vector3(0.038,0.11,0.013),accent.lerp(coat,0.5),part,ear_basis,16)
		if fluff > 0.02:
			lock(Vector3(side*0.075,1.39,0.92),Vector3(side*0.14,1.15,0.89),0.066*fluff,2)
		var h: float = config.horn_length*rng.randf_range(0.97,1.03)
		var horn: Array[Vector4] = [Vector4(side*0.098,1.53,0.825,0.032),Vector4(side*0.116,1.53+0.12*h,0.81-0.02*h,0.028),Vector4(side*0.131,1.53+0.22*h,0.81-0.09*h,0.018),Vector4(side*0.14,1.53+0.27*h,0.81-0.19*h,0.002)]
		sweep(horn,bone,2,10,4,1.0,bone.lightened(0.10))
	sweep([Vector4(0,0.98,-0.79,0.067),Vector4(0,1.035,-0.94,0.06),Vector4(0,1.015,-1.01,0.022)],coat,5,12,3)
	colliders.append({"name":"Body","center":Vector3(0,0.54,-0.07)*morph,"size":Vector3(0.72,1.06,1.52)*morph})
	anchors["Approach"] = Vector3(0,0,1.9)*morph
	anchors["Shoulder"] = Vector3(0,1.14,0.22)*morph
	anchors["Head"] = Vector3(0,1.405,0.915)*morph
	var data := finish()
	data.morph = morph
	data.bounds = AABB(Vector3(-0.85,-0.025,-1.22)*morph,Vector3(1.7,2.20,3.65)*morph)
	return data
