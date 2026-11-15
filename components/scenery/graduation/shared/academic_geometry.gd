@tool
extends RefCounted
## Shared crowd attributes, limb poses and cached heads; only the regalia is new.
const PEOPLE = preload("res://components/characters/crowd/crowd_geometry.gd")
static var _bodies: Dictionary = {}
static var _heads: Dictionary = {}

static func body(variant: int) -> ArrayMesh:
	if _bodies.has(variant):
		return _bodies[variant]
	var s := SurfaceTool.new()
	s.begin(Mesh.PRIMITIVE_TRIANGLES)
	var broad: float = [0.96, 1.12, 1.04, 0.98, 0.92, 1.01, 1.09, 0.94][variant]
	var hem: float = [0.20, 0.23, 0.25, 0.21, 0.19, 0.26, 0.22, 0.24][variant]
	for side: float in [-1.0, 1.0]:
		PEOPLE._tube(s, PackedVector3Array([Vector3(side*0.07,0.06,0.01),Vector3(side*0.075,0.29,0),Vector3(side*0.068,0.50,0)]), PackedVector2Array([Vector2(0.034,0.036),Vector2(0.044,0.046),Vector2(0.052,0.055)]), 1)
		PEOPLE._oval(s,Vector3(side*0.07,0.037,0.035),Vector3(0.046,0.034,0.084),4,0,8,3)
	# Long bell-shaped robe with rounded shoulder transitions and broad folds.
	PEOPLE._tube(s, PackedVector3Array([Vector3(0,hem,0),Vector3(0,hem+0.035,0),Vector3(0,0.53,0),Vector3(0,0.78,0),Vector3(0,0.87,0),Vector3(0,0.93,0),Vector3(0,0.945,0)]), PackedVector2Array([Vector2(0.179*broad,0.105),Vector2(0.18*broad,0.108),Vector2(0.151*broad,0.092),Vector2(0.143*broad,0.082),Vector2(0.157*broad,0.083),Vector2(0.088*broad,0.057),Vector2(0.045,0.043)]),6,16)
	PEOPLE._oval(s,Vector3(0,0.955,0),Vector3(0.041,0.060,0.041),2,0,8,3)
	for side: float in [-1.0, 1.0]:
		var shoulder := Vector3(side*0.126*broad,0.861,0)
		var elbow := Vector3(side*0.178*broad,0.685,0.018)
		var wrist := Vector3(side*0.169*broad,0.506,0.035)
		PEOPLE._oval(s,shoulder,Vector3(0.059,0.059,0.059)*broad,6,0,8,3,side,broad)
		PEOPLE._tube(s,PackedVector3Array([wrist+Vector3.UP*0.032,elbow,shoulder]),PackedVector2Array([Vector2(0.055,0.052)*broad,Vector2(0.056,0.055)*broad,Vector2(0.060,0.057)*broad]),6,10,side,broad)
		PEOPLE._oval(s,wrist,Vector3(0.029,0.040,0.028),2,0,8,3,side,broad)
		# Two broad stole ribbons lie on the robe rather than floating beside it.
		PEOPLE._tube(s,PackedVector3Array([Vector3(side*0.061,0.56,0.092),Vector3(side*0.066,0.80,0.086),Vector3(side*0.065,0.895,0.068),Vector3(side*0.035,0.934,0.041)]),PackedVector2Array([Vector2(0.024,0.005),Vector2(0.026,0.005),Vector2(0.025,0.005),Vector2(0.016,0.005)]),7,6)
	s.index()
	_bodies[variant] = s.commit()
	return _bodies[variant]

static func head(variant: int) -> ArrayMesh:
	if _heads.has(variant):
		return _heads[variant]
	var s := SurfaceTool.new()
	s.begin(Mesh.PRIMITIVE_TRIANGLES)
	var arrays := PEOPLE.get_head(variant if variant < 7 else 0).surface_get_arrays(0)
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var tags: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV2]
	for index: int in arrays[Mesh.ARRAY_INDEX]:
		var p := vertices[index]
		# A fitted cap contains the hair crown; retain the independent lower hair styles.
		if p.y > 1.19:
			p.y = 1.19 + (p.y-1.19)*0.18
		s.set_normal(normals[index])
		s.set_uv2(tags[index])
		PEOPLE._attributes(s,p,0,1)
		s.add_vertex(p)
	var crown := CylinderMesh.new()
	crown.top_radius = 0.10
	crown.bottom_radius = 0.105
	crown.height = 0.065
	crown.radial_segments = 16
	PEOPLE._append(s,crown,Transform3D(Basis.IDENTITY,Vector3(0,1.205,0)),8,1)
	var plate := BoxMesh.new()
	plate.size = Vector3(0.29,0.017,0.29)
	var angle := PI*0.25 + float(variant-3)*0.025
	PEOPLE._append(s,plate,Transform3D(Basis(Vector3.UP,angle),Vector3(0,1.249,0)),8,1)
	PEOPLE._oval(s,Vector3(0,1.261,0),Vector3(0.014,0.008,0.014),9,1,8,3)
	# Readable gold cord and rounded tassel; they follow the head's quiet motion.
	var cord := CylinderMesh.new()
	cord.top_radius = 0.004
	cord.bottom_radius = 0.004
	cord.height = 1.0
	cord.radial_segments = 6
	for pair in [[Vector3(0,1.263,0),Vector3(0.19,1.258,0.03)],[Vector3(0.19,1.258,0.03),Vector3(0.195,1.139,0.04)]]:
		var a: Vector3 = pair[0]
		var b: Vector3 = pair[1]
		var axis := (b-a).normalized()
		var right := axis.cross(Vector3.BACK).normalized()
		PEOPLE._append(s,cord,Transform3D(Basis(right,axis*a.distance_to(b),right.cross(axis)),(a+b)*0.5),9,1)
	PEOPLE._oval(s,Vector3(0.195,1.122,0.04),Vector3(0.010,0.029,0.010),9,1,8,3)
	s.index()
	_heads[variant] = s.commit()
	return _heads[variant]
