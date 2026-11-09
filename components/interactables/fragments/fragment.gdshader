shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled;
uniform vec4 glow_color : source_color = vec4(1.0);
uniform float speed = 1.0;
uniform float tap_feedback = 0.0;
uniform float activity : hint_range(0.0, 1.0) = 0.0;
uniform float seed = 1.0;
uniform int mote_count = 8;
uniform float wisp_strength = 1.0;
uniform float decay : hint_range(0.0, 1.0) = 0.0;
void vertex() {
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
	MODELVIEW_MATRIX[0] *= length(MODEL_MATRIX[0].xyz);
	MODELVIEW_MATRIX[1] *= length(MODEL_MATRIX[1].xyz);
	MODELVIEW_MATRIX[2] *= length(MODEL_MATRIX[2].xyz);
}
void fragment() {
	vec2 p = (UV - 0.5) * vec2(6.0, 8.0);
	p.y = -p.y;
	float t = TIME * speed;
	float burst = 1.0 - pow(1.0 - decay, 3.0);
	float puff = 0.0;
	// Broad, irregular brush puffs accelerate outward, then soften and disperse.
	if (decay > 0.0) {
		for (int i = 0; i < 7; i++) {
			float f = float(i);
			float angle = f * 0.8976 + seed * 1.7;
			vec2 direction = vec2(cos(angle), sin(angle));
			vec2 tangent = vec2(-direction.y, direction.x);
			float reach = mix(0.55, 2.1 + 0.3 * sin(f * 4.0), burst);
			vec2 center = direction * reach + tangent * sin(decay * 5.0 + f) * decay * 0.2;
			vec2 q = p - center;
			vec2 brush = vec2(dot(q, direction), dot(q, tangent));
			brush /= vec2(0.42 + burst * 0.38, 0.28 + burst * 0.22);
			float edge = length(brush) + 0.12 * sin(brush.x * 5.0 + f) * sin(brush.y * 4.0 + f);
			puff += (1.0 - smoothstep(0.35, 1.15 + decay * 0.3, edge)) * (0.65 + 0.15 * sin(f));
		}
	}
	float motes = 0.0;
	for (int i = 0; i < 16; i++) {
		if (i >= mote_count) { break; }
		float f = float(i);
		float cycle = fract(t * (0.10 + fract(f * 0.37) * 0.06) + fract(f * 0.618 + seed * 0.13));
		float y = mix(-1.6, 2.7, cycle);
		float x = sin(f * 5.4 + seed + cycle * 3.0) * (0.6 + 0.6 * cycle) + sin(t * 0.5 + f) * 0.18;
		vec2 drift = vec2(x, y);
		vec2 scatter = vec2(cos(f * 2.4 + seed), sin(f * 2.4 + seed));
		drift = mix(drift, scatter * (0.8 + 1.8 * burst), smoothstep(0.0, 0.22, decay));
		vec2 q = (p - drift) / vec2(1.0, 1.1);
		float radius = 0.055 + 0.05 * fract(f * 0.73);
		float fade = smoothstep(0.0, 0.18, cycle) * (1.0 - smoothstep(0.7, 1.0, cycle));
		motes += (1.0 - smoothstep(radius * 0.25, radius + 0.035, length(q))) * fade;
	}
	// A breathing silhouette and broad painted light regions, not a surface pattern.
	float angle = atan(p.y, p.x);
	float contour = 1.0 + 0.035 * sin(angle * 3.0 + t * 0.9 + seed)
		+ 0.025 * sin(angle * 5.0 - t * 0.7) + 0.025 * sin(t * 1.2 + seed);
	vec2 shape = p / vec2(1.0, 1.04);
	float r = length(shape) / (contour * (1.0 + 0.18 * sin(min(decay * 4.0, 1.0) * 3.14159265)));
	float body = 1.0 - smoothstep(0.92, 1.06, r);
	float shade = dot(shape, normalize(vec2(-0.6, 0.8)));
	float middle = smoothstep(-0.44, -0.35, shade + 0.045 * sin(p.x * 4.0 + t * 0.35));
	float light = smoothstep(0.20, 0.30, shade + 0.03 * sin(p.y * 5.0 - t * 0.25));
	float tone = mix(0.77, 0.91, middle);
	tone = mix(tone, 1.0, light);
	// Uneven, softly brushed rim catches light around the floating volume.
	float rim = smoothstep(0.65, 0.84, r) * (1.0 - smoothstep(0.93, 1.04, r));
	float rim_light = 0.45 + 0.35 * sin(angle + 1.0);
	tone = mix(tone, 1.0, rim * rim_light);
	tone = mix(tone, 1.0, tap_feedback * 0.4);
	float orb_alpha = body * mix(0.56, 0.93, activity) * (1.0 - smoothstep(0.04, 0.32, decay));
	float wisps = puff * wisp_strength * smoothstep(0.0, 0.08, decay) * pow(1.0 - decay, 1.4);
	float particles = motes * mix(0.18, 0.85, activity) * (1.0 - decay);
	float total = orb_alpha + wisps + particles;
	ALBEDO = glow_color.rgb * mix(0.82, 1.0, activity) * mix(1.0, tone, orb_alpha / max(total, 0.001));
	ALPHA = clamp(total, 0.0, 0.97);
}
