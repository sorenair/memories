shader_type spatial;
render_mode unshaded, cull_disabled, fog_disabled;
#include "res://components/effects/recall/shaders/solid_recall.gdshaderinc"
uniform vec4 base_color : source_color = vec4(1.0);
uniform sampler2D base_texture : source_color, hint_default_white;
uniform float tone_strength : hint_range(0.0, 1.0) = 1.0;
uniform bool recall_enabled = false;
uniform float base_y = 0.0;
varying float painted_light;
varying vec3 recall_position;

void vertex() {
	// Match the painted light direction used on the scenery.
	vec3 normal = normalize(MODEL_NORMAL_MATRIX * NORMAL);
	painted_light = dot(normal, normalize(vec3(-0.45, 0.82, -0.35))) * 0.5 + 0.5;
	vec3 world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	recall_position = vec3(world.x, world.y - base_y, world.z);
}

void fragment() {
	float clarity = recall_enabled ? solid_recall_clarity(recall_position) : 1.0;
	if (clarity <= 0.001) { discard; }
	// Keep the main color broad, with a shallow shadow and a soft lit edge.
	float tone = mix(0.78, 0.96, smoothstep(0.27, 0.38, painted_light));
	tone = mix(tone, 1.04, smoothstep(0.70, 0.80, painted_light));
	vec3 pigment = base_color.rgb * texture(base_texture, UV).rgb;
	ALBEDO = mix(recall_void_color.rgb, pigment * mix(1.0, tone, tone_strength), smoothstep(0.0, 1.0, clarity));
}
