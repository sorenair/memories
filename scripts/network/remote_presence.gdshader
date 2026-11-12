shader_type spatial;
render_mode diffuse_toon, specular_toon, cull_disabled, fog_disabled;
#include "res://components/effects/recall/shaders/solid_recall.gdshaderinc"
uniform vec4 base_color : source_color = vec4(1.0);
uniform sampler2D base_texture : source_color, hint_default_white;
uniform float roughness = 1.0;
uniform float metallic = 0.0;
uniform float base_y = 0.0;
varying vec3 recall_position;
void vertex() {
	vec3 world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	recall_position = vec3(world.x, world.y - base_y, world.z);
}
void fragment() {
	float clarity = solid_recall_clarity(recall_position);
	if (clarity <= 0.001) { discard; }
	vec3 pigment = base_color.rgb * texture(base_texture, UV).rgb;
	ALBEDO = mix(recall_void_color.rgb, pigment, smoothstep(0.0, 1.0, clarity));
	ROUGHNESS = roughness;
	METALLIC = metallic;
	// A gentle luminous resolving edge stays legible on dark clothing.
	EMISSION = recall_void_color.rgb * (1.0 - clarity) * 0.35;
}
