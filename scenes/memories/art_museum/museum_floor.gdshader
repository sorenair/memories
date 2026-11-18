shader_type spatial;
render_mode unshaded, cull_disabled, shadows_disabled;
varying vec2 floor_position;

void vertex() {
	floor_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xz;
}

float trace(vec2 p, vec2 a, vec2 b, float width) {
	vec2 axis = b - a;
	float t = clamp(dot(p - a, axis) / dot(axis, axis), 0.0, 1.0);
	return width - length(p - mix(a, b, t));
}

float gallery(vec2 p, vec2 center, vec2 radius) {
	return (1.0 - length((p - center) / radius)) * min(radius.x, radius.y);
}

void fragment() {
	vec2 p = floor_position;
	float field = trace(p, vec2(0, 4), vec2(0, 6.6), 2.8);
	field = max(field, trace(p, vec2(0, -3.8), vec2(0, -9.6), 2.05));
	field = max(field, gallery(p, vec2(0, -10.5), vec2(5.7, 3.6)));
	for (int side = -1; side <= 1; side += 2) {
		float s = float(side);
		vec2 turn = vec2(s * 10.55, -10.8);
		field = max(field, trace(p, vec2(s * 3.1, -10.65), turn, 1.68));
		field = max(field, trace(p, turn, vec2(s * 14.5, -14.6), 1.87));
		field = max(field, gallery(p, vec2(s * 14.5, -16.5), vec2(5.4, 4.65)));
	}
	float erosion = 0.19 * sin(p.x * 2.5 + p.y * 1.8) + 0.12 * cos(p.y * 4.0 - p.x);
	float coverage = smoothstep(0.0, 1.42, field + erosion);
	// Let the portico's stone steps own their surface and feather to their toes.
	coverage *= smoothstep(3.50, 4.05, abs(p.y));
	if (coverage < 0.003) { discard; }
	vec2 tile = p / vec2(1.42, 1.12);
	tile.x += 0.5 * mod(floor(tile.y), 2.0);
	vec2 edge = min(fract(tile), 1.0 - fract(tile));
	float joints = 1.0 - smoothstep(0.006, 0.024, min(edge.x, edge.y));
	float tone = fract(sin(dot(floor(tile), vec2(36.5, 19.2))) * 17913.7);
	ALBEDO = mix(vec3(0.73, 0.705, 0.644), vec3(0.79, 0.764, 0.703), tone) - joints * 0.045;
	ALPHA = coverage * 0.87;
}
