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
