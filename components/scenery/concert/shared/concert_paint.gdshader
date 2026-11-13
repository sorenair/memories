shader_type spatial;
render_mode unshaded, cull_disabled, fog_disabled;
// Same broad pigment pools and softened toon bands as the arcade props.
#include "res://components/effects/recall/shaders/assembled_recall.gdshaderinc"
uniform float pigment_strength = 0.55;
uniform float paint_phase = 0.0;
uniform float beat_bpm = 0.0;
uniform float beat_phase = 0.0;
uniform float pulse_amount = 0.16;
uniform float cone_motion = 0.008;
uniform float light_intensity = 1.0;
uniform float animation_time = -1.0;
varying vec3 paint;
varying vec3 paint_position;
varying float material_kind;
varying float haze;
varying float beat;
void vertex() {
	float t = animation_time >= 0.0 ? animation_time : TIME;
	float wave = sin(t * beat_bpm / 60.0 * 6.283185 + beat_phase);
	beat = beat_bpm > 0.0 ? 0.5 + wave * 0.5 : 0.5;
	material_kind = UV2.x;
	if (material_kind > 2.5) {
		// A very small movement in the cabinet's local +Z; all cones share one batch.
		VERTEX.z += (beat - 0.5) * cone_motion;
	}
	vec3 normal = normalize(MODEL_NORMAL_MATRIX * NORMAL);
	float light = dot(normal, normalize(vec3(-0.45, 0.82, 0.35))) * 0.5 + 0.5;
	float shade = mix(0.74, 0.95, smoothstep(0.28, 0.39, light));
	shade = mix(shade, 1.03, smoothstep(0.71, 0.81, light));
	paint = COLOR.rgb * shade;
	paint_position = VERTEX;
	vec3 world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	haze = smoothstep(32.0, 75.0, length((VIEW_MATRIX * vec4(world, 1.0)).xyz));
	assembly_position = world;
}
void fragment() {
	vec3 p = paint_position;
	float wash = sin(p.x * 4.1 + sin(p.y * 3.6 + paint_phase) + p.z * 1.2)
		* sin(p.y * 4.4 + sin(p.z * 3.0 + paint_phase));
	float band = smoothstep(-0.45, -0.15, wash) * 0.5 + smoothstep(0.2, 0.65, wash) * 0.5;
	vec3 color = paint * mix(0.94, 1.045, band * pigment_strength + (1.0 - pigment_strength) * 0.5);
	float lens = step(1.5, material_kind) * (1.0 - step(2.5, material_kind));
	float pulse = light_intensity * (1.0 - pulse_amount + pulse_amount * beat);
	color = mix(color, COLOR.rgb * (0.86 + pulse * 0.25), lens);
	ALBEDO = mix(color, vec3(0.87, 0.86, 0.77), haze);
	EMISSION = COLOR.rgb * lens * pulse * 0.32 * (1.0 - haze);
	float assembly = assembly_clarity(assembly_position);
	if (assembly <= 0.001) { discard; }
	ALBEDO = mix(vec3(0.94, 0.935, 0.89), ALBEDO, smoothstep(0.0, 1.0, assembly));
	EMISSION *= assembly;
}
