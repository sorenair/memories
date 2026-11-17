@tool
extends RefCounted
## A broad inclined sandstone sheet: closed backing + deeply fractured face plates.
## +Z faces the viewer/toe; the crest recedes toward -Z as it rises.
var surface: SurfaceTool
var rng := RandomNumberGenerator.new()
var colliders: Array[Dictionary] = []
var up_face: Vector3
var face_normal: Vector3
var slab_height: float
var slab_width: float
var slab_depth: float
var bury: float
var jagged: float

func outline(form: int) -> PackedVector2Array:
	var source: PackedVector2Array
	match form:
		1:
			source = PackedVector2Array([Vector2(-0.53,0),Vector2(0.51,0),Vector2(0.52,0.22),Vector2(0.41,0.40),Vector2(0.43,0.49),Vector2(0.30,0.70),Vector2(0.25,0.94),Vector2(0.14,0.97),Vector2(0.055,0.82),Vector2(-0.025,0.65),Vector2(-0.045,0.93),Vector2(-0.15,1.0),Vector2(-0.24,0.86),Vector2(-0.32,0.62),Vector2(-0.43,0.31)])
		2:
			source = PackedVector2Array([Vector2(-0.55,0),Vector2(0.52,0),Vector2(0.52,0.23),Vector2(0.42,0.42),Vector2(0.38,0.63),Vector2(0.25,0.65),Vector2(0.23,0.81),Vector2(0.12,0.91),Vector2(0.07,0.78),Vector2(-0.035,0.90),Vector2(-0.12,1.0),Vector2(-0.23,0.91),Vector2(-0.31,0.70),Vector2(-0.38,0.51),Vector2(-0.49,0.29)])
		_:
			source = PackedVector2Array([Vector2(-0.53,0),Vector2(0.50,0),Vector2(0.52,0.19),Vector2(0.40,0.32),Vector2(0.44,0.38),Vector2(0.32,0.53),Vector2(0.35,0.59),Vector2(0.22,0.76),Vector2(0.25,0.82),Vector2(0.10,0.97),Vector2(0.04,1.0),Vector2(-0.055,0.87),Vector2(-0.22,0.65),Vector2(-0.32,0.43),Vector2(-0.42,0.20)])
	var lean := rng.randf_range(-0.02,0.18)
	var points := PackedVector2Array()
	for i in range(source.size()):
		var p := source[i]
		# Preserve summit/base heights, but seed unequal shoulders and chips.
		if p.y>0 and p.y<0.99:
			p.x += rng.randf_range(-0.027,0.027)*jagged
			p.y += rng.randf_range(-0.018,0.018)*jagged
		p.x += lean*p.y
		points.append(Vector2(p.x*slab_width,p.y*slab_height-bury))
	return points

func point_on_face(p: Vector2, distance: float) -> Vector3:
	return Vector3.RIGHT*p.x+up_face*p.y+face_normal*distance

func triangle(a: Vector3, b: Vector3, c: Vector3, outward: Vector3, tint: Color) -> void:
	var normal := (b-a).cross(c-a)
	if normal.length_squared()<0.00000001: return
	if normal.dot(outward)<0:
		var swap := b
		b = c
		c = swap
		normal = -normal
	surface.set_normal(normal.normalized())
	surface.set_color(tint)
	# Godot's visible faces wind clockwise, opposite the normal's cross product.
	for p: Vector3 in [a,c,b]: surface.add_vertex(p)

func plate(polygon: PackedVector2Array, front_distance: float, back_distance: float, slope: float, pigment: float, cut: float = 1.0, bevel: float = 0.0) -> void:
	if polygon.size()<3: return
	if Geometry2D.is_polygon_clockwise(polygon): polygon.reverse()
	var ids := Geometry2D.triangulate_polygon(polygon)
	if ids.is_empty(): return
	var center_x := 0.0
	for p in polygon: center_x += p.x
	center_x /= float(polygon.size())
	var front := PackedVector3Array()
	var back := PackedVector3Array()
	for p in polygon:
		front.append(point_on_face(p,front_distance+(p.x-center_x)*slope))
		var worn := Vector2(p.x*(1.0-bevel),p.y-maxf(0,p.y)*bevel*0.35)
		back.append(point_on_face(worn,back_distance))
	var face_tint := Color(pigment,cut,0,1)
	var edge_tint := Color(pigment,1,0,1)
	for i in range(0,ids.size(),3):
		triangle(front[ids[i]],front[ids[i+1]],front[ids[i+2]],face_normal,face_tint)
		triangle(back[ids[i]],back[ids[i+1]],back[ids[i+2]],-face_normal,edge_tint)
	for i in range(polygon.size()):
		var next := (i+1)%polygon.size()
		var direction := polygon[next]-polygon[i]
		var outward := Vector3.RIGHT*direction.y-up_face*direction.x
		triangle(front[i],back[i],back[next],outward,edge_tint)
		triangle(front[i],back[next],front[next],outward,edge_tint)
	# Individual convex hulls follow the plates instead of one giant bounding box.
	var hull := front.duplicate()
	hull.append_array(back)
	colliders.append({"name":"StonePlate%d" % colliders.size(),"points":hull})

