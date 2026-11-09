shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, fog_disabled;
#include "res://components/vfx/smoke/plume_common.gdshaderinc"
varying float life;
varying float individuality;
void vertex() {
	float clock = TIME * animation_speed / max(lifetime, 0.1);
	float head = fract(INSTANCE_CUSTOM.r + clock);
	float age = head - (1.0 - UV.y) * wisp_length;
	vec3 center = plume_path(age, INSTANCE_CUSTOM, clock);
	vec3 tangent = plume_path(age + 0.003, INSTANCE_CUSTOM, clock) - plume_path(age - 0.003, INSTANCE_CUSTOM, clock);
	vec3 world = (MODEL_MATRIX * vec4(center, 1.0)).xyz;
	vec3 axis = mat3(MODEL_MATRIX) * tangent;
	vec3 view = normalize(INV_VIEW_MATRIX[3].xyz - world);
	vec3 across = cross(axis, view);
	if (length(across) < 0.001) { across = INV_VIEW_MATRIX[0].xyz; }
	across = normalize(across);
	float taper = pow(max(sin(UV.y * 3.14159), 0.0), 0.7);
	float width = wisp_width * mix(0.65, 1.25, INSTANCE_CUSTOM.a) * taper * length(MODEL_MATRIX[0].xyz);
	world += across * VERTEX.x * width * 0.5;
	VERTEX = (inverse(MODEL_MATRIX) * vec4(world, 1.0)).xyz;
	life = smoothstep(0.04, 0.16, head) * (1.0 - smoothstep(0.72, 0.98, head));
	life *= smoothstep(0.0, 0.08, age);
	individuality = INSTANCE_CUSTOM.b;
}
void fragment() {
	float across = abs(UV.x * 2.0 - 1.0);
	float edge = 1.0 - smoothstep(0.12, 1.0, across);
	float ends = pow(max(sin(UV.y * 3.14159), 0.0), 0.6);
	float brush = paint_noise(vec2(UV.y * 6.0, UV.x * 2.0) + individuality * 9.0);
	vec3 pigment = mix(shade_color.rgb, base_color.rgb, 0.65 + (1.0 - across) * 0.35);
	pigment = mix(pigment, highlight_color.rgb, (1.0 - across) * 0.25);
	ALBEDO = pigment;
	ALPHA = edge * ends * life * wisp_opacity * density * base_color.a * recall_visibility * mix(1.0, 0.75 + brush * 0.25, paint_variation);
	if (ALPHA <= 0.001) { discard; }
}
