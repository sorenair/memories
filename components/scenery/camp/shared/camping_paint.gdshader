shader_type spatial;
render_mode unshaded, cull_disabled, fog_disabled;
#include "res://components/effects/recall/shaders/assembled_recall.gdshaderinc"
uniform float pigment_strength = 0.55;
uniform float paint_phase = 0.0;
uniform float wind_strength = 0.0;
uniform float fabric_height = 1.2;
uniform vec2 fabric_size = vec2(2.4, 2.6);
uniform float burner_strength = 0.0;
uniform float light_strength = 0.0;
uniform float animation_time = -1.0;
varying vec3 pigment;
varying vec3 point;
varying float kind;
void vertex() {
	float t = animation_time >= 0.0 ? animation_time : TIME;
	kind = UV2.x;
	point = VERTEX;
	float cloth = step(1.5, kind) * (1.0 - step(2.5, kind));
	float theta = atan(VERTEX.z / fabric_size.y, VERTEX.x / fabric_size.x);
	float height = clamp((VERTEX.y - 0.08) / max(fabric_height, 0.1), 0.0, 1.0);
	float pinned = pow(cos(theta * 2.0), 2.0) * sin(height * 3.141593);
	VERTEX.z += cloth * pinned * wind_strength * (sin(t * 0.95 + VERTEX.x * 2.7) + 0.25 * sin(t * 1.4 + VERTEX.y * 4.0));
	float flame = step(2.5, kind) * (1.0 - step(3.5, kind));
	VERTEX.y += flame * burner_strength * 0.003 * sin(t * 12.0 + VERTEX.x * 41.0 + VERTEX.z * 33.0);
	vec3 n = normalize(MODEL_NORMAL_MATRIX * NORMAL);
	float light = dot(n, normalize(vec3(-0.45, 0.82, 0.35))) * 0.5 + 0.5;
	float shade = mix(0.73, 0.95, smoothstep(0.26, 0.43, light));
	shade = mix(shade, 1.035, smoothstep(0.72, 0.84, light));
	pigment = COLOR.rgb * shade;
	assembly_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}
void fragment() {
	float wash = sin(point.x * 2.1 + sin(point.y * 2.0 + paint_phase)) * sin(point.z * 2.4 + point.y * 0.8);
	vec3 color = pigment * mix(0.95, 1.04, mix(0.5, smoothstep(-0.35, 0.4, wash), pigment_strength));
	float glass = step(0.5, kind) * (1.0 - step(1.5, kind));
	float broad_glint = smoothstep(-0.1, 0.2, sin(point.y * 5.0 + point.z * 0.7));
	color = mix(color, color * mix(0.94, 1.08, broad_glint), glass);
	float flame = step(2.5, kind) * (1.0 - step(3.5, kind));
	if (flame > 0.5 && burner_strength <= 0.001) { discard; }
	float lamp = step(3.5, kind);
	// Keep vehicle lamps readable in Mobile, where emission alone is subtle.
	color = mix(color, min(vec3(1.0), COLOR.rgb * 1.15 + vec3(0.08)), lamp * clamp(light_strength, 0.0, 1.0));
	ALBEDO = mix(color, COLOR.rgb, flame * 0.8);
	EMISSION = COLOR.rgb * (flame * burner_strength * 0.65 + lamp * light_strength * 0.45);
	float a = assembly_clarity(assembly_position);
	if (a <= 0.001) { discard; }
	ALBEDO = mix(vec3(0.94, 0.935, 0.89), ALBEDO, smoothstep(0.0, 1.0, a));
	EMISSION *= a;
}
