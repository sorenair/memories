shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, fog_disabled;
#include "res://components/vfx/sculpted_fire/fire_common.gdshaderinc"
#include "res://components/vfx/sculpted_fire/smoke_flow.gdshaderinc"
varying float smoke_age;
varying float life;
varying float phase_mix;
void vertex() {
	float t = fire_clock(TIME);
	float age = fract(INSTANCE_CUSTOM.x + t * (0.12 + INSTANCE_CUSTOM.y * 0.035));
	float phase = INSTANCE_CUSTOM.z * 6.283185;
	vec3 center = smoke_center(age, t);
	center.xz += vec2(cos(phase + age * 3.0), sin(phase + age * 3.0)) * smoke_spread * (0.04 + age * 0.38) * smoke_turbulence;
	vec3 world = (MODEL_MATRIX * vec4(center, 1.0)).xyz;
	float size = smoke_spread * mix(0.50, 1.85, pow(age, 0.65)) * mix(0.78, 1.25, INSTANCE_CUSTOM.w);
	float rotation = phase + t * 0.13 + age * 0.8;
	vec2 dab = mat2(vec2(cos(rotation), sin(rotation)), vec2(-sin(rotation), cos(rotation))) * VERTEX.xy;
	float scale = length(MODEL_MATRIX[0].xyz);
	world += (INV_VIEW_MATRIX[0].xyz * dab.x + INV_VIEW_MATRIX[1].xyz * dab.y * 1.15) * size * scale;
	VERTEX = (inverse(MODEL_MATRIX) * vec4(world, 1.0)).xyz;
	smoke_age = age;
	life = smoothstep(0.0, 0.12, age) * (1.0 - smoothstep(0.55, 1.0, age));
	phase_mix = phase;
}
void fragment() {
	vec2 q = (UV * 2.0 - 1.0) * 1.20;
	float t = fire_clock(TIME);
	// Unequal overlapping lobes roll within each brush shape. Erosion eats
	// into its interior before the whole dab dissipates, avoiding solid puffs.
	float roll = smoke_age * 3.5 + phase_mix;
	vec2 offset = vec2(cos(roll), sin(roll)) * 0.24;
	float d0 = length((q + offset * 0.5) * vec2(1.0, 1.12)) / 0.78;
	float d1 = length(q - offset - vec2(0.24, 0.04)) / 0.59;
	float d2 = length((q + offset - vec2(-0.20, 0.18)) * vec2(1.0, 0.88)) / 0.57;
	float d = min(d0, min(d1, d2));
	float brush = fire_noise(vec3(q * 3.4 + vec2(sin(roll), cos(roll)) * 0.3, phase_mix + smoke_age * 1.5));
	float edge = 1.0 - smoothstep(0.72, 1.07, d + (brush - 0.5) * 0.15);
	edge *= 1.0 - smoothstep(0.90, 1.0, max(abs(UV.x * 2.0 - 1.0), abs(UV.y * 2.0 - 1.0)));
	float erosion = mix(0.35 * (1.0-smoke_age), 1.0, smoothstep(mix(0.08, 0.48, smoke_age), 0.76, brush));
	float lighting = smoothstep(0.12, 0.86, dot(q,vec2(-0.16,-0.24)) + brush * 0.50 + 0.25);
	vec3 color = smoke_color.rgb * mix(0.76, 1.22, lighting);
	color = mix(color, edge_color.rgb, (1.0 - smoothstep(0.0, 0.28, smoke_age)) * 0.28);
	ALBEDO = color;
	ALPHA = edge * erosion * life * smoke_amount * intensity * recall_visibility * 0.85;
	if (ALPHA < 0.001) { discard; }
}
