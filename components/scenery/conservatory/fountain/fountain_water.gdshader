shader_type spatial;
render_mode unshaded, cull_disabled, fog_disabled;
#include "res://components/effects/recall/shaders/assembled_recall.gdshaderinc"
uniform sampler2D pigment_mask : repeat_enable, filter_linear_mipmap;
uniform sampler2D caustic_mask : repeat_enable, filter_linear_mipmap;
uniform vec4 water_color : source_color = vec4(0.29, 0.59, 0.57, 1.0);
uniform float flow_speed = 1.0;
uniform float animation_time = -1.0;
varying vec3 p;
varying float kind;
void vertex() {
	p = VERTEX;
	kind = UV2.x;
	float t = (animation_time >= 0.0 ? animation_time : TIME) * flow_speed;
	if (kind > 0.5) {
		VERTEX += NORMAL * sin(UV.y * 25.0 - t * 8.0) * 0.0025;
	}
	assembly_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}
void fragment() {
	float t = (animation_time >= 0.0 ? animation_time : TIME) * flow_speed;
	vec3 color;
	if (kind < 0.5) {
		// Reuses the pond's authored paint masks with crossing wave distortion.
		vec2 warp = vec2(sin(p.z * 4.0 + t), cos(p.x * 3.7 - t * 0.8)) * 0.055;
		float pigment = texture(pigment_mask, p.xz * 0.6 + warp + vec2(t * 0.014, -t * 0.009)).r;
		float light = texture(caustic_mask, p.xz * 0.9 - warp * 0.7 - vec2(t * 0.008)).r;
		float angle = atan(p.z, p.x);
		float ripple = sin(length(p.xz) * 17.0 - t * 3.4 + sin(angle * 4.0 + t * 0.6) * 0.36 + sin(p.x * 5.0 + p.z * 2.0) * 0.25);
		float ring = (1.0 - smoothstep(0.10, 0.25, abs(ripple))) * smoothstep(0.24, 0.65, pigment + sin(angle * 3.0 + t) * 0.12);
		color = water_color.rgb * mix(0.72, 1.18, smoothstep(0.25, 0.7, pigment));
		color = mix(color, vec3(0.83, 0.91, 0.83), ring * 0.14 + smoothstep(0.6, 0.88, light) * 0.14);
	} else {
		float falling = smoothstep(0.15, 0.55, sin(UV.y * 36.0 - t * 9.0));
		color = mix(water_color.rgb * 1.12, vec3(0.92, 0.96, 0.88), 0.38 + falling * 0.30);
	}
	ALBEDO = color;
	float assembly = assembly_clarity(assembly_position);
	if (assembly <= 0.001) { discard; }
	ALBEDO = mix(vec3(0.94, 0.935, 0.89), ALBEDO, smoothstep(0.0, 1.0, assembly));
}
