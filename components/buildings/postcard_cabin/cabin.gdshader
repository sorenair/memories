shader_type spatial;
render_mode unshaded, cull_disabled, fog_disabled;
#include "res://components/effects/recall/shaders/assembled_recall.gdshaderinc"
uniform float pigment_strength = 0.65;
uniform float paint_phase = 0.0;
uniform float window_warmth = 0.72;
uniform float window_glow = 0.28;
uniform float floor_height = 0.58;
uniform vec3 lamp_position = vec3(1.0, 2.8, 1.4);
uniform bool porch_lamp_enabled = true;
varying vec3 paint;
varying vec3 paint_position;
varying float paint_kind;
varying float haze;

void vertex() {
	// Same soft toon thresholds and world-space light direction as the bungalow.
	vec3 normal = normalize(MODEL_NORMAL_MATRIX * NORMAL);
	float light = dot(normal, normalize(vec3(-0.45, 0.82, -0.35))) * 0.5 + 0.5;
	float shade = mix(0.78, 0.96, smoothstep(0.27, 0.38, light));
	shade = mix(shade, 1.04, smoothstep(0.70, 0.80, light));
	paint = COLOR.rgb * shade;
	paint_position = VERTEX;
	paint_kind = UV2.x;
	vec3 world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	haze = smoothstep(30.0, 70.0, length((VIEW_MATRIX * vec4(world, 1.0)).xyz));
	assembly_position = world;
}

void fragment() {
	vec3 p = paint_position;
	float wood = 1.0 - smoothstep(0.1, 0.2, abs(paint_kind - 1.0));
	float glass = 1.0 - smoothstep(0.1, 0.2, abs(paint_kind - 3.0));
	float lamp = 1.0 - smoothstep(0.1, 0.2, abs(paint_kind - 4.0));
	float brush = sin(p.x * 1.65 + sin(p.y * 1.9 + p.z * 0.7) + paint_phase)
		* sin(p.y * 2.2 + sin(p.z * 1.4 + paint_phase));
	float wash = smoothstep(-0.55, 0.55, brush);
	vec3 color = paint * mix(1.0, mix(0.93, 1.065, wash), pigment_strength);
	color *= 1.0 - wood * (1.0 - smoothstep(floor_height, floor_height + 0.35, p.y)) * 0.09;
	if (porch_lamp_enabled) {
		vec3 delta = p - lamp_position;
		float pool = exp(-dot(delta * vec3(2.5, 1.8, 8.0), delta * vec3(2.5, 1.8, 8.0)));
		color += vec3(0.095, 0.043, 0.012) * pool * wood;
	}
	if (glass > 0.5) {
		// Opaque painted reflections: broad forest pigment above, warm light below.
		float clouds = sin(UV.x * 9.0 + sin(UV.y * 6.5 + paint_phase)) * sin(UV.y * 8.0 + UV.x * 3.0);
		float pools = smoothstep(-0.45, 0.45, clouds);
		vec3 reflection = COLOR.rgb * mix(0.62, 1.10, pools);
		vec3 amber = mix(vec3(0.66, 0.30, 0.085), vec3(1.0, 0.68, 0.29), smoothstep(0.04, 0.90, UV.y));
		float glow_wash = 0.5 + 0.5 * sin(UV.x * 6.0 + sin(UV.y * 4.0));
		amber *= mix(0.88, 1.08, glow_wash);
		color = mix(reflection, amber, window_warmth * (0.55 + UV.y * 0.45));
		// Two soft vertical brush marks hint at reflected trees, never modeled rooms.
		float trunk_a = 1.0 - smoothstep(0.012, 0.036, abs(UV.x - 0.24 - sin(UV.y * 8.0) * 0.015));
		float trunk_b = 1.0 - smoothstep(0.014, 0.042, abs(UV.x - 0.76 + sin(UV.y * 6.0) * 0.023));
		color *= 1.0 - (trunk_a + trunk_b) * (1.0 - smoothstep(0.35, 0.95, UV.y)) * 0.24;
		color *= 0.91 + smoothstep(0.0, 0.08, min(min(UV.x, 1.0 - UV.x), min(UV.y, 1.0 - UV.y))) * 0.09;
	}
	ALBEDO = mix(color, vec3(0.87, 0.86, 0.77), haze);
	EMISSION = color * (glass * window_glow * window_warmth + lamp * 0.42) * (1.0 - haze);
	float assembly = assembly_clarity(assembly_position);
	if (assembly <= 0.001) { discard; }
	ALBEDO = mix(vec3(0.94, 0.935, 0.89), ALBEDO, smoothstep(0.0, 1.0, assembly));
	EMISSION *= assembly;
}
