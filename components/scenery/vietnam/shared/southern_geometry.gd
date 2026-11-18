@tool
extends "res://components/scenery/tokyo/shared/japanese_geometry.gd"
## Coastal rock shelves and two compressed Saigon skyline silhouettes.
var _ridge_faces := PackedVector3Array()

func headland(c: Dictionary) -> Dictionary:
	begin(c)
	var half: Vector2 = c.footprint*0.5
	var height: float = c.cliff_height
	var phase := rng.randf()*TAU
	var rings: Array[PackedVector3Array] = []
	var collider_points := PackedVector3Array()
	var has_ridges: bool = not c.ridges.is_empty()
	for level in range(6):
		var t := level/5.0
		var ring := PackedVector3Array()
		for index in 48:
			var angle := TAU*index/48.0
			var radius := 1.0+0.055*sin(angle*5+phase)+0.035*sin(angle*9-phase)
			if has_ridges:
				radius += 0.085 * sin(angle * 3 + phase) * sin(t * PI)
			radius *= 1.05-0.05*t+0.045*sin(t*8+angle*2)
			var p := Vector3(cos(angle)*half.x*radius,height*t-0.04*(1-t),sin(angle)*half.y*radius)
			ring.append(p)
			if level in [0,5]: collider_points.append(p)
		rings.append(ring)
	for level in range(5):
		for index in 48:
			var next := (index+1)%48
			var tone := body.lightened(0.035*sin(index*1.2+phase)+0.015*level)
			quad(rings[level][index],rings[level+1][index],rings[level+1][next],rings[level][next],tone)
	for index in 48:
		var a: Vector3 = rings[5][index]
		var b: Vector3 = rings[5][(index+1)%48]
		for p in [Vector3(0,height,0),a,b]: vertex(p,Vector3.UP,accent)
	colliders.append({"name":"HeadlandTop","points":collider_points})
	for ridge: PackedVector3Array in c.ridges:
		_rock_ridge(ridge, phase)
	anchors["Summit"] = Vector3(0,height,0)
	var result := finish()
	result.ridge_faces = _ridge_faces
	return result

func _rock_ridge(ridge: PackedVector3Array, phase: float) -> void:
	var sections: Array[PackedVector3Array] = []
	for index in ridge.size():
		var point := ridge[index]
		var direction := ridge[mini(index + 1, ridge.size() - 1)] - ridge[maxi(index - 1, 0)]
		var side := Vector3(direction.z, 0.0, -direction.x).normalized()
		var rise := maxf(0.0, point.y)
		var taper := smoothstep(0.07, 0.47, rise)
		var center := point - Vector3.UP * lerpf(0.14, 0.055, taper)
		var section := PackedVector3Array()
		for flank: float in [-1.0, 1.0]:
			var scallop := 0.47 * sin(index * 0.89 + phase + flank)
			# The inner shoulder merges with the headland; the exposed side breaks into ledges.
			var toward_core := (-Vector3(point.x, 0.0, point.z)).normalized()
			var apron := maxf(0.0, side.dot(toward_core) * flank) * smoothstep(12.5, 5.0, Vector2(point.x, point.z).length())
			var tread := center + side * (1.20 + scallop * 0.26) * taper * flank
			var shelf := center + side * (1.58 + rise * (0.32 + apron * 0.55) + scallop * 0.7) * taper * flank
			shelf.y = lerpf(-0.12, rise * (0.56 + apron * 0.10 + 0.13 * sin(index * 0.86 + flank)), taper)
			var toe := center + side * (1.83 + rise * (0.59 + apron) + scallop) * taper * flank
			toe.y = -0.15
			if flank < 0:
				section.append_array(PackedVector3Array([toe, shelf, tread]))
			else:
				section.append_array(PackedVector3Array([tread, shelf, toe]))
		sections.append(section)
	for index in range(sections.size() - 1):
		var first := sections[index]
		var next := sections[index + 1]
		if maxf(ridge[index].y, ridge[index + 1].y) < 0.09:
			continue
		for lane in 5:
			var tint := body.lerp(accent, 0.25 if lane == 1 or lane == 3 else 0.05)
			if lane == 2:
				tint = accent.lerp(body, 0.19)
			tint = tint.lerp(brass, 0.055 + 0.055 * sin(index * 0.51 + lane))
			_ridge_face(first[lane], next[lane], next[lane + 1], tint)
			_ridge_face(first[lane], next[lane + 1], first[lane + 1], tint)

