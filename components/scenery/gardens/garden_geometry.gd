@tool
extends "res://components/scenery/concert/shared/concert_geometry.gd"
const TURNED = preload("res://components/scenery/conservatory/shared/turned_geometry.gd")
func gravel(c: Dictionary) -> Dictionary:
	begin(c)
	var ring := PackedVector3Array()
	var phase := float(posmod(c.prop_seed,997))*0.071
	for index in 80:
		var a := TAU*index/80.0
		var r := 1.0+0.025*sin(a*5+phase)+0.015*sin(a*9-phase)
		ring.append(Vector3(cos(a)*c.footprint.x*.5*r,.018,sin(a)*c.footprint.y*.5*r))
	for index in ring.size():
		for p: Vector3 in [Vector3(0,.018,0),ring[index],ring[(index+1)%ring.size()]]:
			vertex(p,Vector3.UP,body)
	anchors["Approach"] = Vector3(0,0,c.footprint.y*.5+.8)
	return finish()
func lantern(c: Dictionary) -> Dictionary:
	begin(c)
	var scale: float = c.lantern_height/1.84
	frame = Transform3D(Basis.IDENTITY.scaled(Vector3.ONE*scale),Vector3.ZERO)
	var profile: Array[Vector2] = [Vector2(0,.01),Vector2(.44,.01),Vector2(.46,.12),Vector2(.28,.24),Vector2(.24,.28),Vector2(.16,.95),Vector2(.36,1.04),Vector2(.39,1.12),Vector2(0,1.12)]
	TURNED.lathe(self,profile,body,0,24)
	for x: float in [-.21,.21]:
		for z: float in [-.21,.21]:
			soft_box(Vector3(x,1.31,z),Vector3(.085,.42,.085),body.darkened(.06),.018)
	soft_box(Vector3(0,1.13,0),Vector3(.59,.09,.59),body,.035)
	soft_box(Vector3(0,1.51,0),Vector3(.62,.09,.62),body,.035)
	ball(Vector3(0,1.29,0),Vector3(.13,.17,.13),accent.darkened(.35))
	# A broad four-sided stone roof and rounded finial make a quiet garden silhouette.
	var roof: Array[Vector2] = [Vector2(0,1.51),Vector2(.76,1.51),Vector2(.78,1.55),Vector2(.52,1.59),Vector2(.17,1.74),Vector2(0,1.74)]
	TURNED.lathe(self,roof,body.lightened(.035),0,4)
	disc(Vector3(0,1.78,0),.1,.12,body,Vector3.UP,0,16)
	frame = Transform3D.IDENTITY
	colliders.append({"name":"LanternStone","center":Vector3(0,c.lantern_height*.5,0),"size":Vector3(.8*scale,c.lantern_height,.8*scale)})
	anchors["Approach"] = Vector3(0,0,.9*scale)
	return finish()
