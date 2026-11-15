shader_type spatial;
render_mode unshaded,fog_disabled;
#include "res://components/effects/recall/shaders/assembled_recall.gdshaderinc"
uniform float extent=24.0;
uniform float road_width=10.0;
uniform vec4 asphalt_color : source_color=vec4(0.23,0.31,0.35,1.0);
uniform float paint_phase=0.0;
varying vec2 ground;
void vertex(){
	ground=VERTEX.xz;
	assembly_position=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;
}
void fragment(){
	vec2 p=abs(ground);
	float road=1.0-smoothstep(road_width*0.5-0.08,road_width*0.5+0.08,min(p.x,p.y));
	float edge=1.0-smoothstep(extent*0.5-2.4,extent*0.5,max(p.x,p.y));
	float wash=sin(ground.x*0.43+sin(ground.y*0.31+paint_phase))*sin(ground.y*0.49);
	float clarity=road*edge;
	if(clarity<0.015){discard;}
	ALBEDO=mix(vec3(0.87,0.86,0.77),asphalt_color.rgb*(0.98+wash*0.035),clarity);
	float a=assembly_clarity(assembly_position);
	if(a<=0.001){discard;}
	ALBEDO=mix(vec3(0.94,0.935,0.89),ALBEDO,smoothstep(0.0,1.0,a));
}
