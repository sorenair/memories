shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, fog_disabled;
#include "res://components/vfx/sculpted_fire/fire_common.gdshaderinc"
#include "res://components/vfx/sculpted_fire/smoke_flow.gdshaderinc"
varying float smoke_age;
varying float life;
varying float phase_mix;
varying vec2 dab_rotation;
void vertex() {
	float t = fire_clock(TIME);
	float age = fract(INSTANCE_CUSTOM.x+t*(0.12+INSTANCE_CUSTOM.y*0.035));
	float phase = INSTANCE_CUSTOM.z*6.283185;
	vec3 center = smoke_center(age,t);
	center.xz += vec2(cos(phase+age*3.0),sin(phase+age*3.0))*smoke_spread*(0.04+age*0.38)*smoke_turbulence;
	vec3 world = (MODEL_MATRIX*vec4(center,1.0)).xyz;
	float size = smoke_spread*mix(0.40,1.20,pow(age,0.65))*mix(0.85,1.15,INSTANCE_CUSTOM.w);
	float rotation = phase+t*0.10+age*0.65;
	dab_rotation = vec2(cos(rotation),sin(rotation));
	vec2 dab = mat2(vec2(cos(rotation),sin(rotation)),vec2(-sin(rotation),cos(rotation)))*VERTEX.xy;
	float scale = length(MODEL_MATRIX[0].xyz);
	world += (INV_VIEW_MATRIX[0].xyz*dab.x+INV_VIEW_MATRIX[1].xyz*dab.y*1.10)*size*scale;
	VERTEX = (inverse(MODEL_MATRIX)*vec4(world,1.0)).xyz;
	smoke_age = age;
	life = smoothstep(0.02,0.14,age)*(1.0-smoothstep(0.68,1.0,age));
	phase_mix = phase;
}
void fragment() {
	vec2 q = vec2(UV.x*2.0-1.0,1.0-UV.y*2.0)*1.20;
	float roll = smoke_age*3.0+phase_mix;
	vec2 offset = vec2(cos(roll),sin(roll))*0.18;
	vec2 c0 = (q+offset*0.40)/0.77;
	vec2 c1 = (q-offset-vec2(0.24,0.08))/0.59;
	vec2 c2 = (q+offset-vec2(-0.20,-0.18))/0.57;
	float d0 = length(c0);
	float d1 = length(c1);
	float d2 = length(c2);
	float d = min(d0,min(d1,d2));
	vec2 cell = d0<d1 && d0<d2 ? c0 : (d1<d2 ? c1 : c2);
	float brush = fire_noise(vec3(q*1.7,phase_mix+smoke_age*1.2));
	float feather = mix(0.30,0.09,smoke_definition);
	float edge = 1.0-smoothstep(1.0-feather,1.03,d+(brush-0.5)*0.035);
	edge *= 1.0-smoothstep(0.90,1.0,max(abs(UV.x*2.0-1.0),abs(UV.y*2.0-1.0)));
	vec2 normal_xy = cell*0.74;
	normal_xy = mat2(vec2(dab_rotation.x,dab_rotation.y),vec2(-dab_rotation.y,dab_rotation.x))*normal_xy;
	vec3 n = normalize(vec3(normal_xy,sqrt(max(0.05,1.0-dot(normal_xy,normal_xy)))));
	float shade = dot(n,normalize(vec3(-0.45,0.70,0.55)))*0.5+0.5;
	vec3 color = smoke_paint(shade,brush);
	float warmth = (1.0-smoothstep(0.0,0.28,smoke_age))*0.18;
	color = mix(color,edge_color.rgb,warmth);
	float erosion = mix(1.0,smoothstep(0.28,0.64,brush),smoothstep(0.62,0.98,smoke_age));
	ALBEDO = color;
	ALPHA = edge*erosion*life*smoke_amount*intensity*recall_visibility*0.14*smoothstep(0.40,0.70,smoke_age);
	if (ALPHA<0.001) { discard; }
}
