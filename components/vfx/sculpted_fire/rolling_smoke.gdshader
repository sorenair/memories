shader_type spatial;
render_mode unshaded, cull_front, depth_draw_never, fog_disabled;
#include "res://components/vfx/sculpted_fire/fire_common.gdshaderinc"
#include "res://components/vfx/sculpted_fire/smoke_flow.gdshaderinc"
varying float plume_height;
varying vec3 plume_position;
vec3 plume_point(float h, float a, float t) {
	h = clamp(h, 0.0, 1.0);
	float rise = h * 17.0 - t * 1.25;
	float billow = sin(rise + sin(a * 2.0 + h * 5.0) * 0.55) * 0.15;
	billow += sin(h * 27.0 - t * 1.85 - a * 2.0) * 0.05;
	float scallop = sin(a * 3.0 + h * 4.0 - t * 0.34) * 0.09;
	scallop += sin(a * 5.0 - h * 3.0 + t * 0.23) * 0.04;
	float radius = smoke_spread * mix(0.16, 0.68, pow(h, 0.55));
	radius *= 1.0 + (billow + scallop) * smoke_turbulence;
	radius *= smoothstep(0.0, 0.055, h) * (1.0 - smoothstep(0.92, 1.0, h));
	return smoke_center(h, t) + vec3(cos(a) * radius, 0.0, sin(a) * radius);
}
void vertex() {
	float t = fire_clock(TIME);
	float h = UV.y;
	float a = UV.x * 6.283185;
	VERTEX = plume_point(h, a, t);
	vec3 dh = plume_point(h + 0.005, a, t) - plume_point(h - 0.005, a, t);
	vec3 da = plume_point(h, a + 0.01, t) - plume_point(h, a - 0.01, t);
	NORMAL = normalize(cross(dh, da) + vec3(0.0000001));
	plume_height = h;
	plume_position = VERTEX;
}
void fragment() {
	float t = fire_clock(TIME);
	float h = plume_height;
	float face = abs(dot(normalize(NORMAL), normalize(VIEW)));
	// This is a faint connective density, not a lit outer skin. The rolling
	// dabs carry the billows; surface-normal lighting would expose a tube.
	float pigment = fire_noise(plume_position * vec3(4.0, 4.2, 4.0) - vec3(0.0, t * 0.65, 0.0));
	vec3 color = smoke_color.rgb * mix(0.88, 1.10, pigment);
	float warmth = (1.0 - smoothstep(0.0, 0.30, h)) * 0.28;
	color = mix(color, mix(edge_color.rgb, flame_color.rgb, 0.25), warmth);
	float density = smoothstep(0.0, 0.14, h) * (1.0 - smoothstep(0.32, 0.90, h));
	float fray = fire_noise(plume_position * vec3(6.0, 5.0, 6.0) - vec3(0.0, t * 0.85, 0.0));
	density *= pow(face, 1.4) * smoothstep(0.20, 0.72, pigment);
	density *= mix(0.45, 1.0, smoothstep(0.25, 0.65, fray));
	ALBEDO = color;
	EMISSION = flame_color.rgb * warmth * 0.08 * glow_strength;
	ALPHA = density * smoke_amount * intensity * recall_visibility * 0.27;
	if (ALPHA < 0.001) { discard; }
}
