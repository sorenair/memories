shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, fog_disabled;
uniform vec4 root_color : source_color;
uniform vec4 shade_color : source_color;
uniform vec4 leaf_color : source_color;
uniform vec4 sun_color : source_color;
uniform float shape_phase = 0.0;
uniform vec2 patch_size = vec2(7.0, 5.0);

varying vec3 world_position;
varying vec2 local_position;
void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	local_position = VERTEX.xz;
}

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1, 0)), f.x), mix(hash(i + vec2(0, 1)), hash(i + vec2(1)), f.x), f.y);
}
void fragment() {
	vec2 q = local_position / (patch_size * 0.5);
	float angle = atan(q.y, q.x);
	float boundary = 1.0 + 0.07 * sin(angle * 5.0 + shape_phase) + 0.045 * sin(angle * 9.0 - shape_phase);
	float radius = length(q) / boundary;
	vec2 p = q * patch_size * 0.5;
	float mottling = noise(p * 2.5 + shape_phase);
	float edge = 1.0 - smoothstep(0.62, 1.09, radius + (mottling - 0.5) * 0.12);
	float meadow = sin(p.x * 0.9 + shape_phase) * cos(p.y * 1.1 - shape_phase) * 0.5 + 0.5;
	float brush = floor(noise(p * vec2(9.0, 15.0)) * 4.0) / 3.0;
	vec3 pigment = mix(root_color.rgb, shade_color.rgb, meadow * 0.65 + mottling * 0.35);
	pigment = mix(pigment, leaf_color.rgb, brush * 0.13);
	ALBEDO = pigment;
	float haze = smoothstep(25.0, 60.0, length((VIEW_MATRIX * vec4(world_position, 1.0)).xyz));
	ALPHA = edge * mix(0.68, 0.92, mottling) * (1.0 - haze);
}
