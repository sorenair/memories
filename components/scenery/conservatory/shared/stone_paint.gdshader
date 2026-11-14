shader_type spatial;
render_mode unshaded, cull_disabled, fog_disabled;
#include "res://components/effects/recall/shaders/assembled_recall.gdshaderinc"
uniform float pigment_strength = 0.65;
uniform float paint_phase = 0.0;
varying vec3 paint;
varying vec3 local_position;
varying float material_kind;
varying float haze;
void vertex() {
	vec3 normal = normalize(MODEL_NORMAL_MATRIX * NORMAL);
	float light = dot(normal, normalize(vec3(-0.45, 0.82, 0.35))) * 0.5 + 0.5;
	float shade = mix(0.76, 0.96, smoothstep(0.28, 0.39, light));
	shade = mix(shade, 1.025, smoothstep(0.71, 0.81, light));
	paint = COLOR.rgb * shade;
	local_position = VERTEX;
	material_kind = UV2.x;
	assembly_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	haze = smoothstep(30.0, 70.0, length((VIEW_MATRIX * vec4(assembly_position, 1.0)).xyz));
}
void fragment() {
	vec3 p = local_position;
	float brush = sin(p.x * 2.4 + sin(p.z * 2.1 + paint_phase)) * sin(p.y * 3.2 + p.z * 1.4);
	vec3 color = paint * mix(0.95, 1.035, smoothstep(-0.55, 0.55, brush) * pigment_strength);
	if (abs(material_kind - 2.0) < 0.1) {
		// Quiet curved mineral washes; no gritty photographic marble texture.
		float vein = sin(p.x * 3.0 + p.y * 2.0 + sin(p.z * 2.2 + paint_phase) * 1.6);
		float band = 1.0 - smoothstep(0.025, 0.12, abs(vein));
		color *= 1.0 - band * 0.045 * pigment_strength;
	}
	ALBEDO = mix(color, vec3(0.87, 0.86, 0.77), haze);
	float assembly = assembly_clarity(assembly_position);
	if (assembly <= 0.001) { discard; }
	ALBEDO = mix(vec3(0.94, 0.935, 0.89), ALBEDO, smoothstep(0.0, 1.0, assembly));
}
