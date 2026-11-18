// The receiver shades the pattern along with its own paint, depth and recall.
instance uniform vec3 painted_light_origin;
instance uniform vec4 painted_light_x;
instance uniform vec4 painted_light_y;
instance uniform vec4 painted_light_z;
instance uniform vec4 painted_light_settings = vec4(0.0);
instance uniform vec4 painted_light_color : source_color;
instance uniform vec4 painted_light_accent : source_color;

float painted_light_hash(vec2 cell) {
	vec3 p = fract(vec3(cell.xyx) * 0.1031);
	p += dot(p, p.yzx + 33.33);
	return fract((p.x + p.y) * p.z);
}

float painted_light_noise(vec2 p) {
	vec2 cell = floor(p);
	vec2 f = fract(p);
	f *= f * (3.0 - 2.0 * f);
	return mix(
		mix(painted_light_hash(cell), painted_light_hash(cell + vec2(1.0, 0.0)), f.x),
		mix(painted_light_hash(cell + vec2(0.0, 1.0)), painted_light_hash(cell + vec2(1.0)), f.x),
		f.y
	);
}

vec3 apply_painted_light(vec3 base, vec3 world, vec3 normal, float receive) {
	float strength = painted_light_settings.x * receive;
	if (strength <= 0.0) {
		return base;
	}
	vec3 offset = world - painted_light_origin;
	vec3 p = vec3(dot(offset, painted_light_x.xyz), dot(offset, painted_light_y.xyz), dot(offset, painted_light_z.xyz));
	vec3 q = p * vec3(painted_light_x.w, painted_light_y.w, painted_light_z.w);
	float falloff = 1.0 - smoothstep(0.18, 1.0, length(q));
	if (falloff <= 0.0) {
		return base;
	}
	float facing = smoothstep(-0.14, 0.74, dot(normal, painted_light_z.xyz));
	float amount = strength * falloff;
	float t = TIME * painted_light_settings.z;
	vec2 marks = p.xy * painted_light_settings.y;
	if (painted_light_settings.w > 1.5) {
		// Broad, overlapping shade with soft edges and a little warmth in the gaps.
		vec2 drift = vec2(sin(t * 0.83) * 0.41, sin(t * 0.57 + 1.3) * 0.28);
		vec2 canopy_uv = marks * vec2(0.67, 1.0) + drift;
		float canopy = painted_light_noise(canopy_uv + vec2(7.2, 3.5));
		float edges = painted_light_noise(canopy_uv * 1.8 + vec2(canopy, -canopy));
		float opening = canopy * 0.78 + edges * 0.22;
		float shade = 1.0 - smoothstep(0.27, 0.64, opening);
		float sun = smoothstep(0.46, 0.83, opening);
		vec3 shadowed = base * mix(vec3(0.81), painted_light_accent.rgb, 0.15);
		vec3 sunlit = base + painted_light_color.rgb * (1.0 - base) * 0.10;
		amount *= mix(0.10, 1.0, facing);
		return mix(mix(base, shadowed, amount * shade), sunlit, amount * sun);
	}
	if (painted_light_settings.w < 0.5) {
		amount *= mix(0.10, 1.0, facing);
		// The canopy sways as a group with smaller movements moving through it.
		marks += vec2(sin(t * 0.91) * 0.44, sin(t * 0.63 + 1.8) * 0.29);
		marks += vec2(sin(marks.y * 1.4 + t * 1.6), sin(marks.x + t * 1.1)) * 0.18;
		float canopy = painted_light_noise(marks * 0.61 + vec2(7.2, 3.5));
		float detail = painted_light_noise(marks * 1.63 + vec2(canopy, -canopy) * 0.93);
		float opening = canopy * 0.62 + detail * 0.38;
		float sun = smoothstep(0.50, 0.64, opening);
		float shade = 1.0 - smoothstep(0.25, 0.51, opening);

		// Small tilted flecks sit inside the broad, irregular openings.
		vec2 fleck_uv = mat2(vec2(0.87, 0.49), vec2(-0.49, 0.87)) * marks * 1.34;
		vec2 cell = floor(fleck_uv);
		vec2 scatter = vec2(painted_light_hash(cell), painted_light_hash(cell + vec2(3.7, 9.1)));
		vec2 fleck = fract(fleck_uv) - 0.5 - (scatter - 0.5) * 0.24;
		fleck.x += fleck.y * (scatter.x - 0.5) * 0.55;
		float shape = length(fleck * vec2(3.2, 5.4));
		float flecks = (1.0 - smoothstep(0.42, 1.0, shape)) * smoothstep(0.29, 0.59, canopy);
		vec3 shadowed = base * mix(vec3(0.62), painted_light_accent.rgb, 0.32);
		vec3 sunlit = base * 1.10 + painted_light_color.rgb * (1.0 - base * 0.64) * 0.53;
		return mix(mix(base, shadowed, amount * shade * 0.62), sunlit, amount * max(sun * 0.75, flecks));
	}

	// Soft overlapping color pools drift sideways like reflected cabinet light.
	amount *= mix(0.39, 1.0, facing);
	vec2 sweep = marks + vec2(sin(t * 0.85) * 0.46, cos(t * 0.69) * 0.25);
	float edges = painted_light_noise(sweep * vec2(1.2, 2.0) + vec2(4.8, 8.1));
	float wash = sin(sweep.x * 1.8 - sweep.y * 0.85 + edges * 1.48);
	float blend = smoothstep(-0.42, 0.42, wash);
	float pool = 0.30 + 0.70 * smoothstep(0.23, 0.92, abs(wash));
	vec3 tint = mix(painted_light_color.rgb, painted_light_accent.rgb, blend);
	vec3 lit = base * (1.0 + tint * 0.34) + tint * (1.0 - base * 0.45) * 0.54;
	return mix(base, lit, amount * pool);
}
