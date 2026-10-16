// Default solid recall: upward scan with an irregular cream-white resolving edge.
// Call per fragment in the mesh's local coordinates; bounds come from its AABB.
uniform float recall_solid_progress = 0.0;
uniform vec2 recall_solid_bounds = vec2(0.0, 1.0);
uniform vec4 recall_void_color : source_color = vec4(0.94, 0.935, 0.89, 1.0);

float solid_recall_clarity(vec3 position) {
	if (recall_solid_progress <= 0.0) { return 0.0; }
	if (recall_solid_progress >= 1.0) { return 1.0; }
	float height = (position.y - recall_solid_bounds.x) / max(recall_solid_bounds.y - recall_solid_bounds.x, 0.01);
	float grain = sin(position.x * 8.0 + sin(position.z * 6.0)) * 0.025;
	return clamp((recall_solid_progress * 1.12 - height - grain) / 0.09, 0.0, 1.0);
}
