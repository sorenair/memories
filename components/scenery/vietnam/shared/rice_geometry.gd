@tool
extends "res://components/scenery/concert/shared/concert_geometry.gd"
static func edge(c: Dictionary,tier: int,x: float) -> Vector3:
	var u: float = x/(c.footprint.x*0.5)
	var phase: float = float(posmod(c.prop_seed,997))*0.013
	return Vector3(x,0.12+tier*c.terrace_rise,c.footprint.y*0.5-tier*c.footprint.y/c.tier_count-c.curvature*(1.0-u*u)+0.16*sin(x*0.60+phase))
func terraces(c: Dictionary) -> Dictionary:
	begin(c)
	var full_half: float = c.footprint.x*0.5
	var depth: float = c.footprint.y/c.tier_count
	for tier in range(c.tier_count):
		var half := full_half*(1.0-0.033*tier)
		var y: float = 0.12+tier*c.terrace_rise
		var tone := accent.lightened((tier%3-1)*0.035)
		for i in 40:
			var x0 := lerpf(-half,half,i/40.0)
			var x1 := lerpf(-half,half,(i+1)/40.0)
			var a := edge(c,tier,x0)
			var b := edge(c,tier,x1)
			var rear_a := a+Vector3(0,0,-depth)
			var rear_b := b+Vector3(0,0,-depth)
			quad(a,rear_a,rear_b,b,tone)
			quad(a-Vector3.UP*(y+0.08),a,b,b-Vector3.UP*(y+0.08),body)
			# Broad rounded earth bund, uninterrupted along each contour.
			quad(a+Vector3(0,0.035,0.18),a+Vector3(0,0.035,-0.15),b+Vector3(0,0.035,-0.15),b+Vector3(0,0.035,0.18),brass)
			if i==0: quad(rear_a-Vector3.UP*(y+0.08),a-Vector3.UP*(y+0.08),a,rear_a,body)
			if i==39: quad(b,b-Vector3.UP*(y+0.08),rear_b-Vector3.UP*(y+0.08),rear_b,body)
		var count := roundi(half*2.0*(depth-0.7)*c.plants_per_square_meter)
		for index in count:
			var x := rng.randf_range(-half+0.25,half-0.25)
			var front := edge(c,tier,x)
			var at := front+Vector3(0,0.025,-rng.randf_range(0.45,depth-0.25))
			var green := accent.lightened(rng.randf_range(-0.08,0.13))
			var height := rng.randf_range(0.36,0.59)
			for leaf in 3:
				var angle := rng.randf()*TAU
				var side := Vector3(cos(angle),0,sin(angle))
				var tip := at+Vector3.UP*height+side*height*0.30
				var middle := at+Vector3.UP*height*0.58+side*height*0.22
				blade(at-side*0.024,at+side*0.024,middle+side*0.017,green,0,0,0.58)
				blade(at-side*0.024,middle+side*0.017,middle-side*0.017,green,0,0.58,0.58)
				blade(middle-side*0.017,middle+side*0.017,tip,green,0.58,0.58,1)
		# Twenty curved convex cells per shelf provide solid, flat paddy ground.
		for index in 20:
			var points := PackedVector3Array()
			for x in [lerpf(-half,half,index/20.0),lerpf(-half,half,(index+1)/20.0)]:
				var front := edge(c,tier,x)
				for z in [front.z,front.z-depth]:
					points.append(Vector3(x,y,z))
					points.append(Vector3(x,-0.08,z))
			colliders.append({"name":"TerraceSoil%d_%d"%[tier,index],"points":points})

	anchors["FrontApproach"] = edge(c,0,-full_half+1)+Vector3(0,0,1)
	return finish()
func blade(a: Vector3,b: Vector3,c: Vector3,color: Color,wa: float,wb: float,wc: float) -> void:
	var normal := (b-a).cross(c-a).normalized()
	if normal.length_squared()<0.1: return
	for item in [[a,wa],[b,wb],[c,wc]]:
		s.set_normal(normal)
		s.set_color(color.srgb_to_linear())
		s.set_uv2(Vector2(7,item[1]))
		s.add_vertex(item[0])