func create(config: Dictionary) -> Dictionary:
	surface = SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	rng.seed = config.prop_seed
	slab_height = config.formation_height
	slab_width = config.formation_width
	slab_depth = config.thickness
	bury = config.burial
	jagged = config.jaggedness
	var angle := deg_to_rad(config.slope_angle)
	up_face = Vector3(0,1.0,-1.0/tan(angle))
	face_normal = Vector3(0,cos(angle),sin(angle))
	var silhouette := outline(config.formation_type)
	# Dark recessed bed behind the open fractures, so gaps never show white void.
	plate(silhouette,-slab_depth*0.22,-slab_depth,0,0.5,0.12,0.075)
	var shear := slab_width/slab_height*rng.randf_range(0.12,0.24)
	var min_u := INF
	var max_u := -INF
	for p in silhouette:
		min_u = minf(min_u,p.x-shear*p.y)
		max_u = maxf(max_u,p.x-shear*p.y)
	var count: int = config.fracture_count+1
	var boundaries: Array[float] = [min_u-0.05]
	var pitch := (max_u-min_u)/float(count)
	for i in range(1,count):
		boundaries.append(min_u+pitch*(float(i)+rng.randf_range(-0.16,0.16)*jagged))
	boundaries.append(max_u+0.05)
	var gap := slab_width*lerpf(0.004,0.014,jagged)
	var low := -bury-1.0
	var high := slab_height+1.0
	var levels: Array[float] = [low,slab_height*0.32,slab_height*0.68,high]
	var seams: Array[PackedVector2Array] = []
	for index in range(boundaries.size()):
		var seam := PackedVector2Array()
		for level in levels:
			var kink := rng.randf_range(-0.025,0.025)*slab_width*jagged if index>0 and index<boundaries.size()-1 else 0.0
			seam.append(Vector2(boundaries[index]+shear*level+kink,level))
		seams.append(seam)
	for i in range(count):
		var left := boundaries[i]+(gap*0.5 if i>0 else 0.0)
		var right := boundaries[i+1]-(gap*0.5 if i<count-1 else 0.0)
		var band := PackedVector2Array()
		# Shared, gently kinked joints retain irregular stone plates, not straight rails.
		for k in range(levels.size()):
			band.append(seams[i+1][k]-Vector2(gap*(0.35 if k==levels.size()-1 else 0.5) if i<count-1 else 0.0,0))
		for k in range(levels.size()-1,-1,-1):
			band.append(seams[i][k]+Vector2(gap*(0.35 if k==levels.size()-1 else 0.5) if i>0 else 0.0,0))
		var polygons := Geometry2D.intersect_polygons(silhouette,band)
		var depth := slab_depth*rng.randf_range(-0.012,0.025)*jagged
		# Thin/wide authoring extremes must not turn a front plane inside its back.
		var tilt_limit := minf(0.15*jagged,slab_depth*0.12/maxf(0.01,(right-left)*0.5))
		var tilt := rng.randf_range(-tilt_limit,tilt_limit)
		var tint := rng.randf_range(0.05,0.95)
		for polygon: PackedVector2Array in polygons:
			if i%2==1 and jagged>0.15:
				# Sparse, offset diagonal joints: large broken planes, never a tile grid.
				var joint := slab_height*(0.28+float(i%3)*0.15+rng.randf_range(-0.035,0.035))
				var slope := slab_height/slab_width*rng.randf_range(0.12,0.22)
				var across := slab_width*2.0
				var joint_gap := slab_height*lerpf(0.002,0.007,jagged)
				var joint_low := minf(low,joint-slope*across-1.0)
				var joint_high := maxf(high,joint+joint_gap+slope*across+1.0)
				var lower := PackedVector2Array([Vector2(-across,joint_low),Vector2(across,joint_low),Vector2(across,joint+slope*across),Vector2(-across,joint-slope*across)])
				var upper := PackedVector2Array([Vector2(-across,joint+joint_gap-slope*across),Vector2(across,joint+joint_gap+slope*across),Vector2(across,joint_high),Vector2(-across,joint_high)])
				for part: PackedVector2Array in Geometry2D.intersect_polygons(polygon,lower):
					plate(part,depth,-slab_depth*0.26,tilt,tint)
				for part: PackedVector2Array in Geometry2D.intersect_polygons(polygon,upper):
					plate(part,depth+slab_depth*0.015,-slab_depth*0.26,-tilt,rng.randf_range(0.1,0.95))
			else:
				plate(polygon,depth,-slab_depth*0.26,tilt,tint)
	surface.index()
	var mesh := surface.commit()
	var crest := Vector3(0,-INF,0)
	for p: Vector3 in mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]:
		if p.y>crest.y: crest = p
	var anchors := {"Approach":Vector3(0,0,3.0),"Base":Vector3(0,0,0),"Crest":crest}
	return {"mesh":mesh,"colliders":colliders,"anchors":anchors}
