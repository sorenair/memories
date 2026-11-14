shader_type spatial;
render_mode unshaded, cull_disabled, fog_disabled;
#include "res://components/effects/recall/shaders/assembled_recall.gdshaderinc"
uniform vec4 root_color : source_color;
uniform vec4 shade_color : source_color;
uniform vec4 leaf_color : source_color;
uniform vec4 sun_color : source_color;
uniform vec4 bloom_a : source_color;
uniform vec4 bloom_b : source_color;
uniform vec4 center_color : source_color;
uniform float bloom_contrast = 0.45;
uniform float wind_strength = 0.025;
uniform float wind_speed = 0.8;
uniform vec4 explorer_0 = vec4(0.0);
uniform vec4 explorer_1 = vec4(0.0);
varying vec3 paint;
varying float haze;
vec3 disturbance(vec3 origin, vec4 explorer) {
	vec2 away = origin.xz - explorer.xz;
	float influence = (1.0 - smoothstep(0.0, 0.85, length(away))) * explorer.w;
	influence *= 1.0 - smoothstep(0.65, 1.5, abs(origin.y - explorer.y));
	return vec3(away.x, -0.1, away.y) / sqrt(dot(away, away) + 0.09) * influence * 0.16;
}
void vertex() {
	vec3 origin = MODEL_MATRIX[3].xyz;
	float phase = INSTANCE_CUSTOM.b * 6.28318;
	float anchored = UV.y * UV.y;
	float wave = sin(TIME * wind_speed + origin.x * 0.8 + origin.z * 0.6 + phase * 0.35);
	VERTEX.x += wave * wind_strength * anchored;
	VERTEX.z += cos(TIME * wind_speed * 0.7 + phase) * wind_strength * 0.4 * anchored;
	vec3 push = disturbance(origin, explorer_0) + disturbance(origin, explorer_1);
	VERTEX += vec3(dot(normalize(MODEL_MATRIX[0].xyz), push), dot(normalize(MODEL_MATRIX[1].xyz), push), dot(normalize(MODEL_MATRIX[2].xyz), push)) * anchored;
	float light = abs(dot(normalize(MODEL_NORMAL_MATRIX * NORMAL), normalize(vec3(-0.45, 0.82, -0.35))));
	if (COLOR.r < 0.75) {
		vec3 bloom = mix(bloom_a.rgb, bloom_b.rgb, smoothstep(0.2, 0.8, INSTANCE_CUSTOM.r));
		// Borrow meadow pigment rather than laying bright, separate objects over it.
		bloom = mix(mix(leaf_color.rgb, sun_color.rgb, 0.65), bloom, mix(0.35, 1.0, bloom_contrast));
		float brush = COLOR.g * 0.5 + light * 0.35 + INSTANCE_CUSTOM.g * 0.15;
		paint = mix(bloom * 0.84, bloom, smoothstep(0.25, 0.45, brush));
		paint = mix(paint, mix(bloom, vec3(1.0, 0.98, 0.92), 0.12), smoothstep(0.65, 0.8, brush));
	} else {
		paint = mix(center_color.rgb, mix(bloom_a.rgb, bloom_b.rgb, INSTANCE_CUSTOM.r), 0.45) * mix(0.87, 1.0, light);
	}
	haze = smoothstep(25.0, 60.0, length((VIEW_MATRIX * vec4(origin, 1.0)).xyz));
	assembly_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}
void fragment() {
	ALBEDO = mix(paint, vec3(0.87, 0.86, 0.77), haze);
	float assembly = assembly_clarity(assembly_position);
	if (assembly <= 0.001) { discard; }
	ALBEDO = mix(vec3(0.94, 0.935, 0.89), ALBEDO, smoothstep(0.0, 1.0, assembly));
}
