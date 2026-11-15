@tool
extends RefCounted
## The bungalow's opaque windows, shingles and broad pigment, with varied massing.
const G = preload("res://components/buildings/house/house_geometry.gd")

static func _triangle(s: SurfaceTool,a: Vector3,b: Vector3,c: Vector3,color: Color) -> void:
	G._quad(s,a,b,c,c,color,1.0)

static func _gable(s: SurfaceTool,at: Vector3,size: Vector2,rise: float,c: Dictionary,rng: RandomNumberGenerator,side: bool) -> void:
	# Front gable's ridge runs along Z; side gable's ridge runs along X.
	var width := size.y if side else size.x
	var depth := size.x if side else size.y
	var temp := SurfaceTool.new()
	temp.begin(Mesh.PRIMITIVE_TRIANGLES)
	var x := width*0.5
	var z := depth*0.5
	var a := Vector3(-x,0,z)
	var b := Vector3(x,0,z)
	var d := Vector3(-x,0,-z)
	var e := Vector3(x,0,-z)
	var front := Vector3(0,rise,z)
	var back := Vector3(0,rise,-z)
	G._roof_face(temp,a,front,back,d,c.roof_color,c.shingle_size,rng)
	G._roof_face(temp,b,e,back,front,c.roof_color,c.shingle_size,rng)
	_triangle(temp,a,b,front,c.wall_color)
	_triangle(temp,e,d,back,c.wall_color)
	for pair in [[a,front],[b,front],[d,back],[e,back],[front,back]]:
		G._rod(temp,pair[0],pair[1],0.055,c.trim_color)
	for edge in [-1.0,1.0]:
		G._box(temp,Vector3(edge*x,-0.05,0),Vector3(0.12,0.15,depth),c.trim_color)
	var basis := Basis(Vector3.UP,PI*0.5) if side else Basis.IDENTITY
	# Preserve per-face paint tags when appending the roof into the house batch.
	var mesh := temp.commit()
	var arrays := mesh.surface_get_arrays(0)
	for i in arrays[Mesh.ARRAY_VERTEX].size():
		s.set_normal(basis*arrays[Mesh.ARRAY_NORMAL][i])
		s.set_color(arrays[Mesh.ARRAY_COLOR][i])
		s.set_uv2(arrays[Mesh.ARRAY_TEX_UV2][i])
		s.add_vertex(at+basis*arrays[Mesh.ARRAY_VERTEX][i])

static func _rails(s: SurfaceTool,left: Vector3,right: Vector3,color: Color) -> void:
	G._rod(s,left+Vector3.UP*0.84,right+Vector3.UP*0.84,0.035,color)
	G._rod(s,left+Vector3.UP*0.18,right+Vector3.UP*0.18,0.025,color)
	var count := maxi(2,ceili(left.distance_to(right)/0.30))
	for i in count+1:
		var at := left.lerp(right,float(i)/count)
		G._box(s,at+Vector3.UP*0.45,Vector3(0.045,0.9,0.045),color)

