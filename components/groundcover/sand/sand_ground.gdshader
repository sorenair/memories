shader_type spatial;
render_mode unshaded, cull_disabled, fog_disabled;
#include "res://components/effects/recall/shaders/assembled_recall.gdshaderinc"
uniform sampler2D coverage_mask : repeat_disable, filter_linear;
uniform sampler2D footprint_field : repeat_disable, filter_linear;
uniform vec2 field_texel = vec2(0.00390625);
uniform vec2 field_size = vec2(16.0, 12.0);
uniform float snow_time = 0.0;
uniform float footprint_linger = 16.0;
uniform float footprint_fade_duration = 6.0;
uniform float footprint_depth = 0.025;
uniform vec4 sand_color : source_color;
uniform vec4 shadow_color : source_color;
uniform vec4 edge_color : source_color;
uniform float ripple_strength = 0.38;
uniform float dune_direction = 0.0;
uniform float paint_phase = 0.0;
varying vec3 local_point;
varying vec3 base_normal;
varying vec3 axis_x;
varying vec3 axis_z;

float compression(vec2 uv) {
	vec2 stamp = textureLod(footprint_field, uv, 0.0).rg;
	float age = max(snow_time - stamp.g / max(stamp.r, 0.00001), 0.0);
	return stamp.r * (1.0 - smoothstep(footprint_linger, footprint_linger + footprint_fade_duration, age));
}
void vertex() {
	VERTEX.y = max(0.003, VERTEX.y - compression(UV) * footprint_depth);
	local_point = VERTEX;
	base_normal = normalize(MODEL_NORMAL_MATRIX * NORMAL);
	axis_x = normalize(MODEL_MATRIX[0].xyz);
	axis_z = normalize(MODEL_MATRIX[2].xyz);
	assembly_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}
void fragment() {
	float coverage = texture(coverage_mask, UV).r;
	if (coverage < 0.5) { discard; }
	float depth = compression(UV);
	float dx = (compression(UV + vec2(field_texel.x, 0)) - compression(UV - vec2(field_texel.x, 0))) * footprint_depth / (2.0 * field_texel.x * field_size.x);
	float dz = (compression(UV + vec2(0, field_texel.y)) - compression(UV - vec2(0, field_texel.y))) * footprint_depth / (2.0 * field_texel.y * field_size.y);
	vec3 n = normalize(base_normal + axis_x * dx + axis_z * dz);
	float light = dot(n, normalize(vec3(-0.45, 0.82, -0.35)));
	float wash = sin(local_point.x * 0.7 + sin(local_point.z * 0.5 + paint_phase)) * sin(local_point.z * 0.8 - local_point.x * 0.2);
	float shade = smoothstep(0.22, 0.46, light + wash * 0.035) * 0.58;
	shade += smoothstep(0.70, 0.86, light + wash * 0.025) * 0.42;
	vec3 color = mix(shadow_color.rgb, sand_color.rgb, 0.12 + shade * 0.88);
	color *= mix(0.97, 1.035, smoothstep(-0.4, 0.5, wash));
	// Low-contrast, broken wind ripples, filtered in screen space to avoid shimmer.
	vec2 wind = vec2(cos(dune_direction), sin(dune_direction));
	float phase = dot(local_point.xz, wind) * 28.0 + sin(local_point.z * 1.6 + paint_phase) * 1.4;
	float filtered = 1.0 - smoothstep(0.4, 2.5, fwidth(phase));
	float broken = smoothstep(-0.10, 0.55, wash);
	float lines = smoothstep(0.45, 0.92, sin(phase)) * broken * filtered;
	color *= 1.0 - lines * ripple_strength * 0.075;
	color = mix(color, shadow_color.rgb, depth * 0.26);
	float edge = max(smoothstep(0.0, 1.0, COLOR.r), 1.0 - smoothstep(0.5, 0.95, coverage));
	ALBEDO = mix(color, edge_color.rgb, edge);
	float clarity = assembly_clarity(assembly_position);
	if (clarity <= 0.001) { discard; }
	ALBEDO = mix(vec3(0.94, 0.935, 0.89), ALBEDO, smoothstep(0.0, 1.0, clarity));
}
