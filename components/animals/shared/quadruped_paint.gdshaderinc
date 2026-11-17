// Shared smooth painted coat, planted-foot idles and assembled recall.
#include "res://components/effects/recall/shaders/assembled_recall.gdshaderinc"
uniform float pigment_strength = 0.55;
uniform float paint_phase = 0.0;
uniform float idle_motion = 0.7;
uniform float idle_speed = 1.0;
uniform int pose_mode = 0;
uniform float animation_time = -1.0;
uniform bool use_instance_custom = false;
// Species-specific rest anatomy; defaults preserve the elk's existing poses.
uniform vec3 neck_pivot = vec3(0.0,1.20,0.48);
uniform vec2 neck_blend = vec2(1.20,1.92);
uniform vec3 ear_pivot = vec3(0.13,2.075,1.035);
uniform vec3 tail_pivot = vec3(0.0,1.29,-0.97);
uniform vec2 breath_height = vec2(0.7,1.4);
uniform float grazing_angle = 1.57;
uniform float alert_angle = -0.10;
varying vec3 paint;
varying vec3 paint_position;
varying float haze;
vec3 turn_x(vec3 p, float a) { return vec3(p.x,p.y*cos(a)-p.z*sin(a),p.y*sin(a)+p.z*cos(a)); }
vec3 turn_y(vec3 p, float a) { return vec3(p.x*cos(a)+p.z*sin(a),p.y,-p.x*sin(a)+p.z*cos(a)); }
void vertex() {
	vec3 morph = vec3(UV.x,UV.y,UV2.y);
	vec3 p = VERTEX / morph;
	vec3 n = normalize(NORMAL * morph);
	float part = UV2.x;
	float phase = use_instance_custom ? INSTANCE_CUSTOM.x*6.283185 : paint_phase;
	float pose = use_instance_custom ? round(INSTANCE_CUSTOM.y*2.0) : float(pose_mode);
	float motion = idle_motion * (use_instance_custom ? INSTANCE_CUSTOM.w : 1.0);
	float t = (animation_time >= 0.0 ? animation_time : TIME) * idle_speed;
	paint_position = p;
	float breath = sin(t*1.8+phase)*0.005*motion;
	if (part < 0.5) {
		p.x *= 1.0+breath*smoothstep(breath_height.x-0.05,breath_height.y-0.2,p.y);
		p.y += breath*smoothstep(breath_height.x,breath_height.y,p.y);
	} else if (part < 4.5) {
		if (part > 2.5) {
			float side = part < 3.5 ? -1.0 : 1.0;
			vec3 ear = ear_pivot*vec3(side,1.0,1.0);
			float twitch = pow(max(0.0,sin(t*0.71+phase+side*1.9)),14.0)*0.18*motion;
			p = ear+turn_y(p-ear,side*twitch);
			n = turn_y(n,side*twitch);
		}
		float weight = part < 1.5 ? smoothstep(neck_blend.x,neck_blend.y,p.y) : 1.0;
		float graze = step(1.5,pose);
		float alert = step(0.5,pose)*(1.0-graze);
		float nod = graze*grazing_angle+alert*alert_angle + sin(t*0.67+phase)*0.025*motion;
		float yaw = sin(t*0.29+phase)*mix(0.085,0.045,graze)*motion;
		yaw = yaw*(1.0+alert*0.4)+alert*sin(phase)*0.10;
		vec3 pivot = neck_pivot;
		p = pivot+turn_y(turn_x(p-pivot,nod*weight),yaw*weight);
		n = turn_y(turn_x(n,nod*weight),yaw*weight);
		p.y += breath;
	} else {
		float flick = pow(max(0.0,sin(t*0.54+phase+2.0)),10.0)*0.30*motion;
		p = tail_pivot+turn_y(p-tail_pivot,flick);
		n = turn_y(n,flick);
	}
	VERTEX = p*morph;
	NORMAL = normalize(n/morph);
	float light = dot(normalize(MODEL_NORMAL_MATRIX*NORMAL),normalize(vec3(-0.45,0.82,0.35)))*0.5+0.5;
	float shade = mix(0.73,0.94,smoothstep(0.27,0.41,light));
	shade = mix(shade,1.06,smoothstep(0.70,0.83,light));
	paint = COLOR.rgb*shade*(use_instance_custom ? mix(0.94,1.06,INSTANCE_CUSTOM.z) : 1.0);
	assembly_position = (MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;
	haze = smoothstep(35.0,80.0,length((VIEW_MATRIX*vec4(assembly_position,1.0)).xyz));
}
void fragment() {
	vec3 p = paint_position;
	float wash = sin(p.x*4.3+sin(p.y*3.1+paint_phase)+p.z*2.2)*sin(p.y*5.0+p.z*3.2);
	float pigment = smoothstep(-0.45,-0.1,wash)*0.5+smoothstep(0.25,0.70,wash)*0.5;
	vec3 color = paint*mix(0.95,1.05,mix(0.5,pigment,pigment_strength));
	ALBEDO = mix(color,vec3(0.87,0.86,0.77),haze);
	float clarity = assembly_clarity(assembly_position);
	if (clarity <= 0.001) { discard; }
	ALBEDO = mix(vec3(0.94,0.935,0.89),ALBEDO,smoothstep(0.0,1.0,clarity));
}
