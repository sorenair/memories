shader_type spatial;
render_mode unshaded,cull_disabled,fog_disabled;
#include "res://components/effects/recall/shaders/assembled_recall.gdshaderinc"
uniform float pigment_strength=0.55;
uniform float paint_phase=0.0;
uniform vec3 explorer_0=vec3(0,-1000,0);
uniform vec3 explorer_1=vec3(0,-1000,0);
varying vec3 pigment;
varying vec3 local_position;
varying float surface_kind;
void vertex(){
	vec3 world=(MODEL_MATRIX*vec4(VERTEX,1)).xyz;
	float weight=UV2.y*UV2.y;
	if(UV2.x>6.5){
		VERTEX.x+=sin(TIME*0.8+world.x*0.7+world.z*0.5)*0.06*weight;
		VERTEX.z+=cos(TIME*0.6+world.x*0.4)*0.035*weight;
		for(int i=0;i<2;i++){
			vec3 p=i==0?explorer_0:explorer_1;
			vec2 away=world.xz-p.xz;
			float influence=(1.0-smoothstep(0.0,0.85,length(away)))*(1.0-smoothstep(0.5,1.2,abs(world.y-p.y)));
			vec3 push=vec3(away.x,0,away.y)/sqrt(dot(away,away)+0.02)*influence*0.17*weight;
			VERTEX+=inverse(mat3(MODEL_MATRIX))*push;
		}
	}
	vec3 n=normalize(MODEL_NORMAL_MATRIX*NORMAL);
	float light=dot(n,normalize(vec3(-0.45,0.82,0.35)))*0.5+0.5;
	pigment=COLOR.rgb*mix(0.76,1.04,smoothstep(0.25,0.85,light));
	surface_kind=UV2.x;
	local_position=VERTEX;
	assembly_position=(MODEL_MATRIX*vec4(VERTEX,1)).xyz;
}
void fragment(){
	float wash=sin(local_position.x*1.3+sin(local_position.z*1.8+paint_phase));
	ALBEDO=pigment*mix(0.96,1.04,smoothstep(-0.3,0.5,wash)*pigment_strength);
	if (surface_kind > 4.5 && surface_kind < 5.5) {
		float ripple = sin(local_position.z * 8.5 + sin(local_position.x * 1.8) - TIME * 0.86);
		float reflection = smoothstep(0.62, 0.97, ripple) * smoothstep(0.05, 0.90, wash);
		ALBEDO = mix(ALBEDO, vec3(0.72, 0.81, 0.62), reflection * 0.26);
	}
	float a=assembly_clarity(assembly_position);
	if(a<=0.001){discard;}
	ALBEDO=mix(vec3(0.94,0.935,0.89),ALBEDO,smoothstep(0.0,1.0,a));
}
