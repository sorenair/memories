vec3 smoke_center(float h, float t) {
	h = clamp(h, 0.0, 1.0);
	vec2 center = wind * h * h * 2.1;
	center += vec2(sin(h * 6.0 - t * 0.48 + fire_phase), cos(h * 5.2 - t * 0.37)) * h * smoke_spread * smoke_turbulence * 0.32;
	center += vec2(sin(h * 12.0 - t * 0.8), cos(h * 9.0 - t * 0.65)) * h * smoke_turbulence * 0.035;
	return vec3(center.x, smoke_base_height() + h * smoke_height, center.y);
}
