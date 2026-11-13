@tool
extends RefCounted
## Shared festival details built with First Meeting's geometry and crowd meshes.
const PEOPLE = preload("res://components/characters/crowd/crowd_geometry.gd")
const GREEN := Color("4c6657")
const GOLD := Color("d7bb77")
const BULB := Color("ffdda0")

static func person(b: RefCounted, at: Vector3, size: float, variant: int, coat: Color, arms := true) -> void:
	var colors := [coat,Color("485052"),Color("c4a18b"),Color("65574e"),Color("454743"),coat.lightened(0.08)]
	for mesh in [PEOPLE.get_body(variant),PEOPLE.get_head(posmod(variant+2,8))]:
		var arrays: Array = mesh.surface_get_arrays(0)
		var points: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
		var kinds: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV2]
		var uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
		var ids: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
		for triangle in range(0,ids.size(),3):
			if not arms and (absf(uvs[ids[triangle]].x)>0.1 or absf(uvs[ids[triangle+1]].x)>0.1 or absf(uvs[ids[triangle+2]].x)>0.1): continue
			for corner in 3:
				var i := ids[triangle+corner]
				b.vertex(at+points[i]*size,normals[i],colors[clampi(roundi(kinds[i].x),0,5)],1.0)

static func wreath(b: RefCounted, at: Vector3, radius: float) -> void:
	var ring: Array[Vector3] = []
	for i in 33:
		var a := TAU*i/32.0
		ring.append(at+Vector3(cos(a),sin(a),0)*radius)
	b.tube(ring,radius*0.18,GREEN,8)
	for i in 12:
		var a := TAU*i/12.0
		b.ball(at+Vector3(cos(a),sin(a),0)*radius,Vector3(0.15,0.09,0.09),GREEN.lightened(0.055),1.0)
	b.ball(at+Vector3(0,-radius,0.07),Vector3(0.17,0.11,0.08),Color("a36459"),1.0)

static func garland(b: RefCounted, at: Vector3, width: float) -> void:
	var line: Array[Vector3] = []
	for i in 25:
		var t := i/24.0
		var p := at+Vector3((t-0.5)*width,-sin(t*PI)*0.18,0)
		line.append(p)
		if i%2==0:
			b.ball(p,Vector3(0.25,0.12,0.14),GREEN,1.0)
			b.ball(p+Vector3(0,-0.075,0.08),Vector3.ONE*0.065,BULB,3.0)
	b.tube(line,0.035,GREEN.darkened(0.1),6)
