shader_type spatial;
render_mode unshaded, cull_front, fog_disabled;
#include "res://components/vfx/sculpted_fire/fire_common.gdshaderinc"
varying vec3 proxy_position;
// Draw-constant animation state is prepared on the proxy vertices, rather than
// recomputing trigonometry for every ray-march and normal sample.
varying flat vec4 tongue_stem[3];
varying flat vec4 tongue_arc[3];
varying flat vec4 tongue_axis[3];
varying flat vec2 tongue_tip[3];
varying flat vec3 core_motion;
varying flat vec4 body_volume;
varying flat vec4 body_shoulder;

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
float stroke_angle(vec2 p) {
	vec2 a = abs(p);
	float r = min(a.x,a.y)/max(max(a.x,a.y),0.0000001);
	float r2 = r*r;
	float angle = (((-0.0464964749*r2+0.15931422)*r2-0.327622764)*r2)*r+r;
	if (a.y>a.x) { angle = 1.570796327-angle; }
	if (p.x<0.0) { angle = 3.141592654-angle; }
	return p.y<0.0 ? -angle : angle;
}
float flame_stroke(vec3 p, int index) {
	vec4 stem = tongue_stem[index];
	vec4 arc = tongue_arc[index];
	vec4 axis = tongue_axis[index];
	vec3 q = vec3(dot(p.xz,axis.xy),p.y,dot(p.xz,vec2(-axis.y,axis.x))/0.72);
	float h = clamp(q.y/stem.y,0.0,1.0);
	float center_x = stem.x*h+axis.z*h*(1.0-h);
	float stem_distance = length(vec2(q.x-center_x,q.z))-mix(stem.w,stem.z,h);
	stem_distance = max(stem_distance,max(-q.y,q.y-stem.y));
	vec2 delta = q.xy-arc.xy;
	delta.y /= 1.25;
	float angle = stroke_angle(delta)+0.65;
	if (angle<0.0) { angle += 6.283185; }
	float arc_distance;
	if (angle>arc.w) {
		vec3 root_delta = q-vec3(stem.xy,0.0);
		vec3 tip_delta = q-vec3(tongue_tip[index],0.0);
		root_delta.y /= 1.25;
		tip_delta.y /= 1.25;
		float root = length(root_delta)-stem.z;
		float tip = length(tip_delta)-0.0008;
		arc_distance = min(root,tip);
	} else {
		float along = angle/arc.w;
		float width = stem.z*(1.0-along)*(1.0+0.20*along)+0.0008;
		arc_distance = length(vec2(length(delta)-arc.z,q.z))-width;
	}
	return soft_union(stem_distance,arc_distance,0.035)*axis.w;
}
float fire_shape(vec3 p) {
	vec3 q = p;
	q.xz -= wind * q.y * q.y * 0.32;
	// Fullness lives below the shoulders. The moving strokes, rather than a
	// tall sphere, supply most of the visible silhouette and its negative spaces.
	float body = ellipsoid(q - vec3(core_motion.y * 0.25, body_volume.w, core_motion.z * 0.25), body_volume.xyz);
	float shoulder = ellipsoid(q - body_shoulder.xyz, max(body_shoulder.w * vec3(1.0, 1.2, 0.95), vec3(0.001)));
	body = soft_union(body, shoulder, 0.075 * body_fullness + 0.005);
	float stem_height = 0.82 * core_motion.x;
	float h = clamp(q.y / stem_height, 0.0, 1.0);
	vec2 spine = core_motion.yz * h*h*(3.0-2.0*h);
	float stem = length(q.xz - spine) - 0.32*(1.0-h)*(0.85+0.90*h);
	stem = max(stem, max(-q.y, q.y-stem_height));
	body = soft_union(body, stem * 0.70, 0.045);
	for (int i = 0; i < 3; i++) {
		body = soft_union(body, flame_stroke(q, i), 0.045);
	}
	return max(body, -p.y - 0.018);
}
float field(vec3 p) {
	vec3 growth = vec3(sqrt(max(intensity, 0.001)), mix(0.55, 1.0, intensity), sqrt(max(intensity, 0.001)));
	growth *= max(recall_visibility, 0.001);
	return fire_shape(p / growth) * min(growth.x, growth.y) * (0.95 / (1.0 + length(wind)));
}
void vertex() {
	float t = fire_clock(TIME);
	core_motion = vec3(1.0 + sin(t * 5.3) * 0.055 + sin(t * 11.7) * 0.028, sin(t * 6.1) * 0.12, cos(t * 5.3) * 0.10);
	vec3 radii = mix(vec3(0.24, 0.16, 0.23), vec3(0.43, 0.28, 0.39), body_fullness);
	radii *= vec3(1.0 + sin(t * 5.7) * 0.045, 1.0 + sin(t * 6.3 + 1.2) * 0.035, 1.0 + cos(t * 4.9) * 0.045);
	body_volume = vec4(radii, radii.y - 0.015);
	body_shoulder = vec4(cos(t * 4.3) * 0.16, 0.36 + sin(t * 5.4) * 0.10, sin(t * 3.9) * 0.16, 0.20 * body_fullness);
	for (int i = 0; i < 3; i++) {
		float fi = float(i);
		vec4 stem,arc;
		vec2 tip;
		float bend;
		tongue_profile(t,fi,stem,arc,tip,bend);
		float direction = -0.62+fi*2.399963;
		tongue_stem[i] = stem;
		tongue_arc[i] = arc;
		float arc_slope = 1.20 * stem.z / max(arc.z * arc.w,0.001);
		float stem_slope = (abs(bend)+abs(stem.w-stem.z)) / stem.y;
		float slope = max(arc_slope,stem_slope);
		float distance_scale = inversesqrt(1.0/(0.72*0.72)+slope*slope);
		tongue_axis[i] = vec4(cos(direction),sin(direction),bend,distance_scale);
		tongue_tip[i] = tip;
	}
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
	vec2 reach = vec2(0.73) + abs(wind) * 0.55;
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
	for (int step = 0; step < 128; step++) {
		hit = origin + rd * distance;
		float d = field(hit);
		if (d < 0.0014) { found = true; break; }
		distance += max(d, 0.0012);
		if (distance > end) { break; }
	}
	if (!found) { discard; }
	float e = 0.003;
	vec3 normal = normalize(vec3(
		field(hit + vec3(e,0,0)) - field(hit - vec3(e,0,0)),
		field(hit + vec3(0,e,0)) - field(hit - vec3(0,e,0)),
		field(hit + vec3(0,0,e)) - field(hit - vec3(0,0,e))));
	float face = max(dot(normal, -rd), 0.0);
	// Elongated advected strokes keep the colors flowing upward. Avoid the
	// isolated round red/orange patches that made the last body read as lava.
	vec3 paint_position = hit * vec3(5.0, 2.3, 5.0) - vec3(0.0,t*3.0,0.0);
	paint_position.xz += sin(vec2(hit.y*7.0-t*6.0,hit.y*6.0-t*5.0))*0.45;
	float pigment = fire_noise(paint_position);
	float flow = sin(hit.y*7.0-t*7.0+sin(hit.x*4.0+hit.z*3.0)*1.2);
	float heat = pow(face,0.75)*0.35+0.06+(1.0-clamp(hit.y,0.0,1.0))*0.20+(pigment-0.5)*0.16+flow*0.065;
	vec3 color = mix(edge_color.rgb,flame_color.rgb,smoothstep(0.37,0.45,heat));
	vec2 across_view = normalize(vec2(rd.z,-rd.x));
	float side = dot(hit.xz-wind*hit.y*hit.y*0.32,across_view);
	float wave = sin(hit.y*7.0-t*6.0)*0.065+sin(hit.y*12.0-t*8.0)*0.025;
	float heart_width = mix(0.18,0.27,body_fullness)-hit.y*0.20;
	float heart_shape = abs(side-wave)/max(0.035,heart_width)+hit.y*0.90;
	float fork = abs(side+0.10+sin(hit.y*8.0-t*6.0)*0.09)/max(0.02,0.12-hit.y*0.13)+hit.y*1.6;
	heart_shape = min(heart_shape,fork+0.18);
	float heart = (1.0-smoothstep(0.70,1.05,heart_shape))*(1.0-smoothstep(0.35,0.82,hit.y))*mix(0.85,1.0,smoothstep(0.10,0.65,face));
	vec3 gold = mix(flame_color.rgb,core_color.rgb,0.72);
	color = mix(color,gold,heart);
	float white_heat = pow(heart,3.0)*(1.0-smoothstep(0.25,0.60,hit.y));
	color = mix(color,core_color.rgb,white_heat*0.85);
	ALBEDO = color * mix(0.985, 1.015, pigment);
	EMISSION = color * glow_strength * 0.18;
	vec4 clip = PROJECTION_MATRIX * model_view * vec4(hit * units, 1.0);
	float depth = clip.z / clip.w;
	DEPTH = CLIP_SPACE_FAR < 0.0 ? depth * 0.5 + 0.5 : depth;
}
