// Shared world-space front; radius is allowed to start negative for an empty frame.
uniform vec3 recall_origin = vec3(0.0);
uniform float recall_radius = -2.0;
uniform float recall_feather = 1.5;
uniform float recall_complete = 0.0;
uniform vec4 recall_void_color : source_color = vec4(0.94, 0.935, 0.89, 1.0);

float recall_field(vec2 root) {
	float irregularity = sin(root.x * 1.8 + sin(root.y * 1.3)) * 0.16
		+ sin(root.y * 3.1 + root.x * 0.7) * 0.08;
	float distance_from_origin = length(root - recall_origin.xz) + irregularity;
	return mix(clamp((recall_radius - distance_from_origin) / max(recall_feather, 0.01), 0.0, 1.0), 1.0, recall_complete);
}
