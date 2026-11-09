shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, fog_disabled;
#include "res://components/vfx/smoke/plume_common.gdshaderinc"
varying float life;
varying float individuality;
varying float age_mix;
void vertex() {
	float clock = TIME * animation_speed / max(lifetime, 0.1);
	float age = fract(INSTANCE_CUSTOM.r + clock);
	vec3 local_center = plume_path(age, INSTANCE_CUSTOM, clock);
	vec3 world = (MODEL_MATRIX * vec4(local_center, 1.0)).xyz;
	float size = mix(puff_size.x, puff_size.y, smoothstep(0.0, 1.0, age));
	size *= mix(0.75, 1.2, INSTANCE_CUSTOM.a) * length(MODEL_MATRIX[0].xyz);
	float angle = sin(age * 2.4 + INSTANCE_CUSTOM.b * 6.28318) * 0.5;
	vec2 dab = mat2(vec2(cos(angle), sin(angle)), vec2(-sin(angle), cos(angle))) * VERTEX.xy;
	world += INV_VIEW_MATRIX[0].xyz * dab.x * size + INV_VIEW_MATRIX[1].xyz * dab.y * size * 1.18;
	VERTEX = (inverse(MODEL_MATRIX) * vec4(world, 1.0)).xyz;
	life = smoothstep(0.0, 0.13, age) * (1.0 - smoothstep(0.56, 1.0, age));
	individuality = INSTANCE_CUSTOM.b;
	age_mix = age;
}
void fragment() {
	vec2 q = UV * 2.0 - 1.0;
	float angle = atan(q.y, q.x);
	float lobes = 1.0 + sin(angle * 3.0 + individuality * 6.28318) * 0.10 + sin(angle * 5.0 - individuality * 4.0) * 0.055;
	float radius = length(q * vec2(1.0, 0.88)) / lobes;
	float edge = 1.0 - smoothstep(0.42, 1.0, radius);
	float brush = paint_noise(q * 2.1 + individuality * 8.0);
	// Broad pigment shapes with three quiet tones, softened by the cloud boundary.
	float band = floor(brush * 3.0) / 2.0;
	vec3 pigment = mix(shade_color.rgb, base_color.rgb, 0.62 + band * 0.22);
	pigment = mix(pigment, highlight_color.rgb, smoothstep(-0.15, 0.8, -q.y + q.x * 0.35) * 0.34);
	ALBEDO = mix(base_color.rgb, pigment, paint_variation);
	ALPHA = edge * life * puff_opacity * density * base_color.a * recall_visibility * mix(0.78, 1.0, brush);
	if (ALPHA <= 0.001) { discard; }
}
