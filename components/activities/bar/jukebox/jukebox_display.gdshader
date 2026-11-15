shader_type spatial;
render_mode unshaded, cull_disabled, fog_disabled;
#include "res://components/effects/recall/shaders/assembled_recall.gdshaderinc"
uniform vec4 accent_color : source_color = vec4(0.43, 0.78, 0.76, 1.0);
uniform float animation_speed = 1.0;
uniform float brightness = 1.0;
uniform float animation_time = -1.0;
float rounded_box(vec2 p, vec2 half_size, float radius) {
	vec2 q = abs(p) - half_size + radius;
	return 1.0 - smoothstep(-0.003, 0.003, length(max(q, vec2(0))) + min(max(q.x, q.y), 0.0) - radius);
}
vec3 pigment(float index) {
	float value = mod(index, 4.0);
	if (value < 1.0) return vec3(0.76, 0.38, 0.29);
	if (value < 2.0) return accent_color.rgb;
	if (value < 3.0) return vec3(0.47, 0.35, 0.64);
	return vec3(0.84, 0.64, 0.29);
}
void vertex() {
	assembly_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}
void fragment() {
	float t = (animation_time >= 0.0 ? animation_time : TIME) * animation_speed;
	vec3 ink = vec3(0.025, 0.046, 0.055);
	vec3 color = ink;
	// Six painterly abstract album tiles; no external artwork or video texture.
	vec2 grid = (UV - vec2(0.065, 0.055)) / vec2(0.435, 0.235);
	vec2 cell = floor(grid);
	vec2 local = fract(grid);
	float index = cell.x + cell.y * 2.0;
	if (UV.x > 0.065 && UV.x < 0.935 && UV.y > 0.055 && UV.y < 0.76) {
		float tile = rounded_box(local - vec2(0.50, 0.47), vec2(0.445, 0.41), 0.065);
		float field = sin(local.x * 7.0 + sin(local.y * 5.5 + index)) + cos(local.y * 6.0 - index);
		vec3 cover = mix(pigment(index), pigment(index + 1.0), smoothstep(-0.3, 0.4, field));
		float orbit = 1.0 - smoothstep(0.06, 0.11, abs(length(local - vec2(0.5)) - 0.25));
		cover = mix(cover, vec3(0.92, 0.87, 0.72), orbit * 0.33);
		float selected = 1.0 - step(0.1, abs(index - mod(floor(t * 0.45), 6.0)));
		color = mix(color, cover * (0.84 + selected * 0.16), tile);
		float border = tile * (1.0 - rounded_box(local - vec2(0.50, 0.47), vec2(0.425, 0.39), 0.055));
		color = mix(color, vec3(0.93, 0.90, 0.77), border * selected * 0.6);
	}
	if (UV.y > 0.80 && UV.y < 0.91 && UV.x > 0.12 && UV.x < 0.88) {
		float column = floor(UV.x * 13.0);
		float height = 0.025 + (0.5 + 0.5 * sin(t * 2.2 + column * 1.7)) * 0.065;
		float bar = (1.0 - smoothstep(0.24, 0.36, abs(fract(UV.x * 13.0) - 0.5))) * step(0.91 - height, UV.y);
		color = mix(color, accent_color.rgb * 0.9, bar);
	}
	float line = step(0.95, UV.y) * step(UV.y, 0.96) * step(0.10, UV.x) * step(UV.x, 0.90);
	color = mix(color, mix(vec3(0.22), accent_color.rgb, step(UV.x, 0.10 + fract(t * 0.04) * 0.8)), line);
	ALBEDO = color * brightness;
	EMISSION = color * brightness * 0.23;
	float assembly = assembly_clarity(assembly_position);
	if (assembly <= 0.001) { discard; }
	ALBEDO = mix(vec3(0.94, 0.935, 0.89), ALBEDO, smoothstep(0.0, 1.0, assembly));
	EMISSION *= assembly;
}
