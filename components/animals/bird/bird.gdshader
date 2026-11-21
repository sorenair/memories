shader_type spatial;
render_mode unshaded, fog_disabled, cull_disabled;

varying vec3 paint;
varying vec3 local_position;

void vertex() {
	float key = dot(normalize(MODEL_NORMAL_MATRIX * NORMAL), normalize(vec3(-0.45, 0.82, -0.35)));
	float shade = mix(0.86, 1.0, smoothstep(-0.46, 0.64, key));
	// Shared soft lighting at the body and wing roots keeps the hinge seam quiet.
	shade = mix(shade, 0.94, UV2.x * 0.78);
	paint = COLOR.rgb * shade;
	local_position = VERTEX;
}

void fragment() {
	float wash = sin(local_position.z * 14.0 + local_position.x * 7.0 + sin(local_position.x * 12.0));
	ALBEDO = paint * (0.98 + wash * 0.018);
}
