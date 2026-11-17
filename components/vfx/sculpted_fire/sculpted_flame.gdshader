shader_type spatial;
render_mode unshaded, cull_front, fog_disabled;
#include "res://components/vfx/sculpted_fire/fire_common.gdshaderinc"
varying vec3 proxy_position;
// Draw-constant animation state is prepared on the proxy vertices, rather than
// recomputing trigonometry for every field sample.
uniform sampler3D flow_noise : filter_linear, repeat_enable;
varying flat vec3 core_motion;
varying flat vec4 body_volume;
varying flat vec3 flow_offset;

float soft_union(float a, float b, float radius) {
	float h = clamp(0.5 + 0.5 * (b - a) / radius, 0.0, 1.0);
	return mix(b, a, h) - radius * h * (1.0 - h);
}
float ellipsoid(vec3 p, vec3 radii) {
	float k0 = length(p / radii);
	float k1 = length(p / (radii * radii));
	if (k0 < 0.0001) { return -min(radii.x, min(radii.y, radii.z)); }
	return k0 * (k0 - 1.0) / max(k1, 0.0001);
}
vec4 sample_flow(vec3 p) {
	return textureLod(flow_noise,p*vec3(1.10,0.52,1.10)+flow_offset,0.0);
}
float fire_shape(vec3 p) {
	vec3 q = p;
	q.xz -= wind*q.y*q.y*0.32;
	float height = clamp(q.y/1.18,0.0,1.3);
	vec4 flow = sample_flow(q);
	vec3 curl = clamp((flow.rgb-vec3(0.5))*2.0,vec3(-0.75),vec3(0.75));
	q.xz -= curl.xz*(0.06+curl_amount*0.26)*height*(0.35+height);
	q.y -= curl.y*curl_amount*0.30*height*height;
	float h = clamp(q.y/1.18,0.0,1.0);
	q.xz -= core_motion.yz*h*h;
	float radius = (0.27+body_fullness*0.055)*pow(1.0-h,1.25)*(1.0+0.90*h);
	// Let the low rounded root form the foot instead of a flat cylindrical rim.
	radius *= mix(0.30,1.0,smoothstep(-0.02,0.20,q.y));
	float outer_height = clamp(p.y/1.42,0.0,1.0);
	radius = min(radius,0.40*pow(1.0-outer_height,1.10));
	float plume = max(length(q.xz)-radius,max(-q.y,q.y-1.18));
	plume += max(0.52-flow.a,-0.14)*radius*(1.60+curl_amount*0.80)*smoothstep(0.16,0.85,q.y);
	vec3 root = p;
	root.xz -= curl.xz*0.055*smoothstep(0.0,0.45,p.y);
	float body = ellipsoid(root-vec3(core_motion.y*0.15,body_volume.w,core_motion.z*0.15),body_volume.xyz);
	return max(max(soft_union(body,plume,0.07),-p.y-0.018),p.y-1.42);
}
float field(vec3 p) {
	vec3 growth = vec3(sqrt(max(intensity, 0.001)), mix(0.55, 1.0, intensity), sqrt(max(intensity, 0.001)));
	growth *= max(recall_visibility, 0.001);
	return fire_shape(p / growth) * min(growth.x, growth.y);
}
void vertex() {
	float t = fire_clock(TIME);
	core_motion = vec3(1.0+sin(t*5.3)*0.04,sin(t*4.7)*0.13,cos(t*3.9)*0.10);
	vec3 radii = mix(vec3(0.24,0.16,0.23),vec3(0.40,0.26,0.37),body_fullness);
	radii *= vec3(1.0+sin(t*5.7)*0.04,1.0+sin(t*6.3+1.2)*0.035,1.0+cos(t*4.9)*0.04);
	body_volume = vec4(radii,radii.y-0.015);
	flow_offset = vec3(t*0.035,-t*0.43,t*0.018)+fire_phase*vec3(0.137,0.079,0.193);
	VERTEX.y += 0.82;
	proxy_position = VERTEX;
	VERTEX *= vec3(fire_size.x, fire_size.y, fire_size.x);
}
void fragment() {
	if (intensity <= 0.0 || recall_visibility <= 0.001) { discard; }
	vec3 units = vec3(fire_size.x, fire_size.y, fire_size.x);
	mat4 model_view = VIEW_MATRIX * MODEL_MATRIX;
	// VIEW remains a fragment-to-camera vector for orthographic cameras too.
	// Their tracing rays must be parallel, or the proxy distorts the volume.
	vec3 view_ray = PROJECTION_MATRIX[3][3] > 0.5 ? vec3(0.0,0.0,-1.0) : -VIEW;
	vec3 rd = normalize((inverse(model_view) * vec4(view_ray, 0.0)).xyz / units);
	// Render the proxy's back faces, then begin at its analytically found front.
	// This also works with an orthographic camera or a camera inside the proxy.
	vec3 origin = proxy_position - rd * 6.0;
	vec3 inv_direction = 1.0 / (rd + vec3(0.000001));
	vec2 reach = vec2(0.88) + abs(wind) * 0.65;
	vec3 lower = (vec3(-reach.x, -0.08, -reach.y) - origin) * inv_direction;
	vec3 upper = (vec3(reach.x, 1.55, reach.y) - origin) * inv_direction;
	vec3 near_plane = min(lower, upper);
	vec3 far_plane = max(lower, upper);
	float distance = max(max(near_plane.x, near_plane.y), near_plane.z);
	float end = min(min(far_plane.x, far_plane.y), far_plane.z);
	if (distance > end) { discard; }
	float t = fire_clock(TIME);
	vec3 hit = origin + rd * distance;
	bool found = false;
	float previous_distance = distance;
	for (int step = 0; step < 128; step++) {
		hit = origin + rd * distance;
		float d = field(hit);
		if (d < 0.0014) {
			found = true;
			if (d<0.0) {
				float first = previous_distance;
				float last = distance;
				for (int refine=0;refine<5;refine++) {
					float middle = (first+last)*0.5;
					if (field(origin+rd*middle)>0.0) { first = middle; } else { last = middle; }
				}
				hit = origin+rd*((first+last)*0.5);
			}
			break;
		}
		previous_distance = distance;
		distance += clamp(d*0.32,0.0025,0.12);
		if (distance > end) { break; }
	}
	if (!found) { discard; }
	// Projected hot layers follow the volume's thickness. This keeps one
	// coherent luminous heart instead of normal-lit blobs or a painted stripe.
	float growth = min(sqrt(max(intensity,0.001)),mix(0.55,1.0,intensity))*max(recall_visibility,0.001);
	float inside = min(field(hit+rd*0.10*growth),min(field(hit+rd*0.22*growth),field(hit+rd*0.34*growth)));
	float thickness = max(-inside/growth,0.0);
	vec3 color = mix(edge_color.rgb,flame_color.rgb,smoothstep(0.014,0.055,thickness));
	vec3 gold = mix(flame_color.rgb,core_color.rgb,0.72);
	color = mix(color,gold,smoothstep(0.105,0.15,thickness));
	color = mix(color,core_color.rgb,smoothstep(0.205,0.25,thickness));
	float pigment = fire_noise(hit*vec3(5.0,3.0,5.0)-vec3(0.0,t*3.0,0.0));
	ALBEDO = color * mix(0.985, 1.015, pigment);
	EMISSION = color * glow_strength * 0.18;
	vec4 clip = PROJECTION_MATRIX * model_view * vec4(hit * units, 1.0);
	float depth = clip.z / clip.w;
	DEPTH = CLIP_SPACE_FAR < 0.0 ? depth * 0.5 + 0.5 : depth;
}
