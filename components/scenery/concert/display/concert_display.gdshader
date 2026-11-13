shader_type spatial;
render_mode unshaded, cull_disabled, fog_disabled;
#include "res://components/effects/recall/shaders/assembled_recall.gdshaderinc"
uniform vec4 ink_color : source_color = vec4(0.12, 0.14, 0.22, 1.0);
uniform vec4 color_a : source_color = vec4(0.93, 0.58, 0.46, 1.0);
uniform vec4 color_b : source_color = vec4(0.41, 0.84, 0.80, 1.0);
uniform vec4 color_c : source_color = vec4(0.65, 0.55, 0.93, 1.0);
uniform vec4 color_d : source_color = vec4(0.95, 0.79, 0.47, 1.0);
uniform vec2 display_size = vec2(5.4, 2.6);
uniform int pattern_mode = 0;
uniform float beat_bpm = 120.0;
uniform float beats_per_pattern = 1.0;
uniform float playback_speed = 1.0;
uniform float transition_duration = 0.12;
uniform float brightness = 1.1;
uniform float emission_strength = 0.55;
uniform float paint_amount = 0.38;
uniform float pattern_seed = 71.0;
uniform float animation_time = -1.0;

float hash(float value) {
	float p = fract(value * 0.1031);
	p *= p + 33.33;
	return fract(p * (p + p));
}

vec3 palette(float value) {
	float p = fract(value) * 4.0;
	float blend = smoothstep(0.16, 0.84, fract(p));
	if (p < 1.0) { return mix(color_a.rgb, color_b.rgb, blend); }
	if (p < 2.0) { return mix(color_b.rgb, color_c.rgb, blend); }
	if (p < 3.0) { return mix(color_c.rgb, color_d.rgb, blend); }
	return mix(color_d.rgb, color_a.rgb, blend);
}

float sequence_pattern(float epoch) {
	// Complete all six families before repeating. Alternating coprime strides
	// and shifting each round also avoid adjacent repeats across round boundaries.
	float round_id = floor(epoch / 6.0);
	float slot = mod(epoch, 6.0);
	float stride = mod(round_id, 2.0) < 1.0 ? 1.0 : 5.0;
	return mod(slot * stride + floor(mod(pattern_seed, 6.0)) + round_id * 2.0, 6.0);
}