var _bank_faces := PackedVector3Array()

## Authored paddies share one surface, one collision body, and the existing rice shader.
func paddies(c: Dictionary, contours: Array[Curve3D], bund: PackedVector3Array, bund_width: float, clearings: Array[Curve3D]) -> Dictionary:
	begin(c)
	for contour in contours:
		if contour and contour.get_baked_length() > 1.0:
			_paddy(contour, c.plants_per_square_meter)
	_earthen_bund(bund, bund_width)
	for clearing in clearings:
		if clearing and clearing.get_baked_length() > 1.0:
			_paddy(clearing, 0.0)
	var result := finish()
	result.terrain_faces = _bank_faces
	return result

func _paddy(contour: Curve3D, density: float) -> void:
	var perimeter := contour.get_baked_length()
	var steps := clampi(ceili(perimeter / 0.52), 10, 90)
	var outline := PackedVector2Array()
	for index in steps:
		var point := contour.sample_baked(perimeter * float(index) / steps, true)
		outline.append(Vector2(point.x, point.z))
	if Geometry2D.is_polygon_clockwise(outline):
		outline.reverse()
	var triangles := Geometry2D.triangulate_polygon(outline)
	if triangles.is_empty():
		return
	var height := contour.get_point_position(0).y
	var tone := accent.lerp(Color("98a059"), rng.randf_range(0.15, 0.48)) if density > 0 else Color("9b9066")
	_paddy_flat(outline, triangles, height, tone, 0.0, true)

	for index in outline.size():
		var next := (index + 1) % outline.size()
		var a := outline[index]
		var b := outline[next]
		var reach := clampf(height * 0.27, 0.08, 0.42)
		var shoulder_a := _paddy_outward(outline, index) * reach
		var shoulder_b := _paddy_outward(outline, next) * reach
		var crest_a := Vector3(a.x, height, a.y)
		var crest_b := Vector3(b.x, height, b.y)
		var lip_a := crest_a + Vector3(shoulder_a.x * 0.47, -minf(0.22, height * 0.66), shoulder_a.y * 0.47)
		var lip_b := crest_b + Vector3(shoulder_b.x * 0.47, -minf(0.22, height * 0.66), shoulder_b.y * 0.47)
		var toe_a := Vector3(a.x + shoulder_a.x, -0.025, a.y + shoulder_a.y)
		var toe_b := Vector3(b.x + shoulder_b.x, -0.025, b.y + shoulder_b.y)
		_bank_quad(crest_a, crest_b, lip_b, lip_a, tone.lerp(body, 0.41))
		_bank_quad(lip_a, lip_b, toe_b, toe_a, body.lerp(tone, rng.randf_range(0.22, 0.43)))

	if density <= 0.0:
		return
	for wet in Geometry2D.offset_polygon(outline, -0.27, Geometry2D.JOIN_ROUND):
		var water_triangles := Geometry2D.triangulate_polygon(wet)
		if water_triangles.is_empty():
			continue
		var water := Color("819e6e").lerp(Color("8ebb9d"), rng.randf_range(0.18, 0.82))
		_paddy_flat(wet, water_triangles, height + 0.009, water, 5.0, false)
		_plant_rows(wet, height, density, tone)

func _paddy_outward(outline: PackedVector2Array, index: int) -> Vector2:
	var size := outline.size()
	var tangent := outline[(index + 1) % size] - outline[posmod(index - 1, size)]
	return Vector2(tangent.y, -tangent.x).normalized()

func _paddy_flat(outline: PackedVector2Array, ids: PackedInt32Array, height: float, tint: Color, kind: float, solid: bool) -> void:
	for index in range(0, ids.size(), 3):
		for corner in [0, 2, 1]:
			var point := outline[ids[index + corner]]
			var at := Vector3(point.x, height, point.y)
			vertex(at, Vector3.UP, tint, kind)
			if solid:
				_bank_faces.append(at)

