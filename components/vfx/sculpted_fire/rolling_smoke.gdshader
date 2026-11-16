shader_type spatial;
render_mode unshaded, cull_front, depth_draw_never, fog_disabled;
#include "res://components/vfx/sculpted_fire/fire_common.gdshaderinc"
#include "res://components/vfx/sculpted_fire/smoke_flow.gdshaderinc"
varying vec3 proxy_position;
varying flat vec3 cloud_lower;
varying flat vec3 cloud_upper;
varying flat vec4 billow[7];
varying flat float billow_opacity[7];
float cloud_union(float a, float b, float k) {
	float h = clamp(0.5+0.5*(b-a)/k,0.0,1.0);
	return mix(b,a,h)-k*h*(1.0-h);
}
float cloud_distance(vec3 p) {
	float d = 100.0;
	float k = smoke_spread*0.22;
	for (int i=0;i<7;i++) {
		if (billow_opacity[i]<0.01) { continue; }
		float sphere = length((p-billow[i].xyz)*vec3(1.0,0.90,1.0))-billow[i].w;
		d = cloud_union(d,sphere,k);
	}
	return d*0.95;
}
// Sample the strongest optical chord, including billows behind a fading
// foreground lobe. Nearest-surface opacity alone exposes dark seams at joins.
float cloud_opacity(vec3 origin, vec3 rd, float surface_distance) {
	vec3 metric = vec3(1.0,0.90,1.0);
	vec3 v = rd*metric;
	float a = dot(v,v);
	float opacity = 0.0;
	for (int i=0;i<7;i++) {
		if (billow_opacity[i]<0.01) { continue; }
		vec3 q = (origin-billow[i].xyz)*metric;
		float radius = billow[i].w+smoke_spread*0.22;
		float b = dot(q,v);
		float c = dot(q,q)-radius*radius;
		float discriminant = b*b-a*c;
		if (discriminant<0.0) { continue; }
		float root = sqrt(discriminant);
		float first = (-b-root)/a;
		float last = (-b+root)/a;
		float chord = max(last-max(first,surface_distance),0.0);
		opacity = max(opacity,billow_opacity[i]*clamp(chord/(2.0*radius),0.0,1.0));
	}
	return opacity;
}
void vertex() {
	float t = fire_clock(TIME);
	cloud_lower = vec3(1000.0);
	cloud_upper = vec3(-1000.0);
	for (int i=0;i<7;i++) {
		float index = float(i);
		float age = fract(t*0.135+index/7.0);
		float phase = index*2.399963+fire_phase;
		vec3 center = smoke_center(age,t);
		center.xz += vec2(cos(phase+age*2.0),sin(phase+age*2.0))*smoke_spread*0.30*smoke_turbulence;
		float radius = smoke_spread*(0.16+0.58*pow(age,0.60));
		radius *= 1.0+sin(phase+age*7.0)*0.16*smoke_turbulence;
		billow[i] = vec4(center,radius);
		billow_opacity[i] = smoothstep(0.0,0.12,age)*(1.0-smoothstep(0.58,0.96,age));
		if (billow_opacity[i]>=0.01) {
			vec3 reach = vec3(radius,radius/0.90,radius)+vec3(smoke_spread*0.22+0.01);
			cloud_lower = min(cloud_lower,center-reach);
			cloud_upper = max(cloud_upper,center+reach);
		}
	}
	VERTEX = mix(cloud_lower,cloud_upper,VERTEX+vec3(0.5));
	proxy_position = VERTEX;
}
void fragment() {
	if (smoke_amount<=0.0 || intensity<=0.0 || recall_visibility<=0.001) { discard; }
	mat4 model_view = VIEW_MATRIX*MODEL_MATRIX;
	vec3 view_ray = PROJECTION_MATRIX[3][3]>0.5 ? vec3(0.0,0.0,-1.0) : -VIEW;
	vec3 rd = normalize((inverse(model_view)*vec4(view_ray,0.0)).xyz);
	vec3 origin = proxy_position-rd*(length(cloud_upper-cloud_lower)+1.0);
	vec3 inverse_ray = 1.0/(rd+vec3(0.000001));
	vec3 first = (cloud_lower-origin)*inverse_ray;
	vec3 last = (cloud_upper-origin)*inverse_ray;
	vec3 near_plane = min(first,last);
	vec3 far_plane = max(first,last);
	float distance = max(max(near_plane.x,near_plane.y),near_plane.z);
	float end = min(min(far_plane.x,far_plane.y),far_plane.z);
	if (distance>end) { discard; }
	vec3 hit = origin+rd*distance;
	bool found = false;
	for (int step=0;step<64;step++) {
		hit = origin+rd*distance;
		float d = cloud_distance(hit);
		if (d<0.0035) { found = true; break; }
		distance += max(d,0.0025);
		if (distance>end) { break; }
	}
	if (!found) { discard; }
	// One fused surface avoids visible overlaps between translucent puffs.
	vec2 e = vec2(1.0,-1.0)*0.004;
	vec3 gradient = e.xyy*cloud_distance(hit+e.xyy)
		+e.yyx*cloud_distance(hit+e.yyx)
		+e.yxy*cloud_distance(hit+e.yxy)
		+e.xxx*cloud_distance(hit+e.xxx);
	vec3 n = dot(gradient,gradient)>0.0000000001 ? normalize(gradient) : -rd;
	if (dot(n,-rd)<0.0) { n = -n; }
	vec3 view_n = normalize((transpose(inverse(model_view))*vec4(n,0.0)).xyz);
	float face = abs(dot(n,-rd));
	float shade = dot(view_n,normalize(vec3(-0.45,0.70,0.55)))*0.5+0.5;
	float t = fire_clock(TIME);
	float pigment = fire_noise(hit*vec3(2.5,2.8,2.5)-vec3(0.0,t*0.45,0.0));
	vec3 color = smoke_paint(shade,pigment);
	float h = clamp((hit.y-smoke_base_height())/smoke_height,0.0,1.0);
	float warmth = (1.0-smoothstep(0.0,0.22,h))*0.16;
	color = mix(color,mix(edge_color.rgb,flame_color.rgb,0.25),warmth);
	// A strong toon edge keeps density at concave billow joins. Fully fading
	// every grazing normal also cut dark lines through the middle of the cloud.
	float edge = mix(smoothstep(0.0,0.48,face),mix(0.85,1.0,smoothstep(0.0,0.12,face)),smoke_definition);
	ALBEDO = color;
	EMISSION = flame_color.rgb*warmth*glow_strength*0.05;
	float density = 1.0-exp(-cloud_opacity(origin,rd,distance)*smoke_amount*2.4);
	density *= smoothstep(0.0,0.18,h);
	ALPHA = edge*density*intensity*recall_visibility;
	if (ALPHA<0.001) { discard; }
	vec4 clip = PROJECTION_MATRIX*model_view*vec4(hit,1.0);
	float depth = clip.z/clip.w;
	DEPTH = CLIP_SPACE_FAR<0.0 ? depth*0.5+0.5 : depth;
}
