shader_type spatial;
render_mode unshaded, fog_disabled;
#include "res://components/effects/recall/shaders/assembled_recall.gdshaderinc"
varying vec3 ball_color;
varying float number;
varying float shade;
int mask_for(int digit) {
	if (digit == 0) return 63;
	if (digit == 1) return 6;
	if (digit == 2) return 91;
	if (digit == 3) return 79;
	if (digit == 4) return 102;
	if (digit == 5) return 109;
	if (digit == 6) return 125;
	if (digit == 7) return 7;
	if (digit == 8) return 127;
	return 111;
}
float stroke(vec2 p, vec2 at, vec2 size) {
	vec2 q = abs(p - at) - size;
	float d = max(q.x, q.y);
	float aa = max(fwidth(p.x), fwidth(p.y));
	return 1.0 - smoothstep(-aa, aa, d);
}
float digit_ink(vec2 p, int digit) {
	int mask = mask_for(digit);
	float ink = 0.0;
	if ((mask & 1) != 0) ink = max(ink, stroke(p, vec2(0, -0.64), vec2(0.32, 0.065)));
	if ((mask & 2) != 0) ink = max(ink, stroke(p, vec2(0.32, -0.32), vec2(0.065, 0.25)));
	if ((mask & 4) != 0) ink = max(ink, stroke(p, vec2(0.32, 0.32), vec2(0.065, 0.25)));
	if ((mask & 8) != 0) ink = max(ink, stroke(p, vec2(0, 0.64), vec2(0.32, 0.065)));
	if ((mask & 16) != 0) ink = max(ink, stroke(p, vec2(-0.32, 0.32), vec2(0.065, 0.25)));
	if ((mask & 32) != 0) ink = max(ink, stroke(p, vec2(-0.32, -0.32), vec2(0.065, 0.25)));
	if ((mask & 64) != 0) ink = max(ink, stroke(p, vec2(0, 0), vec2(0.32, 0.065)));
	return ink;
}
void vertex() {
	ball_color = INSTANCE_CUSTOM.rgb;
	number = round(INSTANCE_CUSTOM.a * 16.0);
	float light = dot(normalize(MODEL_NORMAL_MATRIX * NORMAL), normalize(vec3(-0.45, 0.82, 0.35))) * 0.5 + 0.5;
	shade = mix(0.73, 0.96, smoothstep(0.28, 0.40, light));
	shade = mix(shade, 1.045, smoothstep(0.72, 0.83, light));
	assembly_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}
void fragment() {
	vec3 ivory = vec3(0.89, 0.86, 0.76);
	vec3 color = ball_color;
	if (number >= 9.0) {
		float stripe = smoothstep(0.29, 0.31, UV.y) * (1.0 - smoothstep(0.69, 0.71, UV.y));
		color = mix(ivory, color, stripe);
	}
	if (number > 0.5) {
		vec2 p = vec2(fract(UV.x * 2.0) - 0.5, UV.y - 0.5) / 0.13;
		float patch = 1.0 - smoothstep(0.92, 1.03, length(p));
		color = mix(color, ivory, patch);
		if (patch > 0.1) {
			int id = int(number);
			float ink;
			if (id < 10) {
				ink = digit_ink(p * 1.05, id);
			} else {
				ink = max(digit_ink((p + vec2(0.37, 0)) * vec2(2.1, 1.2), 1), digit_ink((p - vec2(0.37, 0)) * vec2(2.1, 1.2), id - 10));
			}
			color = mix(color, vec3(0.045, 0.06, 0.06), ink * patch);
		}
	}
	ALBEDO = color * shade;
	float assembly = assembly_clarity(assembly_position);
	if (assembly <= 0.001) { discard; }
	ALBEDO = mix(vec3(0.94, 0.935, 0.89), ALBEDO, smoothstep(0.0, 1.0, assembly));
}
