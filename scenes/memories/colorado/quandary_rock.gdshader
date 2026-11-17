shader_type spatial;
render_mode unshaded, cull_disabled, fog_disabled;
#include "res://components/effects/recall/shaders/assembled_recall.gdshaderinc"

uniform vec4 shadow_color : source_color;
uniform vec4 mid_color : source_color;
uniform vec4 highlight_color : source_color;
varying vec3 stone_tone;

void vertex() {
	vec3 normal = normalize(MODEL_NORMAL_MATRIX * NORMAL);
	float light = dot(normal, normalize(vec3(-0.45, 0.82, -0.35))) * 0.5 + 0.5;
	// Match the broad face tones on the neighboring painterly boulders.
	vec3 stone = mix(shadow_color.rgb, mid_color.rgb, smoothstep(0.38, 0.45, light));
	stone = mix(stone, highlight_color.rgb, smoothstep(0.72, 0.79, light));
	stone_tone = stone * mix(0.91, 1.04, COLOR.r);
	assembly_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	float clarity = assembly_clarity(assembly_position);
	if (clarity <= 0.001) { discard; }
	ALBEDO = mix(vec3(0.94, 0.935, 0.89), stone_tone, smoothstep(0.0, 1.0, clarity));
}
