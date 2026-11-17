@tool
extends RefCounted
## Continuous support ribbon with optional embedded Voronoi stones or running bond.
var path
var length: float
var width: float
var rng := RandomNumberGenerator.new()
var tool: SurfaceTool
var faces := PackedVector3Array()

func emit_triangle(uvs: Array[Vector2], heights: Array[float], pigment: float, kind: float, support: bool = false) -> void:
	var p: Array[Vector3] = []
	for i in range(3): p.append(path._edge(uvs[i].y,uvs[i].x,heights[i]))
	var normal := (p[1]-p[0]).cross(p[2]-p[0])
	if normal.length_squared()<0.00000001: return
	var order := [0,2,1] if normal.y>=0 else [0,1,2]
	if normal.y<0: normal = -normal
	normal = normal.normalized()
	for i: int in order:
		tool.set_normal(normal)
		tool.set_color(Color(pigment,0.5,0.5,1))
		tool.set_uv(Vector2(uvs[i].x/(width*0.5),uvs[i].y))
		tool.set_uv2(Vector2(kind,path.get_half_width(uvs[i].y,signf(uvs[i].x))))
		tool.add_vertex(p[i])
		if support: faces.append(p[i])

func quad(a: Vector2,b: Vector2,c: Vector2,d: Vector2,height: float,pigment: float,kind: float,support: bool = false) -> void:
	emit_triangle([a,b,c],[height,height,height],pigment,kind,support)
	emit_triangle([a,c,d],[height,height,height],pigment,kind,support)

func clip(polygon: PackedVector2Array, normal: Vector2, limit: float) -> PackedVector2Array:
	var result := PackedVector2Array()
	if polygon.is_empty(): return result
	var a := polygon[-1]
	var da := normal.dot(a)-limit
	for b in polygon:
		var db := normal.dot(b)-limit
		if (da<=0)!=(db<=0): result.append(a.lerp(b,da/(da-db)))
		if db<=0: result.append(b)
		a = b
		da = db
	return result

func stone(polygon: PackedVector2Array,pigment: float,height: float = 0.032) -> void:
	if polygon.size()<3: return
	var center := Vector2.ZERO
	for p in polygon: center += p
	center /= float(polygon.size())
	var outer := PackedVector2Array()
	var top := PackedVector2Array()
	for p in polygon:
		var q := p.move_toward(center,minf(path.joint_width,p.distance_to(center)*0.16))
		outer.append(q)
		top.append(q.move_toward(center,0.012))
	var ids := Geometry2D.triangulate_polygon(top)
	for i in range(0,ids.size(),3):
		emit_triangle([top[ids[i]],top[ids[i+1]],top[ids[i+2]]],[height,height,height],pigment,2)
	for i in range(top.size()):
		var j := (i+1)%top.size()
		emit_triangle([outer[i],outer[j],top[j]],[0.013,0.013,height],pigment,3)
		emit_triangle([outer[i],top[j],top[i]],[0.013,height,height],pigment,3)

func flagstones() -> void:
	var cols := maxi(2,ceili(width/path.stone_size))
	var rows := maxi(2,ceili(length/path.stone_size))
	var pitch := Vector2(width/float(cols),length/float(rows))
	var centers := {}
	for row in range(-1,rows+1):
		for col in range(-1,cols+1):
			centers[Vector2i(col,row)] = Vector2((float(col)+0.5)*pitch.x-width*0.5,(float(row)+0.5)*pitch.y)+Vector2(rng.randf_range(-0.28,0.28)*pitch.x,rng.randf_range(-0.28,0.28)*pitch.y)
	for row in range(rows):
		for col in range(cols):
			var center: Vector2 = centers[Vector2i(col,row)]
			var cell := PackedVector2Array([Vector2(-width*0.5,0),Vector2(width*0.5,0),Vector2(width*0.5,length),Vector2(-width*0.5,length)])
			# A jittered local neighborhood is sufficient; no quadratic global search.
			for y in range(maxi(-1,row-2),mini(rows+1,row+3)):
				for x in range(maxi(-1,col-2),mini(cols+1,col+3)):
					if x==col and y==row: continue
					var other: Vector2 = centers[Vector2i(x,y)]
					cell = clip(cell,other-center,(other.length_squared()-center.length_squared())*0.5)
			if cell.size()>2: stone(cell,rng.randf_range(0.18,0.88),rng.randf_range(0.027,0.036))

func pavers() -> void:
	var row_pitch: float = path.stone_size*0.52
	var rows := maxi(1,ceili(length/row_pitch))
	row_pitch = length/float(rows)
	var cols := maxi(2,ceili(width/path.stone_size))
	var pitch := width/float(cols)
	for row in range(rows):
		var shift := 0.5 if row%2==1 else 0.0
		for col in range(-1,cols+1):
			var left := maxf(-width*0.5,-width*0.5+(float(col)+shift)*pitch)
			var right := minf(width*0.5,left+pitch if col>=0 else -width*0.5+shift*pitch)
			if right-left<0.10: continue
			var a := float(row)*row_pitch
			var b := float(row+1)*row_pitch
			stone(PackedVector2Array([Vector2(left,a),Vector2(right,a),Vector2(right,b),Vector2(left,b)]),rng.randf_range(0.30,0.79),0.031)

func accents() -> void:
	var gravel: bool = path.surface_style==1
	var count := roundi(length*width*path.detail_density*(2.0 if gravel else 0.45))
	for i in range(count):
		var across := rng.randf_range(-0.88,0.88)*width*0.5
		if not gravel and absf(across)<width*0.22: across += signf(across)*width*0.20
		var along := rng.randf_range(0.16,maxf(0.17,length-0.16))
		var radius := rng.randf_range(0.025,0.060) if gravel else rng.randf_range(0.055,0.115)
		var polygon := PackedVector2Array()
		for side in range(6):
			var angle := TAU*float(side)/6.0
			polygon.append(Vector2(across,along)+Vector2(cos(angle),sin(angle))*radius*rng.randf_range(0.8,1.15))
		stone(polygon,rng.randf_range(0.20,0.82),0.025)

func build(source) -> Dictionary:
	path = source
	length = source.get_path_length()
	width = source.path_width
	rng.seed = source.paving_seed
	tool = SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var count := maxi(2,ceili(length/source.sample_spacing))
	var lanes: Array[float] = [-0.5,-0.25,0.0,0.25,0.5]
	for i in range(count):
		var a := length*float(i)/float(count)
		var b := length*float(i+1)/float(count)
		var pigment := 0.5+0.16*sin(a*0.71+float(source.paving_seed))
		for lane in range(lanes.size()-1):
			quad(Vector2(width*lanes[lane],a),Vector2(width*lanes[lane],b),Vector2(width*lanes[lane+1],b),Vector2(width*lanes[lane+1],a),0.0125,pigment,0,true)
	match source.surface_style:
		2: flagstones()
		3: pavers()
		_: accents()
	tool.index()
	return {"mesh":tool.commit(),"faces":faces}