static func create(c: Dictionary) -> ArrayMesh:
	var s := SurfaceTool.new()
	s.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rng := RandomNumberGenerator.new()
	rng.seed = c.house_seed
	var size: Vector2 = c.footprint
	var floor_y: float = c.foundation_height
	var h: float = c.wall_height
	var total: float = h*c.storeys
	var front := size.y*0.5
	var top := floor_y+total
	G._box(s,Vector3(0,floor_y*0.5,0),Vector3(size.x+0.08,floor_y,size.y+0.08),c.foundation_color)
	G._box(s,Vector3(0,floor_y+total*0.5,0),Vector3(size.x,total,size.y),c.wall_color,1.0)
	# Sparse horizontal siding reads as brush-sized courses rather than tiny boards.
	for i in ceili(total/0.34):
		var y := floor_y+float(i)*0.34
		G._box(s,Vector3(0,y,front+0.004),Vector3(size.x,0.014,0.008),c.wall_color.darkened(0.07),1.0)
		G._box(s,Vector3(size.x*0.5+0.004,y,0),Vector3(0.008,0.014,size.y),c.wall_color.darkened(0.07),1.0)
	for x in [-size.x*0.5,size.x*0.5]:
		for z in [-front,front]: G._box(s,Vector3(x,floor_y+total*0.5,z),Vector3(0.14,total,0.14),c.trim_color)
	for level in c.storeys:
		var y: float = floor_y+level*h
		if level>0: G._box(s,Vector3(0,y,front+0.025),Vector3(size.x,0.13,0.10),c.trim_color)
		for x in [-size.x*0.29,size.x*0.29]:
			G._window(s,Vector3(x,y+h*0.55,front+0.035),Vector2(size.x*0.19,h*0.48),c.trim_color,c.wood_color,c.glass_color,false,c.window_warmth)
		if c.side_windows:
			for z in [-size.y*0.26,size.y*0.25]:
				G._window(s,Vector3(size.x*0.5+0.04,y+h*0.55,z),Vector2(size.y*0.18,h*0.47),c.trim_color,c.wood_color,c.glass_color,true,c.window_warmth)
	var dh := h*0.78
	G._box(s,Vector3(0,floor_y+dh*0.5,front+0.03),Vector3(c.door_width+0.20,dh+0.12,0.10),c.trim_color)
	G._box(s,Vector3(0,floor_y+dh*0.5,front+0.10),Vector3(c.door_width,dh,0.07),c.wood_color)
	G._box(s,Vector3(0,floor_y+dh*0.70,front+0.145),Vector3(c.door_width*0.67,dh*0.35,0.025),c.glass_color,3.0)
	G._rod(s,Vector3(c.door_width*0.33,floor_y+dh*0.42,front+0.15),Vector3(c.door_width*0.33,floor_y+dh*0.42,front+0.22),0.026,Color("b2a17e"))
	if c.porch_lamp: G._box(s,Vector3(c.door_width*0.75,floor_y+dh*0.88,front+0.1),Vector3(0.15,0.24,0.16),Color("f5dba2"),4.0)
	var deck: float = c.porch_depth if c.porch_enabled else 0.0
	if c.porch_enabled:
		var pw := size.x*0.94
		G._box(s,Vector3(0,floor_y*0.5,front+deck*0.5),Vector3(pw,floor_y,deck),c.wood_color)
		for i in maxi(2,ceili(deck/0.25)):
			G._box(s,Vector3(0,floor_y+0.003,front+i*0.25+0.10),Vector3(pw,0.008,0.014),c.wood_color.darkened(0.12))
		var roof_y := floor_y+h*0.93
		for x in [-size.x*0.45,size.x*0.45]:
			G._box(s,Vector3(x,(floor_y+roof_y)*0.5,front+deck-0.05),Vector3(0.13,roof_y-floor_y,0.13),c.trim_color)
			if c.railings:
				_rails(s,Vector3(x,floor_y,front),Vector3(x,floor_y,front+deck-0.04),c.trim_color)
				_rails(s,Vector3(x,floor_y,front+deck-0.04),Vector3(signf(x)*c.stair_width*0.5,floor_y,front+deck-0.04),c.trim_color)
		G._box(s,Vector3(0,roof_y,front+deck*0.5),Vector3(pw+0.24,0.16,deck+0.32),c.roof_color,2.0)
		G._box(s,Vector3(0,roof_y-0.08,front+deck+0.12),Vector3(pw+0.24,0.18,0.12),c.trim_color)
		if c.profile==3 and c.storeys>1:
			# A second stacked porch is scenic; lower porch remains fully explorable.
			for x in [-size.x*0.45,size.x*0.45]:
				G._box(s,Vector3(x,roof_y+h*0.5,front+deck-0.05),Vector3(0.13,h,0.13),c.trim_color)
				_rails(s,Vector3(x,roof_y+0.09,front),Vector3(x,roof_y+0.09,front+deck-0.04),c.trim_color)
			_rails(s,Vector3(-size.x*0.45,roof_y+0.09,front+deck-0.04),Vector3(size.x*0.45,roof_y+0.09,front+deck-0.04),c.trim_color)
			G._box(s,Vector3(0,roof_y+h,front+deck*0.5),Vector3(pw+0.24,0.16,deck+0.32),c.roof_color,2.0)
	for i in c.step_count:
		var rise: float = floor_y*(1.0-float(i)/c.step_count)
		G._box(s,Vector3(0,rise*0.5,front+deck+c.step_depth*(i+0.5)),Vector3(c.stair_width,rise,c.step_depth+0.012),c.foundation_color)
	_gable(s,Vector3(0,top,0),size+Vector2.ONE*c.roof_overhang*2.0,c.roof_height,c,rng,c.profile==2)
	if c.profile!=2:
		G._window(s,Vector3(0,top+c.roof_height*0.33,front+c.roof_overhang+0.045),Vector2(size.x*0.16,c.roof_height*0.40),c.trim_color,c.wood_color,c.glass_color,false,c.window_warmth)
	return s.commit()
