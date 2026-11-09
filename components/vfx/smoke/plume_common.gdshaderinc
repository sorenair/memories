// Shared flow and pigment for smoke clouds and continuous curling brush strokes.
uniform vec4 base_color : source_color = vec4(0.94, 0.93, 0.86, 1.0);
uniform vec4 shade_color : source_color = vec4(0.62, 0.65, 0.70, 1.0);
uniform vec4 highlight_color : source_color = vec4(1.0, 0.97, 0.88, 1.0);
uniform float plume_height = 3.2;
uniform float emitter_width = 0.16;
uniform float spread = 0.65;
uniform vec2 puff_size = vec2(0.35, 0.85);
uniform float wisp_width = 0.12;
uniform float wisp_length = 0.38;
uniform float curl_radius = 0.30;
uniform float curl_turns = 1.05;
uniform vec2 wind = vec2(0.20, 0.04);
uniform float lifetime = 5.5;
uniform float animation_speed = 0.8;
uniform float density = 0.65;
uniform float puff_opacity = 0.17;
uniform float wisp_opacity = 0.40;
uniform float paint_variation = 0.35;
uniform float recall_visibility = 1.0;
float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float paint_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1, 0)), f.x), mix(hash(i + vec2(0, 1)), hash(i + vec2(1)), f.x), f.y);
}
vec3 plume_path(float age, vec4 data, float clock) {
	float t = clamp(age, 0.0, 1.0);
	float phase = data.b * 6.28318;
	float opening = smoothstep(0.0, 0.48, t);
	vec2 curl = vec2(sin(t * curl_turns * 6.28318 + phase + clock * 0.7),
		cos(t * curl_turns * 4.4 + phase - clock * 0.4) * 0.35);
	vec2 origin = vec2(data.g - 0.5, sin(phase) * 0.24) * emitter_width;
	vec2 lateral = origin + curl * curl_radius * opening;
	lateral.x += (data.g - 0.5) * spread * t;
	lateral += wind * t * t;
	return vec3(lateral.x, t * plume_height, lateral.y);
}
