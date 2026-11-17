shader_type spatial;
render_mode unshaded, fog_disabled;
#include "res://components/effects/recall/shaders/assembled_recall.gdshaderinc"
uniform vec4 base_color : source_color;
uniform vec4 shadow_color : source_color;
uniform vec4 mid_color : source_color;
uniform vec4 highlight_color : source_color;
uniform float plane_variation = 0.14;
varying vec3 painted_color;
varying vec3 local_position;
varying float haze;
void vertex() {
	local_position = VERTEX;
	vec3 normal = normalize(MODEL_NORMAL_MATRIX*NORMAL);
	float light = dot(normal,normalize(vec3(-0.45,0.82,-0.35)))*0.5+0.5;
	// Pigment pools follow the actual fracture planes, with no cloudy noise texture.
	light += (COLOR.r-0.5)*plane_variation*3.5;
	// Same palette and softened three-tone lighting as the approved boulders.
	vec3 color = mix(shadow_color.rgb,mid_color.rgb,smoothstep(0.38,0.45,light));
	color = mix(color,highlight_color.rgb,smoothstep(0.72,0.79,light));
	color *= 1.0+(COLOR.r-0.5)*plane_variation;
	painted_color = mix(base_color.rgb*0.88,color,mix(0.25,1.0,COLOR.g));
	assembly_position = (MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;
	haze = smoothstep(80.0,180.0,length((VIEW_MATRIX*vec4(assembly_position,1.0)).xyz));
}
void fragment() {
	float contact = 1.0-smoothstep(-0.05,0.3,local_position.y);
	vec3 color = mix(painted_color,base_color.rgb,contact*0.18);
	ALBEDO = mix(color,vec3(0.87,0.86,0.77),haze);
	float clarity = assembly_clarity(assembly_position);
	if (clarity<=0.001) { discard; }
	ALBEDO = mix(vec3(0.94,0.935,0.89),ALBEDO,smoothstep(0.0,1.0,clarity));
}
