// A shared vertical scan across all parts of a component, including moving parts.
// Defaults keep ordinary, non-recalled instances fully painted.
uniform float assembly_progress = 1.0;
uniform vec2 assembly_bounds = vec2(0.0, 1.0);
varying vec3 assembly_position;
float assembly_clarity(vec3 world) {
	if (assembly_progress <= 0.0) { return 0.0; }
	if (assembly_progress >= 1.0) { return 1.0; }
	float height = (world.y - assembly_bounds.x) / max(assembly_bounds.y - assembly_bounds.x, 0.01);
	float grain = sin(world.x * 8.0 + sin(world.z * 6.0)) * 0.025;
	return clamp((assembly_progress * 1.12 - height - grain) / 0.09, 0.0, 1.0);
}