func _bank_quad(a: Vector3, b: Vector3, c: Vector3, d: Vector3, tint: Color) -> void:
	_bank_triangle(a, b, c, tint)
	_bank_triangle(a, c, d, tint)

func _bank_triangle(a: Vector3, b: Vector3, c: Vector3, tint: Color) -> void:
	var normal := (b - a).cross(c - a)
	if normal.length_squared() < 0.00000001:
		return
	normal = normal.normalized()
	for point in [a, b, c]:
		vertex(point, normal, tint)
		_bank_faces.append(point)

func _plant_rows(outline: PackedVector2Array, height: float, density: float, tone: Color) -> void:
	var bounds := Rect2(outline[0], Vector2.ZERO)
	for point in outline:
		bounds = bounds.expand(point)
	var step := 1.0 / sqrt(density)
	var row_spacing := step * 1.26
	var phase := rng.randf_range(0.0, TAU)
	for row in ceili(bounds.size.y / row_spacing):
		for column in ceili(bounds.size.x / step):
			var x := bounds.position.x + (column + (row % 2) * 0.44) * step
			var z := bounds.position.y + row * row_spacing + 0.17 * sin(x * 0.59 + phase)
			var point := Vector2(x, z) + Vector2(rng.randf_range(-0.08, 0.08), rng.randf_range(-0.09, 0.09))
			if not Geometry2D.is_point_in_polygon(point, outline) or rng.randf() < 0.10:
				continue
			var base := Vector3(point.x, height + 0.012, point.y)
			var tint := tone.lerp(Color("c5d96e"), rng.randf_range(0.08, 0.65))
			var length := rng.randf_range(0.36, 0.59)
			for leaf in 4:
				var direction := Vector3(cos(leaf * 2.4 + phase), 0.0, sin(leaf * 2.4 + phase))
				var side := direction.cross(Vector3.UP) * rng.randf_range(0.021, 0.039)
				var middle := base + (Vector3.UP + direction * 0.29) * length * 0.59
				var crown := base + (Vector3.UP * rng.randf_range(0.78, 1.12) + direction * 0.44) * length
				blade(base - side * 0.53, base + side * 0.53, middle + side, tint.darkened(0.07), 0, 0, 0.58)
				blade(base - side * 0.53, middle + side, middle - side, tint, 0, 0.58, 0.58)
				blade(middle - side, middle + side, crown, tint.lightened(0.095), 0.58, 0.58, 1)

func _earthen_bund(points: PackedVector3Array, width: float) -> void:
	for index in range(points.size() - 1):
		var start := points[index]
		var end := points[index + 1]
		var a := _bund_side(points, index)
		var b := _bund_side(points, index + 1)
		var start_width := smoothstep(0.0, 0.22, start.y)
		var end_width := smoothstep(0.0, 0.22, end.y)
		if start_width == 0.0 and end_width == 0.0:
			continue
		var inset := Vector3.UP * 0.035
		var start_edge := a * width * 0.42 * start_width
		var end_edge := b * width * 0.42 * end_width
		for sign_value: float in [-1.0, 1.0]:
			var a_edge := start + start_edge * sign_value - inset
			var b_edge := end + end_edge * sign_value - inset
			var toe_a := start + a * (width * 0.46 + start.y * 0.72) * start_width * sign_value
			var toe_b := end + b * (width * 0.46 + end.y * 0.72) * end_width * sign_value
			toe_a.y = 0.018
			toe_b.y = 0.018
			_bank_quad(a_edge, b_edge, toe_b, toe_a, body.lerp(accent, 0.53))
		# Connect the shoulders immediately beneath the authored walking mesh.
		_bank_quad(start - start_edge - inset, end - end_edge - inset,
			end + end_edge - inset, start + start_edge - inset, body.lerp(accent, 0.62))

func _bund_side(points: PackedVector3Array, index: int) -> Vector3:
	var direction := points[mini(index + 1, points.size() - 1)] - points[maxi(index - 1, 0)]
	return Vector3(direction.z, 0.0, -direction.x).normalized()
