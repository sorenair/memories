shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, fog_disabled;
// Soft irregular dabs, with no glow sprites, flashing sparkles, or CPU particles.
uniform vec4 mote_color : source_color = vec4(1.0, 0.96, 0.84, 1.0);
uniform vec4 mote_edge_color : source_color = vec4(0.72, 0.65, 0.47, 1.0);
uniform float beam_height = 4.5;
uniform vec2 source_offset = vec2(-1.5, -1.0);
uniform vec2 footprint = vec2(2.8, 1.8);
uniform float source_width = 0.75;
uniform vec2 mote_size = vec2(0.025, 0.055);
uniform float drift_speed = 0.08;
uniform float wander = 0.10;
uniform float recall_visibility = 1.0;
varying float life;
varying float variation;
void vertex() {
	float clock = TIME * drift_speed;
	float phase = INSTANCE_CUSTOM.r * 6.28318;
	float t = fract(INSTANCE_CUSTOM.r + clock / max(beam_height, 0.1));
	vec2 scatter = INSTANCE_CUSTOM.gb * 2.0 - 1.0;
	float width = mix(footprint.x, source_width, t);
	float depth = mix(footprint.y, source_width * 0.65, t);
	vec3 local_center = vec3(source_offset.x * t + scatter.x * width * 0.43,
		beam_height * t, source_offset.y * t + scatter.y * depth * 0.43);
	local_center.x += sin(clock * 0.67 + phase) * wander;
	local_center.z += sin(clock * 0.43 + phase * 1.7) * wander * 0.6;
	vec3 center = (MODEL_MATRIX * vec4(local_center, 1.0)).xyz;
	float size = mix(mote_size.x, mote_size.y, INSTANCE_CUSTOM.a) * length(MODEL_MATRIX[0].xyz);
	float angle = phase + sin(clock * 0.3 + phase) * 0.15;
	vec2 dab = mat2(vec2(cos(angle), sin(angle)), vec2(-sin(angle), cos(angle))) * VERTEX.xy;
	center += INV_VIEW_MATRIX[0].xyz * dab.x * size + INV_VIEW_MATRIX[1].xyz * dab.y * size * 0.8;
	VERTEX = (inverse(MODEL_MATRIX) * vec4(center, 1.0)).xyz;
	life = smoothstep(0.0, 0.10, t) * (1.0 - smoothstep(0.86, 1.0, t));
	life *= (1.0 - smoothstep(0.45, 1.15, length(scatter))) * 0.65 + 0.25;
	life *= 0.85 + 0.15 * sin(clock * 0.6 + phase);
	variation = INSTANCE_CUSTOM.a;
}
void fragment() {
	vec2 q = UV * 2.0 - 1.0;
	float brush = 0.92 + sin(q.x * 7.0 + q.y * 5.0 + variation * 8.0) * 0.08;
	float dab = 1.0 - smoothstep(0.25, 1.0, length(q * vec2(1.0, 0.85)) / brush);
	ALBEDO = mix(mote_edge_color.rgb, mote_color.rgb, smoothstep(0.12, 0.82, dab)) * mix(0.92, 1.0, variation);
	ALPHA = dab * life * mix(0.3, 0.7, variation) * mote_color.a * recall_visibility;
}
