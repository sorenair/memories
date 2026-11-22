shader_type spatial;
render_mode unshaded, cull_disabled, fog_disabled;
#include "res://components/effects/recall/shaders/assembled_recall.gdshaderinc"
uniform vec2 footprint = vec2(11,9);
uniform vec2 rock_centers[3];
uniform float rake_spacing = .24;
uniform float rake_strength = .65;
uniform float pigment_strength = .55;
uniform float paint_phase = 0.0;
uniform vec4 edge_color : source_color = vec4(0.973,0.971,0.950,1.0);
uniform float rim_variation = 0.04;
varying vec3 point;
varying vec3 pigment;
void vertex() {
	point = VERTEX;
	pigment = COLOR.rgb;
	assembly_position = (MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;
}
void fragment() {
	float distance_to_rock = 1000.0;
	for(int i=0;i<3;i++) { distance_to_rock = min(distance_to_rock,length(point.xz-rock_centers[i])); }
	float phase = distance_to_rock*6.283185/max(rake_spacing,.01);
	float filter_width = fwidth(phase);
	float groove = (.5+.5*cos(phase))*(1.0-smoothstep(.5,3.0,filter_width));
	float wash = sin(point.x*.7+sin(point.z*.9+paint_phase))*sin(point.z*.8);
	vec3 color = pigment*(.97+.025*wash*pigment_strength)*(1.0-groove*rake_strength*.16);
	vec2 scaled = point.xz / (footprint * 0.5);
	float angle = atan(scaled.y, scaled.x);
	float rim = 1.0 + rim_variation * (0.625 * sin(angle * 5.0 + paint_phase) + 0.375 * sin(angle * 9.0 - paint_phase));
	float edge = smoothstep(.79,1.0,length(scaled)/rim);
	ALBEDO = mix(color,edge_color.rgb,edge);
	float clarity = assembly_clarity(assembly_position);
	if(clarity<=.001) { discard; }
	ALBEDO = mix(vec3(.94,.935,.89),ALBEDO,smoothstep(0.0,1.0,clarity));
}