func _ridge_face(a: Vector3, b: Vector3, c: Vector3, tint: Color) -> void:
	var direction := (b - a).cross(c - a)
	if direction.length_squared() < 0.00000001:
		return
	var normal := direction.normalized()
	if normal.y < 0.0:
		normal = -normal
	for point in [a, b, c]:
		vertex(point, normal, tint)
		_ridge_faces.append(point)

func lotus_tower(c: Dictionary) -> Dictionary:
	begin(c)
	var height: float = c.floors*c.floor_height
	var half: Vector2 = c.footprint*0.5
	var levels: int = c.floors
	for level in range(levels):
		var t0 := float(level)/levels
		var t1 := float(level+1)/levels
		for index in 40:
			var a := TAU*index/40.0
			var b := TAU*(index+1)/40.0
			var points: Array[Vector3] = []
			for pair in [Vector2(a,t0),Vector2(a,t1),Vector2(b,t1),Vector2(b,t0)]:
				var factor := 0.74+0.24*sin(pair.y*PI*0.88)
				var y: float = height*pair.y+(0.42*sin(pair.x) if level==levels-1 and pair.y==t1 else 0.0)
				points.append(Vector3(cos(pair.x)*half.x*factor,y,sin(pair.x)*half.y*factor))
			quad(points[0],points[1],points[2],points[3],body.lightened(0.035*sin(index*0.8)+0.015*(level%3)))
			var rim_a := points[1]
			var rim_b := points[2]
			rod(rim_a,rim_b,0.016,roof_paint,6)
			if index%4==0: rod(points[0],points[1],0.017,brass,6)
	var cap := Vector3(0,height,0)
	for index in 40:
		var a := TAU*index/40.0
		var b := TAU*(index+1)/40.0
		var ra := Vector3(cos(a)*half.x*0.83,height+0.42*sin(a),sin(a)*half.y*0.83)
		var rb := Vector3(cos(b)*half.x*0.83,height+0.42*sin(b),sin(b)*half.y*0.83)
		quad(cap,ra,rb,cap,roof_paint)
	# An off-center projecting disc suggests the recognizable lotus-tower helipad.
	var pad := Vector3(0,height*0.68,half.y+0.62)
	disc(pad,half.x*0.72,0.13,brass,Vector3.UP,0,40)
	rod(Vector3(0,height*0.62,half.y*0.70),pad-Vector3.UP*0.08,0.09,roof_paint,10)
	soft_box(Vector3(0,0.65,half.y*0.78),Vector3(0.8,1.3,0.07),Color("344b4e"),0.03)
	collider(Vector3(0,height*0.5,0),Vector3(c.footprint.x,height,c.footprint.y),"TowerExterior")
	anchors={"Entrance":Vector3(0,0,half.y+1.0),"Roof":Vector3(0,height,0)}
	return finish()

func clustered_tower(c: Dictionary) -> Dictionary:
	begin(c)
	var total: float = c.floors*c.floor_height
	var step: Vector2 = c.footprint/3.0
	var heights := [0.61,0.80,0.57,0.83,1.0,0.74,0.56,0.73,0.48]
	for index in 9:
		var x := (index%3-1)*step.x
		var z := (floori(index/3.0)-1)*step.y
		var height: float = total*heights[index]
		flat_deck(Vector3(x,height*0.5,z),step.x*0.94,step.y*0.94,height,body.lightened((index%3-1)*0.025),0.06)
		var floors := maxi(3,roundi(height/c.floor_height))
		for level in floors:
			flat_deck(Vector3(x,(level+1)*height/floors,z),step.x*0.96,step.y*0.96,0.045,roof_paint,0.035)
		for side in [-1.0,1.0]:
			rod(Vector3(x+side*step.x*0.32,0,z+step.y*0.48),Vector3(x+side*step.x*0.32,height,z+step.y*0.48),0.021,brass,6)
		rod(Vector3(x,height,z),Vector3(x,height+0.65,z),0.025,brass,8)
	rod(Vector3(0,total,0),Vector3(0,total+3.8,0),0.045,brass,10)
	collider(Vector3(0,total*0.5,0),Vector3(c.footprint.x,total,c.footprint.y),"TowerExterior")
	anchors={"Entrance":Vector3(0,0,c.footprint.y*0.5+1.0),"Roof":Vector3(0,total,0)}
	return finish()
