shader_type spatial;
render_mode unshaded, cull_disabled, fog_disabled;
#include "res://components/effects/recall/shaders/assembled_recall.gdshaderinc"

uniform float wind_strength : hint_range(0.0, 1.0) = 0.67;
uniform vec4 cloth_red : source_color = vec4(0.82, 0.16, 0.20, 1.0);
uniform vec4 star_gold : source_color = vec4(1.0, 0.79, 0.22, 1.0);
varying float fold_light;

void vertex() {
	float span = UV.x;
	float lift = pow(span, 1.35) * wind_strength;
	float phase = span * 10.0 - TIME * 2.7 + UV.y * 1.5;
	float curl = span * 19.0 - TIME * 4.0;
	VERTEX.z += lift * (sin(phase) * 0.53 + sin(curl) * span * 0.13);
	VERTEX.y += lift * (sin(phase - 0.8) * 0.18 - 0.24 * span);
	VERTEX.x -= lift * (1.0 + sin(phase) * 0.35) * 0.20;
	fold_light = 1.0 + lift * (cos(phase) * 0.15 + cos(curl) * 0.055);
	assembly_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	// Distance to a five-point star with one point straight up.
	vec2 p = (UV - vec2(0.5)) * vec2(1.5, -1.0);
	float step_angle = TAU / 10.0;
	float sector = mod(atan(p.x, p.y) + TAU, TAU) / step_angle;
	float radius_a = mix(0.30, 0.1146, mod(floor(sector), 2.0));
	float radius_b = 0.4146 - radius_a;
	float angle = fract(sector) * step_angle;
	float rim = radius_a * radius_b * sin(step_angle) /
		(radius_b * sin(step_angle - angle) + radius_a * sin(angle));
	float stroke = length(p) - rim;
	float gold = 1.0 - smoothstep(-fwidth(stroke), fwidth(stroke), stroke);
	float clarity = assembly_clarity(assembly_position);
	if (clarity <= 0.001) { discard; }
	ALBEDO = mix(vec3(0.94, 0.935, 0.89), mix(cloth_red.rgb, star_gold.rgb, gold) * fold_light,
		smoothstep(0.0, 1.0, clarity));
}
