shader_type spatial;
render_mode unshaded, cull_disabled, fog_disabled;
#include "res://components/effects/recall/shaders/assembled_recall.gdshaderinc"
uniform vec4 root_color : source_color;
uniform vec4 shade_color : source_color;
uniform vec4 leaf_color : source_color;
uniform vec4 sun_color : source_color;
uniform float wind_strength = 0.055;
uniform float wind_speed = 0.7;
uniform float tree_phase = 0.0;
uniform float disturbance_strength = 0.16;
uniform float disturbance_radius = 1.0;
uniform vec4 disturbance_sources[2];
uniform float animation_time = -1.0;
varying vec3 paint;
varying vec3 paint_position;
varying float haze;
void vertex() {
	vec3 origin = MODEL_MATRIX[3].xyz;
	float t = animation_time >= 0.0 ? animation_time : TIME;
	float anchor = UV.y * UV.y;
	float phase = tree_phase + INSTANCE_CUSTOM.b * 6.283185;
	float wave = sin(t * wind_speed + origin.x * 0.65 + origin.z * 0.45 + tree_phase);
	vec3 motion = vec3(wave, sin(t * wind_speed * 1.3 + phase) * 0.16, cos(t * wind_speed * 0.7 + tree_phase) * 0.4) * wind_strength;
	vec3 disturbed = vec3(0.0);
	if (disturbance_strength > 0.0) {
		for (int i = 0; i < 2; i++) {
			vec2 away = origin.xz - disturbance_sources[i].xz;
			float influence = 1.0 - smoothstep(0.0, disturbance_radius, length(away));
			float gate = 1.0 - smoothstep(1.0, 2.1, abs(origin.y - disturbance_sources[i].y - 0.65));
			vec2 push = away / sqrt(dot(away, away) + 0.0225);
			disturbed += vec3(push.x, -0.20, push.y) * influence * gate * disturbance_sources[i].w;
		}
	}
	motion += disturbed / max(1.0, length(disturbed)) * disturbance_strength;
	vec3 x = MODEL_MATRIX[0].xyz;
	vec3 y = MODEL_MATRIX[1].xyz;
	vec3 z = MODEL_MATRIX[2].xyz;
	VERTEX += vec3(dot(motion, x) / dot(x, x), dot(motion, y) / dot(y, y), dot(motion, z) / dot(z, z)) * anchor;
	vec3 normal = normalize(MODEL_NORMAL_MATRIX * NORMAL);
	float light = abs(dot(normal, normalize(vec3(-0.45, 0.82, -0.35))));
	float tint = clamp(INSTANCE_CUSTOM.r + (light - 0.5) * 0.16 + (COLOR.r - 0.5) * 0.12, 0.0, 1.0);
	vec3 color = mix(root_color.rgb, shade_color.rgb, smoothstep(0.02, 0.28, tint));
	color = mix(color, leaf_color.rgb, smoothstep(0.25, 0.70, tint));
	color = mix(color, sun_color.rgb, smoothstep(0.65, 0.98, tint) * 0.48);
	paint = color * mix(0.96, 1.035, INSTANCE_CUSTOM.g);
	paint_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	haze = smoothstep(25.0, 65.0, length((VIEW_MATRIX * vec4(paint_position, 1.0)).xyz));
	assembly_position = paint_position;
}
void fragment() {
	float wash = sin(paint_position.x * 7.0 + sin(paint_position.y * 5.0)) * sin(paint_position.z * 8.0 + paint_position.y * 3.0);
	ALBEDO = mix(paint * (1.0 + wash * 0.025), vec3(0.87, 0.86, 0.77), haze);
	float assembly = assembly_clarity(assembly_position);
	if (assembly <= 0.001) { discard; }
	ALBEDO = mix(vec3(0.94, 0.935, 0.89), ALBEDO, smoothstep(0.0, 1.0, assembly));
}
