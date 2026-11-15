shader_type spatial;
render_mode unshaded, cull_disabled, fog_disabled;
#include "res://components/effects/recall/shaders/assembled_recall.gdshaderinc"
uniform float banner_top = 3.55;
uniform float wind_strength = 0.045;
uniform float animation_time = -1.0;
varying vec3 pigment;
varying vec3 paint_position;
void vertex() {
	float t = animation_time >= 0.0 ? animation_time : TIME;
	float weight = 1.0-smoothstep(banner_top-1.7,banner_top,VERTEX.y);
	VERTEX.z += sin(t*0.95+VERTEX.y*2.4+VERTEX.x*0.7)*weight*wind_strength;
	vec3 n = normalize(MODEL_NORMAL_MATRIX*NORMAL);
	float light = dot(n,normalize(vec3(-0.45,0.82,0.35)))*0.5+0.5;
	pigment = COLOR.rgb*mix(0.78,1.03,smoothstep(0.3,0.8,light));
	paint_position=VERTEX;
	assembly_position=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;
}
void fragment() {
	float wash=sin(paint_position.x*4.2+sin(paint_position.y*3.2))*sin(paint_position.y*4.3);
	ALBEDO=pigment*mix(0.97,1.04,smoothstep(-0.2,0.5,wash));
	float assembly=assembly_clarity(assembly_position);
	if(assembly<=0.001){discard;}
	ALBEDO=mix(vec3(0.94,0.935,0.89),ALBEDO,smoothstep(0.0,1.0,assembly));
}
