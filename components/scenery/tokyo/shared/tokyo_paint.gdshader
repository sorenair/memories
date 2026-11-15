shader_type spatial;
render_mode unshaded,cull_disabled,fog_disabled;
#include "res://components/effects/recall/shaders/assembled_recall.gdshaderinc"
uniform float pigment_strength=0.55;
uniform float paint_phase=0.0;
uniform float glow_strength=0.5;
varying vec3 pigment;
varying vec3 local_position;
varying float kind;
void vertex(){
	vec3 n=normalize(MODEL_NORMAL_MATRIX*NORMAL);
	float l=dot(n,normalize(vec3(-0.45,0.82,0.35)))*0.5+0.5;
	float shade=mix(0.72,0.95,smoothstep(0.28,0.42,l));
	shade=mix(shade,1.04,smoothstep(0.72,0.83,l));
	kind=UV2.x;
	pigment=COLOR.rgb*shade;
	local_position=VERTEX;
	assembly_position=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;
}
void fragment(){
	float wash=sin(local_position.x*2.7+sin(local_position.y*2.1+paint_phase))*sin(local_position.z*2.4+local_position.y*1.9);
	vec3 painted=pigment*mix(0.96,1.04,smoothstep(-0.3,0.4,wash)*pigment_strength);
	float lit=step(2.5,kind);
	painted=mix(painted,COLOR.rgb,lit*0.8);
	ALBEDO=painted;
	// Luminous windows, sign paint and lantern paper; no real-time light passes.
	EMISSION=COLOR.rgb*lit*glow_strength*(kind>3.5?0.6:0.28);
	float a=assembly_clarity(assembly_position);
	if(a<=0.001){discard;}
	ALBEDO=mix(vec3(0.94,0.935,0.89),ALBEDO,smoothstep(0.0,1.0,a));
	EMISSION*=a;
}