vec3 graphic(float family, vec2 uv, float time, float epoch) {
	vec2 q = uv * 2.0 - 1.0;
	q.x *= display_size.x / max(display_size.y, 0.1);
	float phase = hash(pattern_seed + epoch * 0.31) * TAU;
	float shift = epoch * 0.137 + pattern_seed * 0.017;
	vec3 ink = ink_color.rgb;
	if (family < 0.5) {
		// Posterized liquid pigment: several broad ribbons, not a scrolling image.
		vec2 p = q;
		p.x += sin(q.y * 2.6 + time * 0.93 + phase) * 0.38;
		p.y += cos(q.x * 1.9 - time * 0.77) * 0.31;
		float field = sin(p.x * 2.8 + time * 0.8) * 0.28 + cos(p.y * 3.4 - time) * 0.22 + 0.5;
		float pools = floor(field * 8.0) / 8.0;
		float gap = smoothstep(0.04, 0.19, fract(field * 3.5));
		return mix(ink, palette(pools * 0.8 + shift), gap * 0.94 + 0.06);
	} else if (family < 1.5) {
		// A turning, folded-petal kaleidoscope.
		float r = length(q);
		float angle = atan(q.y, q.x) + time * 0.32;
		float petal = abs(cos(angle * 5.0 + sin(r * 3.0 - time) * 0.3));
		float folds = sin((r + (1.0 - petal) * 0.27) * 12.0 - time * 2.1);
		float shape = smoothstep(-0.2, 0.13, folds);
		vec3 color = palette(r * 0.23 + petal * 0.35 + shift);
		return mix(ink, color, shape * 0.93 + 0.07);
	} else if (family < 2.5) {
		// Animated brush bars. This is a graphic sequence, not an audio spectrum.
		float column = floor(uv.x * 18.0);
		float x = fract(uv.x * 18.0) - 0.5;
		float y = 1.0 - uv.y;
		float height = 0.22 + 0.66 * (0.5 + 0.5 * sin(time * 3.0 + column * 1.43 + phase));
		height *= mix(0.72, 1.0, hash(column + pattern_seed));
		float brush = sin(y * 17.0 + column * 2.4) * 0.018;
		float bar = (1.0 - smoothstep(0.34, 0.46, abs(x) + brush)) * (1.0 - smoothstep(height - 0.018, height + 0.015, y));
		vec3 color = palette(column / 18.0 + y * 0.12 + shift);
		float cap = smoothstep(height - 0.05, height - 0.018, y);
		color = mix(color, vec3(0.92, 0.87, 0.73), cap * 0.22);
		return mix(ink, color, bar);
	} else if (family < 3.5) {
		// Large cut-paper prisms in a slowly turning field.
		float angle = time * 0.23;
		vec2 p = mat2(vec2(cos(angle), -sin(angle)), vec2(sin(angle), cos(angle))) * q;
		p = p * 2.6 + vec2(time * 0.2, phase * 0.4);
		vec2 cell = floor(p);
		vec2 f = fract(p);
		float diagonal = f.x + f.y;
		float triangle = smoothstep(0.97, 1.03, diagonal);
		float index = hash(cell.x * 13.7 + cell.y * 7.3 + pattern_seed);
		vec3 color = palette(index * 0.7 + triangle * 0.19 + shift);
		float seam = smoothstep(0.012, 0.045, abs(diagonal - 1.0));
		return mix(ink, color, seam * 0.94 + 0.06);
	} else if (family < 4.5) {
		// Broken, orbiting brush halos with a warm center.
		q -= vec2(sin(time * 0.43 + phase), cos(time * 0.36 + phase)) * 0.18;
		float r = length(q);
		float angle = atan(q.y, q.x);
		float ripple = sin(r * 13.0 - time * 2.5 + sin(angle * 3.0 + time) * 0.32);
		float ring = 1.0 - smoothstep(0.16, 0.38, abs(ripple));
		float broken = smoothstep(-0.65, -0.25, sin(angle * 4.0 + r * 2.0 - time * 0.7));
		vec3 color = palette(r * 0.21 + angle / TAU * 0.18 + shift);
		vec3 result = mix(ink, color, ring * broken);
		return mix(result, color_d.rgb, exp(-r * r * 38.0) * 0.65);
	}
	// A bold rotating painted sun: different silhouette from the folded rosette.
	float r = length(q);
	float angle = atan(q.y, q.x) + time * 0.45;
	float ray = 0.5 + 0.5 * cos(angle * 12.0 + sin(r * 2.3 - time) * 0.24);
	float shape = smoothstep(0.40, 0.59, ray);
	vec3 color = palette(floor(angle / TAU * 12.0) / 12.0 + r * 0.07 + shift);
	vec3 result = mix(ink, color, shape);
	float sun = 1.0 - smoothstep(0.24, 0.29, r + sin(angle * 6.0) * 0.012);
	return mix(result, mix(color_d.rgb, vec3(1.0, 0.93, 0.78), 0.32), sun);
}

void vertex() {
	assembly_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	float clock = (animation_time >= 0.0 ? animation_time : TIME) * playback_speed;
	float rate = beat_bpm / 60.0 / max(beats_per_pattern, 0.5);
	float epoch = pattern_mode == 0 ? floor(clock * rate) : 0.0;
	float phase = fract(clock * rate);
	float family = pattern_mode == 0 ? sequence_pattern(epoch) : float(pattern_mode - 1);
	vec3 color = graphic(family, UV, clock, epoch);
	float wipe_duration = min(transition_duration, 0.45 / max(rate, 0.001));
	if (pattern_mode == 0 && rate > 0.0 && phase / rate < wipe_duration) {
		float progress = clamp(phase / rate / max(wipe_duration, 0.001), 0.0, 1.0);
		float brush = sin(UV.y * 19.0 + epoch) * 0.018 + sin(UV.y * 37.0 + pattern_seed) * 0.008;
		float wipe = smoothstep(UV.x - 0.045, UV.x + 0.045, progress * 1.12 - 0.06 + brush);
		vec3 previous = graphic(sequence_pattern(epoch - 1.0), UV, clock, epoch - 1.0);
		color = mix(previous, color, wipe);
	}
	// Large pigment pools unify the different graphic families. No LED dot grid.
	vec2 p = UV * display_size;
	float wash = sin(p.x * 9.3 + sin(p.y * 7.4 + pattern_seed)) * sin(p.y * 11.1 + p.x * 1.4);
	float pigment = mix(0.91, 1.025, smoothstep(-0.35, 0.40, wash));
	color *= mix(1.0, pigment, paint_amount);
	float edge = smoothstep(0.45, 1.0, max(abs(UV.x * 2.0 - 1.0), abs(UV.y * 2.0 - 1.0)));
	color *= (1.0 - edge * 0.055) * brightness;
	float assembly = assembly_clarity(assembly_position);
	if (assembly <= 0.001) { discard; }
	ALBEDO = mix(vec3(0.94, 0.935, 0.89), color, smoothstep(0.0, 1.0, assembly));
	EMISSION = color * emission_strength * assembly;
}
